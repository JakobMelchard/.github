#!/usr/bin/env bash
# Install the shared hooks into the current repo.
#
#   curl -fsSL https://raw.githubusercontent.com/JakobMelchard/.github/main/hooks/install.sh | bash
#
# Copies hooks into .githooks/ and sets core.hooksPath. Re-run to update.
set -euo pipefail

REF="${HOOKS_REF:-main}"
REPO="JakobMelchard/.github"

cd "$(git rev-parse --show-toplevel)"
mkdir -p .githooks

if [ -d "$(dirname "${BASH_SOURCE[0]}")/../hooks" ]; then
  # running from a clone of .github itself
  src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cp "$src"/pre-commit "$src"/pre-push .githooks/
else
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  for h in pre-commit pre-push; do
    curl -fsSL "https://raw.githubusercontent.com/$REPO/$REF/hooks/$h" -o "$tmp/$h"
  done
  cp "$tmp"/pre-commit "$tmp"/pre-push .githooks/
fi

chmod +x .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks
echo "hooks installed -> .githooks/ (core.hooksPath set)"

command -v gitleaks >/dev/null || echo "note: gitleaks not found — secret scanning will be skipped (brew install gitleaks)"
