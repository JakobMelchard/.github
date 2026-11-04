#!/usr/bin/env bats
# The gitleaks action's pin: checksums for its version, and the same version as the prek hook.

ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)

f=$ROOT/actions/gitleaks/install.sh

@test "the checksums are for the pinned version" {
  v=$(sed -n 's/^VERSION=//p' "$f")
  [ -n "$v" ]
  [ "$(sed -n 's/^# checksums for //p' "$f")" = "$v" ]
}

@test "the action pins the same gitleaks as the prek hook" {
  rev=$(grep -A1 'repo: https://github.com/gitleaks/gitleaks$' "$ROOT/.pre-commit-config.yaml" | sed -n 's/^ *rev: //p')
  [ "$rev" = "v$(sed -n 's/^VERSION=//p' "$f")" ]
}
