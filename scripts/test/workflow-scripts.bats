#!/usr/bin/env bats
# The jm-* workflow scripts of actions/scripts/bin, run against fake tools in $T/bin.

load helper

setup() {
  common_setup
  mkdir -p "$T/bin"
  export T PATH=$T/bin:$PATH GITHUB_ENV=$T/env GITHUB_OUTPUT=$T/out GITHUB_STEP_SUMMARY=$T/summary RUNNER_TEMP=$T
  : > "$GITHUB_ENV"
  : > "$GITHUB_OUTPUT"
}

# fake <name> <body>: a fake tool in $T/bin that logs its arguments to $T/<name>.log, then runs body
fake() {
  printf '#!/usr/bin/env bash\necho "$*" >> "$T/%s.log"\n%s\n' "$1" "${2-}" > "$T/bin/$1"
  chmod +x "$T/bin/$1"
}

@test "pr title: conventional titles pass" {
  for t in 'feat: x' 'fix(api): y' 'refactor(a/b.c)!: z' 'ci: pin'; do
    TITLE=$t run "$JM/jm-pr-title"
    [ "$status" -eq 0 ]
    [ "$output" = "ok: $t" ]
  done
}

@test "pr title: anything else fails with an annotation" {
  for t in 'Feat: x' 'feature: x' 'fix:x' 'fix(): x' 'fix: ' 'update stuff'; do
    TITLE=$t run "$JM/jm-pr-title"
    [ "$status" -eq 1 ]
    [[ "$output" == "::error title=PR title::'$t' is not a conventional commit"* ]] || false
  done
}

@test "git auth: rewrites https://github.com/ by default" {
  TOKEN=tok run "$JM/jm-git-auth"
  [ "$status" -eq 0 ]
  [ "$(cat "$GITHUB_ENV")" = "GIT_CONFIG_KEY_0=url.https://x-access-token:tok@github.com/.insteadOf
GIT_CONFIG_VALUE_0=https://github.com/
GIT_CONFIG_COUNT=1" ]
}

@test "git auth: one rewrite per given prefix" {
  TOKEN=tok "$JM/jm-git-auth" https://github.com/ git@github.com:
  grep -qx 'GIT_CONFIG_VALUE_1=git@github.com:' "$GITHUB_ENV"
  grep -qx 'GIT_CONFIG_COUNT=2' "$GITHUB_ENV"
}

@test "clone siblings: name and name@ref, next to the checkout" {
  fake git 'case "$1" in -C) echo abc1234 ;; esac'
  mkdir "$T/ws" && cd "$T/ws"
  SIBLINGS='hx flatplan@v1.2.0' run "$JM/jm-clone-siblings"
  [ "$status" -eq 0 ]
  grep -qxF 'clone -q --depth 1 --branch main https://github.com/JakobMelchard/hx.git ../hx' "$T/git.log"
  grep -qxF 'clone -q --depth 1 --branch v1.2.0 https://github.com/JakobMelchard/flatplan.git ../flatplan' "$T/git.log"
  [[ "$output" == *"sibling flatplan @ v1.2.0 -> abc1234"* ]] || false
}

@test "clone siblings: a bad name fails before cloning" {
  fake git
  SIBLINGS='../evil' run "$JM/jm-clone-siblings"
  [ "$status" -eq 1 ]
  [[ "$output" == *"bad sibling '../evil'"* ]] || false
  [ ! -e "$T/git.log" ]
}

# runtimes JSON: one iOS runtime that supports an iPad and an iPhone
runtimes() {
  echo '{"runtimes":[{"platform":"iOS","version":"17.5","identifier":"rt17"},{"platform":"iOS","version":"18.2","identifier":"rt18",
    "supportedDeviceTypes":[{"name":"iPhone 16","identifier":"t.iphone","productFamily":"iPhone"},
    {"name":"iPad Air 11-inch (M4)","identifier":"t.ipad","productFamily":"iPad"}]}]}'
}

@test "simulator: no iOS Simulator destination or no name: nothing to do" {
  fake xcrun
  CMD="" DEST="platform=macOS" run "$JM/jm-xcode-simulator"
  [ "$output" = "no iOS Simulator destination" ]
  CMD="" DEST="platform=iOS Simulator,OS=latest" run "$JM/jm-xcode-simulator"
  [ "$output" = "no simulator name in the destination" ]
  [ ! -e "$T/xcrun.log" ]
}

@test "simulator: an existing device is left alone" {
  fake xcrun 'echo "    iPad Air 11-inch (M4) (ABC) (Shutdown)"'
  CMD="" DEST="platform=iOS Simulator,name=iPad Air 11-inch (M4)" run "$JM/jm-xcode-simulator"
  [ "$status" -eq 0 ]
  [ "$output" = "simulator 'iPad Air 11-inch (M4)' present" ]
}

