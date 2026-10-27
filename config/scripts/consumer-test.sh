#!/usr/bin/env bash
# Packs the package and installs it into a scratch consumer (test/consumer), as a real repo would.
# Pack, do not link: a path install symlinks the checkout and peers would not resolve from it.
# ok.js must pass eslint, prettier and tsc. bad.js shows the rules bite (a function without JSDoc,
# a semicolon, a mismatched @param as an error rather than the preset's warning) and that the house
# block holds (an unknown tag, an undefined type, an unused _ param and an empty catch are not reported).
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
(cd "$root" && npm pack --pack-destination "$d" >/dev/null)
cp "$root"/test/consumer/* "$d"/
cd "$d"
npm i --no-save ./jakobmelchard-config-*.tgz eslint@9 @eslint/js@9 eslint-plugin-jsdoc@50 typescript@5 prettier@3 @types/node@22 >/dev/null
npx eslint ok.js
npx prettier --check ok.js
npx tsc -p tsconfig.json
want="jsdoc/check-param-names:2 jsdoc/require-jsdoc:1 jsdoc/require-param-description:1 jsdoc/require-param:1 jsdoc/require-returns:1"
rules=$(npx eslint -f json bad.js | jq -r '[.[].messages[] | "\(.ruleId):\(.severity)"] | sort | join(" ")') || true
[ "$rules" = "$want" ] || { echo "got: $rules" >&2; exit 1; }
if npx prettier --check bad.js; then
  echo "bad.js passed prettier" >&2
  exit 1
fi
echo "consumer ok"
