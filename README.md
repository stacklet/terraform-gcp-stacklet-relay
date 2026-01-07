# terraform-gcp-stacklet-relay

Modules for deploying GCP relay components for Stacklet.

## Getting started

The first step in getting the GCP relay configured is to have a service account
that the Stacklet deployment will allow to forward events to the GCP relay event bus.

If there is not a service account known, this can easily be deployed using the bootstrap
module.

```hcl
module "relay_bootstrap" {
  source = "github.com/stacklet/terraform-gcp-stacklet-relay/bootstrap"
}
```

Additional configuration variables are defined in the [vars.tf](bootstrap/vars.tf) file.

The output values provide the values for the main deployment, and the service account
oauth ID needed to configure the Stacklet deployment.

* `project_id` - the id of the created project
* `service_account_email` - required for primary deployment module
* `service_account_oauth_id` - needed for Stacklet deployment to configure IAM trust relationship

## Deploying the relay components

Once the Stacklet deployment has been updated with the `service_account_oauth_id`, you will
be provided with the `aws_role` ARN and the `aws_event_bus` ARN.

These values should be passed in to the module.


```hcl
module "relay_bootstrap" {
  source = "github.com/stacklet/terraform-gcp-stacklet-relay"

  aws_role = "arn:..."
  aws_event_bus = "arn:..."
  project_id = "<your GPC project ID>"
  service_account = "<service account email>"

  # You should also set one of
  # organization_id - for an organization wide asset inventory feed
  # folder_ids - for one or more folder level asset inventory feeds
  # project_ids - for one or more project level asset inventory feeds
}
```

