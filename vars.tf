#
#  Required variables
#
variable "aws_role" {
  type        = string
  description = "The AWS role that is assumed to push the events on to the event bus."
}

variable "aws_event_bus" {
  type        = string
  description = "The ARN of the event bus."
}

variable "project_id" {
  type        = string
  description = "The project that the feeds and functions are created in."
}

variable "service_account" {
  type        = string
  description = "The email of the service account that the cloud function uses to access AWS."
}

#
#  Additional variables
#
variable "default_labels" {
  type        = map(string)
  default     = {}
  description = "Labels to be applied to created resources"
}

variable "prefix" {
  type        = string
  default     = ""
  description = "An optional prefix to attach to all deployed assets."
}

variable "function_source_bucket" {
  type        = string
  default     = ""
  description = "If set, use the bucket named as the storage location of the function source."
}

variable "function_source_bucket_location" {
  type        = string
  default     = "US"
  description = "The location to use for the source bucket."
}

variable "function_source_object_name" {
  type        = string
  default     = "function-source.zip"
  description = "The name of the storage object in the source bucket for the function source."
}

variable "location" {
  type        = string
  default     = "us-central1"
  description = "where is the cloud function deployed"
}

variable "organization_id" {
  type        = string
  description = "If set, creates an organization level cloud asset feed"
  default     = ""
}

variable "folder_ids" {
  type        = list(string)
  description = "Any number of folder ids to create folder level cloud asset feeds"
  default     = []
}

variable "project_ids" {
  type        = list(string)
  description = "Any number of project ids to create project level cloud asset feeds"
  default     = []
}

variable "log_debug" {
  type        = bool
  default     = false
  description = "Enables debug logging on the relay cloud function."
}

variable "asset_types" {
  type        = list(string)
  description = "The asset types that the cloud asset inventory feed provides."
  default = [
    "apikeys.googleapis.com/Key",
    "appengine.googleapis.com/Application",
    "bigquery.googleapis.com/Dataset",
    "bigtableadmin.googleapis.com/Instance",
    "cloudbilling.googleapis.com/BillingAccount",
    "cloudfunctions.googleapis.com/CloudFunction",
    "cloudkms.googleapis.com/KeyRing",
    "cloudresourcemanager.googleapis.com/Folder",
    "cloudresourcemanager.googleapis.com/Organization",
    "cloudresourcemanager.googleapis.com/Project",
    "compute.googleapis.com/Address",
    "compute.googleapis.com/Autoscaler",
    "compute.googleapis.com/BackendBucket",
    "compute.googleapis.com/BackendService",
    "compute.googleapis.com/Disk",
    "compute.googleapis.com/Firewall",
    "compute.googleapis.com/ForwardingRule",
    "compute.googleapis.com/GlobalAddress",
    "compute.googleapis.com/GlobalForwardingRule",
    "compute.googleapis.com/HealthCheck",
    "compute.googleapis.com/HttpHealthCheck",
    "compute.googleapis.com/HttpsHealthCheck",
    "compute.googleapis.com/Image",
    "compute.googleapis.com/Instance",
    "compute.googleapis.com/InstanceTemplate",
    "compute.googleapis.com/Interconnect",
    "compute.googleapis.com/InterconnectAttachment",
    "compute.googleapis.com/Network",
    "compute.googleapis.com/Project",
    "compute.googleapis.com/Route",
    "compute.googleapis.com/Router",
    "compute.googleapis.com/SecurityPolicy",
    "compute.googleapis.com/Snapshot",
    "compute.googleapis.com/SslCertificate",
    "compute.googleapis.com/SslPolicy",
    "compute.googleapis.com/Subnetwork",
    "compute.googleapis.com/TargetHttpProxy",
    "compute.googleapis.com/TargetHttpsProxy",
    "compute.googleapis.com/TargetInstance",
    "compute.googleapis.com/TargetPool",
    "compute.googleapis.com/TargetSslProxy",
    "compute.googleapis.com/TargetTcpProxy",
    "compute.googleapis.com/UrlMap",
    "container.googleapis.com/Cluster",
    "dataflow.googleapis.com/Job",
    "datafusion.googleapis.com/Instance",
    "dns.googleapis.com/ManagedZone",
    "dns.googleapis.com/Policy",
    "iam.googleapis.com/Role",
    "iam.googleapis.com/ServiceAccount",
    "logging.googleapis.com/LogMetric",
    "logging.googleapis.com/LogSink",
    "osconfig.googleapis.com/PatchDeployment",
    "pubsub.googleapis.com/Snapshot",
    "pubsub.googleapis.com/Subscription",
    "pubsub.googleapis.com/Topic",
    "redis.googleapis.com/Instance",
    "run.googleapis.com/Job",
    "run.googleapis.com/Revision",
    "run.googleapis.com/Service",
    "secretmanager.googleapis.com/Secret",
    "serviceusage.googleapis.com/Service",
    "spanner.googleapis.com/Instance",
    "sqladmin.googleapis.com/Instance",
    "storage.googleapis.com/Bucket",
  ]
}
