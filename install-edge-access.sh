#!/usr/bin/env bash
# Public bootstrap for the canonical edge-access installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Conalog/tools/main/install-edge-access.sh | bash

{

set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI(gh)가 필요합니다: https://cli.github.com/" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
installer="$tmp_dir/install-edge-access.sh"

echo "==> edge-access 설치 프로그램을 준비합니다."
gh release download \
    --repo Conalog/edge-access \
    --pattern install-edge-access.sh \
    --output "$installer"

bash "$installer"

} # curl 전송이 중간에 끊기면 일부만 실행하지 않는다.
