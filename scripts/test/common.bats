#!/usr/bin/env bats
# scripts/lib/common.sh fetch and fetch_rev: a local clone in $WORKSPACES_ROOT, else the fake gh tarball

load helper

setup() {
  common_setup
  export WORKSPACES_ROOT=$T/ws
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  # shellcheck source=../lib/common.sh
  . "$BIN/lib/common.sh"
  mkdir -p "$T/tar/JakobMelchard-r-abc1234"
  echo remote > "$T/tar/JakobMelchard-r-abc1234/f"
  tar -czf "$GH_FIXTURES/tarball-r.tgz" -C "$T/tar" JakobMelchard-r-abc1234
  git init -q --bare -b main "$T/remote"
  git clone -q "$T/remote" "$WS/r" 2>/dev/null
  echo local > "$WS/r/f"
  git -C "$WS/r" add f
  git -C "$WS/r" commit -q -m seed
  git -C "$WS/r" push -q origin main
}

@test "fetch: a clean clone at origin/main is used as is" {
  d=$(fetch r)
  [ "$d" = "$WS/r" ]
  [ "$(fetch_rev "$d")" = "$(git -C "$WS/r" rev-parse --short=7 HEAD)" ]
  git -C "$WS/r" tag v1.2.3
  [ "$(fetch_rev "$d")" = v1.2.3 ]
}

@test "fetch: a dirty clone falls back to the tarball of main" {
  echo edit > "$WS/r/f"
  d=$(fetch r 2>"$T/err")
  [ "$(cat "$d/f")" = remote ]
  grep -q "is dirty or not at origin/main" "$T/err"
  [ "$(fetch_rev "$d")" = abc1234 ]
}

@test "fetch: a clone behind origin/main falls back to the tarball" {
  git -C "$WS/r" commit -q --allow-empty -m ahead
  d=$(fetch r 2>/dev/null)
  [ "$(cat "$d/f")" = remote ]
}

@test "fetch: an explicit ref always uses the tarball; fetch_rev keeps a tag, else the sha" {
  d=$(fetch r v1.0.0)
  [ "$(cat "$d/f")" = remote ]
  [ "$(fetch_rev "$d")" = v1.0.0 ]
  d=$(fetch r dev)
  [ "$(fetch_rev "$d")" = abc1234 ]
}

@test "fetch: a failed download dies" {
  rm "$GH_FIXTURES/tarball-r.tgz"
  run fetch r main
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot fetch JakobMelchard/r@main"* ]] || false
}
