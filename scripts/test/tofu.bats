#!/usr/bin/env bats
# The jm-tofu-* scripts and the inline run blocks of tofu.yml (extracted with yq and executed the
# way a runner does, bash -eo pipefail), since the workflow's plan and apply paths cannot run in
# this repo's own CI.

load helper

# step <job> <step name>: write that step's script to $T/step.sh
step() {
  yq ".jobs.$1.steps[] | select(.name == \"$2\") | .run" "$BATS_TEST_DIRNAME/../../.github/workflows/tofu.yml" > "$T/step.sh"
  [ -s "$T/step.sh" ]
}
# script <name>: use jm-<name> as $T/step.sh
script() { cp "$JM/jm-$1" "$T/step.sh"; }
runner() { bash --noprofile --norc -eo pipefail "$T/step.sh"; }

setup() {
  common_setup
  export GITHUB_ENV=$T/env
  : > "$GITHUB_ENV"
}

@test "env map: sets the target from the source, masked, skipping blank lines" {
  script tofu-env-map
  export SRC_A=one SRC_B=two
  MAP=$'A=SRC_A\n\n   \nB=SRC_B\n' run runner
  [ "$status" -eq 0 ]
  [[ "$output" == *"::add-mask::one"* ]] || false
  grep -q '^A<<EOF_' "$GITHUB_ENV"
  grep -qx one "$GITHUB_ENV"
  grep -qx two "$GITHUB_ENV"
}

@test "env map: malformed lines fail" {
  script tofu-env-map
  export SRC_A=one
  for m in 'noequals' '1BAD=SRC_A' 'A=1bad' 'A=SRC A' '=SRC_A' 'A='; do
    MAP=$m run runner
    [ "$status" -ne 0 ]
    [[ "$output" == *"bad env-map line"* ]] || false
  done
  [ ! -s "$GITHUB_ENV" ]
}

@test "env map: an empty or unset source fails" {
  script tofu-env-map
  SRC_EMPTY="" MAP='A=SRC_EMPTY' run runner
  [ "$status" -ne 0 ]
  [[ "$output" == *"SRC_EMPTY is empty or not loaded"* ]] || false
  MAP='A=SRC_UNSET' run runner
  [ "$status" -ne 0 ]
}

@test "credential guard: plan and apply run the same scripts" {
  for name in "snapshot gha credentials" "guard gha credentials"; do
    step plan "$name"; cp "$T/step.sh" "$T/plan.sh"
    step apply "$name"
    diff "$T/plan.sh" "$T/step.sh"
  done
}

@test "credential guard: passes when the extra project leaves the gha secrets alone" {
  export TOFU_STATE_PASSPHRASE=p APP_CLIENT_ID=c APP_PRIVATE_KEY=k
  step apply "snapshot gha credentials"
  runner
  GHA_GUARD=$(sed 's/^GHA_GUARD=//' "$GITHUB_ENV") && export GHA_GUARD
  step apply "guard gha credentials"
  run runner
  [ "$status" -eq 0 ]
}

@test "credential guard: fails when the extra project overrides one" {
  export TOFU_STATE_PASSPHRASE=p APP_CLIENT_ID=c APP_PRIVATE_KEY=k
  step apply "snapshot gha credentials"
  runner
  GHA_GUARD=$(sed 's/^GHA_GUARD=//' "$GITHUB_ENV") && export GHA_GUARD
  step apply "guard gha credentials"
  TOFU_STATE_PASSPHRASE=other run runner
  [ "$status" -ne 0 ]
  [[ "$output" == *"overrides TOFU_STATE_PASSPHRASE"* ]] || false
}

# changed <working-directory> <file>...: run jm-tofu-changed on a PR with these files
changed() {
  mkdir -p "$T/bin"
  cat > "$T/bin/gh" <<'SH'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do [ "$1" = --jq ] && q=$2; shift; done
jq -r "$q" "$T/files.json"
SH
  chmod +x "$T/bin/gh"
  local dir=$1; shift
  jq -nc '[$ARGS.positional[] | {filename: .}]' --args "$@" > "$T/files.json"
  script tofu-changed
  : > "$T/out"
  export T PATH=$T/bin:$PATH
  GITHUB_OUTPUT=$T/out GITHUB_REPOSITORY=o/r PR=1 DIR=$dir runner >/dev/null
  cat "$T/out"
}

