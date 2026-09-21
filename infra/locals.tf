locals {
  settings = jsondecode(file("${path.module}/settings.json"))
  defaults = local.settings.repo_defaults

  # Every repo listed in settings.json is managed. Unlisted repos are touched
  # only by `org-repo sync`, which applies repo_defaults imperatively.
  repos = {
    for name, override in local.settings.repos :
    name => merge(local.defaults, override)
  }
}
