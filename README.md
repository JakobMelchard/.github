# .github

Shared CI for the `JakobMelchard` org and the `lilfeelz` personal repos:
reusable workflows, composite actions, and the org's GitHub settings as code.
This repo is public so that `lilfeelz` repos can call the workflows cross-account
and so the org profile renders; everything else on the platform is private —
see `JakobMelchard/.agents/PLATFORM.md` for the map.

Actions are pinned by commit SHA with the version in a trailing comment; Renovate
keeps the pins fresh through the org preset in `renovate/default.json`, which every
repo extends (`github>JakobMelchard/.github//renovate/default`). Digest and patch
bumps automerge once CI is green; everything else waits for a review. Updates arrive weekly (Monday before 4am, Vienna)
as grouped PRs per repo: one for patch and digest, one for minor, plus the `hx`, `github actions` and `pre-commit hooks`
groups for their packages; majors and security fixes come on their own. The CI workflows declare
`permissions: contents: read` at the top (`release.yml` needs `contents: write` +
`pull-requests: write` + `id-token: write`), checkouts do not persist credentials, and caller-supplied
`*-cmd` inputs reach the shell through `env`, never by template expansion.
`lint.yml` gates every change here — actionlint over workflows, zizmor, shellcheck over the hooks, a bash-3.2 portability check, tofu
validate, and smoke calls of `go` `python` `node` (including the Chromium path)
and `shell`, plus `xcode` with an empty scheme (no xcodebuild, macOS minutes cost 10x) and `android`
with no Gradle tasks (toolchain setup only). `release.yml` and `terraform.yml` are not smoke-called.

Callers currently reference `@main`, so fixes propagate immediately. `@v1` is the
alternative: it follows the latest 1.x release of this repo (see *Releases of this repo*).

## Other workflows

`.github/workflows/interaction-limits.yml` re-applies, monthly and on change, the `interaction_limit`
a repo declares in `infra/settings.json` (`collaborators_only`, `contributors_only`, `existing_users`):
GitHub caps these at six months, the workflow makes them permanent.

