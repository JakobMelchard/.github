#!/usr/bin/env bash
# Rewrite unformatted .tf files. OpenTofu first (house tool), terraform as a fallback.
set -eo pipefail
export HOOK=tofu-fmt
. "$(dirname "$0")/lib.sh"
bin=$(command -v tofu 2>/dev/null || command -v terraform 2>/dev/null || true)
[ -n "$bin" ] || fail "tofu not found (brew install opentofu). Skip once with SKIP=$HOOK."
"$bin" fmt "$@" >/dev/null