@test "simulator: creates the named device on the newest runtime, test-cmd wins over destination" {
  runtimes > "$T/runtimes.json"
  fake xcrun 'case "$2 $3" in "list runtimes") cat "$T/runtimes.json" ;; create*) echo UDID ;; esac'
  CMD="xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 16'" DEST="platform=iOS Simulator,name=Other" \
    run "$JM/jm-xcode-simulator"
  [ "$status" -eq 0 ]
  grep -qxF 'simctl create iPhone 16 t.iphone rt18' "$T/xcrun.log"
  [[ "$output" == *"created 'iPhone 16' (t.iphone, rt18): UDID"* ]] || false
}

@test "simulator: an unknown device name becomes the newest iPad, with a warning" {
  runtimes > "$T/runtimes.json"
  fake xcrun 'case "$2 $3" in "list runtimes") cat "$T/runtimes.json" ;; create*) echo UDID ;; esac'
  CMD="" DEST="platform=iOS Simulator,name=Future Pad" run "$JM/jm-xcode-simulator"
  [ "$status" -eq 0 ]
  grep -qxF 'simctl create Future Pad t.ipad rt18' "$T/xcrun.log"
  [[ "$output" == *"::warning::rt18 has no device type named 'Future Pad'"* ]] || false
}

@test "simulator: no runtime even after a download fails" {
  fake xcrun 'case "$2 $3" in "list runtimes") echo "{\"runtimes\":[]}" ;; esac'
  fake xcodebuild
  CMD="" DEST="platform=iOS Simulator,name=X" run "$JM/jm-xcode-simulator"
  [ "$status" -eq 1 ]
  grep -qxF -- '-downloadPlatform iOS' "$T/xcodebuild.log"
  [[ "$output" == *"::error::no iOS simulator runtime available"* ]] || false
}

@test "xcodebuild test: finds the workspace before the project, filters the console" {
  fake xcodebuild 'echo "Compiling a"; echo "Test Suite x passed"'
  mkdir -p "$T/p/App.xcodeproj" "$T/p/App.xcworkspace" && cd "$T/p"
  PROJECT="" SCHEME=App DEST=d run "$JM/jm-xcodebuild-test"
  [ "$status" -eq 0 ]
  [ "$output" = "Test Suite x passed" ]
  grep -qxF -- '-workspace ./App.xcworkspace -scheme App -destination d -skipMacroValidation -skipPackagePluginValidation test' "$T/xcodebuild.log"
  grep -qxF 'Compiling a' xcodebuild.log
}

@test "xcodebuild test: no project fails, a failing build fails" {
  fake xcodebuild 'echo "error: boom"; exit 65'
  mkdir -p "$T/p" && cd "$T/p"
  PROJECT="" SCHEME=App DEST=d run "$JM/jm-xcodebuild-test"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no .xcodeproj/.xcworkspace found"* ]] || false
  PROJECT=Other.xcodeproj SCHEME=App DEST=d run "$JM/jm-xcodebuild-test"
  [ "$status" -eq 65 ]
}

# events <n labels now> <n old>: one issues events page with recent and day-old ai:pr-agent labels
events() {
  jq -nc --argjson n "$1" --argjson o "$2" '[(range($n) | {event: "labeled", label: {name: "ai:pr-agent"},
    issue: {pull_request: {}}, actor: {type: "User"}, created_at: (now | todate)}),
    {event: "labeled", label: {name: "ai:pr-agent"}, issue: {pull_request: {}}, actor: {type: "Bot"}, created_at: (now | todate)},
    (range($o) | {event: "labeled", label: {name: "ai:pr-agent"}, issue: {pull_request: {}}, actor: {type: "User"},
    created_at: (now - 90000 | todate)})]' > "$T/events.json"
}

@test "review cap: under the cap reviews, over it skips" {
  fake gh 'cat "$T/events.json"'
  export GITHUB_REPOSITORY=o/r
  events 3 2
  CAP=3 run "$JM/jm-ai-review-cap"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ai:pr-agent labels in 24 h: 3, cap 3"* ]] || false
  [ ! -s "$GITHUB_OUTPUT" ]
  events 4 0
  CAP=3 run "$JM/jm-ai-review-cap"
  [ "$(cat "$GITHUB_OUTPUT")" = "skip=true" ]
  [ "$(wc -l < "$T/gh.log")" -eq 2 ]
}

# review <first output> [second output]: run jm-ai-review with a fake uv answering in turn
review() {
  rm -f "$T/uv.log" "$T/models"
  printf '%s' "$1" > "$T/r1"
  printf '%s' "${2-}" > "$T/r2"
  fake uv 'n=$(($(wc -l < "$T/uv.log"))); cat "$T/r$n"; env | grep -E "^CONFIG__MODEL=" >> "$T/models"'
  export GITHUB_REPOSITORY=o/r PR_NUM=3 PR_URL=https://pr MODEL=m1 FALLBACK_MODEL=m2
  run "$JM/jm-ai-review"
}