@test "changed files: a root working directory plans on any change" {
  [ "$(changed . main.tf)" = "run=true" ]
  [ "$(changed ./ README.md)" = "run=true" ]
}

@test "changed files: a nested directory plans only on changes under it" {
  [ "$(changed infra README.md infra/main.tf)" = "run=true" ]
  [ "$(changed ./infra/ infra/main.tf)" = "run=true" ]
  [ "$(changed infra/ terraform-other/main.tf infra-x/a.tf README.md)" = "run=false" ]
}

# commit state: a repo with the state committed at serial 1, a local bare remote behind the app URL
state_repo() {
  mkdir -p "$T/bin" "$T/remote" "$T/work/root/state"
  cat > "$T/bin/gh" <<'SH'
#!/usr/bin/env bash
echo 42
SH
  chmod +x "$T/bin/gh"
  export PATH=$T/bin:$PATH
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.$T/remote.insteadOf" GIT_CONFIG_VALUE_0="https://x-access-token:tok@github.com/o/r.git"
  git init -q --bare -b main "$T/remote"
  cd "$T/work" || return
  git init -q -b main .
  echo '{"serial":1,"encrypted_data":"x"}' > root/state/terraform.tfstate
  git add -A && git commit -q -m seed && git push -q "$T/remote" main
  git remote add origin "$T/remote"
  cd root || return
  export STATE=state/terraform.tfstate GITHUB_REF=refs/heads/main GITHUB_REPOSITORY=o/r
  export TOKEN=tok APP=app DIR=root GH_TOKEN=x
}

@test "commit state: an unchanged serial commits nothing" {
  state_repo
  script tofu-state-commit
  echo '{"serial":1,"encrypted_data":"re-encrypted"}' > "$STATE"
  run runner
  [ "$status" -eq 0 ]
  [[ "$output" == *"state unchanged (serial 1)"* ]] || false
  [ "$(git rev-list --count HEAD)" -eq 1 ]
}

@test "commit state: a plaintext state is refused and not committed" {
  state_repo
  script tofu-state-commit
  echo '{"serial":2,"resources":[]}' > "$STATE"
  run runner
  [ "$status" -ne 0 ]
  [ "$(git rev-list --count HEAD)" -eq 1 ]
}

@test "commit state: a moved serial is committed and pushed" {
  state_repo
  script tofu-state-commit
  echo '{"serial":2,"encrypted_data":"y"}' > "$STATE"
  run runner
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  [[ "$(git --git-dir="$T/remote" log -1 --format=%s main)" == "chore(root): update encrypted state (serial 2) "* ]] || false
}

@test "commit state: a push that lost the race is rebased and retried" {
  state_repo
  script tofu-state-commit
  git clone -q "$T/remote" "$T/other"
  git -C "$T/other" commit -q --allow-empty -m "other push"
  git -C "$T/other" push -q origin main
  echo '{"serial":2,"encrypted_data":"y"}' > "$STATE"
  run runner
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  [ "$(git --git-dir="$T/remote" log --format=%s main | sed -n 2p)" = "other push" ]
  [ "$(git --git-dir="$T/remote" rev-list --count main)" -eq 3 ]
}

@test "tofu env: exports the passphrase, masked, and the extra env lines" {
  script tofu-env
  local v=fixture target=TF_VAR_p
  export PASSPHRASE=$v PASSPHRASE_VAR=$target EXTRA=$'A=1\nB=2'
  run runner
  [ "$status" -eq 0 ]
  [ "$output" = "::add-mask::$v" ]
  [ "$(cat "$GITHUB_ENV")" = "TF_VAR_p=$v"$'\nA=1\nB=2' ]
}

@test "tofu env: an empty passphrase fails" {
  script tofu-env
  local target=TF_VAR_p
  PASSPHRASE="" PASSPHRASE_VAR=$target EXTRA="" run runner
  [ "$status" -ne 0 ]
  [[ "$output" == *"TOFU_STATE_PASSPHRASE is empty"* ]] || false
  [ ! -s "$GITHUB_ENV" ]
}

@test "app tokens: exports each minted token under its env var" {
  script tofu-tokens
  TOKEN=t1 TOKEN_VAR=GITHUB_TOKEN TOKEN2=t2 TOKEN2_VAR=GH2 run runner
  [ "$status" -eq 0 ]
  [ "$(cat "$GITHUB_ENV")" = $'GITHUB_TOKEN=t1\nGH2=t2' ]
}

