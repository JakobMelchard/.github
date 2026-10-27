#!/usr/bin/env bash
# pre-push: vet and build the module at the repo root. Tests belong in CI.
set -euo pipefail
export HOOK=go-build
. "$(dirname "$0")/lib.sh"
[ -f go.mod ] || exit 0
need go "install Go"
go vet ./...
go build ./...
