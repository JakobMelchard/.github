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

# :- matters: piped from curl there is no BASH_SOURCE, and `set -u` would
# abort the substitution — it happened to pick the right branch anyway, but
# printed "BASH_SOURCE[0]: unbound variable" on the documented install path.
self="${BASH_SOURCE[0]:-}"
if [ -n "$self" ] && [ -d "$(dirname "$self")/../hooks" ]; then
  # running from a clone of .github itself
  src="$(cd "$(dirname "$self")" && pwd)"
  cp "$src"/pre-commit "$src"/pre-push .githooks/
else
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  for h in pre-commit pre-push; do
    curl -fsSL "https://raw.githubusercontent.com/$REPO/$REF/hooks/$h" -o "$tmp/$h"
  done
  cp "$tmp"/pre-commit "$tmp"/pre-push .githooks/
fi

# mark the copies as vendored so nobody edits them in place
for h in pre-commit pre-push; do
  tmpf=$(mktemp)
  {
    head -1 ".githooks/$h"
    echo "# VENDORED from JakobMelchard/.github/hooks/$h — do not edit."
    echo "# Refresh: curl -fsSL https://raw.githubusercontent.com/$REPO/$REF/hooks/install.sh | bash"
    echo "# Repo-specific checks belong in .githooks/$h.local (executable)."
    tail -n +2 ".githooks/$h"
  } > "$tmpf"
  mv "$tmpf" ".githooks/$h"
done

chmod +x .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks
echo "hooks installed -> .githooks/ (core.hooksPath set)"

command -v gitleaks >/dev/null || echo "note: gitleaks not found — secret scanning will be skipped (brew install gitleaks)"
