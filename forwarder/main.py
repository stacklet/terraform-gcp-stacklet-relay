import base64
import functools
import json
import threading

from datetime import datetime, UTC, timedelta
import logging
from typing import Any

import boto3
from botocore.config import Config
import functions_framework
import os

from cloudevents.http import CloudEvent
from google.auth.compute_engine import IDTokenCredentials
from google.auth.transport.requests import Request
import google.cloud.logging

# Both the role and the event bus are provided with full ARNs
AWS_ROLE = os.environ["AWS_ROLE"]
AWS_EVENT_BUS = os.environ["AWS_EVENT_BUS"]
DETAIL_TYPE = os.environ["RELAY_DETAIL_TYPE"]

logger = logging.getLogger("relay")

# Threading and Parallelism Model:
# Cloud Run handles parallelism by processing up to CLOUD_RUN_CONCURRENCY (default: 80)
# concurrent requests per instance. Each request runs in its own thread, so multiple
# threads may simultaneously access the module-level cached credentials and tokens below.
# The threading.Lock() objects protect shared state during credential refresh operations,
# using a double-checked locking pattern for optimal performance (fast path without lock,
# slow path with lock only when refresh is needed).

# Cache AWS credentials at module level (credentials are valid for 1 hour)
_cached_credentials = None
_credentials_expiry = None
_credentials_lock = threading.Lock()

# Cache GCP identity token at module level (tokens are valid for 1 hour)
_cached_gcp_token = None
_cached_gcp_token_expiry = None
_gcp_token_lock = threading.Lock()

# Module-level boto3 clients with connection pooling
# Connection pool size matches Cloud Run concurrency setting
# with default set to tf vars default (also the Cloud Run default)
CONCURRENCY = int(os.environ.get("CLOUD_RUN_CONCURRENCY", "80"))
_boto_config = Config(
    max_pool_connections=CONCURRENCY,
    retries={'max_attempts': 3, 'mode': 'standard'}
)

# Pre-compute timedelta to avoid creating it on every request
_REFRESH_BUFFER = timedelta(minutes=5)


def _needs_refresh(cached_value: Any, expiry: datetime | None, current_time: datetime) -> bool:
    """
    Check if a cached credential or token needs refresh.

    Args:
        cached_value: The cached credential or token (None if not cached)
        expiry: When the cached value expires (None if not set)
        current_time: Current time to check against expiry

    Returns:
        True if the value needs refresh, False if still valid
    """
    if not cached_value or expiry is None:
        return True
    return (current_time + _REFRESH_BUFFER) >= expiry


_sts_client = None
_sts_client_lock = threading.Lock()
_events_client = None  # Single cached events client
_events_client_lock = threading.Lock()
_events_client_expiry = None


def get_sts_client():
    """
    Get or create the STS client with connection pooling.

    Note: The STS client does not require AWS credentials - it's used to OBTAIN
    credentials via AssumeRoleWithWebIdentity. It only needs to be created once
    per instance and can be reused throughout the instance lifecycle. Only the
    EventBridge client needs to be recreated when credentials expire.
    """
    global _sts_client

    # Fast path - client already exists
    if _sts_client is not None:
        return _sts_client

    # Slow path - need to create client
    with _sts_client_lock:
        # Double-check after acquiring lock (another thread may have created it)
        if _sts_client is None:
            logger.info("Creating STS client with connection pooling")
            _sts_client = boto3.client('sts', config=_boto_config)

    return _sts_client


def get_events_client(region: str, credentials: dict):
    """
    Get or create an EventBridge client for the specified region.
    Client is cached and recreated when credentials expire.
    """
    global _events_client, _events_client_expiry

    credentials_expiry = credentials.get("Expiration")

    # Check if client needs to be (re)created
    needs_refresh = (
        _events_client is None
        or _events_client_expiry is None
        or credentials_expiry != _events_client_expiry
    )

    if needs_refresh:
        with _events_client_lock:
            # Double-check after acquiring lock to prevent duplicate creation
            if (
                _events_client is None
                or _events_client_expiry is None
                or credentials_expiry != _events_client_expiry
            ):
                logger.info(f"Creating new EventBridge client for region {region}")
                _events_client = boto3.client(
                    'events',
                    region_name=region,
                    aws_access_key_id=credentials["AccessKeyId"],
                    aws_secret_access_key=credentials["SecretAccessKey"],
                    aws_session_token=credentials["SessionToken"],
                    config=_boto_config
                )
                _events_client_expiry = credentials_expiry

    return _events_client


