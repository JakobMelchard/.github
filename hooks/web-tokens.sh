#!/usr/bin/env bash
# Each path in .config/tokens.path (one per line) is a copy of JakobMelchard/web dist/tokens.css:
# line 1 names the web tag, the rest must equal that tag's file. No .config/tokens.path: no-op.
set -euo pipefail
export HOOK=web-tokens
. "$(dirname "$0")/lib.sh"
list=.config/tokens.path
[ -f "$list" ] || exit 0
need curl "brew install curl"
src=${WEB_TOKENS_URL:-https://raw.githubusercontent.com/JakobMelchard/web}
mark='VENDORED from JakobMelchard/web dist/tokens.css @'
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
rc=0
while IFS= read -r p || [ -n "$p" ]; do
  case $p in '' | '#'*) continue ;; esac
  if [ ! -f "$p" ]; then echo "$HOOK: $p is listed in $list but missing" >&2; rc=1; continue; fi
  ref=$(sed -n "1s|^/\* $mark\(v[0-9][0-9.]*[0-9]\)\. .*|\1|p" "$p")
  if [ -z "$ref" ]; then
    echo "$HOOK: $p line 1 must be: /* $mark<tag>. Do not edit; the web-tokens hook checks it. */" >&2
    rc=1; continue
  fi
  if ! curl -fsSL "$src/$ref/dist/tokens.css" -o "$tmp/want"; then
    echo "$HOOK: cannot fetch web dist/tokens.css at $ref" >&2; rc=1; continue
  fi
  tail -n +2 "$p" >"$tmp/have"
  if ! cmp -s "$tmp/have" "$tmp/want"; then
    echo "$HOOK: $p differs from web dist/tokens.css at $ref. Refresh it:" >&2
    echo "  { head -n 1 $p; curl -fsSL $src/$ref/dist/tokens.css; } >$p.new && mv $p.new $p" >&2
    rc=1
  fi
done <"$list"
exit "$rc"