@test "ai review: a review that worked is not retried" {
  review "posted"
  [ "$status" -eq 0 ]
  [ "$(cat "$T/models")" = "CONFIG__MODEL=m1" ]
}

@test "ai review: a failed review is retried once on the fallback model" {
  review "Failed to review PR" "posted"
  [ "$status" -eq 0 ]
  [ "$(cat "$T/models")" = $'CONFIG__MODEL=m1\nCONFIG__MODEL=m2' ]
  review "Failed to review PR" "Failed to review PR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"::error::PR-Agent failed to review the PR"* ]] || false
}

@test "ai review: a timeout or usage limit is not retried" {
  review $'litellm.Timeout\nFailed to review PR'
  [ "$status" -eq 1 ]
  [ "$(cat "$T/models")" = "CONFIG__MODEL=m1" ]
  [[ "$output" == *"fallback not tried"* ]] || false
}

@test "shell: collect finds bash, sh and zsh shebangs under the roots, skipping vendored dirs" {
  mkdir -p "$T/r/bin" "$T/r/node_modules/x" "$T/r/.git"
  printf '#!/usr/bin/env bash\n' > "$T/r/bin/a"
  printf '#!/bin/sh\n' > "$T/r/b.sh"
  printf '#!/bin/zsh -f\n' > "$T/r/c"
  printf '#!/usr/bin/env python3\n' > "$T/r/d"
  printf '#!/bin/sh\n' > "$T/r/node_modules/x/e"
  printf '#!/bin/sh\n' > "$T/r/.git/f"
  cd "$T/r"
  PATHS="bin ." run "$JM/jm-shell-collect"
  [ "$status" -eq 0 ]
  [ "$(cat "$T/scripts.txt")" = $'./b.sh\n./bin/a\n./c\nbin/a' ]
  grep -qx 'count=4' "$GITHUB_OUTPUT"
}

@test "shell: syntax checks bash with bash -n and zsh with zsh -n" {
  fake zsh
  printf '#!/usr/bin/env bash\nif then\n' > "$T/bad"
  printf '#!/usr/bin/env bash\necho ok\n' > "$T/good"
  printf '#!/bin/zsh\necho ok\n' > "$T/z"
  printf '%s\n' "$T/good" "$T/z" > "$T/scripts.txt"
  run "$JM/jm-shell-syntax"
  [ "$status" -eq 0 ]
  [ "$(cat "$T/zsh.log")" = "-n $T/z" ]
  printf '%s\n' "$T/bad" "$T/good" > "$T/scripts.txt"
  run "$JM/jm-shell-syntax"
  [ "$status" -eq 1 ]
}

@test "shell: shellcheck runs at the severity on every script but zsh ones" {
  fake shellcheck '[[ "$*" != *bad ]]'
  printf '#!/bin/sh\n' > "$T/good"
  printf '#!/bin/sh\n' > "$T/bad"
  printf '#!/bin/zsh\n' > "$T/z"
  printf '%s\n' "$T/good" "$T/z" > "$T/scripts.txt"
  SEVERITY=error run "$JM/jm-shellcheck"
  [ "$status" -eq 0 ]
  [ "$(cat "$T/shellcheck.log")" = "--severity=error $T/good" ]
  printf '%s\n' "$T/bad" "$T/good" > "$T/scripts.txt"
  SEVERITY=error run "$JM/jm-shellcheck"
  [ "$status" -eq 1 ]
}

@test "py: a command runs through uv, the pip venv or as is" {
  fake uv
  mkdir -p "$T/p/.venv/bin" && cd "$T/p"
  printf '#!/usr/bin/env bash\necho "venv $*"\n' > .venv/bin/pytest && chmod +x .venv/bin/pytest
  PKG_MGR=uv "$JM/jm-py" 'pytest -q'
  [ "$(cat "$T/uv.log")" = "run pytest -q" ]
  [ "$(PKG_MGR=pip "$JM/jm-py" 'pytest -q')" = "venv -q" ]
  [ "$(PKG_MGR=none "$JM/jm-py" 'echo "$HOME_UNSET_X" plain')" = " plain" ]
}

