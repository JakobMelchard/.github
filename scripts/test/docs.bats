#!/usr/bin/env bats
# actions/docs/build.mjs over the docs-smoke fixture: pages, nav, stylesheet and rewritten links.
# Needs `npm ci --prefix actions/docs`.

load helper

setup() {
  common_setup
  node "$BATS_TEST_DIRNAME/../../actions/docs/build.mjs" --src "$BATS_TEST_DIRNAME/docs-smoke" \
    --out "$T/site" --title smoke --assets https://a.example/assets/ --repo https://github.com/o/r >/dev/null
  cd "$T/site" || return
}

@test "docs: every page and asset, plus the action's stylesheet" {
  test -f index.html && test -f guide/setup.html && test -f guide/logo.svg && test -f doc.css
  grep -qF '<link rel="stylesheet" href="https://a.example/assets/style.css">' index.html
  grep -qF '<link rel="stylesheet" href="doc.css">' index.html
  grep -qF '<link rel="stylesheet" href="../doc.css">' guide/setup.html
  ! grep -q '<style' index.html guide/setup.html
}

@test "docs: nav entries, section labels and the active page" {
  grep -qF '<a href="index.html" class="active">Home</a>' index.html
  grep -qF '<span>Guides</span>' index.html
  grep -qF '<a href="guide/setup.html#install">' index.html
  grep -qF '<a href="../guide/setup.html" class="active">Setup</a>' guide/setup.html
  grep -qF '<a href="https://github.com/o/r" target="_blank" rel="noopener">GitHub</a>' index.html
}

@test "docs: markdown links and images point at the rendered pages" {
  grep -qF '<a href="../index.html#usage">' guide/setup.html
  grep -qF '<img src="logo.svg"' guide/setup.html
  grep -qF '<a href="../index.html">← Home</a>' guide/setup.html
}

@test "docs: overlapping src and out fail" {
  run node "$BATS_TEST_DIRNAME/../../actions/docs/build.mjs" --src "$T/site" --out "$T/site/out" --title x
  [ "$status" -ne 0 ]
  [[ "$output" == *"must not overlap"* ]] || false
}
