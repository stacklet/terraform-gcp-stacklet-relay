resource "google_cloudfunctions2_function" "scc_finding_relay" {
  count       = var.relay_security_command_center_findings ? 1 : 0
  name        = "${local.prefix}scc-finding-relay"
  location    = var.location
  description = "Stacklet security command center finding relay"

  build_config {
    runtime     = "python312"
    entry_point = "forward_event"
    environment_variables = {
      # Causes a re-deploy of the function when the source changes
      "SOURCE_SHA" = data.archive_file.function_source.output_sha
    }

    source {
      storage_source {
        bucket = local.function_source_bucket
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    environment_variables = {
      AWS_EVENT_BUS     = var.aws_event_bus
      AWS_ROLE          = var.aws_role
      LOG_DEBUG         = var.log_debug ? "DEBUG" : ""
      RELAY_DETAIL_TYPE = "GCP SCC Finding"

    }
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
    service_account_email = var.service_account
  }

  event_trigger {
    trigger_region = var.location
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.scc_findings_feed[0].id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}

resource "google_cloudfunctions2_function_iam_member" "scc_finding_relay_invoker" {
  count          = var.relay_security_command_center_findings ? 1 : 0
  location       = google_cloudfunctions2_function.scc_finding_relay[0].location
  cloud_function = google_cloudfunctions2_function.scc_finding_relay[0].name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.service_account}"
}

resource "google_cloud_run_service_iam_member" "scc_finding_relay_invoker" {
  count    = var.relay_security_command_center_findings ? 1 : 0
  location = google_cloudfunctions2_function.scc_finding_relay[0].location
  service  = google_cloudfunctions2_function.scc_finding_relay[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_account}"
}
