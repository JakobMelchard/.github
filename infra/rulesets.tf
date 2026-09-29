# One branch ruleset per public repo on its default branch. Private repos are
# skipped: the free plan accepts rulesets there and then does not enforce them.
# Content comes from settings.json `rulesets.defaults`, overridden per repo by
# `checks` (required status contexts, all from GitHub Actions), `bypass_always`
# (app names), `ruleset: false` (opt out) and the `required_*` /
# `strict_status_checks` keys.
#
# Review count is 0 on purpose: one maintainer, and GitHub forbids approving
# your own PR, so 1 would deadlock every PR. Bypass is pull_request mode only
# (merge a PR when CI itself is broken), never a direct push. The one `always`
# bypass is the org app on this repo: it pushes the state commit after apply.

locals {
  ruleset_defaults = local.settings.rulesets.defaults
  apps             = local.settings.rulesets.apps

  rulesets = {
    for k, v in local.repos : k => {
      linear        = try(v.required_linear_history, local.ruleset_defaults.required_linear_history)
      threads       = try(v.required_review_thread_resolution, local.ruleset_defaults.required_review_thread_resolution)
      strict        = try(v.strict_status_checks, local.ruleset_defaults.strict_status_checks)
      checks        = try(v.checks, [])
      bypass_pr     = [for a in try(v.bypass_apps, local.ruleset_defaults.bypass_apps) : local.apps[a]]
      bypass_always = [for a in try(v.bypass_always, []) : local.apps[a]]
      # Linear history rules out merge commits, whatever the repo allows.
      merge_methods = compact([
        v.allow_merge_commit && !try(v.required_linear_history, local.ruleset_defaults.required_linear_history) ? "merge" : "",
        v.allow_squash_merge ? "squash" : "",
        v.allow_rebase_merge ? "rebase" : "",
      ])
    } if v.visibility == "public" && try(v.ruleset, true)
  }
}

resource "github_repository_ruleset" "main" {
  for_each = local.rulesets

  name        = "main"
  repository  = github_repository.this[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # The owner, for a PR whose required checks cannot pass (CI outage).
  bypass_actors {
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }

  dynamic "bypass_actors" {
    for_each = each.value.bypass_pr
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "pull_request"
    }
  }

  dynamic "bypass_actors" {
    for_each = each.value.bypass_always
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "always"
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = each.value.linear

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = true
      require_last_push_approval        = false
      require_code_owner_review         = false
      required_review_thread_resolution = each.value.threads
      allowed_merge_methods             = each.value.merge_methods
    }

    # Only GitHub Actions may satisfy a check: another app posting the same
    # context name does not count. Not strict: with allow_update_branch every
    # merge would otherwise invalidate every other open PR's checks.
    dynamic "required_status_checks" {
      for_each = length(each.value.checks) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = each.value.strict
        do_not_enforce_on_create             = true

        dynamic "required_check" {
          for_each = each.value.checks
          content {
            context        = required_check.value
            integration_id = local.apps["github-actions"]
          }
        }
      }
    }
  }
}
