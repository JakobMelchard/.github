# .github

Shared CI for the `JakobMelchard` org and the `lilfeelz` personal repos:
reusable workflows, composite actions, and the org's GitHub settings as code.
This repo is public so that `lilfeelz` repos can call the workflows cross-account
and so the org profile renders; everything else on the platform is private —
see `JakobMelchard/.agents/PLATFORM.md` for the map.

Actions are pinned by commit SHA with the version in a trailing comment; Renovate
keeps the pins fresh through the org preset in `renovate/default.json`, which every
repo extends (`github>JakobMelchard/.github//renovate/default`). Digest and patch
bumps automerge once CI is green; everything else waits for a review. The CI workflows declare
`permissions: contents: read` at the top (`release.yml` needs `contents: write` +
`pull-requests: write`), checkouts do not persist credentials, and caller-supplied
`*-cmd` inputs reach the shell through `env`, never by template expansion.
`lint.yml` gates every change here — actionlint over workflows and starter
templates, zizmor, shellcheck over the hooks, a bash-3.2 portability check, tofu
validate, and smoke calls of `go` `python` `node` (including the Chromium path)
and `shell`, plus `xcode` with an empty scheme (no xcodebuild, macOS minutes cost 10x). `release.yml` and `terraform.yml` are not smoke-called.

Callers currently reference `@main`, so fixes propagate immediately. `@v1` is the
alternative: it follows the latest 1.x release of this repo (see *Releases of this repo*).

## Starter workflows

`workflow-templates/` holds a one-job caller per toolchain (`go` `python` `node` `shell`
`terraform`). They are offered under **Actions → New workflow** in every org repo —
suggested by `filePatterns` where one applies (`go.mod`, `pyproject.toml`, `package.json`,
`.tf`; `shell` has none) — so a repo that skips `org-repo new` can pick the shared
pipeline in one click. Nothing is installed automatically. `auto` is the toolchain-free
starter: it detects `go.mod`, `pyproject.toml`, `package.json` and `*.tf` at run time and
calls the matching workflow, shell always. It is the same file as `ci.yml` in the template
repository.

## Community files

Default community health files here apply to every org repo that has none of its own,
private repos included: the issue forms under `.github/ISSUE_TEMPLATE/` (`Bug`, `Task`,
blank issues off), `.github/PULL_REQUEST_TEMPLATE.md`, `SECURITY.md` and `CONTRIBUTING.md`.
CODEOWNERS and LICENSE are not inheritable and stay per repo. Private vulnerability
reporting is on for the public repos (`private_vulnerability_reporting` in `infra/settings.json`).

## Labels

`infra/settings.json` `labels` declares the label set every non-archived repo carries: the
GitHub defaults, `fleet/*` for agent-driven work, and release-please's `autorelease: *`.
`infra/labels` creates or updates them with `gh label create --force` and only lists labels
it does not know; it never deletes. Two callers, one script:

```sh
org-repo labels [repo…]        # JakobMelchard/bin, your gh auth
```

`.github/workflows/labels.yml` runs the same script weekly and on every change to the file,
with a token from the org GitHub App (see below). Without the `APP_*` secrets it exits green
and says so.

## GitHub App

`melchbot` is the org GitHub App behind every cross-repo job: private dependencies in
the reusable workflows, `labels.yml`, and `fleet-sync.yml`. It is installed on **all
repositories** with Contents, Issues and Pull requests read and write, which is exactly
what those jobs mint tokens for (each job requests only the permissions it names, scoped
to the repos in `infra/settings.json`, revoked when the job ends).

Its credentials live in Infisical (the project `interviews` uses, `dev` environment) as
`MELCHBOT_CLIENT_ID` and `MELCHBOT_PRIVATE_KEY`. The workflows read them as Actions
secrets `APP_CLIENT_ID` and `APP_PRIVATE_KEY` on this repo; copy them without echoing:

```sh
cd ~/Workspaces/JakobMelchard/interviews
infisical secrets get MELCHBOT_CLIENT_ID --plain | gh secret set APP_CLIENT_ID -R JakobMelchard/.github
infisical secrets get MELCHBOT_PRIVATE_KEY --plain | gh secret set APP_PRIVATE_KEY -R JakobMelchard/.github
```

A private repo that passes them to a reusable workflow (`private-deps`) needs the same
two secrets on itself: the free plan only lets org secrets reach public repos.

## Reusable workflows

Call with `uses: JakobMelchard/.github/.github/workflows/<name>.yml@main`.

| Workflow | For | Key inputs |
|----------|-----|------------|
| `release.yml` | any repo using release-please | `release-type` `config-file`; secrets `app-client-id` `app-private-key` (or `token`) make the app author the release PR so CI runs on it |
| `go.yml` | `health` `workouts` `gsheet` | `go-version` `vet-cmd` `test-cmd` `build-cmd` `private-modules` |
| `python.yml` | `monitor` `observe` `cf` | `python-version` `package-manager` (`uv`\|`pip`\|`none`) `lint-cmd` `test-cmd` |
| `node.yml` | `cf` `hx` `lift` `lists` `lyrics` `switchboard` `lilfeelz.github.io` | `node-version` `install-cmd` `check-cmd` `lint-cmd` `test-cmd` `e2e-cmd` `browsers` (Linux runners) |
| `shell.yml` | `bin` `lilfeelz/bin` `monitor` `.githooks` `.devcontainer` | `paths` `severity` |
| `terraform.yml` | `infra` | `working-directory` `terraform-version` |
| `xcode.yml` | `attach` | `scheme` `project` `destination` `generate-cmd` `lint-cmd` `test-cmd` `xcode-version` (macOS runner; empty `scheme` skips xcodebuild) |

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

