# Git Hooks

This directory contains git hooks for this repository.

## Installation

To install the hooks, run:

```bash
bash hooks/install.sh
```

This will create symlinks from your `.git/hooks` directory to the hooks in this directory.

## Available Hooks

Add your git hooks to this directory. Common hooks include:

- `pre-commit` - Runs before a commit is created
- `pre-push` - Runs before pushing to a remote
- `commit-msg` - Validates commit messages
- `post-checkout` - Runs after checking out a branch
- `post-merge` - Runs after a merge

## Creating a Hook

1. Create a new file in this directory with the hook name (e.g., `pre-commit`)
2. Make it executable: `chmod +x hooks/pre-commit`
3. Run `bash hooks/install.sh` to install all hooks
