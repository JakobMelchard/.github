#!/usr/bin/env bash
# commit-msg: reject a non-conventional subject. Same regex as the PR-title check in
# JakobMelchard/.github, because squash-merge makes the PR title the commit release-please parses.
set -eo pipefail
export HOOK=conventional-commit
. "$(dirname "$0")/lib.sh"

msg=${1:?commit message file}
# first line that is neither empty nor a comment; stripspace follows core.commentChar.
# awk reads all input: a reader that exits early would SIGPIPE stripspace on a large message.
subject=$(git stripspace --strip-comments <"$msg" | awk 'NF && !s {print; s=1}')
[ -n "$subject" ] || exit 0 # git aborts an empty message on its own

case "$subject" in
  "Merge "* | "Revert "* | "fixup! "* | "squash! "* | "amend! "*) exit 0 ;;
esac

types='feat|fix|chore|docs|refactor|test|ci|build|perf|style|revert'
if ! printf '%s\n' "$subject" | grep -Eq "^($types)(\([A-Za-z0-9._/-]+\))?!?: .+"; then
  fail "\"$subject\" is not a conventional commit: <type>(<scope>)!: <subject>, type one of $types"
fi
[ "${#subject}" -le 72 ] || fail "subject is ${#subject} characters; keep it at 72 or under"