A repo that depends on a private Go module in the org needs more than
`GOPRIVATE`, which does not authenticate a runner. Set `private-modules` and
pass a token with read access to the module repo (`gsheet`, which `workouts`
imports, is public since 2026-09-27 and needs neither):

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

**GitHub App — recommended.** No expiry to babysit, and each run mints a token
scoped to the listed repos that is revoked when the job ends.

1. Org Settings → Developer settings → GitHub Apps → **New GitHub App**
   - Name: anything (e.g. `melchbot`)
   - Homepage URL: any valid URL; **uncheck Webhook → Active**
   - Repository permissions: **Contents → Read-only** (Metadata follows automatically)
   - Where can it be installed: *Only on this account*
2. After creating it: note the **Client ID**, then **Generate a private key**
   (downloads a `.pem`).
3. **Install App** → Only select repositories → every repo that will be read
   as a dependency (`observe` today). A token is only mintable for repos in the
   installation, so `private-repos` naming one the App is not installed on
   fails to mint.
4. Add two secrets (Settings → Secrets and variables → Actions) on each repo
   that calls a workflow with `private-deps` — `transcriber` today:
   - `APP_CLIENT_ID` — the Client ID
   - `APP_PRIVATE_KEY` — the full contents of the `.pem`, `BEGIN`/`END` lines included

   **Repository secrets, not org secrets.** `JakobMelchard` is on the free
   plan, where an org secret can only be granted to public repos, and the
   consumers that need these are private. Org secrets become an option on Team,
   or for a public caller.

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
as a repository secret `PRIVATE_DEPS_TOKEN` on the calling repo — same free-plan
constraint as above — and pass it instead:

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
```

## Git hooks

The hooks live in the public repo **`JakobMelchard/.githooks`** as a prek / pre-commit hook
repository. Each repo pins it by tag in `.pre-commit-config.yaml` (Renovate bumps the pin) and
runs `prek install` once per clone. In CI, the reusable `hooks.yml` runs the same config over
every file; its `skip` input names hooks the runner cannot run.

## Releases of this repo

`self-release.yml` runs release-please on every push to `main` (the reusable `release.yml`,
called locally) and, once a release exists, moves the major tag (`v1`) onto it. Immutable
releases are enabled here, so `vX.Y.Z` release tags and their assets never change after
publish; `v1` is a plain tag, not a release, which is why it may move. Pin `@v1` for a
tested line, `@vX.Y.Z` for a frozen one, `@main` to follow every merge. `bootstrap-sha` in
`release-please-config.json` keeps history before the first automated release out of the
changelog. The release PR is authored by melchbot (the `APP_*` secrets go to `release.yml`),
so `lint.yml` runs on it like on any PR. A consumer gets the same by passing its own
`APP_CLIENT_ID` / `APP_PRIVATE_KEY` repository secrets to `release.yml`; with `github.token`
alone the release PR triggers no workflows.

## Fleet sync

`fleet-sync.yml` runs `fleet-sync` (JakobMelchard/bin) weekly with the org app token: for
every non-archived repo in `infra/settings.json` it refreshes the vendored copies the repo
already carries (config-sync groups whose file exists, `.githooks/` when hooks are vendored),
and opens or updates one `chore/fleet-sync` PR per changed repo, labelled `fleet/deps`.
Nothing is added to a repo that lacks it. Dispatch it with `dry-run` to see the diffs, or run
`fleet-sync --dry-run` locally with your own gh auth.

## Template repository

`JakobMelchard/template` is a GitHub template repository (**Use this template**, or
`gh repo create JakobMelchard/<name> --template JakobMelchard/template --private`). After
creating a repo from it, set `toolchain` in `template.json` to one of `go` `py` `hx-app` `cf`
`infra` `c-cpp` and commit: `bootstrap.yml` copies the matching `.devcontainer`, rewrites the
README title and removes itself from the picture. Its `ci.yml` is the `auto` starter above.
Both mirror sources here and in `.devcontainer`; change those first, then the template.
`org-repo new` stays the terminal path and additionally vendors configs, hooks and agent rules.

## Infra

`infra/` is OpenTofu for the org: every repo listed in `infra/settings.json` is
adopted (import blocks) and kept at the shared settings — merge strategies,
branch deletion, auto-merge, visibility, archived, Dependabot alerts. Org-level
settings apply only with `-var manage_org=true` and an `admin:org` token.
`bin/org-repo sync` applies the same document imperatively when tofu is not at hand.
Labels (`labels`) and private vulnerability reporting are applied by `org-repo` and the
workflows, not by tofu: the provider's label resource fails on labels that already exist.

Rulesets and branch protection are not managed: unavailable on private repos
under the free plan.

## Layout

```
.github/workflows/    reusable workflows + this repo's own lint.yml, labels.yml, self-release.yml, fleet-sync.yml
.github/ISSUE_TEMPLATE/  org-wide issue forms; PULL_REQUEST_TEMPLATE.md beside it
actions/              composite actions (gitleaks, hooks)
infra/                opentofu: org + repo settings, settings.json, labels script
renovate/             org Renovate preset
release-please-config.json  this repo's own releases (self-release.yml)
profile/              org profile README
```
