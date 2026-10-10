#!/usr/bin/env bats
# ci against the fake gh: latest CI conclusion per non-archived repo

load helper

setup() {
  common_setup
  echo '[{"name":"b","isArchived":false},{"name":"a","isArchived":false},{"name":"z","isArchived":true}]' > "$GH_FIXTURES/repos.json"
}

@test "ci: no args lists every non-archived repo" {
  run "$BIN/ci"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%-26s %-10s %-18s %s\n%-26s %s\n%-26s %s' REPO STATUS WORKFLOW WHEN a - b -)" ]
}
