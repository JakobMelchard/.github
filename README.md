# .github

Shared CI for the `JakobMelchard` org and the `lilfeelz` personal repos:
reusable workflows, composite actions, and the org's GitHub settings as code.
This repo is public so that `lilfeelz` repos can call the workflows cross-account
and so the org profile renders; everything else on the platform is private —
see `JakobMelchard/.agents/PLATFORM.md` for the map.

Actions are pinned by commit SHA with the version in a trailing comment; Renovate
(`config:best-practices`) keeps the pins fresh. The CI workflows declare
`permissions: contents: read` at the top (`release.yml` needs `contents: write` +
`pull-requests: write`), checkouts do not persist credentials, and caller-supplied
`*-cmd` inputs reach the shell through `env`, never by template expansion.
`lint.yml` gates every change here — actionlint over workflows and starter
templates, zizmor, shellcheck over the hooks, a bash-3.2 portability check, tofu
validate, and smoke calls of `go` `python` `node` (including the Chromium path)
and `shell`. `release.yml` and `terraform.yml` are not smoke-called.

Callers currently reference `@main`, so fixes propagate immediately. `v1` is
tagged as a stable alternative if you would rather pin and bump deliberately.

## Starter workflows

`workflow-templates/` holds a one-job caller per toolchain (`go` `python` `node` `shell`
`terraform`). They are offered under **Actions → New workflow** in every org repo —
suggested by `filePatterns` where one applies (`go.mod`, `pyproject.toml`, `package.json`,
`.tf`; `shell` has none) — so a repo that skips `org-repo new` can pick the shared
pipeline in one click. Nothing is installed automatically.

## Reusable workflows

Call with `uses: JakobMelchard/.github/.github/workflows/<name>.yml@main`.

| Workflow | For | Key inputs |
|----------|-----|------------|
| `release.yml` | any repo using release-please | — |
| `go.yml` | `gsheet` `health` `workouts` | `go-version` `vet-cmd` `test-cmd` `build-cmd` `private-modules` |
| `python.yml` | `transcriber` `monitor` `observe` `CKAD-prep` | `python-version` `package-manager` (`uv`\|`pip`\|`none`) `lint-cmd` `test-cmd` |
| `node.yml` | `cf` `transcriber` `lilfeelz.github.io` `lyrics` `lift` `hx` | `node-version` `install-cmd` `check-cmd` `lint-cmd` `test-cmd` `e2e-cmd` `browsers` (Linux runners) |
| `shell.yml` | `bin` `monitor` `infra` | `paths` `severity` |
| `terraform.yml` | `infra` | `working-directory` `terraform-version` |

Every `*-cmd` input skips its step when set to `""`.

### Go

```yaml
name: ci
on: { pull_request: {}, push: { branches: [main] } }
jobs:
  ci:
    uses: JakobMelchard/.github/.github/workflows/go.yml@main
    with:
      test-cmd: make test
      build-cmd: make build
```

`workouts` depends on the private `github.com/JakobMelchard/gsheet` module.
`GOPRIVATE` alone does not authenticate a runner, so set `private-modules` and
pass a token with read access to the module repo:

```yaml
jobs:
  ci:
    uses: JakobMelchard/.github/.github/workflows/go.yml@main
    with:
      private-modules: true
    secrets: inherit
```

`github.token` is scoped to the calling repo only — a cross-repo private module
needs a PAT or app token passed as `secrets.token`. Map it explicitly rather
than using `secrets: inherit`, so only that one secret crosses the boundary:

```yaml
    secrets:
      token: ${{ secrets.PRIVATE_DEPS_TOKEN }}
```

### Private dependencies: GitHub App (preferred) or PAT

`transcriber` imports private `observe` and needs cross-repo read access. The
shared workflows support two credential types and prefer the app when its
private key is present.

