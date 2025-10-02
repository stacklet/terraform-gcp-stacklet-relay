# Subscribe to the audit log
locals {
  # "cloudaudit.googleapis.com/activity" is the log name for "Admin Activity"
  # audit logs. The %2F encoding represents / when using filters in Terraform.
  # This filter ensures that only logs related to user-initiated API calls
  # are forwarded to the Pub/Sub topic.
  audit_filter = "logName:\"cloudaudit.googleapis.com%2Factivity\""
}

resource "google_pubsub_topic" "audit_feed" {
  count = var.relay_audit_log ? 1 : 0
  name  = "${local.prefix}audit-feed"
}

# Workaround for https://github.com/hashicorp/terraform-provider-google/issues/10811
# Separate resources for include_children true/false to force recreation on change

resource "google_logging_organization_sink" "organization_audit_feed_with_children" {
  count       = (var.relay_audit_log && var.organization_id != "" && var.audit_log_include_children) ? 1 : 0
  name        = "${local.prefix}audit-feed-with-children"
  description = "Organization level audit logs for Stacklet relay"

  org_id           = var.organization_id
  filter           = local.audit_filter
  include_children = true

  destination = "pubsub.googleapis.com/${google_pubsub_topic.audit_feed[0].id}"
}

resource "google_logging_organization_sink" "organization_audit_feed_without_children" {
  count       = (var.relay_audit_log && var.organization_id != "" && !var.audit_log_include_children) ? 1 : 0
  name        = "${local.prefix}audit-feed-without-children"
  description = "Organization level audit logs for Stacklet relay"

  org_id           = var.organization_id
  filter           = local.audit_filter
  include_children = false

  destination = "pubsub.googleapis.com/${google_pubsub_topic.audit_feed[0].id}"
}

resource "google_pubsub_topic_iam_member" "organization_feed_publisher" {
  count  = (var.relay_audit_log && var.organization_id != "") ? 1 : 0
  topic  = google_pubsub_topic.audit_feed[0].name
  role   = "roles/pubsub.publisher"
  member = var.audit_log_include_children ? google_logging_organization_sink.organization_audit_feed_with_children[0].writer_identity : google_logging_organization_sink.organization_audit_feed_without_children[0].writer_identity
}

resource "google_logging_folder_sink" "folder_feed_with_children" {
  count       = (var.relay_audit_log && var.audit_log_include_children) ? length(var.folder_ids) : 0
  name        = "${local.prefix}folder-audit-feed-${var.folder_ids[count.index]}-with-children"
  description = "Folder level audit logs for Stacklet relay"

  folder           = var.folder_ids[count.index]
  filter           = local.audit_filter
  include_children = true

  destination = "pubsub.googleapis.com/${google_pubsub_topic.audit_feed[0].id}"
}

resource "google_logging_folder_sink" "folder_feed_without_children" {
  count       = (var.relay_audit_log && !var.audit_log_include_children) ? length(var.folder_ids) : 0
  name        = "${local.prefix}folder-audit-feed-${var.folder_ids[count.index]}-without-children"
  description = "Folder level audit logs for Stacklet relay"

  folder           = var.folder_ids[count.index]
  filter           = local.audit_filter
  include_children = false

  destination = "pubsub.googleapis.com/${google_pubsub_topic.audit_feed[0].id}"
}

resource "google_pubsub_topic_iam_member" "folder_feed_publisher" {
  count  = var.relay_audit_log ? length(var.folder_ids) : 0
  topic  = google_pubsub_topic.audit_feed[0].name
  role   = "roles/pubsub.publisher"
  member = var.audit_log_include_children ? google_logging_folder_sink.folder_feed_with_children[count.index].writer_identity : google_logging_folder_sink.folder_feed_without_children[count.index].writer_identity
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
