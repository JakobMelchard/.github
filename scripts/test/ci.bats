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

@test "ci: a failing gh lists the repo as - and carries on" {
  touch "$GH_FIXTURES/fail-a"
  echo '[{"name":"ci","conclusion":"success","status":"completed","createdAt":"2026-01-02T03:04:05Z","headBranch":"main"}]' > "$GH_FIXTURES/runs-b.json"
  run "$BIN/ci"
  [ "$status" -eq 0 ]
  [ "${lines[1]}" = "$(printf '%-26s %s' a -)" ]
  [ "${lines[2]}" = "$(printf '%-26s %-10s %-18s %s  %s' b success ci 2026-01-02T03:04 main)" ]
}

@test "ci: a run in progress shows its status" {
  echo '[{"name":"ci","conclusion":null,"status":"in_progress","createdAt":"2026-01-02T03:04:05Z","headBranch":"dev"}]' > "$GH_FIXTURES/runs-a.json"
  run "$BIN/ci" a
  [ "${lines[1]}" = "$(printf '%-26s %-10s %-18s %s  %s' a in_progress ci 2026-01-02T03:04 dev)" ]
}
