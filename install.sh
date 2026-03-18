#!/usr/bin/env bash
# Conalog CLI installer
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/Conalog/cli/main/install.sh | bash
#   curl -sSL ... | bash -s -- --version v0.1.0
#   curl -sSL ... | bash -s -- --bin-dir ~/.local/bin
#
# Environment variables:
#   CONALOG_VERSION     - Version to install (default: latest)
#   CONALOG_INSTALL_DIR - Install directory (default: /usr/local/bin)

# Wrap entire script in braces to prevent partial execution when piped via curl | bash.
# Without this, a network interruption mid-download could execute a truncated script.
{

set -euo pipefail

REPO="Conalog/cli"
BINARY_NAME="conalog"
INSTALL_DIR="${CONALOG_INSTALL_DIR:-/usr/local/bin}"
VERSION="${CONALOG_VERSION:-}"
MAX_RETRIES=3

# ── Output helpers ───────────────────────────────────────────

has_color() {
    [ -t 1 ] && [ -z "${NO_COLOR:-}" ]
}

info() {
    if has_color; then
        printf "\033[1;34m==>\033[0m %s\n" "$*"
    else
        printf "==> %s\n" "$*"
    fi
}

warn() {
    if has_color; then
        printf "\033[1;33m==> Warning:\033[0m %s\n" "$*" >&2
    else
        printf "==> Warning: %s\n" "$*" >&2
    fi
}

error() {
    if has_color; then
        printf "\033[1;31m==> Error:\033[0m %s\n" "$*" >&2
    else
        printf "==> Error: %s\n" "$*" >&2
    fi
    exit 1
}

success() {
    if has_color; then
        printf "\033[1;32m==>\033[0m %s\n" "$*"
    else
        printf "==> %s\n" "$*"
    fi
}

# ── Argument parsing ────────────────────────────────────────

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -v|--version)
                VERSION="${2:-}"
                [ -z "$VERSION" ] && error "Missing value for $1"
                shift 2
                ;;
            -b|--bin-dir)
                INSTALL_DIR="${2:-}"
                [ -z "$INSTALL_DIR" ] && error "Missing value for $1"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1 (use --help for usage)"
                ;;
        esac
    done
}

usage() {
    cat <<EOF
Conalog CLI Installer

Usage:
  install.sh [options]

Options:
  -v, --version VERSION   Install a specific version (e.g., v0.1.0)
  -b, --bin-dir DIR       Install directory (default: /usr/local/bin)
  -h, --help              Show this help message

Environment Variables:
  CONALOG_VERSION         Same as --version
  CONALOG_INSTALL_DIR     Same as --bin-dir
  NO_COLOR                Disable colored output

Examples:
  # Install latest version
  curl -sSL https://raw.githubusercontent.com/Conalog/cli/main/install.sh | bash

  # Install specific version
  curl -sSL ... | bash -s -- --version v0.1.0

  # Install to custom directory
  curl -sSL ... | bash -s -- --bin-dir \$HOME/.local/bin
EOF
}

# ── Platform detection ──────────────────────────────────────

detect_platform() {
    local os arch uname_s uname_m

    uname_s="$(uname -s)"
    uname_m="$(uname -m)"

    case "$uname_s" in
        Darwin)           os="darwin" ;;
        Linux)            os="linux" ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT)
            error "Windows is not supported. Please use WSL2 or download the binary manually from https://github.com/${REPO}/releases"
            ;;
        *)
            error "Unsupported OS: ${uname_s}. Supported: macOS, Linux"
            ;;
    esac

    case "$uname_m" in
        x86_64|amd64)   arch="amd64" ;;
        arm64|aarch64)  arch="arm64" ;;
        armv6l)         arch="armv6" ;;
        armv7l)         arch="armv7" ;;
        *)
            error "Unsupported architecture: ${uname_m}. Supported: x86_64, arm64"
            ;;
    esac

    echo "${os}_${arch}"
}

# ── Download helpers ────────────────────────────────────────

has_curl() { command -v curl &>/dev/null; }
has_wget() { command -v wget &>/dev/null; }

check_download_tool() {
    if ! has_curl && ! has_wget; then
        error "curl or wget is required. Install one and try again."
    fi
}

# Download a URL to a file with retry and HTTP error detection
download() {
    local url="$1" dest="$2"
    local attempt

    for attempt in $(seq 1 "$MAX_RETRIES"); do
        if has_curl; then
            if curl --fail --silent --show-error --location --output "$dest" "$url" 2>/dev/null; then
                return 0
            fi
        elif has_wget; then
            if wget --quiet --output-document="$dest" "$url" 2>/dev/null; then
                return 0
            fi
        fi

        if [ "$attempt" -lt "$MAX_RETRIES" ]; then
            local wait_secs=$((attempt * 2))
            warn "Download failed (attempt ${attempt}/${MAX_RETRIES}), retrying in ${wait_secs}s..."
            sleep "$wait_secs"
        fi
    done

    error "Failed to download ${url} after ${MAX_RETRIES} attempts"
}

# Fetch URL content to stdout (for API calls)
fetch() {
    local url="$1"

    if has_curl; then
        curl --fail --silent --show-error --location "$url"
    elif has_wget; then
        wget --quiet --output-document=- "$url"
    fi
}

