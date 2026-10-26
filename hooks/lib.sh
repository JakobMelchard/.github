# shellcheck shell=bash
have() { command -v "$1" >/dev/null 2>&1; }
fail() { echo "${HOOK:-hook}: $*" >&2; exit 1; }
# need <tool> <install hint>: a hook the repo opted into must not pass because a tool is missing.
need() { have "$1" || fail "$1 not found ($2). Skip once with SKIP=${HOOK:-<id>}."; }
