# .github

Shared CI for the `JakobMelchard` org and the `lilfeelz` personal repos.
Reusable workflows, composite actions, and the common git hook set live here —
there is no separate `core` repo.

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

### The `PRIVATE_DEPS_TOKEN` org secret

Two repos need it: `workouts` (imports private `gsheet`) and `transcriber`
(imports private `observe`).

1. Create a **fine-grained PAT** — Settings → Developer settings → Personal
   access tokens → Fine-grained tokens:
   - Resource owner: **JakobMelchard**
   - Repository access: **Only select repositories** → `gsheet`, `observe`
   - Permissions: **Contents → Read-only** (Metadata read-only is added automatically)
2. Add it as an **organization secret** — org Settings → Secrets and variables
   → Actions → New organization secret:
   - Name: `PRIVATE_DEPS_TOKEN`
   - Repository access: **Selected repositories** → `workouts`, `transcriber`

Fine-grained PATs expire; the workflows fail closed when it does. A GitHub App
installation token avoids expiry if that becomes annoying. Making `gsheet` and
`observe` public removes the need for a secret entirely.

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
