#!/usr/bin/env bats
# actions/code-changed: its run block executed against a fake gh compare API

load helper

# run_with <gh output> [gh exit]: output is what `gh api ... --jq` would print
run_with() {
  mkdir -p "$T/bin"
  printf '#!/usr/bin/env bash\ncat "$T/files"\nexit %s\n' "${2:-0}" > "$T/bin/gh"
  chmod +x "$T/bin/gh"
  printf '%s' "$1" > "$T/files"
  yq '.runs.steps[0].run' "$BATS_TEST_DIRNAME/../../actions/code-changed/action.yml" > "$T/step.sh"
  export T PATH=$T/bin:$PATH GITHUB_OUTPUT=$T/out REPO=o/r EVENT=${EVENT:-pull_request} BASE=${BASE-abc} HEAD=def
  : > "$GITHUB_OUTPUT"
  bash --noprofile --norc -eo pipefail "$T/step.sh" >/dev/null
  cat "$GITHUB_OUTPUT"
}

setup() { common_setup; }

@test "only Markdown changed: false" {
  [ "$(run_with $'README.md\ndocs/a.md')" = "code=false" ]
}

@test "a code file among Markdown: true" {
  [ "$(run_with $'README.md\nsrc/a.go')" = "code=true" ]
}

@test "a rename out of code counts by its old name" {
  [ "$(run_with $'a.md\na.py')" = "code=true" ]
}

@test "a truncated compare list: true" {
  [ "$(run_with 'truncated')" = "code=true" ]
}

@test "an API failure or empty list: true" {
  [ "$(run_with '' 1)" = "code=true" ]
  [ "$(run_with '')" = "code=true" ]
}

@test "a new branch (all-zero base), no base and other events: true" {
  [ "$(BASE=0000000000000000000000000000000000000000 run_with 'README.md')" = "code=true" ]
  [ "$(BASE='' run_with 'README.md')" = "code=true" ]
  [ "$(EVENT=schedule run_with 'README.md')" = "code=true" ]
}
