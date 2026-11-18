# .github

Rules for agents working in this repo. Overview and commands: README.md.

## Boundary

- Workflows, actions, hooks and scaffolding templates belong here.
- Repo settings, labels and tofu live in `JakobMelchard/infra`, not here. Never `gh label create` by hand.
- `scripts/ci` is executed directly; `scripts/lib/common.sh` is sourced by other repos via `JM_LIB`. Keep both bash 3.2 compatible.

## Workflows

- Every `*-cmd` input skips its step when `""`. Add an input instead of an `if` (except `python.yml` `install-cmd`, which overrides `package-manager`). Describe every input under `inputs:`.
- A `run:` block longer than a few lines belongs in a script: `actions/scripts/bin/jm-*` for reusable workflows, `scripts/` for repo workflows, next to `action.yml` for actions. Add a bats test in `scripts/test/` and pass shellcheck at warning. Scripts that `eval` caller commands use `set -eo pipefail` without `-u`.
- JavaScript carries strict JSDoc types checked by `tsc --checkJs` and formatted with prettier (`npm run check --prefix actions/docs`). No inline `<style>` or `<script>` in generated HTML.
- Pin third-party actions by commit SHA with the version in a trailing comment.
- No checkout takes a `repository` input. Cross-repo private dependencies require explicit `app-client-id` and `app-private-key` inputs, never `secrets: inherit`.
- New reusable workflows need a `smoke-<name>` job in `lint.yml` called with empty inputs. Not smoked on purpose: `release`, `ai-review`, `review-label`, `automerge`, `config-publish.yml`. `cf` uses `dry-run`; `tofu` skips plan, apply and state commit.
- Add a starter in `workflow-templates/` once released. Rendered callers live in `JakobMelchard/template`.

## Releases

- Callers pin a release tag, never `@main`. Never move a tag by hand; `self-release.yml` moves the major tag, and `config-publish.yml` manually stages `config-v*` releases on npm.
