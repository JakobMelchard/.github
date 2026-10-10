# Contributing

Applies to every `JakobMelchard` repository and to the `lilfeelz` personal repos that call the
workflows in this repo. A repo's own `AGENTS.md` adds the specifics; it may narrow these rules,
never contradict them. This file is the reference the rebuild cites instead of re-deciding.

## Accounts and placement

- `JakobMelchard` owns the platform (CI, hooks, configs, templates, infrastructure as code) and
  the products: services, libraries, the public showcases.
- `lilfeelz` owns the person's environment: dotfiles, agent rules and skills, the terminal stack,
  device layouts, the study layer. Personal repos consume the org platform; org repos never
  depend on a personal repo.
- Work-account configuration lives under the work account and is pulled in on the work machine
  only. Nothing work-related is committed to either of these accounts.
- Private by default. Public only for the showcases (one per technology: `flatplan` for JS,
  `services` for Go and htmx, `observe` for Python, `workline`, `tu`, `keyboard`) and for what
  must be fetched without a token (`.github`, `.githooks`, `.config`, the Pages sites). A repo
  goes public as a new repo with clean history, never by flipping visibility.

## Naming

- Repo name = service name = DNS label = local directory. No `-go`, `-hx`, `-wiki` suffixes.
- launchd labels follow the owner of the code: `at.melchard.<name>` for org services,
  `com.lilfeelz.<name>` for personal and host jobs.
- Tailnet services are `<name>.lilfeelz.org`; public docs are `docs.melchard.org/<repo>` for
  public org repos and `docs.lilfeelz.org/<repo>` for public personal repos.

## Branches, commits, merges

- Org repos are trunk-based: short branches, squash merge, the PR title becomes the commit.
- Personal repos run `dev` plus `main`: work lands on `dev`, `main` is promoted by PR. Rulesets
  protect both and block deletion.
- Commits and PR titles are Conventional Commits: `feat:` `fix:` `chore:` `docs:` `refactor:`
  `test:` `ci:` `build:` `perf:` `style:` `revert:`, optional `(scope)`, `!` for breaking. The
  `commit-msg` hook and the `pr-title` CI job enforce it.
- No attribution trailers in commits or PR bodies.
- Before a PR is called done: every review, inline thread and bot comment is read, fixed or
  answered, and resolved. Review bots skip drafts: mark ready and wait. Merge only on green CI,
  all threads answered, and the owner's go. Production deploys need the owner's go each time.

## Versioning and pins

- release-please only where a tag is consumed: this repo, `.githooks`, `.config`, `template`,
  `workline`, `observe`. Apps deploy from `main` and carry no version.
- Callers pin this repo's reusable workflows by release tag (`@v2.3.1`), never `@main`.
- Third-party actions are pinned by full commit SHA with the version in a comment.
- Hooks pin `JakobMelchard/.githooks` by tag in `.pre-commit-config.yaml`.
- The template is pinned by tag in `.copier-answers.yml`.
- Renovate bumps all of the above from the org preset (`config:best-practices`,
  `:enablePreCommit`, the copier manager); digest, pin and patch updates automerge on green CI,
  everything else waits for review. No other mechanism touches rendered files across repos.

## Files every repo has at birth

Rendered by `JakobMelchard/template`, refreshed by `copier update` through Renovate:

- `README.md` with a one-line purpose, usage, and a screenshot for apps.
- `AGENTS.md` for the repo-specific rules; `.claude/skills/` or `.agents/` for repo-specific
  skills. Generic org skills live in `JakobMelchard/.agents`, personal ones in `lilfeelz/.agents`.
- `LICENSE` (MIT) on every public repo.
- `renovate.json` extending the org preset.
- `.pre-commit-config.yaml` pinning the org hooks; `prek install` once per clone.
- One CI caller workflow using the reusable workflows here; add an input, never a second
  pipeline.
- `.github/CODEOWNERS` naming the owner; `.editorconfig`; `.gitleaks.toml`;
  `.copier-answers.yml`.
- Community health files (issue and PR templates, SECURITY, SUPPORT) are inherited from this
  repo unless the repo needs its own.

## Settings as code

- Every repo in both accounts is declared once in `JakobMelchard/infra` and applied by OpenTofu:
  visibility, description, rulesets, labels, runner variables, Dependabot alerts, secret scanning
  and push protection on public repos, `delete_branch_on_merge`. A repo that is not declared does
  not exist. Pages and homepage URLs are set by hand because the provider ignores them.
- The GitHub app installations are declared in the same repo and diffed against the live set on
  a schedule. Third-party apps are installed and scoped in the GitHub UI; only the org's own app
  is managed by API.
- Cloudflare: zone settings, DNS, Access and Email Routing in OpenTofu, split per account and per
  zone. Workers are described by their `wrangler` config, deployed by Workers Builds where the
  Worker has no Durable Object and by the reusable workflow where it has one.

## Secrets

Infisical only: shells and launchd jobs read through `with-secret`, CI through OIDC, Workers
through secret syncs. No personal access tokens, no hand-set Actions secrets, no secrets or
credential files in any repo, including gitignored ones under a dotfiles tree.

## Deploy

- The repo that owns the code owns its launchd plist and its `app.toml` entry. `infra` holds
  host-level state only: Caddy, pf, certificates, backups, runners, Forgejo, monitoring.
- The reconciler on mimi deploys `origin/main` of each app after CI is green; nothing is
  deployed by hand. Every scheduled job is wrapped by healthchecks.
- Anything that does not need the GUI session runs as a LaunchDaemon.

## Stack

Fixed for the estate; a repo picks from it, it does not add to it.

- Services on mimi: Go, standard library `net/http`, htmx, files or Google Sheets as the store,
  assets embedded in one binary. One public `services` repo holds them.
- Browser code and Cloudflare Workers: vanilla JavaScript with JSDoc types, `@ts-check`, `tsc`
  in CI, no build step beyond what wrangler needs. PWAs embed the shared `web` package (tokens,
  base CSS, manifest, service worker with queued writes and the iOS fallback).
- Compute-heavy work: Python with `uv`, `ruff`, `pytest`; FastAPI where it serves.
- Native code only where the OS forces it: Swift for the terminal client and the keyboard
  extension, Kotlin for the launcher, Capacitor shells where a web app needs a native API.
- Infrastructure: OpenTofu for every account; Brewfile, chezmoi profiles and launchd plists in
  git for every host.

## Public showcase checklist

CI badge, docs under the owner's Pages umbrella, tests that run in CI, a CHANGELOG where
versioned, no personal data anywhere in history, README that a stranger can follow.
