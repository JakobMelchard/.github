variable "org" {
  type    = string
  default = "JakobMelchard"
}

variable "manage_org" {
  description = "Also manage organization-level settings. Needs a token with admin:org and a billing_email."
  type        = bool
  default     = false
}

variable "billing_email" {
  description = "Required by github_organization_settings when manage_org is true."
  type        = string
  default     = null
  sensitive   = true
}
