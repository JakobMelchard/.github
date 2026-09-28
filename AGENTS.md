# .github — shared CI, actions and hooks

Reusable workflows, composite actions and the common git hook set for the
`JakobMelchard` org and the `lilfeelz` personal repos. No application code.

## Boundary against hx

This repo is **how code is built and checked**. `hx` is code that **ships
inside the app**. Workflows, composite actions, hooks and scaffolding templates
belong here. `hx` keeps `src/`, `SPEC.md`, the store contract test and the
semver tags consumers pin. `hx` must never grow a second reusable workflow or
a second hook set.

## Layout

- `.github/workflows/` `release go python node shell terraform xcode android hooks lint labels self-release fleet-sync`
- `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`, `SECURITY.md`, `CONTRIBUTING.md` org defaults, inherited by every repo without its own
- `actions/gitleaks/` composite action
- `infra/` settings.json (repo settings **and** labels), tofu, `infra/labels`
- `renovate/default.json` the org Renovate preset every repo extends
- `profile/README.md` the org profile page

## Commands

```sh
prek install           # once per clone (brew install prek)
prek run --all-files   # what the smoke-hooks job runs
```

Hooks live in `JakobMelchard/.githooks` (public), pinned by tag in `.pre-commit-config.yaml`.
`hooks.yml` here is the reusable CI job that runs a caller's config.

## Rules

- Every `*-cmd` input skips its step when set to `""`. That is the extension
  point: add an input, not an `if` inside the workflow. One exception:
  `python.yml`'s `install-cmd` is an override, not a skip switch — its install
  step is unguarded and falls back to `package-manager`. Install nothing with
  `package-manager: none`.
- Actions are pinned by commit SHA with the version in a trailing comment. Bump
  deliberately.
- Labels are declared in `infra/settings.json` and written only by `infra/labels`.
  Never `gh label create` by hand in a repo; add it to the document.
- `lint.yml` gates every change here: actionlint, shellcheck over the hooks, a
  bash 3.2 portability check, and a smoke call of `go.yml` `python.yml`
  `node.yml` `shell.yml` with empty inputs. A new workflow of that kind must
  survive being called with nothing set — add a `smoke-<name>` job for it.
  `release.yml` and `terraform.yml` are deliberately not smoked: release-please
  holds `contents: write` and would open real release PRs, and terraform needs
  a config directory to act on.
- Callers reference `@main`, so a mistake here reaches every repo immediately.
  `v1` follows the latest 1.x release and is moved only by `self-release.yml`;
  release tags are immutable. Never move a tag by hand.
- `workflow-templates/auto.yml` and `.devcontainer/templates` are mirrored into
  `JakobMelchard/template`. Change the source here first, then the template.
- `github.token` is scoped to the calling repo. A cross-repo private module needs
  a PAT or app token mapped explicitly as `secrets.token`, not `secrets: inherit`,
  so only that one secret crosses the boundary.

## Gotcha

These reusable workflows build their caller's checkout. `actions/checkout`
itself takes `repository:`/`ref:`, so this is a property of these workflows and
of token scope, not a platform limit: every checkout here is bare, none takes a
`repository` input, and `github.token` only reads the calling repo. Pointing one
at another repo would need both a new input and a token passed in. That is why
`hx`'s `consumers-e2e.yml` inlines its steps instead of calling `node.yml`,
and why it mints an app token (falling back to `CONSUMERS_TOKEN`) to read a
private consumer.
