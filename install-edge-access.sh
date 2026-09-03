#!/usr/bin/env bash
# Public bootstrap for the canonical edge-access installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Conalog/tools/main/install-edge-access.sh | bash

{

# 토큰을 변수와 하위 명령에 전달하므로 호출자가 켠 shell trace를 먼저 끈다.
set +x
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI(gh)가 필요합니다: https://cli.github.com/" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
installer="$tmp_dir/install-edge-access.sh"

can_access_repository() {
    local token="${1:-}"

    [ -n "$token" ] || return 1
    GH_TOKEN="$token" gh api "repos/Conalog/edge-access" --silent >/dev/null 2>&1
}

download_installer() {
    local token="${1:-}"

    GH_TOKEN="$token" gh release download \
        --repo Conalog/edge-access \
        --pattern install-edge-access.sh \
        --output "$installer" >/dev/null 2>&1
}

echo "==> edge-access 설치 프로그램을 준비합니다."

if [ -n "${GH_TOKEN:-}" ]; then
    if ! can_access_repository "$GH_TOKEN"; then
        echo "지정한 GH_TOKEN으로 Conalog/edge-access release를 읽지 못했습니다." >&2
        exit 1
    fi
    if ! download_installer "$GH_TOKEN"; then
        echo "Conalog/edge-access 최신 설치 프로그램을 내려받지 못했습니다." >&2
        exit 1
    fi
    GH_TOKEN="$GH_TOKEN" bash "$installer"
    exit 0
fi

if [ -n "${GITHUB_TOKEN:-}" ]; then
    if ! can_access_repository "$GITHUB_TOKEN"; then
        echo "지정한 GITHUB_TOKEN으로 Conalog/edge-access release를 읽지 못했습니다." >&2
        exit 1
    fi
    if ! download_installer "$GITHUB_TOKEN"; then
        echo "Conalog/edge-access 최신 설치 프로그램을 내려받지 못했습니다." >&2
        exit 1
    fi
    GH_TOKEN="$GITHUB_TOKEN" bash "$installer"
    exit 0
fi

accounts="$(gh auth status \
    --hostname github.com \
    --json hosts \
    --jq '.hosts["github.com"][] | select(.state == "success") | .login' \
    2>/dev/null || true)"

while IFS= read -r account; do
    [ -n "$account" ] || continue
    account_token="$(gh auth token --hostname github.com --user "$account" 2>/dev/null || true)"
    [ -n "$account_token" ] || continue

    if ! can_access_repository "$account_token"; then
        unset account_token
        continue
    fi
    echo "GitHub 계정 ${account}으로 edge-access release를 확인했습니다."
    if ! download_installer "$account_token"; then
        echo "Conalog/edge-access 최신 설치 프로그램을 내려받지 못했습니다." >&2
        exit 1
    fi
    GH_TOKEN="$account_token" bash "$installer"
    exit 0
done <<EOF
$accounts
EOF

echo "Conalog/edge-access release를 읽을 수 있는 GitHub 계정을 찾지 못했습니다." >&2
echo "GitHub CLI 로그인 상태와 저장소 권한을 확인하십시오: gh auth status --hostname github.com" >&2
exit 1

} # curl 전송이 중간에 끊기면 일부만 실행하지 않는다.
