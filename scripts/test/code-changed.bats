#!/usr/bin/env bats
# actions/code-changed: code-changed.sh executed against a fake gh compare API

load helper

# run_with <compare JSON> [gh exit]: the fake gh applies the action's --jq to the JSON
run_with() {
  mkdir -p "$T/bin"
  cat > "$T/bin/gh" <<EOS
#!/usr/bin/env bash
while [ \$# -gt 0 ]; do [ "\$1" = --jq ] && q=\$2; shift; done
[ "${2:-0}" = 0 ] || exit ${2:-0}
jq -r "\$q" "$T/files"
EOS
  chmod +x "$T/bin/gh"
  printf '%s' "$1" > "$T/files"
  export T PATH=$T/bin:$PATH GITHUB_OUTPUT=$T/out REPO=o/r EVENT=${EVENT:-pull_request} BASE=${BASE-abc} HEAD=def
  : > "$GITHUB_OUTPUT"
  "$BATS_TEST_DIRNAME/../../actions/code-changed/code-changed.sh" >/dev/null
  cat "$GITHUB_OUTPUT"
}

# files <name>...: a compare response listing these files
files() { jq -nc '{files: [$ARGS.positional[] | {filename: .}]}' --args "$@"; }

# md_files <n>: a compare response with n Markdown files
md_files() { jq -nc --argjson n "$1" '{files: [range($n) | {filename: "d/\(.).md"}]}'; }

setup() { common_setup; }

@test "only Markdown changed: false" {
  [ "$(run_with "$(files README.md docs/a.md)")" = "code=false" ]
}

@test "a code file among Markdown: true" {
  [ "$(run_with "$(files README.md src/a.go)")" = "code=true" ]
}

@test "a rename out of code counts by its old name" {
  [ "$(run_with '{"files":[{"filename":"a.md","previous_filename":"a.py"}]}')" = "code=true" ]
}

@test "300 or more files may be cut: true; fewer Markdown files: false" {
  [ "$(run_with "$(md_files 300)")" = "code=true" ]
  [ "$(run_with "$(md_files 299)")" = "code=false" ]
}

@test "an API failure or empty list: true" {
  [ "$(run_with "$(files README.md)" 1)" = "code=true" ]
  [ "$(run_with "$(files)")" = "code=true" ]
}

@test "a new branch (all-zero base), no base and other events: true" {
  [ "$(BASE=0000000000000000000000000000000000000000 run_with "$(files README.md)")" = "code=true" ]
  [ "$(BASE='' run_with "$(files README.md)")" = "code=true" ]
  [ "$(EVENT=schedule run_with "$(files README.md)")" = "code=true" ]
}
