data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/forwarder"
  output_path = "${path.module}/function-source.zip"
}

resource "google_storage_bucket" "function_source_bucket" {
  count                       = var.function_source_bucket == "" ? 1 : 0
  name                        = "${local.prefix}${var.project_id}-gcf-source" # Every bucket name must be globally unique
  location                    = var.function_source_bucket_location
  uniform_bucket_level_access = true
}

locals {
  function_source_bucket = var.function_source_bucket == "" ? google_storage_bucket.function_source_bucket[0].name : var.function_source_bucket
  prefix                 = var.prefix == "" ? "" : endswith(var.prefix, "-") ? var.prefix : "${var.prefix}-"
}

resource "google_storage_bucket_object" "function_source" {
  name   = var.function_source_object_name
  bucket = local.function_source_bucket
  source = data.archive_file.function_source.output_path
}
