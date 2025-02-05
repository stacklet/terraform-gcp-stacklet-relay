# terraform-gcp-stacklet-relay

Modules for deploying GCP relay components for Stacklet.

## Getting Started

The first step in getting the GCP relay configured is to have a service account
that the Stacklet deployment will allow to forward events to the GCP relay event bus.

If there is not a service account known, this can easily be deployed using the bootstrap
module.

```hcl
module "relay_bootstrap" {
  source = "github.com/stacklet/terraform-gcp-stacklet-relay/bootstrap"
}
```

Additional configuration values are defined in the [vars.tf](bootstrap/vars.tf) file.

The output values provide the values for the main deployment, and the service account
oauth ID needed to configure the Stacklet deployment.

* `project_id` - the id of the created project
* `service_account_email` - required for primary deployment module
* `service_account_oauth_id` - needed for Stacklet deployment to configure IAM trust relationship

