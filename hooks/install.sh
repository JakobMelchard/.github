#!/usr/bin/env bash
# DEPRECATED shim. The shared hooks moved to the private repo JakobMelchard/.githooks.
# This entry point stays one cycle so vendored copies that point here keep working.
set -euo pipefail
echo "hooks moved to JakobMelchard/.githooks — forwarding (needs gh auth)" >&2
command -v gh >/dev/null || { echo "install: gh is required; or use hooks-install from JakobMelchard/bin" >&2; exit 1; }
exec bash <(gh api "repos/JakobMelchard/.githooks/contents/install?ref=${HOOKS_REF:-main}" -q .content | base64 -d)
