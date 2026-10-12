# .github

Shared CI for the `JakobMelchard` org and the `lilfeelz` personal repos: reusable workflows,
composite actions, starter workflows and the org Renovate preset. The repo is public so that
`lilfeelz` repos can call the workflows and the org profile renders. Contributing rules are in
[CONTRIBUTING.md](CONTRIBUTING.md), rules for agents working here in [AGENTS.md](AGENTS.md).

## Reusable workflows

Inputs and defaults are documented under `on.workflow_call.inputs` in each file, secrets under
`on.workflow_call.secrets`.

| Workflow | What it does |
|----------|--------------|
| [`go`](.github/workflows/go.yml) | vet, test, build |
| [`python`](.github/workflows/python.yml) | uv or pip install, lint, test |
| [`node`](.github/workflows/node.yml) | install, check, lint, test, optional Playwright e2e |
| [`shell`](.github/workflows/shell.yml) | syntax check and shellcheck over every script with a shell shebang |
| [`hooks`](.github/workflows/hooks.yml) | the caller's prek config over all files |
| [`terraform`](.github/workflows/terraform.yml) | OpenTofu fmt, init, validate |
| [`tofu`](.github/workflows/tofu.yml) | OpenTofu plan on PRs, apply and encrypted state commit on the default branch |
| [`cf`](.github/workflows/cf.yml) | `wrangler deploy` for a Worker with a Durable Object |
| [`xcode`](.github/workflows/xcode.yml) | swift-format, xcodebuild test on a macOS runner |
| [`android`](.github/workflows/android.yml) | Gradle build and unit tests |
| [`release`](.github/workflows/release.yml) | release-please, authored by the org app so CI runs on the release PR |
| [`ai-review`](.github/workflows/ai-review.yml) | PR-Agent review on the `ai:pr-agent` label |
| [`review-label`](.github/workflows/review-label.yml) | requests a cubic review on the `ai:cubic` label |
| [`automerge`](.github/workflows/automerge.yml) | squash-merges a PR labelled `automerge` as the org app once every other check on the head commit is green and no review thread is open. It polls on `pull_request` (`labeled`, `synchronize`, `ready_for_review`), so callers need no CI workflow names. A failed check, draft, removed label or new commit ends the run without merging; re-label to retry. Not for `infra` or `.github`. |

```yaml
jobs:
  ci:
    uses: JakobMelchard/.github/.github/workflows/go.yml@vX.Y.Z
    with:
      test-cmd: make test
```

Shared behaviour:

- Every `*-cmd` input skips its step when set to `""`, except `python`'s `install-cmd`, which
  overrides the `package-manager` install.
- `go`, `python`, `node`, `shell`, `terraform` and `android` skip their `ci` job when a change
  touched only Markdown (`actions/code-changed`). A skipped job reports success. `pr-title` and
  `hooks` still run. `xcode` has no gate, callers filter with `paths`.
- The language workflows, `hooks`, `cf`, `xcode`, `android` and `release` write the reusable
  workflow's ref and SHA to the step summary.
- `runs-on` is a plain label in most workflows and JSON in `shell`, `release`, `ai-review` and
  `review-label`. Empty uses the org variable `RUNNER_LINUX` (`RUNNER_MACOS` for `xcode`), then
  Blacksmith (`blacksmith-2vcpu-ubuntu-2404`) for Linux in JakobMelchard repos, and GitHub's hosted runner elsewhere (macOS always falls back to `macos-latest`, never the self-hosted runner). The default is owner-aware: a missing RUNNER_LINUX never reaches hosted runners in this org (the account's hosted minutes are refused), while personal repos have no Blacksmith and keep hosted.

Find callers with a code search for `JakobMelchard/.github/.github/workflows/<name>.yml`.

### Pinning

Pin a release tag (`@vX.Y.Z`) or its commit SHA with the tag in a trailing comment, never
`@main`. The moving `v1` tag exists for old callers; do not use it. Third-party actions are pinned
by SHA. Renovate bumps both through the org preset, which every repo extends:

```json
{ "extends": ["github>JakobMelchard/.github//renovate/default"] }
```

Updates arrive weekly (Monday, Vienna time), grouped per repo. Patch, digest and GitHub Actions
minor updates automerge once CI is green; majors, Docker and `copier` updates wait for review.

### Private dependencies

`go`, `python` and `node` read private org repos when `private-modules` (go) or `private-deps`
(python, node) is true and `private-repos` names them. They need the `app-client-id` and
`app-private-key` secrets, which mint a token for the listed repos, revoked when the job ends.
Without them `github.token` is used, which cannot read other repos, so the job fails. The `token`
(PAT) secret was removed in v2.0.0.

