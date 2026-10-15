# .github

Reusable workflows, composite actions and the org Renovate preset for `JakobMelchard` and the `lilfeelz` personal repos. Public so that personal repos can call the workflows.

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
