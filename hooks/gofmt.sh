#!/usr/bin/env bash
# Rewrite unformatted Go files, then fail so they get re-staged.
set -eo pipefail
export HOOK=gofmt
. "$(dirname "$0")/lib.sh"
need gofmt "install Go"
bad=$(gofmt -l "$@")
[ -z "$bad" ] && exit 0
printf '%s\n' "$bad" | tr '\n' '\0' | xargs -0 gofmt -w
echo "gofmt rewrote:"
printf '%s\n' "$bad" | sed 's/^/  /'
exit 1
