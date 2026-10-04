# Repos owned by the personal account (settings.json `personal`), with the org's
# repo_defaults. Locally the same PAT covers both (the account owns the org);
# in CI an installation token is per account, so infra.yml mints a second one
# from the same app installed on the personal account (var.personal_token).
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

  # Same as repos.tf: free on public repos, rejected on private ones.
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
      homepage_url, topics, pages,
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

# Same as repos.tf: Renovate opens the fix PRs, not Dependabot.
resource "github_repository_dependabot_security_updates" "personal" {
  for_each   = local.personal_repos
  provider   = github.personal
  repository = github_repository.personal[each.key].name
  enabled    = false
}

# actions_can_approve_prs: let github.token open and approve PRs, which the
# shared release.yml needs where the org app secrets are not available (they
# are org-only, so every personal repo running release-please). The token's
# default permissions stay read; workflows that write declare it themselves.
locals {
  personal_actions_approve = { for k, v in local.personal_repos : k => v if try(v.actions_can_approve_prs, false) }
}

import {
  for_each = local.personal_actions_approve
  provider = github.personal
  to       = github_workflow_repository_permissions.personal[each.key]
  id       = each.key
}

resource "github_workflow_repository_permissions" "personal" {
  for_each = local.personal_actions_approve
  provider = github.personal

  repository                       = github_repository.personal[each.key].name
  can_approve_pull_request_reviews = true
  default_workflow_permissions     = "read"
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

# chrome-extensions moved from the personal account to the org (2026-10-03): carry its
# state over to the org resources instead of destroying and re-importing.
moved {
  from = github_repository.personal["chrome-extensions"]
  to   = github_repository.this["chrome-extensions"]
}

moved {
  from = github_repository_vulnerability_alerts.personal["chrome-extensions"]
  to   = github_repository_vulnerability_alerts.this["chrome-extensions"]
}