Issues labeled `feedback` (filed from an app's in-app form)
are triaged by the nightly cloud routine (see Routines), which retitles them and queues
scoped ones with `agent:cloud`; the former opencode action is gone.

`actions/docs` builds a repo's markdown docs (`docs/`, nav from `SUMMARY.md`) into static pages in the
docs.melchard.org shell: `tokens.css` + `style.css` loaded from the `assets` input (default
`https://docs.melchard.org/assets`, the docs root's files), one centred mono column, no HonKit.
Callers: flatplan, lilfeelz/keyboard.

There are no starter workflows (`workflow-templates/` was removed): a new repo gets its CI caller from
`JakobMelchard/template`, rendered by `scripts/org-repo new` in that repo.

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
infra/labels [repo…]           # your gh auth, from a clone of this repo
```

`.github/workflows/labels.yml` runs the same script weekly and on every change to the file,
with a token from the org GitHub App (see below).

## GitHub App

`melchbot` is the org GitHub App behind every cross-repo job: private dependencies in
the reusable workflows, `labels.yml`, and `fleet-sync.yml`. It is installed on **all
repositories** with Contents, Issues and Pull requests read and write, which is exactly
what those jobs mint tokens for (each job requests only the permissions it names, scoped
to the repos in `infra/settings.json`, revoked when the job ends).

Its credentials live in Infisical project `core` (`dev`) as `MELCHBOT_CLIENT_ID` and
`MELCHBOT_PRIVATE_KEY`, with a copy as `APP_CLIENT_ID` and `APP_PRIVATE_KEY` in project
`gha` (slug `gha-lfq-y`, `dev`) for CI. Rotate both. The workflows in this repo load them at
runtime over OIDC, no Actions secret involved:

```yaml
permissions:
  id-token: write
steps:
  - uses: Infisical/secrets-action@d2e351f16c6ca20d17c85e6c992e04bdeb64e87d # v1.0.18
    with:
      method: oidc
      identity-id: b1ede60d-f7a7-4699-86ec-eea6ac51be30 # gha-org: any JakobMelchard repo
      domain: https://eu.infisical.com
      project-slug: gha-lfq-y
      env-slug: dev
  # then ${{ env.APP_CLIENT_ID }} / ${{ env.APP_PRIVATE_KEY }}
```

The step exports every key in `gha` to the rest of the job. New CI secrets go into `gha`,
not into Actions secrets. The reusable workflows (`release.yml`, `private-deps`) still take
the app credentials as `secrets:` from their callers until those are migrated.

## Reusable workflows

Call with `uses: JakobMelchard/.github/.github/workflows/<name>.yml@main`.

| Workflow | For | Key inputs |
|----------|-----|------------|
| `release.yml` | any repo using release-please | `release-type` `config-file`; the app authors the release PR so CI runs on it, credentials from Infisical, caller grants `id-token: write` |
| `go.yml` | `health` `workouts` `gsheet` | `go-version` `vet-cmd` `test-cmd` `build-cmd` `private-modules` |
| `python.yml` | `monitor` `observe` `cf` | `python-version` `package-manager` (`uv`\|`pip`\|`none`) `lint-cmd` `test-cmd` |
| `node.yml` | `cf` `hx` `workouts-hx` `lists` `switchboard` `interviews` `lilfeelz.github.io` | `node-version` `install-cmd` `check-cmd` `lint-cmd` `test-cmd` `e2e-cmd` `browsers` (Linux runners) |
| `shell.yml` | `bin` `lilfeelz/bin` `monitor` `.githooks` `template` | `paths` `severity` |
| `terraform.yml` | `infra` | `working-directory` `validate` |
| `xcode.yml` | `zmxapp` `zmxkit` | `scheme` `project` `destination` `generate-cmd` `lint-cmd` `test-cmd` `xcode-version` (macOS runner; empty `scheme` skips xcodebuild) |
| `android.yml` | `zmxdroid` `lift` | `gradle-tasks` `android-packages` `setup-cmd` `working-directory` `java-version` `java-distribution` `artifact-path` (Linux runner; empty `gradle-tasks` skips Gradle) |

Every `*-cmd` input skips its step when set to `""`.

The language workflows (`go`, `python`, `node`, `shell`, `terraform`, `android`) skip their `ci`
job when a push or PR changed only Markdown (`actions/code-changed`, from the compare API; a
new branch, a manual run or an API error count as code). `pr-title` and `hooks.yml` still run,
since they lint titles and docs. A skipped job reports success. `xcode.yml` has no gate:
callers filter with `paths` (macOS minutes are 10x).

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
changelog. The release PR is authored by melchbot (`release.yml` loads its credentials from
Infisical), so `lint.yml` runs on it like on any PR. Every caller gets the same; its calling
job must grant `id-token: write`, or the run fails at startup.

## Fleet sync

`fleet-sync.yml` checks out `JakobMelchard/.config` and runs its `scripts/fleet-sync` weekly with the org app
token: for every non-archived repo in `infra/settings.json` it refreshes the vendored copies the repo
already carries (config-sync groups whose file exists, opt-in tokens), from the latest `.config` release
tag, and opens or updates one `chore/fleet-sync` PR per changed repo, labelled `fleet/deps`. A copy whose
only change is its `VENDORED` header opens no PR. Nothing is added to a repo that lacks it. Only
`APP_CLIENT_ID` and `APP_PRIVATE_KEY` are fetched from Infisical, one step each. Dispatch it with `dry-run`
to see the diffs, or run `~/Workspaces/JakobMelchard/.config/scripts/fleet-sync --dry-run` locally with your own
gh auth.

## Routines

Two Claude Code cloud routines (claude.ai/code/routines, account of the org owner, Max
subscription) work the org at night, Europe/Vienna: `nightly-sweep` at 03:07
triages new issues, implements issues labelled `agent:cloud` as draft PRs on `claude/issue-*`
branches, and comments a verdict on Renovate PRs; `nightly-improve` at 04:37 opens at most
three draft PRs on `claude/improve-*` branches, three repos per night in rotation. Both stay
inside the repos named in their prompts (every live org repo plus lilfeelz workspaces,
bin, .config, .agents, keyboard; the personal dotfiles use `dev` as base; keyboard
gets reading-only changes since its checks cannot run in the cloud), never
merge, never touch base branches, workflows or infra. A repo's own checks run with `GH_TOKEN` and `GITHUB_TOKEN` removed from their environment (`env -u`). `routines/*.md` are the prompts, copied verbatim into the routine; edit the
file, then paste it into the routine (`/schedule update` in Claude Code, or the web form).
The repos must be selected on each routine in the web form (menu next to the routine
name, Edit, "Select a repository"): a run only reaches the repos attached to it (GitHub
API calls for any other repo get a 403 from the gateway), and the picker only offers
repos the Claude GitHub App is installed on.
The sweep's triage applies `agent:ready`, which switchboard hands to Jules; switchboard swaps it
for `agent:cloud` when Jules cannot take the repo, and that is the sweep's own queue. Every write
shows up on GitHub, so the Telegram `github` topic sees it. Each run appends one comment to the
pinned issue #70.

Fallback without the Max subscription: `.github/workflows/routines-fallback.yml` runs the same
`routines/*.md` prompts with opencode (`opencode-go/mimo-v2.5` by default) on the org app token,
org repos only. It is dormant: `workflow_dispatch` runs it once (dry run by default); set the repo
variable `ROUTINES_FALLBACK` to `on` and the nightly schedule takes over. Needs the repo secret
`OPENCODE_API_KEY` next to the `APP_*` secrets and the app's Checks and Actions read permissions.

## Template repository

`JakobMelchard/template` is a [copier](https://copier.readthedocs.io) template (tags `v*`), not a
GitHub template repository. `scripts/org-repo new <name> --template <t>` (in `JakobMelchard/template`) renders it
and does the GitHub side; templates are `hx-app` `cf` `go` `py` `c-cpp` `infra` `ios` `macos`.
Each rendered repo records its answers in `.copier-answers.yml`; Renovate's copier manager opens a PR
when the template gets a new tag, and `uvx copier update --defaults` does the same by hand. The
template's CI callers point at the workflows here, so change a workflow here first, then the template.

## Infra

`infra/` is OpenTofu for the org: every repo listed in `infra/settings.json` is
adopted (import blocks) and kept at the shared settings — merge strategies,
branch deletion, auto-merge, visibility, archived, Dependabot alerts. Org-level
settings apply only with `-var manage_org=true` and an `admin:org` token.
`org-repo new` applies the repo-level defaults once to a repo it creates, before it is listed here.
Labels (`labels`) are applied by `labels.yml`, not by tofu: the provider's label resource fails on labels
that already exist. Private vulnerability reporting and `is_template` are applied by `org-repo new` only;
tofu ignores them.

Every public repo gets a branch ruleset on `main` (`rulesets.tf`): PR only, no
force push or deletion, linear history, and the repo's `checks` from `settings.json`
as required status checks. Private repos get none: the free plan does not enforce
rulesets there.

`infra.yml` runs it: `tofu plan` on every PR as a comment and a required check,
`tofu apply` on push to `main`, then the encrypted state (`infra/state/`) is
committed back by the org app. `infra/README.md` has the details and the local
fallback (`make plan`, `make apply`).

## Layout

```
.github/workflows/    reusable workflows + this repo's own lint.yml, labels.yml, self-release.yml, fleet-sync.yml
.github/ISSUE_TEMPLATE/  org-wide issue forms; PULL_REQUEST_TEMPLATE.md beside it
actions/              composite actions (code-changed, docs, gitleaks, tokens-check)
infra/                opentofu: org + repo settings, settings.json, labels script
scripts/              shell tools: `ci` (latest CI conclusion per repo) and `lib/common.sh`, the helpers
                      config-sync, fleet-sync, org-repo and ios source (`JM_LIB`, default
                      `~/Workspaces/JakobMelchard/.github/scripts/lib`); bats tests in `scripts/test`
renovate/             org Renovate preset
release-please-config.json  this repo's own releases (self-release.yml)
profile/              org profile README
```
