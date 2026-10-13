#!/usr/bin/env bats
# The run blocks of tofu.yml, extracted with yq and executed the way a runner does (bash -eo
# pipefail), since the workflow's plan and apply paths cannot run in this repo's own CI.

load helper

# step <job> <step name>: write that step's script to $T/step.sh
step() {
  yq ".jobs.$1.steps[] | select(.name == \"$2\") | .run" "$BATS_TEST_DIRNAME/../../.github/workflows/tofu.yml" > "$T/step.sh"
  [ -s "$T/step.sh" ]
}
runner() { bash --noprofile --norc -eo pipefail "$T/step.sh"; }

setup() {
  common_setup
  export GITHUB_ENV=$T/env
  : > "$GITHUB_ENV"
}

@test "env map: sets the target from the source, masked, skipping blank lines" {
  step apply "env map"
  export SRC_A=one SRC_B=two
  MAP=$'A=SRC_A\n\n   \nB=SRC_B\n' run runner
  [ "$status" -eq 0 ]
  [[ "$output" == *"::add-mask::one"* ]] || false
  grep -q '^A<<EOF_' "$GITHUB_ENV"
  grep -qx one "$GITHUB_ENV"
  grep -qx two "$GITHUB_ENV"
}

@test "env map: malformed lines fail" {
  step apply "env map"
  export SRC_A=one
  for m in 'noequals' '1BAD=SRC_A' 'A=1bad' 'A=SRC A' '=SRC_A' 'A='; do
    MAP=$m run runner
    [ "$status" -ne 0 ]
    [[ "$output" == *"bad env-map line"* ]] || false
  done
  [ ! -s "$GITHUB_ENV" ]
}

@test "env map: an empty or unset source fails" {
  step apply "env map"
  SRC_EMPTY="" MAP='A=SRC_EMPTY' run runner
  [ "$status" -ne 0 ]
  [[ "$output" == *"SRC_EMPTY is empty or not loaded"* ]] || false
  MAP='A=SRC_UNSET' run runner
  [ "$status" -ne 0 ]
}

@test "env map: plan and apply run the same script" {
  step plan "env map"; cp "$T/step.sh" "$T/plan.sh"
  step apply "env map"
  diff "$T/plan.sh" "$T/step.sh"
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
  step apply "commit state"
  echo '{"serial":1,"encrypted_data":"re-encrypted"}' > "$STATE"
  run runner
  [ "$status" -eq 0 ]
  [[ "$output" == *"state unchanged (serial 1)"* ]] || false
  [ "$(git rev-list --count HEAD)" -eq 1 ]
}

@test "commit state: a plaintext state is refused and not committed" {
  state_repo
  step apply "commit state"
  echo '{"serial":2,"resources":[]}' > "$STATE"
  run runner
  [ "$status" -ne 0 ]
  [ "$(git rev-list --count HEAD)" -eq 1 ]
}

@test "commit state: a moved serial is committed and pushed" {
  state_repo
  step apply "commit state"
  echo '{"serial":2,"encrypted_data":"y"}' > "$STATE"
  run runner
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  [[ "$(git --git-dir="$T/remote" log -1 --format=%s main)" == "chore(root): update encrypted state (serial 2) "* ]] || false
}

@test "commit state: a push that lost the race is rebased and retried" {
  state_repo
  step apply "commit state"
  git clone -q "$T/remote" "$T/other"
  git -C "$T/other" commit -q --allow-empty -m "other push"
  git -C "$T/other" push -q origin main
  echo '{"serial":2,"encrypted_data":"y"}' > "$STATE"
  run runner
  [ "$status" -eq 0 ] || { echo "$output"; false; }
  [ "$(git --git-dir="$T/remote" log --format=%s main | sed -n 2p)" = "other push" ]
  [ "$(git --git-dir="$T/remote" rev-list --count main)" -eq 3 ]
}