Map secrets explicitly instead of `secrets: inherit`, so only those cross the boundary.

### Tofu

`terraform` lints only. `tofu` is separate so lint-only callers never grant its permissions. It
needs `id-token: write` and `pull-requests: write` from the caller, who also owns the triggers:
filter push on the root's paths and exclude the state directory.

```yaml
permissions: { contents: read, id-token: write, pull-requests: write }
jobs:
  tofu:
    uses: JakobMelchard/.github/.github/workflows/tofu.yml@vX.Y.Z
    with:
      working-directory: terraform/tailscale
```

State is OpenTofu-encrypted and committed to git. The passphrase and app credentials come from
Infisical. The state commit is pushed by the org app, which needs an `always` bypass on the branch
ruleset. Plans and applies of one directory queue in the group `tofu-state-<dir>` and never cancel.

Secrets from a second Infisical project (for example Cloudflare tokens) are read in place with
`extra-infisical-project` and `extra-infisical-identity`, and renamed with `env-map`. The identity
must trust every OIDC subject the caller presents (`repo:OWNER/REPO:pull_request` for PR plans,
`repo:OWNER/REPO:ref:refs/heads/<branch>` for pushes and manual runs). PR plans run the PR's code
with these secrets loaded, so use them only where PR authors are trusted.

## Composite actions

Call with `uses: JakobMelchard/.github/actions/<name>@vX.Y.Z`.

| Action | What it does |
|--------|--------------|
| [`code-changed`](actions/code-changed/action.yml) | whether a push or PR changed more than Markdown |
| [`docs`](actions/docs/action.yml) | builds a repo's `docs/` into static pages in the docs.melchard.org shell |
| [`gitleaks`](actions/gitleaks/action.yml) | scans the checkout for committed secrets |

## Starter workflows

[`workflow-templates/`](workflow-templates) has a one-line caller for each reusable workflow except `cf` and
`tofu`, pinned to the latest release, for "New workflow" in any org repo. Repos created from `JakobMelchard/template`
get their caller from there instead; change a workflow here first, then the template.

## Hooks, community files, settings

- Git hooks live in the public `JakobMelchard/.githooks`. Each repo pins it by tag in
  `.pre-commit-config.yaml` and runs `prek install` once per clone.
- Issue forms, the PR template, `SECURITY.md`, `SUPPORT.md` and `CONTRIBUTING.md` here are the
  defaults for every org repo without its own. `CODEOWNERS` and `LICENSE` are not inherited.
- Repo settings, rulesets and labels are OpenTofu in the private `JakobMelchard/infra`
  (`terraform/github`).

## Labels

`infra` declares the label set every repo carries: the GitHub defaults, `fleet:*` for agent work,
release-please's `autorelease: *` and `automerge`. Review bots run on demand by PR label:

| Label | Bot | Notes |
|-------|-----|-------|
| `ai:coderabbit` | CodeRabbit | label allowlist in its own config; free on public repos only |
| `ai:sourcery` | Sourcery | label allowlist in its own config; free on public repos only |
| `ai:cubic` | cubic | `review-label` comments `@cubic-dev-ai review` and removes the label |
| `ai:pr-agent` | PR-Agent | `ai-review` |

Bots skip draft PRs.

## Routines

Two nightly routines run the prompts in [`routines/`](routines) against the org: `nightly-sweep`
triages issues, implements `agent:cloud` issues as draft PRs and comments a verdict on Renovate
PRs; `nightly-improve` opens at most three draft PRs per night. Neither merges nor touches base
branches, workflows or infra. Each non-dry run appends a comment to issue #70.

[`routines.yml`](.github/workflows/routines.yml) runs them with opencode on the org app token.
`workflow_dispatch` is a dry run by default; the nightly schedule only runs when the repo variable
`ROUTINES` is `on`.

## Secrets

No Actions secrets. CI loads secrets from Infisical over OIDC with the `Infisical/secrets-action`
step (project `gha`, identity `gha-org`). The org GitHub App `melchbot` is installed on all repos
with Contents, Issues and Pull requests read and write; its credentials are `APP_CLIENT_ID` and
`APP_PRIVATE_KEY` in that project, and every job mints a token scoped to what it needs. Any job
using this needs `id-token: write`. Add new CI secrets to `gha`.

## Releases

`self-release.yml` runs release-please on every push to `main` and moves the major tag onto the
new release. `vX.Y.Z` releases are immutable.
