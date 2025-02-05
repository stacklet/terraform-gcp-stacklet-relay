data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/forwarder"
  output_path = "${path.module}/function-source.zip"
}

resource "google_storage_bucket" "function_source_bucket" {
  count                       = var.function_source_bucket == "" ? 1 : 0
  name                        = "${var.prefix}-${var.project_id}-gcf-source" # Every bucket name must be globally unique
  location                    = var.function_source_bucket_location
  uniform_bucket_level_access = true
}

locals {
  function_source_bucket = var.function_source_bucket == "" ? google_storage_bucket.function_source_bucket[0].name : var.function_source_bucket
}

resource "google_storage_bucket_object" "function_source" {
  name   = var.function_source_object_name
  bucket = local.function_source_bucket
  source = data.archive_file.function_source.output_path
}


resource "google_cloudfunctions2_function" "function" {
  name        = "${var.prefix}-relay"
  location    = var.location
  description = "Stacklet cloud asset changes relay"

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
      AWS_EVENT_BUS = var.aws_event_bus
      AWS_ROLE      = var.aws_role
      LOG_DEBUG     = var.log_debug ? "DEBUG" : ""
    }
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
    service_account_email = var.service_account
  }

  event_trigger {
    trigger_region = var.location
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.feed_output.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}

resource "google_cloudfunctions2_function_iam_member" "invoker" {
  location       = google_cloudfunctions2_function.function.location
  cloud_function = google_cloudfunctions2_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.service_account}"
}

resource "google_cloud_run_service_iam_member" "cloud_run_invoker" {
  location = google_cloudfunctions2_function.function.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_account}"
}
