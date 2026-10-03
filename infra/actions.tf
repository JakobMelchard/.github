# Runner routing. Workflows use
#   runs-on: ${{ fromJSON(vars.RUNNER_MACOS || '"macos-latest"') }}
# and the same with RUNNER_LINUX / ubuntu-latest. RUNNER_MACOS points at the
# self-hosted runner on mimi (macOS minutes count 10x); RUNNER_LINUX points at
# Blacksmith (org app blacksmith-sh), so private-repo Linux jobs use no GitHub
# minutes.
# Org variables would be simpler, but the free plan does not pass org-level
# variables to private repos at runtime, so every private repo gets its own
# copy of settings.json `runners`. Public repos get none and stay on free
# hosted runners. `"runners": {}` is the kill switch.
locals {
  runner_vars = {
    for p in setproduct(
      [for k, v in local.repos : k if v.visibility == "private"],
      keys(try(local.settings.runners, {}))
    ) : "${p[0]}/${p[1]}" => { repo = p[0], name = p[1] }
  }
}

# Adopt variables that already exist (a repo coming back from archive keeps
# its old copy), same pattern as the repo import in repos.tf. An import of a
# missing variable fails the plan, so only names that existed before they were
# managed are adopted; a newly added name is created.
import {
  for_each = { for k, v in local.runner_vars : k => v if v.name == "RUNNER_MACOS" }
  to       = github_actions_variable.runner[each.key]
  id       = "${each.value.repo}:${each.value.name}"
}
resource "github_actions_variable" "runner" {
  for_each = local.runner_vars

  repository    = github_repository.this[each.value.repo].name
  variable_name = each.value.name
  value         = jsonencode(local.settings.runners[each.value.name])
}
