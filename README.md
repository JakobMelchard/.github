# .github

Shared CI for the `JakobMelchard` org and the `lilfeelz` personal repos.
Reusable workflows, composite actions, and the common git hook set live here.

The boundary against `core`: **this repo is how code is built and checked,
`core` is code that ships inside the app.** Workflows, composite actions,
hooks and scaffolding templates belong here; `core` keeps `src/`, `SPEC.md`,
the store contract test, and the semver tags consumers pin. `core` must not
grow a second reusable CI workflow or a second hook set.

Actions are pinned by commit SHA with the version in a trailing comment.
Bump deliberately; `lint.yml` gates every change to this repo — actionlint,
shellcheck over the hooks, a bash-3.2 portability check, and a smoke call of
every reusable workflow with empty inputs.

Callers currently reference `@main`, so fixes propagate immediately. `v1` is
tagged as a stable alternative if you would rather pin and bump deliberately.

## Reusable workflows

Call with `uses: JakobMelchard/.github/.github/workflows/<name>.yml@main`.

| Workflow | For | Key inputs |
|----------|-----|------------|
| `release.yml` | any repo using release-please | — |
| `go.yml` | `gsheet` `health` `workouts` | `go-version` `vet-cmd` `test-cmd` `build-cmd` `private-modules` |
| `python.yml` | `transcriber` `monitor` `observe` `CKAD-prep` | `python-version` `package-manager` (`uv`\|`pip`\|`none`) `lint-cmd` `test-cmd` |
| `node.yml` | `cf` `transcriber` `lilfeelz.github.io` `weiterbildungszeit` | `node-version` `install-cmd` `check-cmd` `lint-cmd` `test-cmd` |
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
4. Add two secrets (Settings → Secrets and variables → Actions):
   - `APP_CLIENT_ID` — the Client ID
   - `APP_PRIVATE_KEY` — the full contents of the `.pem`, `BEGIN`/`END` lines included

   **These must be repository secrets, not org secrets.** `JakobMelchard` is
   on the free plan, where an org secret can only be granted to public repos;
   every consumer here is private. Add them on each consuming repo — `lift`
   today — and repeat the pair when a second consumer appears. Org secrets
   become an option on Team.

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

`install-cmd` defaults to `npm ci`. Repos with no committed lockfile (`lift`)
must pass `npm install` instead.

Set `browsers: true` to install and cache Playwright Chromium, and put the
browser-driven suite in `e2e-cmd` so it runs after `test-cmd`:

```yaml
    with:
      install-cmd: npm install
      lint-cmd: ""
      check-cmd: npx tsc
      test-cmd: npm test
      e2e-cmd: npm run e2e
      browsers: true
```

`lift` depends on private `core` as `github:JakobMelchard/core#v0.1.0`. npm
expands that shorthand to `git+ssh`, so `private-deps: true` rewrites the ssh
and https forms alike — same app/PAT credentials as `go.yml` and `python.yml`:

```yaml
    with:
      private-deps: true
      private-repos: core
    secrets:
      app-client-id: ${{ secrets.APP_CLIENT_ID }}
      app-private-key: ${{ secrets.APP_PRIVATE_KEY }}
```

## Composite actions

```yaml
- uses: JakobMelchard/.github/actions/gitleaks@main
  with:
    config: .gitleaks.toml     # optional

- uses: JakobMelchard/.github/actions/hooks@main
```

## Git hooks

One hook set replaces the per-repo `.githooks/` copies. `pre-commit` dispatches
on staged file type and skips any tool that is not installed:

| Staged | Action |
|--------|--------|
| any | `gitleaks` on the staged diff — **blocks** |
| `*.go` | `gofmt -w` + re-stage |
| `*.py` | `py_compile` — blocks; `ruff check` — blocks |
| shebang `bash`/`sh`/`zsh` | `bash -n` / `zsh -n` — blocks; `shellcheck` — blocks |
| `*.js` `*.css` `*.html` `*.md` `*.yml` … | `prettier --write` + re-stage (needs `package.json`) |
| `*.js` | `eslint --quiet` — blocks |
| `*.tf` | `terraform fmt` + re-stage |

Repo-specific checks go in `.githooks/pre-commit.local` / `.githooks/pre-push.local`
(executable). The shared hook runs them last, so the shared part stays updatable.

`pre-push` is a cheap build gate: `go vet` + `go build` when `go.mod` exists,
`terraform fmt -check` when `terraform/` exists. Tests belong in CI.

Install:

```sh
curl -fsSL https://raw.githubusercontent.com/JakobMelchard/.github/main/hooks/install.sh | bash
```

Hooks target **bash 3.2** — macOS ships 3.2 and never updated it. No `mapfile`,
no `declare -A`. `lint.yml` rejects both.

Bypass with `git commit --no-verify`.

## Layout

```
.github/workflows/    reusable workflows + this repo's own lint.yml
actions/              composite actions (gitleaks, hooks)
hooks/                shared pre-commit / pre-push / install.sh
profile/              org profile README
```