@test "app tokens: a second token without its env var fails, no token exports nothing" {
  script tofu-tokens
  TOKEN="" TOKEN_VAR=GITHUB_TOKEN TOKEN2=t2 TOKEN2_VAR="" run runner
  [ "$status" -ne 0 ]
  [[ "$output" == *"app-token-owner-2 needs app-token-env-2"* ]] || false
  TOKEN="" TOKEN_VAR=GITHUB_TOKEN TOKEN2="" TOKEN2_VAR="" run runner
  [ "$status" -eq 0 ]
  [ ! -s "$GITHUB_ENV" ]
}

# comment <existing comments JSON>: run jm-tofu-comment in $T/c; the fake gh logs its calls to $T/calls
comment() {
  mkdir -p "$T/bin" "$T/c"
  cat > "$T/bin/gh" <<'SH'
#!/usr/bin/env bash
echo "$*" >> "$T/calls"
q=; while [ $# -gt 0 ]; do [ "$1" = --jq ] && q=$2; shift; done
[ -z "$q" ] || jq -r "$q" "$T/comments.json"
SH
  chmod +x "$T/bin/gh"
  printf '%s' "$1" > "$T/comments.json"
  script tofu-comment
  export T PATH=$T/bin:$PATH GITHUB_STEP_SUMMARY=$T/summary GITHUB_REPOSITORY=o/r PR=7 OUTCOME=success DIR=infra RUN_URL=https://run
  (cd "$T/c" && runner)
}

@test "plan comment: a new comment with the plan summary line and output" {
  mkdir -p "$T/c"
  printf 'x will be created\nPlan: 1 to add, 0 to change, 0 to destroy.\n' > "$T/c/plan.txt"
  run comment '[]'
  [ "$status" -eq 0 ]
  head -1 "$T/c/comment.md" | grep -qxF '<!-- tofu-plan:infra -->'
  grep -qxF '**Plan: 1 to add, 0 to change, 0 to destroy.**' "$T/c/comment.md"
  grep -qxF 'x will be created' "$T/c/comment.md"
  grep -qxF '[run](https://run)' "$T/c/comment.md"
  cmp -s "$T/c/comment.md" "$T/summary"
  [ "$(tail -1 "$T/calls")" = "api repos/o/r/issues/7/comments -F body=@comment.md" ]
}

@test "plan comment: edits the earlier comment for the same root, notes a missing plan" {
  run comment '[{"id":5,"user":{"login":"github-actions[bot]"},"body":"<!-- tofu-plan:infra -->\nold"},
    {"id":6,"user":{"login":"github-actions[bot]"},"body":"<!-- tofu-plan:other -->\nold"}]'
  [ "$status" -eq 0 ]
  grep -qxF 'no plan output (earlier step failed)' "$T/c/comment.md"
  [ "$(tail -1 "$T/calls")" = "api -X PATCH repos/o/r/issues/comments/5 -F body=@comment.md" ]
}

@test "tofu apply: summary carries the result and the state serial before and after" {
  mkdir -p "$T/bin" "$T/a/state"
  cat > "$T/bin/tofu" <<'SH'
#!/usr/bin/env bash
echo '{"serial":4}' > state/terraform.tfstate
echo 'Apply complete! Resources: 1 added, 0 changed, 0 destroyed.'
SH
  chmod +x "$T/bin/tofu"
  echo '{"serial":3}' > "$T/a/state/terraform.tfstate"
  script tofu-apply
  export PATH=$T/bin:$PATH GITHUB_STEP_SUMMARY=$T/summary STATE=state/terraform.tfstate WD=infra
  (cd "$T/a" && runner)
  grep -qxF 'Apply complete! Resources: 1 added, 0 changed, 0 destroyed.' "$T/summary"
  grep -qxF 'state serial: 3 -> 4' "$T/summary"
}

@test "tofu apply: a failed apply fails the step" {
  mkdir -p "$T/bin" "$T/a"
  printf '#!/usr/bin/env bash\necho boom\nexit 1\n' > "$T/bin/tofu"
  chmod +x "$T/bin/tofu"
  script tofu-apply
  export PATH=$T/bin:$PATH GITHUB_STEP_SUMMARY=$T/summary STATE=state/terraform.tfstate WD=infra
  run bash -c 'cd "$1" && "$2"' _ "$T/a" "$T/step.sh"
  [ "$status" -ne 0 ]
}
