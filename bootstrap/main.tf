resource "google_project" "stacklet_relay" {
  count           = vars.create_project ? 1 : 0
  name            = var.project_name
  project_id      = var.project_id
  folder_id       = var.folder_id
  billing_account = var.billing_account
  tags            = var.project_tags

  deletion_policy = "DELETE"
}

locals {
    project_id = vars.create_project ? google_project.stacklet_relay.project_id : var.project_id
}

resource "google_project_service" "artifactregistry" {
  project = local.project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "cloudasset" {
  project = local.project_id
  service = "cloudasset.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "cloudbuild" {
  project = local.project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "cloudfunctions" {
  project = local.project_id
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "compute" {
  project = local.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "eventarc" {
  project = local.project_id
  service = "eventarc.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  project = local.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "logging" {
  project = local.project_id
  service = "logging.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "pubsub" {
  project = local.project_id
  service = "pubsub.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "run" {
  project = local.project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "service_account" {
  project = local.project_id

  account_id   = var.service_account_id
  display_name = var.service_account_display_name

  depends_on = [ google_project_service.iam ]
}

output "project_id" {
  value = local.project_id
}

output "service_account_email" {
    value = google_service_account.service_account.email
}

output "service_account_oauth_id" {
    value = google_service_account.service_account.unique_id
}