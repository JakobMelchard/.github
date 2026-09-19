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

Two constraints of the GitHub API: **unarchiving is not supported**, so `archived: true` is one-way (`habits` and `weiterbildungszeit` are already archived; the first apply performs no archive action). And an `import` of a repo that does not exist fails the whole plan rather than degrading to a create — every name in `settings.json` must exist before `tofu plan`.
- `org.tf` — organization settings, only with `-var manage_org=true` (needs `admin:org` and `-var billing_email=…`).

## What is not

- **Rulesets / branch protection.** Unavailable on private repos under the free plan. Governance is hooks + CI + convention.
- **App installations.** Read them with `org-repo apps`. `github_app_installation_repositories` needs per-app installation ids and can't express "all repositories"; not worth the state.
- **Secrets.** Set through the UI or `gh secret set --org`; never in tofu state.

State is local and gitignored. Add a backend before a second machine applies.