def get_gcp_identity_token(audience: str, current_time: datetime) -> str:
    """Get GCP identity token with caching. Pass current time to avoid repeated datetime calls."""
    global _cached_gcp_token, _cached_gcp_token_expiry

    # Check if refresh needed without lock first (fast path)
    if _needs_refresh(_cached_gcp_token, _cached_gcp_token_expiry, current_time):
        with _gcp_token_lock:
            # Double-check after acquiring lock (another thread may have refreshed)
            now = datetime.now(UTC)
            if _needs_refresh(_cached_gcp_token, _cached_gcp_token_expiry, now):
                logger.info("Refreshing GCP identity token (expired or not cached)")

                request = Request()
                credentials = IDTokenCredentials(
                    request=request, target_audience=audience, use_metadata_identity_endpoint=True
                )
                credentials.refresh(request)

                _cached_gcp_token = credentials.token
                # GCP tokens are typically valid for 1 hour, set expiry to 55 minutes from now
                _cached_gcp_token_expiry = now + timedelta(minutes=55)

                logger.info(f"GCP identity token cached until {_cached_gcp_token_expiry}")

    return _cached_gcp_token  # type:ignore


def get_aws_credentials(identity_token: str, current_time: datetime) -> dict:
    """
    Get AWS credentials via STS AssumeRoleWithWebIdentity.
    Returns cached credentials if still valid.
    Pass current time to avoid repeated datetime calls.
    """
    global _cached_credentials, _credentials_expiry

    # Check if refresh needed without lock first (fast path)
    if _needs_refresh(_cached_credentials, _credentials_expiry, current_time):
        with _credentials_lock:
            # Double-check after acquiring lock (another thread may have refreshed)
            now = datetime.now(UTC)
            if _needs_refresh(_cached_credentials, _credentials_expiry, now):
                logger.info("Refreshing AWS credentials (expired or not cached)")

                sts_client = get_sts_client()
                res = sts_client.assume_role_with_web_identity(
                    RoleArn=AWS_ROLE,
                    RoleSessionName="StackletGCPRelay",
                    WebIdentityToken=identity_token,
                )

                _cached_credentials = res["Credentials"]
                _credentials_expiry = res["Credentials"]["Expiration"]

                logger.info(f"AWS credentials cached until {_credentials_expiry}")

    return _cached_credentials


def get_detail_from_cloud_event(cloud_event: CloudEvent) -> dict[str, Any] | None:
    data = base64.b64decode(cloud_event.data["message"]["data"])
    try:
        return {
            "event": json.loads(data),
            "type": cloud_event["type"],
            "specversion": cloud_event["specversion"],
            "source": cloud_event["source"],
            "id": cloud_event["id"],
            "time": cloud_event["time"],
        }
    except json.decoder.JSONDecodeError:
        logger.debug(f"not JSON, {data=}")
        return None


def send_event_to_aws(credentials: dict, region: str, payload: dict, bus_name: str, detail_type: str):
    """
    Send event to AWS EventBridge using synchronous boto3 with connection pooling.
    Cloud Run's concurrency model handles parallelism across 'CLOUD_RUN_CONCURRENCY' concurrent requests.
    """
    logger.debug(f"sending event {payload=}")

    events_client = get_events_client(region, credentials)
    response = events_client.put_events(
        Entries=[
            {
                "Time": datetime.now(UTC),
                "Source": "GCP Relay",
                "DetailType": detail_type,
                "Detail": json.dumps(payload),
                "EventBusName": bus_name,
            }
        ]
    )

    logger.debug(f"put_events {response=}")
    return response


@functools.cache
def setup():
    base_log_level = logging.DEBUG if os.environ.get("LOG_DEBUG") else logging.INFO
    client = google.cloud.logging.Client()
    client.setup_logging(log_level=base_log_level)
    logging.getLogger("botocore").setLevel(logging.ERROR)
    logging.getLogger("urllib3").setLevel(logging.ERROR)


# Triggered from a message on a Cloud Pub/Sub topic.
@functions_framework.cloud_event
def forward_event(cloud_event: CloudEvent):
    """
    Synchronous event forwarding using boto3 with connection pooling,
    with concurrency set per the ENV
    """
    setup()

    # Get current time once and pass to credential functions to avoid repeated calls
    current_time = datetime.now(UTC)

    identity_token = get_gcp_identity_token("sts.amazonaws.com", current_time)
    bus_parts = AWS_EVENT_BUS.split(":")
    region = bus_parts[3]
    bus_name = bus_parts[-1].split("/", 1)[1]

    credentials = get_aws_credentials(identity_token, current_time)

    try:
        if payload := get_detail_from_cloud_event(cloud_event):
            send_event_to_aws(credentials, region, payload, bus_name, DETAIL_TYPE)
        else:
            logger.warning(f"could not parse cloud event payload: {cloud_event}")
    except Exception as e:
        logger.error(f"Error forwarding event to AWS EventBridge: {e}")
