#!/usr/bin/env bash
# Lint with the repo's own eslint and config.
set -eo pipefail
export HOOK=eslint
. "$(dirname "$0")/lib.sh"

if [ -x "node_modules/.bin/eslint" ]; then
  ESLINT=(node_modules/.bin/eslint)
elif npx --no-install eslint --version >/dev/null 2>&1; then
  ESLINT=(npx --no-install eslint)
else
  fail "eslint not installed in this repo (npm ci). Skip once with SKIP=$HOOK."
fi

has_config=0
for f in eslint.config.* .eslintrc*; do [ -e "$f" ] && has_config=1; done
grep -qs '"eslintConfig"' package.json && has_config=1

if [ "$has_config" -eq 0 ]; then
  echo "eslint: no config found, skipping."
  exit 0
fi

"${ESLINT[@]}" --quiet "$@"
