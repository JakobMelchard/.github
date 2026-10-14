#!/usr/bin/env bats
# automerge.yml's "wait for checks" step, executed against a fake gh with fixture check runs,
# commit statuses, branch rules and review threads. sleep is a no-op that counts polls.

load helper

setup() {
  common_setup
  mkdir -p "$T/bin"
  cat > "$T/bin/gh" <<'SH'
#!/usr/bin/env bash
q=""; a=()
while [ $# -gt 0 ]; do
  case $1 in --jq) q=$2; shift ;; *) a+=("$1") ;; esac
  shift
done
case "${a[0]} ${a[1]}" in
  "pr view") f=pr ;;
  "api graphql") f=threads ;;
  "api "*/check-runs) f=runs ;;
  "api "*/status) f=status ;;
  "api "*/rules/branches/*) f=rules ;;
  *) echo "fake gh: unhandled: ${a[*]}" >&2; exit 99 ;;
esac
[ -f "$T/$f.err" ] && { cat "$T/$f.err"; exit 1; }
if [ -n "$q" ]; then jq -r "$q" "$T/$f.json"; else cat "$T/$f.json"; fi
SH
  printf '#!/usr/bin/env bash\necho >> "$T/sleeps"\n' > "$T/bin/sleep"
  chmod +x "$T/bin/gh" "$T/bin/sleep"
  echo '{"state":"OPEN","isDraft":false,"headRefOid":"abc","labels":[{"name":"automerge"}],"reviewDecision":""}' > "$T/pr.json"
  threads 0
  echo '[]' > "$T/rules.json"
  yq '.jobs.automerge.steps[] | select(.name == "wait for checks") | .run' \
    "$BATS_TEST_DIRNAME/../../.github/workflows/automerge.yml" > "$T/step.sh"
  export T PATH=$T/bin:$PATH GITHUB_OUTPUT=$T/out GITHUB_STEP_SUMMARY=$T/summary GH_REPO=o/r PR_NUM=1 SHA=abc BASE=main
}

ok() { printf '{"name":"%s","status":"completed","conclusion":"%s"}' "$1" "${2:-success}"; }
wip() { printf '{"name":"%s","status":"in_progress","conclusion":null}' "$1"; }
st() { printf '{"context":"%s","state":"%s"}' "$1" "$2"; }

# threads <unresolved> [total]
threads() {
  jq -n --argjson u "$1" --argjson t "${2:-$1}" \
    '{data: {repository: {pullRequest: {reviewThreads: {totalCount: $t, nodes: [range($u) | {isResolved: false}]}}}}}' \
    > "$T/threads.json"
}

# gate <check runs> <statuses>: run the step, print its output and then $GITHUB_OUTPUT
gate() {
  echo "{\"check_runs\":[$1]}" > "$T/runs.json"
  echo "{\"statuses\":[$2]}" > "$T/status.json"
  : > "$GITHUB_OUTPUT"
  bash --noprofile --norc -eo pipefail "$T/step.sh"
  cat "$GITHUB_OUTPUT"
}

@test "all passed, skipped or neutral: ready after two equal polls" {
  run gate "$(ok lint),$(ok docs skipped),$(ok scan neutral)" "$(st ci/x success)"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ready=true"* ]] || false
  [ "$(wc -l < "$T/sleeps")" -eq 1 ]
}

@test "a failed check stops without merging" {
  run gate "$(ok lint),$(ok test failure)" ""
  [[ "$output" == *"not merging: failed: test"* ]] || false
  [[ "$output" != *"ready=true"* ]] || false
}

@test "a failed status stops without merging" {
  run gate "$(ok lint)" "$(st ci/x error)"
  [[ "$output" == *"not merging: failed: ci/x"* ]] || false
}

@test "a pending status or running check never gets ready" {
  run gate "$(ok lint)" "$(st ci/x pending)"
  [[ "$output" == *"timed out"* ]] || false
  [[ "$output" != *"ready=true"* ]] || false
  run gate "$(ok lint),$(wip test)" ""
  [[ "$output" == *"timed out"* ]] || false
}

@test "an unresolved review thread, or more than 100, never gets ready" {
  threads 1
  run gate "$(ok lint)" ""
  [[ "$output" == *"timed out"* ]] || false
  threads 0 101
  run gate "$(ok lint)" ""
  [[ "$output" == *"timed out"* ]] || false
}

@test "the automerge check itself is ignored" {
  run gate "$(ok lint),$(wip automerge),$(wip 'automerge / automerge')" ""
  [[ "$output" == *"ready=true"* ]] || false
}

@test "a check named like automerge is not ignored" {
  run gate "$(ok lint),$(ok automerge-lint failure)" ""
  [[ "$output" == *"failed: automerge-lint"* ]] || false
}

@test "no checks yet: waits a few polls before merging" {
  run gate "" ""
  [[ "$output" == *"ready=true"* ]] || false
  [ "$(wc -l < "$T/sleeps")" -ge 4 ]
}

@test "a new head commit stops without merging" {
  SHA=other run gate "$(ok lint)" ""
  [[ "$output" == *"not merging: head commit changed"* ]] || false
}

# rules <required check contexts as a JSON array> <required approvals>
rules() {
  jq -n --argjson c "$1" --argjson a "$2" '[
    {type: "required_status_checks", parameters: {required_status_checks: [$c[] | {context: .}]}},
    {type: "pull_request", parameters: {required_approving_review_count: $a}}]' > "$T/rules.json"
}

@test "a required check that never reports never gets ready" {
  rules '["lint","test"]' 0
  run gate "$(ok lint)" ""
  [[ "$output" == *"timed out"* ]] || false
  [[ "$output" != *"ready=true"* ]] || false
  run gate "" ""
  [[ "$output" == *"timed out"* ]] || false
}

@test "required checks pass as check runs or statuses" {
  rules '["lint","ci/x"]' 0
  run gate "$(ok lint)" "$(st ci/x success)"
  [[ "$output" == *"ready=true"* ]] || false
}

@test "required approvals: waits for one, merges once approved" {
  rules '[]' 1
  run gate "$(ok lint)" ""
  [[ "$output" == *"timed out"* ]] || false
  [[ "$output" != *"ready=true"* ]] || false
  jq '.reviewDecision = "APPROVED"' "$T/pr.json" > "$T/pr2.json" && mv "$T/pr2.json" "$T/pr.json"
  run gate "$(ok lint)" ""
  [[ "$output" == *"ready=true"* ]] || false
}

@test "no rulesets on a free private repo: no extra requirements" {
  echo '{"message":"Upgrade to GitHub Pro or make this repository public to enable this feature.","status":"403"}' > "$T/rules.err"
  run gate "$(ok lint)" ""
  [[ "$output" == *"ready=true"* ]] || false
}

@test "any other rules error fails without merging" {
  echo '{"message":"Server Error","status":"500"}' > "$T/rules.err"
  run gate "$(ok lint)" ""
  [[ "$output" != *"ready=true"* ]] || false
  [ ! -f "$T/sleeps" ]
}