@test "py install: install-cmd wins, else the package manager's install" {
  fake uv
  INSTALL_CMD='echo custom' PKG_MGR=uv run "$JM/jm-py-install"
  [ "$output" = "custom" ]
  [ ! -e "$T/uv.log" ]
  INSTALL_CMD="" PKG_MGR=uv "$JM/jm-py-install"
  [ "$(cat "$T/uv.log")" = "sync --all-extras" ]
  INSTALL_CMD="" PKG_MGR=none run "$JM/jm-py-install"
  [ "$status" -eq 0 ]
  INSTALL_CMD="" PKG_MGR=poetry run "$JM/jm-py-install"
  [ "$status" -eq 1 ]
  [ "$output" = "unknown package-manager: poetry" ]
}

@test "wrangler deploy: pinned version, environment, account and dry run" {
  fake npx 'echo "account=${CLOUDFLARE_ACCOUNT_ID-}"'
  WRANGLER_ENV=dev WRANGLER_VERSION=4.1.0 ACCOUNT_ID=acc DRY_RUN=true run "$JM/jm-wrangler-deploy"
  [ "$status" -eq 0 ]
  [ "$output" = "account=acc" ]
  [ "$(cat "$T/npx.log")" = "--yes wrangler@4.1.0 deploy --env dev --dry-run" ]
}

@test "wrangler deploy: the project's wrangler at the top level; bad inputs fail" {
  fake npx
  WRANGLER_ENV="" WRANGLER_VERSION="" ACCOUNT_ID="" DRY_RUN=false "$JM/jm-wrangler-deploy"
  [ "$(cat "$T/npx.log")" = "--no-install wrangler deploy" ]
  WRANGLER_ENV='a b' WRANGLER_VERSION="" ACCOUNT_ID="" DRY_RUN=false run "$JM/jm-wrangler-deploy"
  [ "$status" -eq 1 ]
  WRANGLER_ENV="" WRANGLER_VERSION='1;x' ACCOUNT_ID="" DRY_RUN=false run "$JM/jm-wrangler-deploy"
  [ "$status" -eq 1 ]
}

@test "move major tag: an annotated tag is dereferenced, an existing major tag moved" {
  fake gh 'case "$*" in
    "api repos/o/r/git/ref/tags/v2.3.1") echo "{\"object\":{\"sha\":\"tagobj\",\"type\":\"tag\"}}" ;;
    "api repos/o/r/git/tags/tagobj -q .object.sha") echo commit1 ;;
  esac'
  GITHUB_REPOSITORY=o/r TAG=v2.3.1 run "$BIN/move-major-tag"
  [ "$status" -eq 0 ]
  [ "$output" = "v2 -> v2.3.1 (commit1)" ]
  grep -qxF 'api -X PATCH repos/o/r/git/refs/tags/v2 -f sha=commit1 -F force=true' "$T/gh.log"
}

@test "move major tag: a missing major tag is created" {
  fake gh 'case "$*" in
    "api repos/o/r/git/ref/tags/v3.0.0") echo "{\"object\":{\"sha\":\"c3\",\"type\":\"commit\"}}" ;;
    "api repos/o/r/git/ref/tags/v3") exit 1 ;;
  esac'
  GITHUB_REPOSITORY=o/r TAG=v3.0.0 run "$BIN/move-major-tag"
  [ "$status" -eq 0 ]
  grep -qxF 'api -X POST repos/o/r/git/refs -f ref=refs/tags/v3 -f sha=c3' "$T/gh.log"
}

@test "routine pick: the schedule picks the routine, else the input" {
  EVENT=schedule CRON="37 2 * * *" INPUT="" "$BIN/routine" pick
  EVENT=schedule CRON="7 3 * * *" INPUT="" "$BIN/routine" pick
  EVENT=workflow_dispatch CRON="" INPUT=nightly-improve "$BIN/routine" pick
  [ "$(cat "$GITHUB_OUTPUT")" = $'routine=nightly-improve\nroutine=nightly-sweep\nroutine=nightly-improve' ]
}

@test "routine run: the prompt goes to opencode, a dry run asks for a plan only" {
  fake opencode
  printf 'do it' > "$T/p.md"
  PROMPT=$T/p.md MODEL=m DRY=false "$BIN/routine" run
  PROMPT=$T/p.md MODEL=m DRY=true "$BIN/routine" run
  [ "$(sed -n 1p "$T/opencode.log")" = "run --model m do it" ]
  grep -qF 'routine-fire-payload: DRY RUN.' "$T/opencode.log"
  run "$BIN/routine" nope
  [ "$status" -eq 2 ]
}

@test "routine clone: every listed repo into work/, a failed clone is skipped" {
  fake gh 'case "$1" in repo) echo a; echo b ;; esac'
  fake git '[[ "$*" != *"/o/b "* ]]'
  mkdir "$T/ws" && cd "$T/ws"
  OWNER=o run "$BIN/routine" clone
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped b"* ]] || false
  grep -qxF 'clone -q https://github.com/o/a work/a' "$T/git.log"
  grep -qxF 'auth setup-git' "$T/gh.log"
}
