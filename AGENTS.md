# .github

Rules for agents working in this repo. Overview and commands: README.md.

## Boundary

- Workflows, actions, hooks and scaffolding templates belong here. `hx` is code that ships inside an app and must never grow a second reusable workflow or hook set.
- Repo settings, labels and tofu live in `JakobMelchard/infra`, not here. Never `gh label create` by hand.
- `scripts/ci` and `scripts/lib/common.sh` are sourced by other repos via `JM_LIB`. Keep them bash 3.2 compatible.

## Workflows

- Every `*-cmd` input skips its step when `""`. To make a step optional, add an input, not an `if`. Exception: `python.yml` `install-cmd` overrides the `package-manager` install.
- Describe every input with `description:` under `inputs:`. Keep the workflow header short.
- A `run:` block longer than a few lines is a script: a `jm-*` file in `actions/scripts/bin` for the reusable workflows (on PATH after `uses: JakobMelchard/.github/actions/scripts@<sha>`), `scripts/` for this repo's own workflows, a file next to `action.yml` for an action. Each gets a bats test in `scripts/test` and must pass shellcheck at warning. Scripts that `eval` a caller's command keep `set -eo pipefail` without `-u`, so a caller's command may read unset variables as in an inline step.
- JavaScript carries JSDoc types checked by `tsc --checkJs` in strict mode and is formatted with prettier (`npm run check --prefix actions/docs`). No inline `<style>` or `<script>` in generated HTML.
- Pin third-party actions by commit SHA with the version in a trailing comment.
- No checkout takes a `repository` input: workflows build their caller's checkout. A cross-repo private dependency needs a new input and `app-client-id` plus `app-private-key` mapped explicitly, never `secrets: inherit`.
- A new workflow must survive being called with no inputs: add a `smoke-<name>` job to `lint.yml`. Not smoked on purpose: `release`, `ai-review`, `review-label`, `automerge`. `cf` runs with `dry-run`, `tofu` with plan, apply and state commit off.
- A workflow gets a starter in `workflow-templates/` once a release contains it. A rendered repo's caller comes from `JakobMelchard/template`.

## Releases

- Callers pin a release tag, never `@main`. Never move a tag by hand; `self-release.yml` moves the major tag.
