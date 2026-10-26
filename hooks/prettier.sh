#!/usr/bin/env bash
# Format with the repo-installed prettier; only files that resolve a config are touched.
set -eo pipefail
export HOOK=prettier
. "$(dirname "$0")/lib.sh"

if [ -x "node_modules/.bin/prettier" ]; then
  PRETTIER=(node_modules/.bin/prettier)
elif npx --no-install prettier --version >/dev/null 2>&1; then
  PRETTIER=(npx --no-install prettier)
else
  fail "prettier not installed in this repo (npm ci). Skip once with SKIP=$HOOK."
fi

files=()
for f in "$@"; do
  if "${PRETTIER[@]}" --find-config-path "$f" >/dev/null 2>&1; then
    files+=("$f")
  fi
done

if [ ${#files[@]} -eq 0 ]; then
  echo "prettier: no config found, skipping."
  exit 0
fi

"${PRETTIER[@]}" --write --ignore-unknown --log-level warn "${files[@]}"
