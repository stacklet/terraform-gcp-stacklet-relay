# terraform-gcp-stacklet-relay

Modules for deploying GCP relay components for Stacklet.

## Getting started

The first step in getting the GCP relay configured is to have a service account
that the Stacklet deployment will allow to forward events to the GCP relay event bus.

If there is not a service account known, this can easily be deployed using the bootstrap
module.

```hcl
module "relay_bootstrap" {
  source     = "github.com/stacklet/terraform-gcp-stacklet-relay/bootstrap"
  project_id = "my-unique-project-id"
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
