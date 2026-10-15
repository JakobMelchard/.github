#!/usr/bin/env bash
# code-changed.sh: set code=false in $GITHUB_OUTPUT when every file changed between $BASE and
# $HEAD of $REPO is Markdown, else code=true. Only push and pull_request events with a base
# compare; anything else, and an API failure, counts as code.
set -euo pipefail

code=true
# compare lists at most 300 files: at that size the list may be cut, so count it as code. A
# rename counts by both names (foo.py -> foo.md removes code).
if [[ "$EVENT" =~ ^(push|pull_request)$ && -n "$BASE" && ! "$BASE" =~ ^0+$ ]] &&
  files=$(gh api "repos/$REPO/compare/$BASE...$HEAD" --jq '
    if (.files | length) >= 300 then "truncated"
    else .files[] | .filename, (.previous_filename // empty) end') &&
  [ -n "$files" ] && ! grep -qv '\.md$' <<<"$files"; then
  code=false
fi
echo "code=$code" >> "$GITHUB_OUTPUT"
echo "changed besides Markdown: $code"
