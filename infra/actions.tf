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

# Every variable that existed before this was managed is in state now, so there
# is no import: a newly listed repo gets its copy created. A repo restored from
# archive with an old copy fails the apply with "already exists"; import it once
# by hand (tofu import 'github_actions_variable.runner["<repo>/<name>"]' <repo>:<name>).
resource "github_actions_variable" "runner" {
  for_each = local.runner_vars

  repository    = github_repository.this[each.value.repo].name
  variable_name = each.value.name
  value         = jsonencode(local.settings.runners[each.value.name])
}
