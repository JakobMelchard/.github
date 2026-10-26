# .githooks

Shared hooks for the `JakobMelchard` org and the `lilfeelz` repos, as a
[prek](https://github.com/j178/prek) / pre-commit hook repository. Public, so it fetches without a token.

## Use in a repo

`.pre-commit-config.yaml` at the repo root, pinning this repo by tag. Pick the hooks the repo needs:

```yaml
default_install_hook_types: [pre-commit, commit-msg, pre-push]
default_stages: [pre-commit] # upstream hooks (gitleaks) would otherwise rerun at every stage
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.30.1
    hooks: [{ id: gitleaks }]
  - repo: https://github.com/JakobMelchard/.githooks
    rev: v2.0.1
    hooks:
      - id: conventional-commit
      - id: swift-format
  - repo: local # repo-specific checks
    hooks: []
```

```sh
brew install prek          # once per machine
prek install               # once per clone; writes .git/hooks shims
prek run --all-files       # what CI runs
```

## Hooks

| id | stage | does |
|----|-------|------|
| `conventional-commit` | commit-msg | `type(scope)!: subject`, max 72 chars; merge, revert, fixup, squash and amend pass. The same regex gates PR titles in the org workflows. |
| `shell-syntax` | pre-commit | `bash -n` / `sh -n` / `zsh -n` by shebang, else by name (`.zshrc`, `.zshenv`, `.zprofile`, `.zlogin`, `*.zsh` are zsh). Pair with `shellcheck-py` (`exclude_types: [zsh]`). |
| `gofmt` | pre-commit | rewrites, then fails so you re-stage |
| `go-build` | pre-push | `go vet ./...` and `go build ./...` when `go.mod` is at the root |
| `swift-format` | pre-commit | `format --in-place`, then `lint --strict`; a brew `swift-format` wins over Xcode's |
| `xcodegen` | pre-push | every tracked `project.yml` still generates |
| `prettier` | pre-commit | the repo's own prettier (`npx --no-install`), so version and config come from `package.json` |
| `eslint` | pre-commit | the repo's own eslint |
| `tofu-fmt` | pre-commit | `tofu fmt`, else `terraform fmt` |

Upstream for the rest: `gitleaks/gitleaks`, `astral-sh/ruff-pre-commit` (`ruff-check`), `shellcheck-py/shellcheck-py`.

```sh
SKIP=<id> git commit     # skip one hook once
```

## Develop

```sh
prek install     # this repo runs its hooks from the working tree (repo: local)
test/run         # hook scripts against good and bad inputs
```

Release: merge the release-please PR, which tags `vX.Y.Z`.
