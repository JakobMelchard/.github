# Existing repos are adopted with import blocks (tofu >= 1.7 supports for_each
# here), so a first `tofu plan` shows adoption, not creation. Attributes this
# module does not own are ignored so a plan never proposes flipping them.

import {
  for_each = local.repos
  to       = github_repository.this[each.key]
  id       = each.key
}

resource "github_repository" "this" {
  for_each = local.repos

  name         = each.key
  description  = try(each.value.description, null)
  homepage_url = try(each.value.homepage_url, null)
  visibility   = each.value.visibility
  archived     = each.value.archived

  has_issues   = each.value.has_issues
  has_wiki     = each.value.has_wiki
  has_projects = each.value.has_projects

  allow_merge_commit          = each.value.allow_merge_commit
  allow_squash_merge          = each.value.allow_squash_merge
  allow_rebase_merge          = each.value.allow_rebase_merge
  squash_merge_commit_title   = each.value.squash_merge_commit_title
  squash_merge_commit_message = each.value.squash_merge_commit_message
  delete_branch_on_merge      = each.value.delete_branch_on_merge
  allow_auto_merge            = each.value.allow_auto_merge
  allow_update_branch         = each.value.allow_update_branch
  web_commit_signoff_required = each.value.web_commit_signoff_required

  # Secret scanning and push protection are free on public repos. Private
  # repos need Advanced Security, which the free plan lacks (the API rejects
  # the block there), so they get no block and the computed attribute keeps
  # whatever GitHub reports.
  dynamic "security_and_analysis" {
    for_each = each.value.visibility == "public" ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      auto_init, gitignore_template, license_template, template,
      topics, pages,
      has_downloads, has_discussions, is_template, archive_on_destroy,
      vulnerability_alerts, # deprecated attribute; managed by the resource below
    ]
  }
}

# Dependabot alerts: the github_repository attribute is deprecated in provider v6.
import {
  for_each = { for k, v in local.repos : k => v if v.vulnerability_alerts && !v.archived }
  to       = github_repository_vulnerability_alerts.this[each.key]
  id       = each.key
}

resource "github_repository_vulnerability_alerts" "this" {
  for_each   = { for k, v in local.repos : k => v if v.vulnerability_alerts && !v.archived }
  repository = github_repository.this[each.key].name
}

# Dependabot security updates (automated fix PRs) off everywhere: Renovate opens
# the fix PRs (renovate/default.json vulnerabilityAlerts), reading the alerts above.
resource "github_repository_dependabot_security_updates" "this" {
  for_each   = local.repos
  repository = github_repository.this[each.key].name
  enabled    = false

  # GitHub rejects this call (422) until alerts are on: create the alerts first.
  depends_on = [github_repository_vulnerability_alerts.this]
}
