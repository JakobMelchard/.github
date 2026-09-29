# Repos owned by the personal account (settings.json `personal`), with the org's
# repo_defaults. Locally the same PAT covers both (the account owns the org);
# in CI the org app's installation token cannot reach personal repos, so the
# token comes from var.personal_token (secret PERSONAL_GITHUB_TOKEN).
provider "github" {
  alias = "personal"
  owner = local.settings.personal.owner
  token = var.personal_token != "" ? var.personal_token : null
}

locals {
  personal_repos = {
    for name, override in try(local.settings.personal.repos, {}) :
    name => merge(local.defaults, { required_checks = [] }, override) if !try(override.archived, false)
  }
}

import {
  for_each = local.personal_repos
  provider = github.personal
  to       = github_repository.personal[each.key]
  id       = each.key
}

resource "github_repository" "personal" {
  for_each = local.personal_repos
  provider = github.personal

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
  # Native auto-merge only waits for checks where a ruleset requires them.
  allow_auto_merge            = each.value.allow_auto_merge && each.value.visibility == "public"
  allow_update_branch         = each.value.allow_update_branch
  web_commit_signoff_required = each.value.web_commit_signoff_required

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      auto_init, gitignore_template, license_template, template,
      homepage_url, topics, pages, security_and_analysis,
      has_downloads, has_discussions, is_template, archive_on_destroy,
      vulnerability_alerts,
    ]
  }
}

resource "github_repository_vulnerability_alerts" "personal" {
  for_each   = { for k, v in local.personal_repos : k => v if v.vulnerability_alerts }
  provider   = github.personal
  repository = github_repository.personal[each.key].name
}

# required_checks → a ruleset on the default branch. Rulesets need a public repo on the
# free plan, so private repos with required_checks are skipped.
resource "github_repository_ruleset" "personal" {
  for_each = {
    for k, v in local.personal_repos : k => v
    if length(v.required_checks) > 0 && v.visibility == "public"
  }
  provider    = github.personal
  name        = "default branch: required checks"
  repository  = github_repository.personal[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    required_status_checks {
      strict_required_status_checks_policy = false
      dynamic "required_check" {
        for_each = each.value.required_checks
        content {
          context = required_check.value
        }
      }
    }
  }
}
