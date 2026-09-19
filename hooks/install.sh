#!/usr/bin/env bash
# DEPRECATED shim. The shared hooks moved to the private repo JakobMelchard/.githooks.
# This entry point stays one cycle so vendored copies that point here keep working.
set -euo pipefail
echo "hooks moved to JakobMelchard/.githooks — forwarding (needs gh auth)" >&2
command -v gh >/dev/null || { echo "install: gh is required; or use hooks-install from JakobMelchard/bin" >&2; exit 1; }
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
# raw representation: no base64 (BSD vs GNU flags differ); a failed gh api aborts under set -e
gh api -H 'Accept: application/vnd.github.raw+json' "repos/JakobMelchard/.githooks/contents/install?ref=${HOOKS_REF:-main}" > "$tmp"
[ -s "$tmp" ] || { echo "install: empty response from gh api" >&2; exit 1; }
HOOKS_REF="${HOOKS_REF:-main}" bash "$tmp"
