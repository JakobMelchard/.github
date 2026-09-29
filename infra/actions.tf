# Self-hosted runner routing. Workflows use
#   runs-on: ${{ fromJSON(vars.RUNNER_MACOS || '"macos-latest"') }}
# and the same with RUNNER_LINUX / ubuntu-latest. Only RUNNER_MACOS is set
# today: macOS minutes count 10x, Linux stays on hosted runners. Adding
# RUNNER_LINUX back to settings.json moves Linux jobs to mimi too.
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

resource "github_actions_variable" "runner" {
  for_each = local.runner_vars

  repository    = github_repository.this[each.value.repo].name
  variable_name = each.value.name
  value         = jsonencode(local.settings.runners[each.value.name])
}
