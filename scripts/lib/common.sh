#!/usr/bin/env bash
# Helpers shared by the org's shell tools (ci here, config-sync and fleet-sync in .config, org-repo
# in template, ios in lilfeelz/workspaces). Sourced, not executed; bash 3.2 compatible.
#   . "${JM_LIB:-$HOME/Workspaces/JakobMelchard/.github/scripts/lib}/common.sh"
ORG="${ORG:-JakobMelchard}"
WS="${WORKSPACES_ROOT:-$HOME/Workspaces}/$ORG"

die()  { echo "${0##*/}: $*" >&2; exit 1; }
say()  { printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
need() { for c in "$@"; do have "$c" || die "needs $c"; done; }

root() { git rev-parse --show-toplevel 2>/dev/null || die "not in a git repo"; }

# fetch <repo> [ref]: print a directory holding a checkout of $ORG/<repo>.
# No ref: the local clone when it is clean and at origin/main, else a gh tarball of main.
# With a ref: always the gh tarball, so the ref is what gets vendored.
fetch() {
  local repo=$1 ref=${2:-} c="$WS/$1" d
  if [ -z "${FETCH_REMOTE:-}" ] && [ -z "$ref" ] && [ -d "$c/.git" ]; then
    if [ -z "$(git -C "$c" status --porcelain)" ] &&
       [ "$(git -C "$c" rev-parse HEAD)" = "$(git -C "$c" rev-parse -q --verify origin/main)" ]; then
      printf '%s\n' "$c"; return
    fi
    echo "${0##*/}: warning: $c is dirty or not at origin/main; using $ORG/$repo@main from GitHub" >&2
  fi
  ref=${ref:-main}
  need gh
  d=$(mktemp -d)
  # bash 3.2 drops set -e inside command substitution, so check each step
  gh api "repos/$ORG/$repo/tarball/$ref" > "$d/t.tgz" || die "cannot fetch $ORG/$repo@$ref"
  tar -xzf "$d/t.tgz" -C "$d" --strip-components=1 || die "cannot unpack $ORG/$repo@$ref"
  # the tarball's top directory is <owner>-<repo>-<short sha>; record ref and sha for fetch_rev
  printf '%s %s\n' "$ref" "$(tar -tzf "$d/t.tgz" | sed -n '1{s|/.*||;s|.*-||;p;}')" > "$d/.fetch-rev"
  rm -f "$d/t.tgz"
  printf '%s\n' "$d"
}

# fetch_rev <dir from fetch>: the version it holds, its tag when exactly at one, else a short sha
fetch_rev() {
  local d=$1 ref sha
  if [ -d "$d/.git" ]; then
    git -C "$d" describe --tags --exact-match HEAD 2>/dev/null || git -C "$d" rev-parse --short=7 HEAD
    return
  fi
  read -r ref sha < "$d/.fetch-rev" || { echo unknown; return; }
  case "$ref" in v[0-9]*) printf '%s\n' "$ref" ;; *) printf '%s\n' "${sha:-$ref}" ;; esac
}

# vendored <src> <dst> <label> [rev]: print <src> as vendor writes it, with a one-line header
# where <dst>'s format has comments. <label> is <repo>/<path>, rev the source version.
vendored() {
  local src=$1 dst=$2 label=$3 rev=${4:-unknown}
  case "$dst" in
    *.js)   echo "// VENDORED from $ORG/$label - do not edit here; run config-sync." ;;
    *.toml|*.yml|*.yaml|*editorconfig)
            echo "# VENDORED from $ORG/$label - do not edit here; run config-sync." ;;
    *.css)  echo "/* VENDORED from $ORG/${label%%/*} ${label#*/} @$rev. Do not edit; run config-sync. */" ;;
    *.swift) echo "// VENDORED from $ORG/${label%%/*} ${label#*/} @$rev. Do not edit; run config-sync." ;;
  esac      # json and markdown have no comment syntax: copied verbatim
  cat "$src"
}

# vendor <src> <dst> <label> [rev]: write the vendored copy of <src> to <dst>
vendor() {
  mkdir -p "$(dirname "$2")"
  vendored "$@" > "$2"
  say "  $2"
}

# vendor_check <src> <dst> <label> [rev]: succeed when <dst> matches what vendor would write, else
# print a diff and fail. The VENDORED header is ignored, so a version bump alone is not drift.
vendor_check() {
  local dst=$2 unheader='1{/VENDORED from/d;}'
  [ -f "$dst" ] || { say "  missing $dst"; return 1; }
  if diff -u --label "$dst" --label "$dst (expected)" <(sed "$unheader" "$dst") <(vendored "$@" | sed "$unheader"); then
    say "  ok $dst"
  else
    say "  drift $dst"; return 1
  fi
}

org_repos() { # org_repos [all]: sorted $ORG repo names; archived ones only with `all`
  local q='.[] | select(.isArchived|not) | .name'
  [ "${1:-}" = all ] && q='.[].name'
  gh repo list "$ORG" --limit 200 --json name,isArchived -q "$q" | sort
}

settings_json() { # print terraform/github/settings.json from JakobMelchard/infra
  gh api -H 'Accept: application/vnd.github.raw' "repos/$ORG/infra/contents/terraform/github/settings.json"
}
