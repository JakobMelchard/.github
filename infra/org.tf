# Organization settings. Off by default: needs admin:org and a billing email.
#   GITHUB_TOKEN=<admin token> tofu apply -var manage_org=true -var billing_email=…
resource "github_organization_settings" "this" {
  count = var.manage_org ? 1 : 0

  billing_email = var.billing_email

  default_repository_permission           = local.settings.org.default_repository_permission
  members_can_create_repositories         = local.settings.org.members_can_create_repositories
  members_can_create_public_repositories  = local.settings.org.members_can_create_public_repositories
  members_can_create_private_repositories = local.settings.org.members_can_create_private_repositories
  members_can_create_pages                = local.settings.org.members_can_create_pages
  web_commit_signoff_required             = local.settings.org.web_commit_signoff_required

  lifecycle {
    precondition {
      condition     = var.billing_email != null
      error_message = "billing_email is required when manage_org is true."
    }
  }
}
