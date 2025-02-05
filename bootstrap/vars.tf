variable "default_labels" {
    type = map(string)
    default = {}
    description = "Labels to be applied to created resources"
}

variable "create_project" {
  type = bool
  default = true
  description = "Allow reuse of an existing project."
}

variable "project_name" {
  type        = string
  default     = "Stacklet Relay"
  description = "The name of the project that will hold the Stacklet relay components"
}

variable "project_id" {
  type        = string
  default     = "stacklet-relay"
  description = "The id of the project that will hold the Stacklet relay components"
}

variable "folder_id" {
  type        = string
  default     = null
  description = "An optional folder id for the Stacklet relay project to exist in"
}

variable "project_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to be associated with the Stacklet relay project"
}

variable "billing_account" {
  type        = string
  default = ""
  description = "The billing account to be associated with the Stacklet relay project"
  validation {
    condition = !var.create_project || length(var.billing_account) > 0
    error_message = "billing_account must be set if you are creating the project"
  }
}

variable "service_account_id" {
  type        = string
  default     = "stacklet-relay"
  description = "The id of the service account created in the relay project"
}

variable "service_account_display_name" {
  type        = string
  default     = "Stacklet relay service account"
  description = "The display name of the service account created in the relay project"
}
