# Subscribe to the audit log
locals {
  # "cloudaudit.googleapis.com/activity" is the log name for "Admin Activity"
  # audit logs. The %2F encoding represents / when using filters in Terraform.
  # This filter ensures that only logs related to user-initiated API calls
  # are forwarded to the Pub/Sub topic.
  audit_filter = "logName:\"cloudaudit.googleapis.com%2Factivity\""
}

# Workaround for https://github.com/hashicorp/terraform-provider-google/issues/10811
# Force recreation of sinks when include_children changes
resource "terraform_data" "include_children_trigger" {
  input = var.audit_log_include_children
}

resource "google_pubsub_topic" "audit_feed" {
  count = var.relay_audit_log ? 1 : 0
  name  = "${local.prefix}audit-feed"
}

resource "google_logging_organization_sink" "organization_audit_feed" {
  count       = (var.relay_audit_log && var.organization_id != "") ? 1 : 0
  name        = "${local.prefix}audit-feed"
  description = "Organization level audit logs for Stacklet relay"

  org_id           = var.organization_id
  filter           = local.audit_filter
  include_children = var.audit_log_include_children

  destination = "pubsub.googleapis.com/${google_pubsub_topic.audit_feed[0].id}"

  lifecycle {
    replace_triggered_by = [terraform_data.include_children_trigger]
  }
}
resource "google_pubsub_topic_iam_member" "organization_feed_publisher" {
  count  = (var.relay_audit_log && var.organization_id != "") ? 1 : 0
  topic  = google_pubsub_topic.audit_feed[0].name
  role   = "roles/pubsub.publisher"
  member = google_logging_organization_sink.organization_audit_feed[0].writer_identity
}

resource "google_logging_folder_sink" "folder_feed" {
  count       = var.relay_audit_log ? length(var.folder_ids) : 0
  name        = "${local.prefix}folder-audit-feed-${var.folder_ids[count.index]}"
  description = "Folder level audit logs for Stacklet relay"

  folder           = var.folder_ids[count.index]
  filter           = local.audit_filter
  include_children = var.audit_log_include_children

  destination = "pubsub.googleapis.com/${google_pubsub_topic.audit_feed[0].id}"

  lifecycle {
    replace_triggered_by = [terraform_data.include_children_trigger]
  }
}
resource "google_pubsub_topic_iam_member" "folder_feed_publisher" {
  count  = var.relay_audit_log ? length(var.folder_ids) : 0
  topic  = google_pubsub_topic.audit_feed[0].name
  role   = "roles/pubsub.publisher"
  member = google_logging_folder_sink.folder_feed[count.index].writer_identity
}

resource "google_logging_project_sink" "project_feed" {
  count       = var.relay_audit_log ? length(var.project_ids) : 0
  name        = "${local.prefix}project-audit-feed-${var.project_ids[count.index]}"
  description = "Project level audit logs for Stacklet relay"

  project = var.project_ids[count.index]
  filter  = local.audit_filter

  destination = "pubsub.googleapis.com/${google_pubsub_topic.audit_feed[0].id}"
}

resource "google_pubsub_topic_iam_member" "project_feed_publisher" {
  count  = var.relay_audit_log ? length(var.project_ids) : 0
  topic  = google_pubsub_topic.audit_feed[0].name
  role   = "roles/pubsub.publisher"
  member = google_logging_project_sink.project_feed[count.index].writer_identity
}
