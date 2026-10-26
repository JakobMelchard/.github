# .github

Reusable workflows, composite actions, development policy, portable hooks and the org Renovate preset for `JakobMelchard` and the `lilfeelz` personal repos. Public so that personal repos can call the workflows.

Rules: [CONTRIBUTING.md](CONTRIBUTING.md) for every repo, [AGENTS.md](AGENTS.md) for work here.

## Use

Pin a release tag, or its commit SHA with the tag in a trailing comment. Never `@main`.

```yaml
jobs:
  ci:
    uses: JakobMelchard/.github/.github/workflows/go.yml@vX.Y.Z
    with:
      test-cmd: make test
```

```json
{ "extends": ["github>JakobMelchard/.github//renovate/default"] }
```

Inputs and secrets are documented in each workflow under `on.workflow_call`.

```yaml
# tofu: the caller owns the triggers
permissions: { contents: read, id-token: write, pull-requests: write }
jobs:
  tofu:
    uses: JakobMelchard/.github/.github/workflows/tofu.yml@vX.Y.Z
    with:
      working-directory: terraform/tailscale
```

## Develop

```sh
prek install           # once per clone
prek run --all-files   # same as the CI hooks job
npm ci --prefix actions/docs && bats scripts/test   # needs bats-core, yq, node
npm run check --prefix actions/docs                  # tsc --checkJs strict and prettier
scripts/ci [repo...]   # latest CI result per org repo
```

## Reusable workflows

| Workflow | What it does |
|----------|--------------|
| [`go`](.github/workflows/go.yml) | vet, test, build |
| [`python`](.github/workflows/python.yml) | uv or pip install, lint, test |
| [`node`](.github/workflows/node.yml) | install, check, lint, test, optional Playwright e2e |
| [`shell`](.github/workflows/shell.yml) | syntax check and shellcheck |
| [`hooks`](.github/workflows/hooks.yml) | the caller's prek config over all files |
| [`terraform`](.github/workflows/terraform.yml) | OpenTofu fmt, init, validate |
| [`tofu`](.github/workflows/tofu.yml) | OpenTofu plan on PRs, apply and encrypted state commit on the default branch |
| [`cf`](.github/workflows/cf.yml) | `wrangler deploy` for a Worker with a Durable Object |
| [`xcode`](.github/workflows/xcode.yml) | swift-format, xcodebuild test |
| [`android`](.github/workflows/android.yml) | Gradle build and unit tests |
| [`release`](.github/workflows/release.yml) | release-please as the org app |
| [`ai-review`](.github/workflows/ai-review.yml) | PR-Agent review on the `ai:pr-agent` label, skips drafts and runs over `daily-cap` (10 a day per repo) |
| [`review-label`](.github/workflows/review-label.yml) | cubic review on the `ai:cubic` label |
| [`automerge`](.github/workflows/automerge.yml) | squash-merges a PR labelled `automerge` once its other checks are green, the branch rules are met and no thread is open |

## Layout

| Path | What |
|------|------|
| `.github/workflows/` | reusable workflows, plus `lint.yml`, `self-release.yml`, `routines.yml` for this repo |
| `.github/ISSUE_TEMPLATE/`, `SECURITY.md`, `SUPPORT.md`, `CONTRIBUTING.md` | org defaults for repos without their own |
| `actions/` | composite actions: `code-changed`, `docs`, `gitleaks`, and `scripts`, which puts the workflows' `jm-*` scripts on PATH |
| `workflow-templates/` | starter callers for "New workflow" |
| `renovate/default.json` | org Renovate preset |
| `routines/` | prompts for the nightly sweep and improve routines |
| `scripts/` | `ci` and `lib/common.sh`, this repo's own workflow scripts, bats tests in `test/` |
| `profile/` | org profile |
| `config/` | `@jakobmelchard/config` npm package, consumer fixtures and tests |
| `hooks/`, `.pre-commit-hooks.yaml` | portable hook implementations and consumer manifest |

### component release outputs

`release.yml` retains `release_created`, `tag_name` and `version` for the root
package only. Component-only releases do not change these legacy outputs.
`releases_created` is `"true"` when any package releases. `paths_released` is a JSON
array of canonical manifest paths, and `releases` maps each released path to its
`tag_name` and `version`. No release returns `[]`, `{}` and `"false"` respectively.

For example, two independent releases produce:

```json
{"apps/fz":{"tag_name":"fz-v1.2.0","version":"1.2.0"},"apps/pull":{"tag_name":"pull-v3.0.1","version":"3.0.1"}}
```

A release matrix can use `fromJSON(needs.release.outputs.paths_released)` and
`fromJSON(needs.release.outputs.releases)[matrix.path].tag_name`. Guard the job
with `needs.release.outputs.releases_created == 'true'` before evaluating an empty
matrix. Root releases use the `"."` key. This adapts the upstream
[release-please path outputs](https://github.com/googleapis/release-please-action#outputs)
without guessing one tag from a multi-package release.
