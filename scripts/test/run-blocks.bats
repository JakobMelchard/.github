#!/usr/bin/env bats
# No workflow, starter or action carries a run block longer than 4 lines: longer logic lives in a
# script (actions/scripts/bin, scripts/, or next to an action.yml) that shellcheck and bats cover.

load helper

@test "run blocks stay at 4 lines or fewer" {
  cd "$BATS_TEST_DIRNAME/../.."
  set -o pipefail
  long=$(for f in .github/workflows/*.yml workflow-templates/*.yml actions/*/action.yml; do
    yq -o=tsv '.. | select(tag == "!!map" and has("run") and (.run | tag) == "!!str") | [(.name // .id // "-"), (.run | sub("\n$"; "") | split("\n") | length)]' "$f" |
      awk -v f="$f" -F'\t' '$2 > 4 { print f ": " $1 " (" $2 " lines)" }'
  done)
  [ -z "$long" ] || { echo "$long"; false; }
}
