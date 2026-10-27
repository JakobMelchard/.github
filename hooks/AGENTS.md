# .githooks

A prek / pre-commit hook repository. `.pre-commit-hooks.yaml` declares the hooks; `hooks/*.sh`
implement them. No build.

- bash 3.2 only. `hooks/test/portable` (CI and a local hook) fails on `mapfile`, `readarray`, `declare -A`.
- A hook wraps a tool the consumer already needs. Missing tool: `need <tool> <hint>` fails. Only
  `eslint` and `prettier` skip, when the repo has no config for them.
- Prefer an upstream hook repo over wrapping a tool here (gitleaks, ruff, shellcheck already are).
- Formatters rewrite and exit non-zero; prek reports the modified files.
- Check: `hooks/test/run`, `prek validate-manifest .pre-commit-hooks.yaml` from repository root, `prek run --all-files`.
- Consumers pin a tag. Changing a hook id or its stage is a breaking change: bump the major.
