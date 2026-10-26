#!/usr/bin/env bash
# Every JSON file in the repo parses.
set -euo pipefail
cd "$(dirname "$0")/.."
rc=0
while IFS= read -r f; do
  jq -e . "$f" >/dev/null || { echo "$f invalid" >&2; rc=1; }
done < <(find . -name '*.json' -not -path './node_modules/*')
exit "$rc"
