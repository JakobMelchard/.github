# platform components

This repo owns three independent release streams: reusable CI/actions (`.`), shared lint/format/tsconfig presets (`config/`, published as `@jakobmelchard/config`), and portable prek hooks (`hooks/` + `.pre-commit-hooks.yaml`, 10 hooks including `web-tokens`).

`JakobMelchard/.config` and `JakobMelchard/.githooks` are retired (kept only for historical tags). Consumer repos install `@jakobmelchard/config` from npm and pin `hooks-vX.Y.Z` tags from this repo.

## Release streams

| path | manifest version | tag format | artifact |
| --- | --- | --- | --- |
| `.` | 2.8.3 | `vX.Y.Z` (`self-release.yml` updates major tag) | reusable workflows and actions |
| `config` | 3.1.0 | `config-vX.Y.Z` | `@jakobmelchard/config` npm package |
| `hooks` | 2.2.0 | `hooks-vX.Y.Z` | root `.pre-commit-hooks.yaml` and `hooks/` |

Root release-please excludes `config/` and `hooks/`. Use `config-publish.yml` (`workflow_dispatch`, `stage: true`) to manually stage a published `config-vX.Y.Z` tag on npm with provenance (owner 2FA approval required).

## Verification

- `config/scripts/consumer-test.sh` and `config/scripts/check-json.sh`
- `hooks/test/run`, `hooks/test/portable`, and `prek validate-manifest .pre-commit-hooks.yaml`
- `bats scripts/test/`
