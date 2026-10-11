# .github

Reusable workflows, composite actions and the org Renovate preset for `JakobMelchard` and the
`lilfeelz` personal repos. No application code. The human overview is in README.md.

This repo is how code is built and checked. `hx` is code that ships inside an app. Workflows,
actions, hooks and scaffolding templates belong here; `hx` must never grow a second reusable
workflow or hook set.

## Layout

- `.github/workflows/` reusable workflows, plus this repo's own `lint.yml`, `self-release.yml` and `routines.yml`
- `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`, `SECURITY.md`, `SUPPORT.md`, `CONTRIBUTING.md` org defaults
- `workflow-templates/` starter callers (`<name>.yml` + `<name>.properties.json`)
- `actions/` composite actions
- `scripts/ci` and `scripts/lib/common.sh`: the helpers that `fleet-sync` (`.config`), `org-repo` (`template`) and `ios` (`lilfeelz/workspaces`) source via `JM_LIB`; bats tests in `scripts/test`
- `renovate/default.json` org preset, `routines/` prompts for the nightly routines, `profile/` org profile
- Repo settings, labels and tofu live in `JakobMelchard/infra`, not here

## Commands

```sh
prek install           # once per clone
prek run --all-files   # same as the CI hooks job
```

## Rules

- Every `*-cmd` input skips its step when `""`. To make a step optional, add an input, not an
  `if` in the workflow. `python.yml`'s `install-cmd` is the exception: it overrides the
  `package-manager` install, and `package-manager: none` installs nothing.
- Describe every input with `description:` in `inputs:`. The workflow header stays short.
- Pin third-party actions by commit SHA with the version in a trailing comment.
- Labels are declared in `JakobMelchard/infra` `terraform/github/settings.json`. Never
  `gh label create` by hand.
- Callers pin a release tag, never `@main`. Never move a tag by hand; `self-release.yml` moves `v1`.
- A reusable workflow gets a starter in `workflow-templates/` once a release contains it. A
  rendered repo's caller comes from `JakobMelchard/template`.
- `lint.yml` gates every change. A new workflow must survive being called with no inputs: add a
  `smoke-<name>` job. Not smoked on purpose: `release` (opens real release PRs), `ai-review` and
  `review-label` (need a labelled PR and secrets). `cf` runs with `dry-run`, `tofu` with plan,
  apply and state commit off.
- `github.token` reads only the calling repo. A cross-repo private dependency needs credentials
  mapped explicitly (`app-client-id` and `app-private-key`; the `token` secret is gone), not `secrets: inherit`.

## Gotcha

These workflows build their caller's checkout: no checkout here takes a `repository` input, and
`github.token` reads only the calling repo. Building another repo needs both a new input and a
token. That is why `hx`'s `consumers-e2e.yml` inlines its steps instead of calling `node.yml`.
