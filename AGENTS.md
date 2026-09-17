# .github — shared CI, actions and hooks

Reusable workflows, composite actions and the common git hook set for the
`JakobMelchard` org and the `lilfeelz` personal repos. No application code.

## Boundary against core

This repo is **how code is built and checked**. `core` is code that **ships
inside the app**. Workflows, composite actions, hooks and scaffolding templates
belong here. `core` keeps `src/`, `SPEC.md`, the store contract test and the
semver tags consumers pin. `core` must never grow a second reusable workflow or
a second hook set.

## Layout

- `.github/workflows/` `release go python node shell terraform lint`
- `actions/gitleaks/`, `actions/hooks/` composite actions
- `hooks/` `pre-commit`, `pre-push`, `install.sh`
- `profile/README.md` the org profile page

## Commands

```sh
curl -fsSL https://raw.githubusercontent.com/JakobMelchard/.github/main/hooks/install.sh | bash
```

Copies the hooks into `.githooks/` and sets `core.hooksPath`. Re-run to update.
It detects being run from a clone of this repo and copies locally instead of
fetching. `HOOKS_REF` overrides the ref.

## Rules

- Every `*-cmd` input skips its step when set to `""`. That is the extension
  point: add an input, not an `if` inside the workflow. One exception:
  `python.yml`'s `install-cmd` is an override, not a skip switch — its install
  step is unguarded and falls back to `package-manager`. Install nothing with
  `package-manager: none`.
- Actions are pinned by commit SHA with the version in a trailing comment. Bump
  deliberately.
- `lint.yml` gates every change here: actionlint, shellcheck over the hooks, a
  bash 3.2 portability check, and a smoke call of `go.yml` `python.yml`
  `node.yml` `shell.yml` with empty inputs. A new workflow of that kind must
  survive being called with nothing set — add a `smoke-<name>` job for it.
  `release.yml` and `terraform.yml` are deliberately not smoked: release-please
  holds `contents: write` and would open real release PRs, and terraform needs
  a config directory to act on.
- Callers reference `@main`, so a mistake here reaches every repo immediately.
  `v1` exists for anyone who prefers to pin.
- `github.token` is scoped to the calling repo. A cross-repo private module needs
  a PAT or app token mapped explicitly as `secrets.token`, not `secrets: inherit`,
  so only that one secret crosses the boundary.

## Gotcha

These reusable workflows build their caller's checkout. `actions/checkout`
itself takes `repository:`/`ref:`, so this is a property of these workflows and
of token scope, not a platform limit: every checkout here is bare, none takes a
`repository` input, and `github.token` only reads the calling repo. Pointing one
at another repo would need both a new input and a token passed in. That is why
`core`'s `consumers-e2e.yml` inlines its steps instead of calling `node.yml` —
and why it needs `CONSUMERS_TOKEN` to read a private consumer.
