#!/usr/bin/env bash
# shellcheck disable=SC2016

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

test "$(head -n 7 "$repo_root/install-edge-access.sh" | tail -n 1)" = "{"
test "$(tail -n 1 "$repo_root/install-edge-access.sh")" = "} # curl 전송이 중간에 끊기면 일부만 실행하지 않는다."

fake_bin="$work_dir/bin"
mkdir -p "$fake_bin"
fake_gh_log="$work_dir/fake-gh.log"

printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'case "${1:-}" in' \
    '  auth)' \
    '    if [[ "${2:-}" == status ]]; then' \
    '      printf "%s\\n" perhapsspy kujung-conalog' \
    '    else' \
    '      account=""' \
    '      while (($#)); do' \
    '        if [[ "$1" == --user ]]; then account="$2"; shift 2; else shift; fi' \
    '      done' \
    '      [[ "$account" == perhapsspy ]] && printf "%s\\n" bad-token || printf "%s\\n" good-token' \
    '    fi' \
    '    ;;' \
    '  api)' \
    '    printf "api %s\n" "${GH_TOKEN:-}" >> "$FAKE_GH_LOG"' \
    '    [[ "${GH_TOKEN:-}" == good-token ]]' \
    '    ;;' \
    '  release)' \
    '    printf "release %s\n" "${GH_TOKEN:-}" >> "$FAKE_GH_LOG"' \
    '    [[ "${GH_TOKEN:-}" == good-token ]]' \
    '    output=""' \
    '    while (($#)); do' \
    '      if [[ "$1" == --output ]]; then output="$2"; shift 2; else shift; fi' \
    '    done' \
    '    cp "$FAKE_INNER" "$output"' \
    '    ;;' \
    '  *) exit 64 ;;' \
    'esac' > "$fake_bin/gh"
chmod 0755 "$fake_bin/gh"

install_dir="$work_dir/install"
mkdir -p "$install_dir"
PATH="$fake_bin:$PATH" \
    EDGE_ACCESS_INSTALL_DIR="$install_dir" \
    EDGE_ACCESS_TEST_MARKER="$install_dir/installed" \
    FAKE_INNER="$repo_root/tests/fake-edge-access-installer.sh" \
    FAKE_GH_LOG="$fake_gh_log" \
    bash "$repo_root/install-edge-access.sh" >/dev/null

test -f "$install_dir/installed"
test "$(grep -c '^release good-token$' "$fake_gh_log")" = 1
if grep -q '^release bad-token$' "$fake_gh_log"; then
    echo "inaccessible account reached release download" >&2
    exit 1
fi

github_token_install_dir="$work_dir/github-token-install"
mkdir -p "$github_token_install_dir"
PATH="$fake_bin:$PATH" \
    GITHUB_TOKEN=good-token \
    EDGE_ACCESS_INSTALL_DIR="$github_token_install_dir" \
    EDGE_ACCESS_TEST_MARKER="$github_token_install_dir/installed" \
    FAKE_INNER="$repo_root/tests/fake-edge-access-installer.sh" \
    FAKE_GH_LOG="$fake_gh_log" \
    bash "$repo_root/install-edge-access.sh" >/dev/null

test -f "$github_token_install_dir/installed"

explicit_log="$work_dir/explicit.log"
printf '%s\n' \
    '#!/usr/bin/env bash' \
    'printf "%s\\n" "${1:-} ${2:-}" >> "$FAKE_GH_LOG"' \
    'if [[ "${GH_TOKEN:-}" != good-token ]]; then exit 1; fi' \
    'exit 0' > "$work_dir/logging-gh"
chmod 0755 "$work_dir/logging-gh"
cp "$work_dir/logging-gh" "$work_dir/gh"

if PATH="$work_dir:$PATH" GH_TOKEN=bad-token FAKE_GH_LOG="$explicit_log" \
    bash "$repo_root/install-edge-access.sh" >/dev/null 2>&1; then
    echo "explicit token unexpectedly succeeded" >&2
    exit 1
fi

test -s "$explicit_log"
if grep -q 'auth status' "$explicit_log"; then
    echo "explicit token was overridden by account discovery" >&2
    exit 1
fi

trace_log="$work_dir/trace.log"
mkdir -p "$work_dir/trace-install"
PATH="$fake_bin:$PATH" \
    GH_TOKEN=good-token \
    EDGE_ACCESS_INSTALL_DIR="$work_dir/trace-install" \
    EDGE_ACCESS_TEST_MARKER="$work_dir/trace-install/installed" \
    FAKE_INNER="$repo_root/tests/fake-edge-access-installer.sh" \
    FAKE_GH_LOG="$fake_gh_log" \
    bash -x "$repo_root/install-edge-access.sh" >"$trace_log" 2>&1
if grep -q 'good-token' "$trace_log"; then
    echo "shell trace exposed the GitHub token" >&2
    exit 1
fi

asset_error_log="$work_dir/asset-error.log"
printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    '[[ "${1:-}" == api ]] && exit 0' \
    '[[ "${1:-}" == release ]] && exit 1' \
    'exit 64' > "$work_dir/asset-gh"
chmod 0755 "$work_dir/asset-gh"
cp "$work_dir/asset-gh" "$work_dir/gh"
if PATH="$work_dir:$PATH" GH_TOKEN=accessible-token \
    bash "$repo_root/install-edge-access.sh" >"$asset_error_log" 2>&1; then
    echo "missing release asset unexpectedly succeeded" >&2
    exit 1
fi
grep -q '최신 설치 프로그램을 내려받지 못했습니다' "$asset_error_log"
if grep -q '저장소 권한' "$asset_error_log"; then
    echo "release asset failure was misclassified as repository access" >&2
    exit 1
fi

echo "install-edge-access account routing tests passed"
