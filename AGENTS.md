# .github

Rules for agents and contributors working in this repo. Overview and commands: README.md.

## Rules

- Workflows, actions, hooks and scaffolding templates belong here.
- `scripts/lib/common.sh` is sourced by other repos via `JM_LIB`; `scripts/ci` uses it too. Keep both bash 3.2 compatible.
- Every `*-cmd` input skips its step when `""`. To make a step optional, add an input, not an `if`.
- Describe every input with `description:` under `inputs:`. Keep the workflow header short.
- A long `run:` block becomes a script: `jm-*` in `actions/scripts/bin` for the reusable workflows, `scripts/` for this repo. Each gets a bats test in `scripts/test` and passes shellcheck at warning.
- JavaScript carries JSDoc types checked by `tsc --checkJs` in strict mode and is formatted with prettier.
- Pin third-party actions by commit SHA with the version in a trailing comment.
- A new workflow gets a `smoke-<name>` job in `lint.yml` and a starter in `workflow-templates/` once a release contains it.
- Callers pin a release tag, never `@main`. Never move a tag by hand; `self-release.yml` moves the major tag.
