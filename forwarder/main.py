import base64
import functools
import json

from datetime import datetime, UTC
import logging
from typing import Any

import boto3
import boto3.session
import functions_framework
import os

from cloudevents.http import CloudEvent
from google.auth.compute_engine import IDTokenCredentials
from google.auth.transport.requests import Request
import google.cloud.logging

# Both the role and the event bus are provided with full ARNs
AWS_ROLE = os.environ["AWS_ROLE"]
AWS_EVENT_BUS = os.environ["AWS_EVENT_BUS"]


logger = logging.getLogger("relay")


def get_gcp_identity_token(audience: str) -> str:
    request = Request()
    credentials = IDTokenCredentials(
        request=request, target_audience=audience, use_metadata_identity_endpoint=True
    )
    credentials.refresh(request)
    return credentials.token  # type:ignore


def get_events_client(identity_token: str, region: str):
    client = boto3.client("sts")
    res = client.assume_role_with_web_identity(
        RoleArn=AWS_ROLE,
        RoleSessionName="StackletGCPRelay",
        WebIdentityToken=identity_token,
    )

    session = boto3.session.Session(
        aws_access_key_id=res["Credentials"]["AccessKeyId"],
        aws_secret_access_key=res["Credentials"]["SecretAccessKey"],
        aws_session_token=res["Credentials"]["SessionToken"],
    )
    return session.client("events", region)


def get_detail_from_cloud_event(cloud_event: CloudEvent) -> dict[str, Any] | None:
    data = base64.b64decode(cloud_event.data["message"]["data"])
    try:
        return {
            "change_event": json.loads(data),
            "type": cloud_event["type"],
            "specversion": cloud_event["specversion"],
            "source": cloud_event["source"],
            "id": cloud_event["id"],
            "time": cloud_event["time"],
        }
    except json.decoder.JSONDecodeError:
        logger.debug(f"not JSON, {data=}")
        return None


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
    setup()
    identity_token = get_gcp_identity_token("sts.amazonaws.com")
    bus_parts = AWS_EVENT_BUS.split(":")
    region = bus_parts[3]
    bus_name = bus_parts[-1].split("/", 1)[1]
    if client := get_events_client(identity_token, region):
        if payload := get_detail_from_cloud_event(cloud_event):
            logger.debug(f"sending event {payload=}")
            response = client.put_events(
                Entries=[
                    {
                        "Time": datetime.now(UTC),
                        "Source": "GCP Relay",
                        "DetailType": "GCP Cloud Asset Change",
                        "Detail": json.dumps(payload),
                        "EventBusName": bus_name,
                    }
                ]
            )
            logger.debug(f"put_events {response=}")
    else:
        logger.warning("could not get events client")
