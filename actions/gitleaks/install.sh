#!/usr/bin/env bash
# install.sh: install the pinned gitleaks release for this Linux runner's architecture to
# /usr/local/bin, checksum-verified.
set -euo pipefail

VERSION=8.30.1
# Renovate bumps VERSION only: take both sums from the release's checksums.txt and update the
# next line with them. scripts/test/gitleaks.bats fails until the two versions match.
# checksums for 8.30.1
case "$(uname -m)" in
  aarch64 | arm64) ARCH=arm64 SHA256=e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080 ;;
  *) ARCH=x64 SHA256=551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb ;;
esac
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/gitleaks.tgz" "https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_linux_${ARCH}.tar.gz"
echo "$SHA256  $tmp/gitleaks.tgz" | sha256sum -c -
tar -xzf "$tmp/gitleaks.tgz" -C "$tmp" gitleaks
sudo install -m 0755 "$tmp/gitleaks" /usr/local/bin/gitleaks
