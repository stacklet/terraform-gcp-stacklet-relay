# Subscribe to security command center findings

# The topic where the findings notifications will be sent.
resource "google_pubsub_topic" "scc_findings_feed" {
  count = var.relay_security_command_center_findings ? 1 : 0
  name  = "${local.prefix}scc-findings-feed"
}

# Project needs to have enabled cloud asset inventory API

resource "google_scc_v2_organization_notification_config" "organization_feed" {
  count        = (var.relay_security_command_center_findings && var.organization_id != "") ? 1 : 0
  config_id    = "${local.prefix}stacklet-scc-feed"
  organization = var.organization_id
  pubsub_topic = google_pubsub_topic.scc_findings_feed[0].id

  streaming_config {
    filter = var.security_findings_filter
  }
}

resource "google_scc_v2_folder_notification_config" "folder_feed" {
  count        = var.relay_security_command_center_findings ? length(var.folder_ids) : 0
  config_id    = "${local.prefix}folder-feed-${var.folder_ids[count.index]}"
  folder       = var.folder_ids[count.index]
  pubsub_topic = google_pubsub_topic.scc_findings_feed[0].id

  streaming_config {
    filter = var.security_findings_filter
  }
}

resource "google_scc_v2_project_notification_config" "project_feed" {
  count        = var.relay_security_command_center_findings ? length(var.project_ids) : 0
  config_id    = "${local.prefix}project-feed-${var.project_ids[count.index]}"
  project      = var.project_ids[count.index]
  pubsub_topic = google_pubsub_topic.scc_findings_feed[0].id

  streaming_config {
    filter = var.security_findings_filter
  }
}

