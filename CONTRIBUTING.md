# Contributing

Applies to every `JakobMelchard` repository and to `lilfeelz` repos calling workflows here. A repo's own `AGENTS.md` adds specifics without contradicting these rules.

## Accounts and placement

- `JakobMelchard` owns the platform (CI, hooks, configs, templates, IaC) and shipped products (services, libraries, showcases).
- `lilfeelz` owns the personal environment (`lilfeelz/.files` for dotfiles, agent rules/skills, extensions, workspace server; `totem` for firmware). Personal repos consume the org platform; org repos never depend on a personal repo.
- Work-account configuration lives under the work account only. Never commit work data here.
- Private by default (`services` is private). Public only for showcases (`web` for JS, `observe` for Python, `pull` for Android `pull` trainer, `notes` for study wiki, `totem`, `based`, `fmsh`) and what must fetch without auth (`.github`, Pages sites). New public repos start with clean history, never by flipping visibility.

## Naming

- Repo name = service name = DNS label = local directory (no `-go`, `-hx`, `-wiki` suffixes).
- launchd labels: `at.melchard.<name>` (org services), `com.lilfeelz.<name>` (personal and host jobs).
- Tailnet services: `<name>.lilfeelz.org` or `<name>.feelz.dev`; public docs: `docs.melchard.org/<repo>` and `docs.lilfeelz.org/<repo>`.

## Branches, commits, merges

- Trunk-based on `main`: short branches, squash merge, PR title becomes the commit.
- Conventional Commits (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `build`, `perf`, `style`, `revert`, optional `(scope)`, `!` for breaking), enforced by `commit-msg` hook and `pr-title` CI job.
- No attribution trailers in commits or PR bodies.
- Before calling a PR done: read, fix or answer, and resolve every review thread and bot comment (bots skip drafts). Merge only on green CI, resolved threads, and owner's go; production deploys need owner's go each time.

## Versioning and pins

- release-please in template-rendered repos. Consumed tags come from `.github` (`vX.Y.Z`, `config-vX.Y.Z`, `hooks-vX.Y.Z`), `template`, `web`, `observe`. Apps deploy from `main`.
- Pin everything: reusable workflows by release tag, third-party actions by commit SHA + version comment, hooks by `hooks-vX.Y.Z`, template by tag in `.copier-answers.yml`. Never `@main`. Renovate bumps pins from the org preset.

## Files every repo has at birth

Rendered by `JakobMelchard/template` (`copier update` via Renovate):

- `README.md` (one-line purpose, usage, screenshot for apps) and `AGENTS.md` (repo rules).
- Repo-local skills in `.agents/skills/` or `.claude/skills/`. Shared skills live in `lilfeelz/.files` (`agents/` personal, `agents/org/` org).
- `LICENSE` (MIT on public repos), `renovate.json`, `.pre-commit-config.yaml` (`prek install`), one CI caller workflow, `.github/CODEOWNERS`, `.editorconfig`, `.gitleaks.toml`, `.copier-answers.yml`. Community health files inherit from `.github`.

## Settings as code

- Repos, visibility, rulesets, labels and runner variables are declared in `JakobMelchard/infra` (`terraform/github/settings.json`) and applied by OpenTofu. Secrets, Pages and app installations are managed manually in GitHub UI.
- Cloudflare zone settings, DNS, Access and Email Routing live in OpenTofu; Workers use `wrangler` config (Workers Builds or `cf.yml` for Durable Objects).

## Secrets

Infisical only: shells and launchd jobs read via `with-secret`, CI via OIDC, Workers via secret syncs. No PATs, manual Actions secrets, or secrets in git.

## Deploy

- App repos own their launchd plist and `deploy/mimi/app.toml`. `infra` holds host config only: Caddy, pf, certificates, backups, runners, Forgejo, monitoring.
- Mimi's reconciler deploys `origin/main` after green CI (or a trusted `local-checks` status); scheduled jobs wrap with healthchecks. Run non-GUI jobs as LaunchDaemons.

## Stack

Fixed across the estate; pick from it rather than adding tools:

- Self-hosted services: Go `net/http`, htmx, embedded assets (`services`, private; `lilfeelz/.files` `server/` for web-workspace).
- Browser and Workers: vanilla JS with strict JSDoc + `tsc`, no bundler beyond `wrangler`. PWAs embed `@jakobmelchard/web`.
- Compute: Python (`uv`, `ruff`, `pytest`, FastAPI).
- Native: Swift (`apple` macOS/iOS clients), Kotlin (`pull` trainer in `pull`, offline viewer/launcher).
- Infra: OpenTofu, Brewfile, chezmoi (`lilfeelz/.files`), launchd plists.

## Public showcase checklist

CI badge, Pages docs, CI tests, CHANGELOG if versioned, clean history without personal data, clear README.
