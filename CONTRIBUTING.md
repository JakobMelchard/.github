# Contributing

Applies to every `JakobMelchard` repository. A repo's own `AGENTS.md` adds the specifics.

- **Commits and PR titles are conventional commits**: `feat:` `fix:` `chore:` `docs:` `refactor:`
  `test:` `ci:` `build:` `perf:` `style:` `revert:`, optional `(scope)`, `!` for breaking.
  PRs are squash-merged with the title as the commit subject, and release-please turns that into
  versions and `CHANGELOG.md`. The `commit-msg` hook and the `pr-title` CI job enforce the format.
- **Hooks**: run `hooks-install` (from `JakobMelchard/bin`) once per clone. `pre-commit` formats
  and lints staged files, `pre-push` runs the cheap build gate, `commit-msg` checks the subject.
- **CI** is the org's reusable workflows in this repo. Do not add a second pipeline; add an input.
- **Versioning** is release-please. Never hand-edit `CHANGELOG.md` or version files.
- **No secrets in tracked files.** `gitleaks` runs in the hooks and in CI.
