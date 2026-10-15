#!/usr/bin/env bash
# install.sh: install the pinned gitleaks release for this Linux runner's architecture to
# /usr/local/bin, checksum-verified.
set -euo pipefail

VERSION=8.28.0
case "$(uname -m)" in
  aarch64 | arm64) ARCH=arm64 SHA256=eff65261156100e5d94a6b3dec313d532fddfe19ae1590bf7a2b4f2699128356 ;;
  *) ARCH=x64 SHA256=a65b5253807a68ac0cafa4414031fd740aeb55f54fb7e55f386acb52e6a840eb ;;
esac
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/gitleaks.tgz" "https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_linux_${ARCH}.tar.gz"
echo "$SHA256  $tmp/gitleaks.tgz" | sha256sum -c -
tar -xzf "$tmp/gitleaks.tgz" -C "$tmp" gitleaks
sudo install -m 0755 "$tmp/gitleaks" /usr/local/bin/gitleaks
