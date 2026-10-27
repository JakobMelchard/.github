#!/usr/bin/env bash
# Parse-check with the interpreter the shebang (else the file name) names. shellcheck skips zsh, so this is its only check.
set -eo pipefail
export HOOK=shell-syntax
. "$(dirname "$0")/lib.sh"

rc=0
for f in "$@"; do
  i=$(head -1 "$f" | sed -nE 's#^\#![^ ]*/(env +)?(bash|sh|zsh)([[:space:]].*)?$#\2#p')
  b=${f##*/}
  case "${i:-$b}" in
    zsh|*.zsh|.zshrc|.zshenv|.zprofile|.zlogin) need zsh "brew install zsh"; zsh -n "$f" || rc=1 ;;
    sh|*.sh) sh -n "$f" || rc=1 ;;
    *) bash -n "$f" || rc=1 ;;
  esac
done
exit $rc
