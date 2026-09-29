variable "org" {
  type    = string
  default = "JakobMelchard"
}

variable "manage_org" {
  description = "Also manage organization-level settings. Needs a token with admin:org and a billing_email."
  type        = bool
  default     = false
}

variable "personal_token" {
  description = "Token for the personal-account provider (personal.tf). Empty falls back to GITHUB_TOKEN. CI: an installation token of the org app installed on the personal account (infra.yml)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "billing_email" {
  description = "Required by github_organization_settings when manage_org is true."
  type        = string
  default     = null
  sensitive   = true
}
