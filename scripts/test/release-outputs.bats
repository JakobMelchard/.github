#!/usr/bin/env bats
load helper
setup() {
  common_setup
  export GITHUB_OUTPUT="$T/out"
}
@test "release outputs: no release is an empty component map" {
  RELEASE_OUTPUTS='{}' run "$JM/jm-release-outputs"
  [ "$status" -eq 0 ]
  grep -qx 'releases={}' "$GITHUB_OUTPUT"
  grep -qx 'paths_released=\[\]' "$GITHUB_OUTPUT"
  grep -qx 'releases_created=false' "$GITHUB_OUTPUT"
}
@test "release outputs: preserves root release path and version" {
  RELEASE_OUTPUTS='{"paths_released":"[\".\"]","releases_created":"true","release_created":"true","tag_name":"v2.5.1","version":"2.5.1"}' run "$JM/jm-release-outputs"
  [ "$status" -eq 0 ]
  grep -qx 'releases={".":{"tag_name":"v2.5.1","version":"2.5.1"}}' "$GITHUB_OUTPUT"
}
@test "release outputs: two nested component paths retain independent tags" {
  RELEASE_OUTPUTS='{"paths_released":"[\"apps/fz\",\"apps/pull\"]","releases_created":"true","apps/fz--tag_name":"fz-v1.2.0","apps/fz--version":"1.2.0","apps/pull--tag_name":"pull-v3.0.1","apps/pull--version":"3.0.1"}' run "$JM/jm-release-outputs"
  [ "$status" -eq 0 ]
  grep -qx 'releases={"apps/fz":{"tag_name":"fz-v1.2.0","version":"1.2.0"},"apps/pull":{"tag_name":"pull-v3.0.1","version":"3.0.1"}}' "$GITHUB_OUTPUT"
}
@test "release outputs: malformed or incomplete releases fail without partial outputs" {
  for value in 'null' '{"paths_released":"oops"}' '{"paths_released":"[\"apps/fz\"]"}' '{"paths_released":"[3]"}'; do
    RELEASE_OUTPUTS=$value run "$JM/jm-release-outputs"
    [ "$status" -ne 0 ]
    [ ! -s "$GITHUB_OUTPUT" ]
  done
}

@test "release outputs: workflow pin already contains helper" {
  root=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  sha=$(sed -n 's/.*uses: JakobMelchard\/.github\/actions\/scripts@\([a-f0-9]*\) # component output helper/\1/p' "$root/.github/workflows/release.yml")
  [ "${#sha}" -eq 40 ]
  git -C "$root" cat-file -e "$sha^{commit}" 2>/dev/null || skip "pinned commit is not in this clone"
  git -C "$root" cat-file -e "$sha:actions/scripts/bin/jm-release-outputs"
}
