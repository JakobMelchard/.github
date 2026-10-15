# Shared setup for the bats suite. Offline: gh is scripts/test/bin/gh, answering from $GH_FIXTURES.

common_setup() {
  unset GITHUB_ACTIONS GH_TOKEN FETCH_REMOTE ORG
  T=$BATS_TEST_TMPDIR
  export GH_FIXTURES=$T/fx
  PATH="$BATS_TEST_DIRNAME/bin:$PATH"
  # shellcheck disable=SC2034 # used by the .bats files
  BIN=$(cd "$BATS_TEST_DIRNAME/.." && pwd)
  # shellcheck disable=SC2034 # used by the .bats files
  JM=$(cd "$BATS_TEST_DIRNAME/../../actions/scripts/bin" && pwd)
  mkdir -p "$GH_FIXTURES"
}
