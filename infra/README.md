# infra — GitHub as code

OpenTofu for the `JakobMelchard` org and the `lilfeelz` personal repos. `settings.json` is the single settings document; `bin/org-repo` reads the same file for the imperative path.

CI does the work: `infra.yml` plans every PR (comment on the PR, required check `plan`) and applies on push to `main`, then commits the encrypted state back. Local apply is the fallback:

```sh
cd infra
make plan                                 # gh auth token + Infisical TOFU_STATE_PASSPHRASE
make apply                                # stages state/terraform.tfstate; commit and push it
```

CI authenticates as the org app (`APP_CLIENT_ID` / `APP_PRIVATE_KEY`, the release-please app), which needs repository **administration** and **variables** read/write on all org repos. `github.token` cannot manage repo settings.

## What is managed

- `repos.tf` — every repo listed in `settings.json` → `github_repository`. Description, homepage (`homepage_url` where set), merge strategies, branch deletion, auto-merge, visibility, archived, Dependabot alerts on and Dependabot security updates off (Renovate opens the fix PRs, `renovate/default.json` `vulnerabilityAlerts`), and on public repos secret scanning with push protection (free there; private repos need Advanced Security, so the block is not set for them). Existing repos are adopted through `import` blocks; `prevent_destroy` is on and unowned attributes are ignored, so a plan never proposes deleting a repo or touching attributes this module does not own — it does re-plan the owned ones, which is the point. `pages` is ignored: Pages is switched on or off per repo by hand, never from this module.

Archived repos are not managed: the provider refuses to read or update an archived repository ("please remove the resource from your configuration"), and the API cannot unarchive. To archive: `gh repo archive JakobMelchard/<name>`, set `"archived": true` in `settings.json`, and `tofu state rm 'github_repository.this["<name>"]'` (plus the matching `github_repository_vulnerability_alerts` and `github_repository_dependabot_security_updates`) so `prevent_destroy` does not block the plan. Every name in `settings.json` must exist on GitHub: an `import` of a missing repo fails the whole plan rather than degrading to a create.
- `actions.tf` — `settings.json` `runners` → a repo-level Actions variable per private repo, which routes jobs off GitHub-hosted runners: `RUNNER_MACOS` to the self-hosted runner on mimi (macOS minutes count 10x), `RUNNER_LINUX` to Blacksmith (org app `blacksmith-sh`), so private-repo Linux jobs use no GitHub minutes. It is repo-level because the free plan does not pass org variables to private repos. `"runners": {}` removes them all, and jobs fall back to hosted runners.
- `personal.tf` — `settings.json` `personal.repos` → the same `github_repository` settings for repos owned by `personal.owner`, adopted with `import` blocks. `required_checks` on a public repo becomes a ruleset on its default branch, so native auto-merge waits for those checks. Locally the same token covers both owners; in CI an installation token is per account, so `infra.yml` mints a second one from the same app installed on `personal.owner` (the app must be public, "any account", and installed there on the managed repos) and passes it as `var.personal_token`. No PAT. `required_review_thread_resolution` on a repo adds a pull-request ruleset on its default branch (private repos too: the personal account is on GitHub Pro); it also blocks direct pushes there, so work happens on `dev` and `dev` is promoted by PR. The repo admin may bypass in `pull_request` mode (merge a PR with open threads), never push directly.
- `org.tf` — organization settings, only with `-var manage_org=true` (needs `admin:org` and `-var billing_email=…`). Not applied by CI.
- `rulesets.tf` — a branch ruleset named `main` on the default branch of every public repo: no deletion, no force push, linear history, PR required (0 approvals: one maintainer, and GitHub forbids self-approval), review threads resolved, and the repo's `checks` from `settings.json` as required status checks that only GitHub Actions may report. Bypass is pull-request mode for the org owner and Renovate (its own automerge merges through the Renovate app), and `always` for the org app on this repo only, which pushes the state commit. Private repos get none: the free plan does not enforce rulesets there.

  Adding a check: the context is what GitHub shows on the PR, `<caller job> / <reusable job>` for the org workflows (`go / ci`, `hooks / prek`). Only list jobs that run on every PR; a required check that never reports blocks the merge forever. `pr-title` jobs run on PRs and are skipped on push, so they qualify. Removing a repo's `checks` keeps the ruleset without a status rule; `"ruleset": false` removes it.

  CI broken by the platform itself: the owner merges the PR with the bypass (GitHub asks to confirm). Nothing bypasses a direct push to `main`.

## What is not

- **Rulesets on private repos.** Unavailable under the free plan; org and personal alike. Governance there is hooks + CI + convention.
- **App installations.** Read them with `org-repo apps`. `github_app_installation_repositories` needs per-app installation ids and can't express "all repositories"; not worth the state.
- **Labels.** `settings.json` `labels` is applied by `infra/labels` (`org-repo labels`, `labels.yml`), not by tofu: the provider's label resource fails on a label that already exists and importing needs every label to exist first.
- **Private vulnerability reporting, `is_template`.** Own endpoint / plain PATCH attribute; `org-repo sync` applies them, tofu ignores `is_template`.
- **Secrets.** Set through the UI or `gh secret set --org`; never in tofu state.

## State

`state/terraform.tfstate` is committed, encrypted (`encryption.tofu`, passphrase `TOFU_STATE_PASSPHRASE`: Infisical core/dev locally, a repo secret in CI; the same value as `infra/terraform/tailscale`). CI commits it after every apply that moved the serial. The `import` blocks still re-adopt every repo and variable if the state is ever lost; rulesets are the exception, they have no import block. Recover one with `tofu import 'github_repository_ruleset.main["<repo>"]' '<repo>:<id>'`, the id from `gh api repos/JakobMelchard/<repo>/rulesets`.