(`workouts` imports private `gsheet`, but `gsheet` is being retired — see that
repo's open CI PR.)

**GitHub App — recommended.** No expiry to babysit, and each run mints a token
scoped to the listed repos that is revoked when the job ends.

1. Org Settings → Developer settings → GitHub Apps → **New GitHub App**
   - Name: anything (e.g. `melchbot`)
   - Homepage URL: any valid URL; **uncheck Webhook → Active**
   - Repository permissions: **Contents → Read-only** (Metadata follows automatically)
   - Where can it be installed: *Only on this account*
2. After creating it: note the **Client ID**, then **Generate a private key**
   (downloads a `.pem`).
3. **Install App** → Only select repositories → `observe`.
4. Add two org secrets (Settings → Secrets and variables → Actions), scoped to
   `transcriber`:
   - `APP_CLIENT_ID` — the Client ID
   - `APP_PRIVATE_KEY` — the full contents of the `.pem`, `BEGIN`/`END` lines included

```yaml
    with:
      private-deps: true
      private-repos: observe       # what the minted token may read
    secrets:
      app-client-id: ${{ secrets.APP_CLIENT_ID }}
      app-private-key: ${{ secrets.APP_PRIVATE_KEY }}
```

**PAT — simpler, expires.** Fine-grained PAT, resource owner `JakobMelchard`,
repository access limited to `observe`, permission Contents: Read-only. Store
as org secret `PRIVATE_DEPS_TOKEN` and pass it instead:

```yaml
    secrets:
      token: ${{ secrets.PRIVATE_DEPS_TOKEN }}
```

Supplying both is fine — the app wins. Supplying neither falls back to
`github.token`, which cannot read another repo, so the job fails closed.

Making `observe` public removes the need for either.

### Python

```yaml
jobs:
  ci:
    uses: JakobMelchard/.github/.github/workflows/python.yml@main
    with:
      python-version: "3.11"
      package-manager: pip          # transcriber: venv + pip install -e ".[dev]"
      lint-cmd: ruff check src tests
      test-cmd: python -m pytest
```

`monitor` is stdlib-only — use `package-manager: none`.

`transcriber` depends on `observe` via `git+https://github.com/JakobMelchard/observe.git`,
which is private. Set `private-deps: true` and `secrets: inherit`, and provide a
`token` secret — same constraint as `private-modules` in `go.yml`.

### Node

```yaml
jobs:
  ci:
    uses: JakobMelchard/.github/.github/workflows/node.yml@main
    with:
      check-cmd: make check
      lint-cmd: make lint
```

## Composite actions

```yaml
- uses: JakobMelchard/.github/actions/gitleaks@main
  with:
    config: .gitleaks.toml     # optional

- uses: JakobMelchard/.github/actions/hooks@main
```

## Git hooks

The hook set lives in the private repo **`JakobMelchard/.githooks`**. Install with
`hooks-install` from `JakobMelchard/bin` (vendors `pre-commit` + `pre-push` into
`.githooks/`, sets `core.hooksPath`). In CI, `actions/hooks` points `core.hooksPath`
at the vendored copies; it can refresh them first given a token that can read
`.githooks` (`github.token` cannot — that repo is private).

`hooks/install.sh` here is a deprecated shim that forwards to the new installer;
`hooks/pre-commit` and `hooks/pre-push` are the frozen legacy copies. All three go
away one cycle after every consumer has re-vendored.

## Infra

`infra/` is OpenTofu for the org: every repo listed in `infra/settings.json` is
adopted (import blocks) and kept at the shared settings — merge strategies,
branch deletion, auto-merge, visibility, archived, Dependabot alerts. Org-level
settings apply only with `-var manage_org=true` and an `admin:org` token.
`bin/org-repo sync` applies the same document imperatively when tofu is not at hand.

Rulesets and branch protection are not managed: unavailable on private repos
under the free plan.

## Layout

```
.github/workflows/    reusable workflows + this repo's own lint.yml
actions/              composite actions (gitleaks, hooks)
infra/                opentofu: org + repo settings, settings.json
hooks/                DEPRECATED shim → JakobMelchard/.githooks
profile/              org profile README
```
