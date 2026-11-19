# .github

## Purpose

- Public reusable CI workflows, composite actions, portable hooks, org policy and shared configuration for JakobMelchard and personal repositories.
- Repo settings and labels belong to `JakobMelchard/infra`; rendered project scaffolding belongs to `JakobMelchard/template`.

## Layout

```text
.github/             Reusable workflows, self-CI and default issue/PR templates
actions/             code-changed, docs, gitleaks and jm-* script actions
config/              @jakobmelchard/config package and consumer tests
hooks/               Portable hook implementations
.pre-commit-hooks.yaml Consumer hook manifest
workflow-templates/  Starter workflow callers
renovate/            Shared dependency-update preset
scripts/             CI utilities, shared shell library and Bats tests
profile/             Public org profile
REFERENCE.md         Workflow contracts, examples and release outputs
```

## Usage

From repository root:

```sh
prek install
prek run --all-files
npm ci --prefix actions/docs
npm run check --prefix actions/docs
bats scripts/test
scripts/ci
```

- Consumers pin a released tag or SHA, never `@main`; hook releases use `hooks-vX.Y.Z`, npm config releases use `config-vX.Y.Z`.
- Workflow inputs and required secrets are defined under `on.workflow_call` in each workflow.
- Renovate preset: `github>JakobMelchard/.github//renovate/default`.
- See [REFERENCE.md](REFERENCE.md) for caller examples, workflow inventory, concurrency and component-release output contracts.
- Follow [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md).

## Operate

- Owner: JakobMelchard org platform maintainers.
- Deploy: `self-release.yml` runs release-please and updates the major workflow tag. `config-publish.yml` stages npm publication only on manual opt-in from a `config-v*` tag, pending trusted-publisher migration. Do not move tags manually.
- Rollback: consumers restore the previous pinned workflow, hook or package version. No automated consumer-wide rollback is defined.
- CI: `lint.yml` runs actionlint, zizmor, Bats, docs checks, workflow smoke calls and portable-hook tests (`hook-consumer`); reusable `hooks.yml` runs a caller's prek config.
- Keep shared shell code Bash 3.2 compatible. Third-party actions are SHA-pinned.

## Dependencies

- Bash, GitHub Actions, Node/npm, Python/uv, prek, Bats Core, jq, yq and shellcheck for local checks.
- Additional toolchains are workflow-specific; see workflow inputs and action manifests.
- `scripts/ci` uses authenticated GitHub CLI and the shared library at `scripts/lib/common.sh`.

## Status

- Live source: shared workflows, hooks and config live here. No replacement is selected; deployment state of consuming repositories is unverified.
