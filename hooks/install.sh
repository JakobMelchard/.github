#!/usr/bin/env bash

set -e

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_DIR="$(git rev-parse --git-dir)"

echo "Installing git hooks from $HOOKS_DIR to $GIT_DIR/hooks"

mkdir -p "$GIT_DIR/hooks"

for hook in "$HOOKS_DIR"/*; do
	hook_name=$(basename "$hook")
	{
	    [[ -d "$hook" ]] || 
	    [[ "$hook_name" == "install.sh" ]] || 
	    [[ "$hook_name" == "README.md" ]]
	} && continue

	target="$GIT_DIR/hooks/$hook_name"
	cp "$hook" "$target"
	echo "Installed: $hook_name"
done

echo "Git hooks installed successfully!"
