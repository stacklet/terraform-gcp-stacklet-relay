import base64
import functools
import json

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

# Cache AWS credentials at module level (credentials are valid for 1 hour)
_cached_credentials = None
_credentials_expiry = None

# Cache GCP identity token at module level (tokens are valid for 1 hour)
_cached_gcp_token = None
_cached_gcp_token_expiry = None

# Module-level boto3 clients with connection pooling
# Connection pool size matches Cloud Run concurrency setting
CONCURRENCY = int(os.environ.get("CLOUD_RUN_CONCURRENCY", "100"))
_boto_config = Config(
    max_pool_connections=CONCURRENCY,
    retries={'max_attempts': 3, 'mode': 'standard'}
)
_sts_client = None
_events_clients = {}  # Cache events clients per region


def get_sts_client():
    """Get or create the STS client with connection pooling."""
    global _sts_client
    if _sts_client is None:
        _sts_client = boto3.client('sts', config=_boto_config)
    return _sts_client


def get_events_client(region: str, credentials: dict):
    """Get or create an EventBridge client for the specified region."""
    # Cache key includes region and credential expiry to handle credential rotation
    cache_key = f"{region}_{credentials.get('Expiration', '')}"

    if cache_key not in _events_clients:
        _events_clients[cache_key] = boto3.client(
            'events',
            region_name=region,
            aws_access_key_id=credentials["AccessKeyId"],
            aws_secret_access_key=credentials["SecretAccessKey"],
            aws_session_token=credentials["SessionToken"],
            config=_boto_config
        )

    return _events_clients[cache_key]


def get_gcp_identity_token(audience: str) -> str:
    global _cached_gcp_token, _cached_gcp_token_expiry

    now = datetime.now(UTC)

    # Refresh token if expired or about to expire (5 minute buffer)
    if not _cached_gcp_token or not _cached_gcp_token_expiry or \
       (now + timedelta(minutes=5)) >= _cached_gcp_token_expiry:

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
    else:
        logger.debug(f"Using cached GCP identity token (valid until {_cached_gcp_token_expiry})")

    return _cached_gcp_token  # type:ignore


def get_aws_credentials(identity_token: str) -> dict:
    """
    Get AWS credentials via STS AssumeRoleWithWebIdentity.
    Returns cached credentials if still valid.
    """
    global _cached_credentials, _credentials_expiry

    now = datetime.now(UTC)

    # Refresh credentials if expired or about to expire (5 minute buffer)
    if not _cached_credentials or not _credentials_expiry or \
       (now + timedelta(minutes=5)) >= _credentials_expiry:

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
    else:
        logger.debug(f"Using cached AWS credentials (valid until {_credentials_expiry})")

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
    Cloud Run's concurrency model handles parallelism across 100 concurrent requests.
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
    Synchronous event forwarding using boto3 with connection pooling.
    Cloud Run handles concurrency with up to 100 concurrent requests per instance.
    """
    setup()

    identity_token = get_gcp_identity_token("sts.amazonaws.com")
    bus_parts = AWS_EVENT_BUS.split(":")
    region = bus_parts[3]
    bus_name = bus_parts[-1].split("/", 1)[1]

    credentials = get_aws_credentials(identity_token)

    try:
        if payload := get_detail_from_cloud_event(cloud_event):
            send_event_to_aws(credentials, region, payload, bus_name, DETAIL_TYPE)
        else:
            logger.warning("could not parse cloud event payload")
    except Exception as e:
        logger.warning(f"could not get events client: {e}")