# ── Version resolution ──────────────────────────────────────

get_latest_version() {
    local url="https://api.github.com/repos/${REPO}/releases/latest"
    local response version

    response=$(fetch "$url" 2>/dev/null) || true

    if [ -z "$response" ]; then
        error "Failed to fetch latest version. GitHub API may be rate-limited.\n  Try specifying a version: --version v0.1.0\n  Releases: https://github.com/${REPO}/releases"
    fi

    version=$(echo "$response" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')

    if [ -z "$version" ]; then
        error "Failed to parse latest version from GitHub API response.\n  Check: https://github.com/${REPO}/releases"
    fi

    echo "$version"
}

# ── Checksum verification ──────────────────────────────────

verify_checksum() {
    local tmp_dir="$1" archive_name="$2"

    if command -v sha256sum &>/dev/null; then
        (cd "$tmp_dir" && grep "${archive_name}" checksums.txt | sha256sum -c - >/dev/null 2>&1)
    elif command -v shasum &>/dev/null; then
        (cd "$tmp_dir" && grep "${archive_name}" checksums.txt | shasum -a 256 -c - >/dev/null 2>&1)
    elif command -v openssl &>/dev/null; then
        local expected actual
        expected=$(grep "${archive_name}" "${tmp_dir}/checksums.txt" | awk '{print $1}')
        actual=$(openssl dgst -sha256 "${tmp_dir}/${archive_name}" | awk '{print $NF}')
        [ "$expected" = "$actual" ]
    else
        warn "No checksum tool found (sha256sum, shasum, openssl). Skipping verification."
        return 0
    fi
}

# ── Existing installation check ─────────────────────────────

check_existing() {
    local target="${INSTALL_DIR}/${BINARY_NAME}"

    if [ ! -x "$target" ]; then
        return 0
    fi

    local current_version
    current_version=$("$target" version 2>/dev/null || "$target" --version 2>/dev/null || echo "")

    if [ -n "$current_version" ]; then
        info "Existing installation detected: ${current_version}"
    else
        info "Existing installation detected at ${target}"
    fi
}

# ── PATH check ──────────────────────────────────────────────

check_path() {
    case ":${PATH}:" in
        *":${INSTALL_DIR}:"*)
            return 0
            ;;
    esac

    warn "${INSTALL_DIR} is not in your PATH"
    echo ""
    echo "  Add it to your shell profile:"
    echo ""

    local shell_name
    shell_name="$(basename "${SHELL:-/bin/bash}")"

    case "$shell_name" in
        zsh)
            echo "    echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> ~/.zshrc"
            echo "    source ~/.zshrc"
            ;;
        bash)
            echo "    echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> ~/.bashrc"
            echo "    source ~/.bashrc"
            ;;
        fish)
            echo "    echo 'fish_add_path ${INSTALL_DIR}' >> ~/.config/fish/config.fish"
            echo "    source ~/.config/fish/config.fish"
            ;;
        *)
            echo "    export PATH=\"${INSTALL_DIR}:\$PATH\""
            ;;
    esac
    echo ""
}

# ── Main ────────────────────────────────────────────────────

main() {
    parse_args "$@"

    info "Conalog CLI Installer"

    check_download_tool

    local platform version archive_name download_url checksum_url tmp_dir

    platform=$(detect_platform)
    info "Platform: ${platform}"

    if [ -n "$VERSION" ]; then
        version="$VERSION"
        # Ensure version starts with 'v'
        case "$version" in
            v*) ;;
            *)  version="v${version}" ;;
        esac
    else
        version=$(get_latest_version)
    fi
    info "Version: ${version}"

    check_existing

    local ver_no_v="${version#v}"
    archive_name="${BINARY_NAME}_${ver_no_v}_${platform}.tar.gz"
    download_url="https://github.com/${REPO}/releases/download/${version}/${archive_name}"
    checksum_url="https://github.com/${REPO}/releases/download/${version}/checksums.txt"

    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT

    info "Downloading ${archive_name}..."
    download "$checksum_url" "${tmp_dir}/checksums.txt"
    download "$download_url" "${tmp_dir}/${archive_name}"

    info "Verifying checksum..."
    if ! verify_checksum "$tmp_dir" "$archive_name"; then
        error "Checksum verification failed! The download may be corrupted or tampered with."
    fi
    info "Checksum verified"

    info "Extracting..."
    tar -xzf "${tmp_dir}/${archive_name}" -C "$tmp_dir"

    # Create install directory if it doesn't exist (for custom dirs like ~/.local/bin)
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
    fi

    info "Installing to ${INSTALL_DIR}/${BINARY_NAME}..."
    if [ -w "$INSTALL_DIR" ]; then
        install -m 755 "${tmp_dir}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
    else
        sudo install -m 755 "${tmp_dir}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
    fi

    success "Installed conalog ${version}"

    check_path

    echo "Next steps:"
    echo "  1. conalog login          # Authenticate with Google"
    echo "  2. conalog list            # Browse available packages"
    echo "  3. conalog install <name>  # Install a package"
    echo ""
}

main "$@"

} # End of wrapping braces — do not remove.
