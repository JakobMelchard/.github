#!/usr/bin/env bats
# The gitleaks action's pin: checksums for its version, and the same version as the prek hook.

ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)

f=$ROOT/actions/gitleaks/install.sh

@test "the checksums are for the pinned version" {
  v=$(sed -n 's/^VERSION=//p' "$f")
  [ -n "$v" ]
  [ "$(sed -n 's/^# checksums for //p' "$f")" = "$v" ]
}

@test "both checksums are full SHA256 digests" {
  [ "$(grep -cE 'SHA256=[0-9a-f]{64} ' "$f")" -eq 2 ]
  ! grep -E 'SHA256=' "$f" | grep -vqE 'SHA256=[0-9a-f]{64} '
}

@test "the action pins the same gitleaks as the prek hook" {
  rev=$(grep -A1 'repo: https://github.com/gitleaks/gitleaks$' "$ROOT/.pre-commit-config.yaml" | sed -n 's/^ *rev: //p')
  [ "$rev" = "v$(sed -n 's/^VERSION=//p' "$f")" ]
}
