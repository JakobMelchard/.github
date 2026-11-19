# Contributing

Applies to the repositories under `JakobMelchard` and to any repository that calls the workflows here.

- Bugs and feature requests: open an issue with the repository's template.
- Security problems: follow [SECURITY.md](SECURITY.md), never a public issue.
- One change per pull request, small diffs, docs updated when behaviour changes.

## Pull requests

- Branch from the default branch, keep the branch short-lived, squash merge.
- Titles and commits are [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `refactor:`, `test:`, optional `(scope)`, `!` for breaking changes. The `pr-title` check enforces it.
- No attribution trailers.
- CI must be green. Every review comment, inline thread and bot finding is either fixed or answered.

## Pins

- Reusable workflows, hooks and templates are pinned by release tag, third-party actions by commit SHA with the version in a trailing comment. Never `@main`.
- Renovate bumps pins from the shared preset. Do not update pins by hand.

## Scope

- Reusable workflows, composite actions, hooks, workflow templates and shared config live here.
- Repository settings and infrastructure as code do not.
