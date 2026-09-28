# infra — GitHub as code

OpenTofu for the `JakobMelchard` org. `settings.json` is the single settings document; `bin/org-repo` reads the same file for the imperative path.

```sh
cd infra
export GITHUB_TOKEN=$(gh auth token)      # repo scope: repos. admin:org: + org settings
tofu init
tofu plan                                 # first run: adoption via import blocks, then drift
tofu apply
```

## What is managed

- `repos.tf` — every repo listed in `settings.json` → `github_repository`. Merge strategies, branch deletion, auto-merge, visibility, archived, Dependabot alerts. Existing repos are adopted through `import` blocks; `prevent_destroy` is on and unowned attributes are ignored, so a plan never proposes deleting a repo or touching attributes this module does not own — it does re-plan the owned ones, which is the point.

Archived repos are not managed: the provider refuses to read or update an archived repository ("please remove the resource from your configuration"), and the API cannot unarchive. To archive: `gh repo archive JakobMelchard/<name>`, set `"archived": true` in `settings.json`, and `tofu state rm 'github_repository.this["<name>"]'` (plus the matching `github_repository_vulnerability_alerts`) so `prevent_destroy` does not block the plan. Every name in `settings.json` must exist on GitHub: an `import` of a missing repo fails the whole plan rather than degrading to a create.
- `org.tf` — organization settings, only with `-var manage_org=true` (needs `admin:org` and `-var billing_email=…`).

## What is not

- **Rulesets / branch protection.** Unavailable on private repos under the free plan. Governance is hooks + CI + convention.
- **App installations.** Read them with `org-repo apps`. `github_app_installation_repositories` needs per-app installation ids and can't express "all repositories"; not worth the state.
- **Labels.** `settings.json` `labels` is applied by `infra/labels` (`org-repo labels`, `labels.yml`), not by tofu: the provider's label resource fails on a label that already exists and importing needs every label to exist first.
- **Private vulnerability reporting, `is_template`.** Own endpoint / plain PATCH attribute; `org-repo sync` applies them, tofu ignores `is_template`.
- **Secrets.** Set through the UI or `gh secret set --org`; never in tofu state.

State is local and gitignored. The `import` blocks make it disposable: a lost state file re-adopts every repo on the next plan. Add a backend before a second machine applies.
