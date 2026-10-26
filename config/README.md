# .config

Org lint, format and tsconfig bases. Public.

```sh
npm i -D @jakobmelchard/config eslint @eslint/js eslint-plugin-jsdoc
```

| Export | Use |
|--------|-----|
| `@jakobmelchard/config/eslint` | `import base from '@jakobmelchard/config/eslint'; export default [...base, ...]` |
| `@jakobmelchard/config/prettier` | `"prettier": "@jakobmelchard/config/prettier"` in `package.json` |
| `@jakobmelchard/config/tsconfig` | `"extends": "@jakobmelchard/config/tsconfig"` |

| Path | What |
|------|------|
| `eslint/`, `prettier/`, `tsconfig/` | the exported bases |
| `.github/workflows/` | CI, release-please, npm publish |

Ruff, gitleaks, editorconfig and Renovate files come from `JakobMelchard/template`. Design tokens live in `@jakobmelchard/web`.
