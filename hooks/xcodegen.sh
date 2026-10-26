#!/usr/bin/env bash
# pre-push: every tracked project.yml (any directory) still generates.
set -euo pipefail
export HOOK=xcodegen
. "$(dirname "$0")/lib.sh"
specs=$(git ls-files -- 'project.yml' '*/project.yml')
[ -n "$specs" ] || exit 0
need xcodegen "brew install xcodegen"
top=$(pwd)
while IFS= read -r s; do
  cd "$top/$(dirname "$s")"
  xcodegen generate --quiet || fail "xcodegen generate failed for $s"
done <<<"$specs"
