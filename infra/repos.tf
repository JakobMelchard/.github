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

  name        = each.key
  description = try(each.value.description, null)
  visibility  = each.value.visibility
  archived    = each.value.archived

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
  vulnerability_alerts        = each.value.vulnerability_alerts

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      auto_init, gitignore_template, license_template, template,
      homepage_url, topics, pages, security_and_analysis,
      has_downloads, has_discussions, is_template, archive_on_destroy,
    ]
  }
}