Additional configuration variables are defined in the [vars.tf](vars.tf) file.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2.0 |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_cloud_asset_folder_feed.folder_feed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_asset_folder_feed) | resource |
| [google_cloud_asset_organization_feed.organization_feed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_asset_organization_feed) | resource |
| [google_cloud_asset_project_feed.project_feed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_asset_project_feed) | resource |
| [google_cloud_run_service_iam_member.asset_change_relay_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_member) | resource |
| [google_cloud_run_service_iam_member.audit_log_relay_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_member) | resource |
| [google_cloud_run_service_iam_member.scc_finding_relay_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_member) | resource |
| [google_cloudfunctions2_function.asset_change_relay](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function) | resource |
| [google_cloudfunctions2_function.audit_log_relay](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function) | resource |
| [google_cloudfunctions2_function.scc_finding_relay](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function) | resource |
| [google_cloudfunctions2_function_iam_member.asset_change_relay_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function_iam_member) | resource |
| [google_cloudfunctions2_function_iam_member.audit_log_relay_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function_iam_member) | resource |
| [google_cloudfunctions2_function_iam_member.scc_finding_relay_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function_iam_member) | resource |
| [google_logging_folder_sink.folder_feed_with_children](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_folder_sink) | resource |
| [google_logging_folder_sink.folder_feed_without_children](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_folder_sink) | resource |
| [google_logging_organization_sink.organization_audit_feed_with_children](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_sink) | resource |
| [google_logging_organization_sink.organization_audit_feed_without_children](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_sink) | resource |
| [google_logging_project_sink.project_feed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_sink) | resource |
| [google_pubsub_topic.asset_feed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic.audit_feed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic.scc_findings_feed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.folder_feed_publisher](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_topic_iam_member.organization_feed_publisher](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_topic_iam_member.project_feed_publisher](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_scc_v2_folder_notification_config.folder_feed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/scc_v2_folder_notification_config) | resource |
| [google_scc_v2_organization_notification_config.organization_feed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/scc_v2_organization_notification_config) | resource |
| [google_scc_v2_project_notification_config.project_feed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/scc_v2_project_notification_config) | resource |
| [google_storage_bucket.function_source_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_object.function_source](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [archive_file.function_source](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asset_types"></a> [asset\_types](#input\_asset\_types) | The asset types that the cloud asset inventory feed provides. | `list(string)` | <pre>[<br/>  "apikeys.googleapis.com/Key",<br/>  "appengine.googleapis.com/Application",<br/>  "bigquery.googleapis.com/Dataset",<br/>  "bigtableadmin.googleapis.com/Instance",<br/>  "cloudbilling.googleapis.com/BillingAccount",<br/>  "cloudfunctions.googleapis.com/CloudFunction",<br/>  "cloudkms.googleapis.com/KeyRing",<br/>  "cloudresourcemanager.googleapis.com/Folder",<br/>  "cloudresourcemanager.googleapis.com/Organization",<br/>  "cloudresourcemanager.googleapis.com/Project",<br/>  "compute.googleapis.com/Address",<br/>  "compute.googleapis.com/Autoscaler",<br/>  "compute.googleapis.com/BackendBucket",<br/>  "compute.googleapis.com/BackendService",<br/>  "compute.googleapis.com/Disk",<br/>  "compute.googleapis.com/Firewall",<br/>  "compute.googleapis.com/ForwardingRule",<br/>  "compute.googleapis.com/GlobalAddress",<br/>  "compute.googleapis.com/GlobalForwardingRule",<br/>  "compute.googleapis.com/HealthCheck",<br/>  "compute.googleapis.com/HttpHealthCheck",<br/>  "compute.googleapis.com/HttpsHealthCheck",<br/>  "compute.googleapis.com/Image",<br/>  "compute.googleapis.com/Instance",<br/>  "compute.googleapis.com/InstanceTemplate",<br/>  "compute.googleapis.com/Interconnect",<br/>  "compute.googleapis.com/InterconnectAttachment",<br/>  "compute.googleapis.com/Network",<br/>  "compute.googleapis.com/Project",<br/>  "compute.googleapis.com/Route",<br/>  "compute.googleapis.com/Router",<br/>  "compute.googleapis.com/SecurityPolicy",<br/>  "compute.googleapis.com/Snapshot",<br/>  "compute.googleapis.com/SslCertificate",<br/>  "compute.googleapis.com/SslPolicy",<br/>  "compute.googleapis.com/Subnetwork",<br/>  "compute.googleapis.com/TargetHttpProxy",<br/>  "compute.googleapis.com/TargetHttpsProxy",<br/>  "compute.googleapis.com/TargetInstance",<br/>  "compute.googleapis.com/TargetPool",<br/>  "compute.googleapis.com/TargetSslProxy",<br/>  "compute.googleapis.com/TargetTcpProxy",<br/>  "compute.googleapis.com/UrlMap",<br/>  "container.googleapis.com/Cluster",<br/>  "dataflow.googleapis.com/Job",<br/>  "datafusion.googleapis.com/Instance",<br/>  "dns.googleapis.com/ManagedZone",<br/>  "dns.googleapis.com/Policy",<br/>  "iam.googleapis.com/Role",<br/>  "iam.googleapis.com/ServiceAccount",<br/>  "logging.googleapis.com/LogMetric",<br/>  "logging.googleapis.com/LogSink",<br/>  "osconfig.googleapis.com/PatchDeployment",<br/>  "pubsub.googleapis.com/Snapshot",<br/>  "pubsub.googleapis.com/Subscription",<br/>  "pubsub.googleapis.com/Topic",<br/>  "redis.googleapis.com/Instance",<br/>  "run.googleapis.com/Job",<br/>  "run.googleapis.com/Revision",<br/>  "run.googleapis.com/Service",<br/>  "secretmanager.googleapis.com/Secret",<br/>  "serviceusage.googleapis.com/Service",<br/>  "spanner.googleapis.com/Instance",<br/>  "sqladmin.googleapis.com/Instance",<br/>  "storage.googleapis.com/Bucket"<br/>]</pre> | no |
| <a name="input_audit_log_include_children"></a> [audit\_log\_include\_children](#input\_audit\_log\_include\_children) | Controls whether audit log sinks include logs from child resources (folders/projects). | `bool` | `false` | no |
| <a name="input_aws_event_bus"></a> [aws\_event\_bus](#input\_aws\_event\_bus) | The ARN of the event bus. | `string` | n/a | yes |
| <a name="input_aws_role"></a> [aws\_role](#input\_aws\_role) | The AWS role that is assumed to push the events on to the event bus. | `string` | n/a | yes |
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | Any number of folder ids to create folder level cloud asset feeds | `list(string)` | `[]` | no |
| <a name="input_function_cpu"></a> [function\_cpu](#input\_function\_cpu) | CPU allocation for Cloud Function instances. Valid values: '0.08' to '8'<br/>(in increments of 0.001 below 1, or 1/2/4/6/8 for >= 1). Default '1' supports<br/>high concurrency. Note: GCP requires cpu >= 1 when max\_concurrency > 1. | `string` | `"1"` | no |
| <a name="input_function_max_concurrency"></a> [function\_max\_concurrency](#input\_function\_max\_concurrency) | Maximum number of concurrent requests each Cloud Function instance can handle.<br/>Higher values increase throughput but require more CPU. Must be paired with<br/>adequate CPU allocation (cpu >= 1 required for concurrency > 1). | `number` | `80` | no |
| <a name="input_function_memory"></a> [function\_memory](#input\_function\_memory) | Memory allocation for Cloud Function instances. Valid values: '128M' to '32G'<br/>in increments (e.g., '256M', '512M', '1G', '2G'). Default '512M'. Make sure<br/>to configure memory values appropriately based on CPU count per GCP docs. | `string` | `"512M"` | no |
| <a name="input_function_source_bucket"></a> [function\_source\_bucket](#input\_function\_source\_bucket) | If set, use the bucket named as the storage location of the function source. | `string` | `""` | no |
| <a name="input_function_source_bucket_location"></a> [function\_source\_bucket\_location](#input\_function\_source\_bucket\_location) | The location to use for the source bucket. | `string` | `"US"` | no |
| <a name="input_function_source_object_name"></a> [function\_source\_object\_name](#input\_function\_source\_object\_name) | The name of the storage object in the source bucket for the function source. | `string` | `"function-source.zip"` | no |
| <a name="input_location"></a> [location](#input\_location) | where is the cloud function deployed | `string` | `"us-central1"` | no |
| <a name="input_log_debug"></a> [log\_debug](#input\_log\_debug) | Enables debug logging on the relay cloud function. | `bool` | `false` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | If set, creates an organization level cloud asset feed | `string` | `""` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | An optional prefix to attach to all deployed assets. | `string` | `""` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project that the feeds and functions are created in. | `string` | n/a | yes |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Any number of project ids to create project level cloud asset feeds | `list(string)` | `[]` | no |
| <a name="input_relay_asset_changes"></a> [relay\_asset\_changes](#input\_relay\_asset\_changes) | Controls whether or not asset changes are forwarded - faster assetdb updates. | `bool` | `true` | no |
| <a name="input_relay_audit_log"></a> [relay\_audit\_log](#input\_relay\_audit\_log) | Controls whether or not audit logs are forwarded - required for 'gcp-audit' policies. | `bool` | `true` | no |
| <a name="input_relay_security_command_center_findings"></a> [relay\_security\_command\_center\_findings](#input\_relay\_security\_command\_center\_findings) | Controls whether or not security command center findings are forwarded - required for 'gcp-scc' policies. | `bool` | `true` | no |
| <a name="input_security_findings_filter"></a> [security\_findings\_filter](#input\_security\_findings\_filter) | A filter to apply as streaming config for the security command center findings. By default all active findings are forwarded. | `string` | `"state = \"ACTIVE\""` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | The email of the service account that the cloud function uses to access AWS. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->