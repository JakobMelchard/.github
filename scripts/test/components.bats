#!/usr/bin/env bats
load helper
setup() {
  common_setup
  ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
}
@test "components: independent versions preserve platform and package identity" {
  jq -e 'keys == [".","config","hooks"]' "$ROOT/.release-please-manifest.json"
  [ "$(jq -r .config "$ROOT/.release-please-manifest.json")" = "$(jq -r .version "$ROOT/config/package.json")" ]
  [ "$(jq -r .hooks "$ROOT/.release-please-manifest.json")" = "$(cat "$ROOT/hooks/version.txt")" ]
  jq -e '.packages["."]."include-component-in-tag" == false and .packages.config.component == "config" and .packages.hooks.component == "hooks"' "$ROOT/release-please-config.json"
  jq -e '.name == "@jakobmelchard/config" and (.exports | keys == ["./eslint","./prettier","./tsconfig"])' "$ROOT/config/package.json"
}
@test "components: component publishing cannot match platform or hooks tags" {
  run env GITHUB_REF_NAME=v2.5.0 "$BIN/check-config-tag"
  [ "$status" -ne 0 ]
  run env GITHUB_REF_NAME=hooks-v3.0.0 "$BIN/check-config-tag"
  [ "$status" -ne 0 ]
  v=$(jq -r .version "$ROOT/config/package.json")
  run env GITHUB_REF_NAME="config-v$v" "$BIN/check-config-tag"
  [ "$status" -eq 0 ]
  run env GITHUB_REF_NAME="config-v$v.1" "$BIN/check-config-tag"
  [ "$status" -ne 0 ]
}

@test "components: remote-style hook consumer executes preserved manifest entry" {
  command -v prek >/dev/null || skip "prek required"
  mkdir "$T/consumer"
  cd "$T/consumer"
  git init -q
  printf '#!/bin/sh\necho ok\n' > example.sh
  git add example.sh
  printf 'repos:\n  - repo: %s\n    rev: %s\n    hooks: [{id: shell-syntax}]\n' "$ROOT" "$(git -C "$ROOT" rev-parse HEAD)" > .pre-commit-config.yaml
  run prek run shell-syntax --files example.sh
  [ "$status" -eq 0 ]
  printf '#!/bin/sh\nif then\n' > example.sh
  run prek run shell-syntax --files example.sh
  [ "$status" -ne 0 ]
}
