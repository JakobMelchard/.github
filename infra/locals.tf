locals {
  settings = jsondecode(file("${path.module}/settings.json"))
  defaults = local.settings.repo_defaults

  # Every repo listed in settings.json is managed, except archived ones: the
  # provider refuses to read or update an archived repository ("please remove the
  # resource from your configuration"). Archive with `gh repo archive`, then mark
  # it `archived: true` here, which takes it out of state on the next apply
  # (`tofu state rm` first, so prevent_destroy does not block the plan).
  # Unlisted repos are touched only by `org-repo sync`.
  all_repos = {
    for name, override in local.settings.repos :
    name => merge(local.defaults, override)
  }
  # GitHub ignores allow_auto_merge on private repos under the free plan (native
  # auto-merge needs branch protection), so asking for it there is a permanent
  # diff. Renovate's own automerge covers private repos (renovate/default.json).
  repos = {
    for k, v in local.all_repos : k => merge(v, {
      allow_auto_merge = v.allow_auto_merge && v.visibility == "public"
    }) if !v.archived
  }
}
