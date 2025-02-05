# Subscribe to the cloud asset inventory

# The topic where the resource change notifications will be sent.
resource "google_pubsub_topic" "feed_output" {
  name = "${local.prefix}asset-feed"
}

# Project needs to have enabled cloud asset inventory API

resource "google_cloud_asset_organization_feed" "organization_feed" {
  count           = var.organization_id == "" ? 0 : 1
  billing_project = var.project_id
  org_id          = var.organization_id
  feed_id         = "${local.prefix}stacklet-resource-feed"
  content_type    = "RESOURCE"

  # https://cloud.google.com/asset-inventory/docs/supported-asset-types
  # but only those marked as supported in custodian.
  asset_types = var.asset_types

  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.feed_output.id
    }
  }
}

resource "google_cloud_asset_folder_feed" "folder_feed" {
  count           = length(var.folder_ids)
  billing_project = var.project_id
  folder          = var.folder_ids[count.index]
  feed_id         = "${local.prefix}folder-feed-${var.folder_ids[count.index]}"
  content_type    = "RESOURCE"

  # https://cloud.google.com/asset-inventory/docs/supported-asset-types
  # but only those marked as supported in custodian.
  asset_types = var.asset_types

  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.feed_output.id
    }
  }
}

# Create a feed that sends notifications about network resource updates.
resource "google_cloud_asset_project_feed" "project_feed" {
  count           = length(var.project_ids)
  project         = var.project_ids[count.index]
  billing_project = var.project_id
  feed_id         = "${local.prefix}project-feed-${var.project_ids[count.index]}"
  content_type    = "RESOURCE"

  asset_types = var.asset_types

  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.feed_output.id
    }
  }
}

