#!/usr/bin/env bash
# Kite Passport Installer
#
# Installs the kpass CLI binary and passport-skills to ~/.kpass/
#
# Usage:
#   curl -fsSL https://cli.gokite.ai/install.sh | bash
#   curl -fsSL https://cli.gokite.ai/install.sh | bash -s -- stable
#   curl -fsSL https://cli.gokite.ai/install.sh | bash -s -- 3
#
# Environment variables:
#   KPASS_INSTALL_DIR  Override install directory (default: ~/.kpass)
#   KPASS_BASE_URL     Override S3 base URL (for testing)
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────────
BASE_URL="${KPASS_BASE_URL:-https://cli.gokite.ai}"
INSTALL_DIR="${KPASS_INSTALL_DIR:-$HOME/.kpass}"
BIN_LINK_DIR="$HOME/.local/bin"
tmpdir=""

# ── Colors (disabled if not a terminal) ───────────────────────────────────────
if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

info()  { echo -e "${BLUE}=>${NC} $*"; }
ok()    { echo -e "${GREEN}=>${NC} $*"; }
warn()  { echo -e "${YELLOW}warning:${NC} $*" >&2; }
error() { echo -e "${RED}error:${NC} $*" >&2; }
die()   { error "$@"; exit 1; }

# ── Argument parsing ──────────────────────────────────────────────────────────
TARGET="${1:-latest}"
if [[ ! "$TARGET" =~ ^(stable|latest|[0-9]+)$ ]]; then
    echo "Kite Passport Installer"
    echo ""
    echo "Usage: install.sh [latest|stable|<bundle-version>]"
    echo ""
    echo "  latest    Install the latest bundle (default)"
    echo "  stable    Install the stable bundle"
    echo "  <number>  Install a specific bundle version"
    exit 1
fi

# ── OS / Architecture detection ───────────────────────────────────────────────
detect_platform() {
    local os arch

    case "$(uname -s)" in
        Darwin) os="darwin" ;;
        Linux)  os="linux" ;;
        MINGW*|MSYS*|CYGWIN*)
            die "Windows detected. Use install.ps1 instead:\n  irm https://cli.gokite.ai/install.ps1 | iex" ;;
        *)
            die "Unsupported operating system: $(uname -s)" ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        *)
            die "Unsupported architecture: $(uname -m)" ;;
    esac

    # Rosetta 2 detection: prefer native arm64 on Apple Silicon
    if [ "$os" = "darwin" ] && [ "$arch" = "amd64" ]; then
        if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = "1" ]; then
            arch="arm64"
        fi
    fi

    echo "${os}-${arch}"
}

# ── Download helper (curl preferred, wget fallback) ───────────────────────────
DOWNLOADER=""
detect_downloader() {
    if command -v curl &>/dev/null; then
        DOWNLOADER="curl"
    elif command -v wget &>/dev/null; then
        DOWNLOADER="wget"
    else
        die "curl or wget is required but neither was found"
    fi
}

# Download to stdout
download_text() {
    local url="$1"
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$url"
    else
        wget -qO- "$url"
    fi
}

# Download to file
download_file() {
    local url="$1" output="$2"
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL -o "$output" "$url"
    else
        wget -q -O "$output" "$url"
    fi
}

# ── Checksum verification ─────────────────────────────────────────────────────
verify_checksum() {
    local file="$1" expected="$2" actual

    # Strip sha256: prefix if present
    expected="${expected#sha256:}"

    if [ -z "$expected" ] || [ "$expected" = "null" ]; then
        warn "No checksum found in manifest, skipping verification for $(basename "$file")"
        return 0
    fi

    # Validate it looks like a hex sha256
    if [[ ! "$expected" =~ ^[a-f0-9]{64}$ ]]; then
        die "Invalid checksum format in manifest: $expected"
    fi

    if command -v shasum &>/dev/null; then
        actual=$(shasum -a 256 "$file" | cut -d' ' -f1)
    elif command -v sha256sum &>/dev/null; then
        actual=$(sha256sum "$file" | cut -d' ' -f1)
    else
        warn "No SHA256 tool found (shasum or sha256sum), skipping verification"
        return 0
    fi

    if [ "$actual" != "$expected" ]; then
        die "Checksum verification failed for $(basename "$file")\n  Expected: $expected\n  Actual:   $actual"
    fi
}

# ── JSON parsing (jq preferred, fallback to grep/sed) ─────────────────────────
HAS_JQ=false
detect_jq() {
    if command -v jq &>/dev/null; then
        HAS_JQ=true
    fi
}

# Extract a simple string value from JSON by key path
# Usage: json_extract "$json" '.cli.version'       (jq syntax)
#    or: json_extract "$json" 'version'             (flat key)
json_extract() {
    local json="$1" key="$2"
    if $HAS_JQ; then
        echo "$json" | jq -r "$key // empty" 2>/dev/null
    else
        # Simple fallback: works for flat keys like "version", "checksum"
        local simple_key="${key##*.}"
        simple_key="${simple_key//\"/}"
        echo "$json" | grep -o "\"${simple_key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | \
            head -1 | sed 's/.*:[[:space:]]*"//;s/"//'
    fi
}

# Extract platform-specific archive path and checksum from manifest
# These need jq for nested access; fallback constructs from convention
json_extract_platform_field() {
    local json="$1" section="$2" platform="$3" field="$4"
    if $HAS_JQ; then
        echo "$json" | jq -r ".${section}.platforms[\"$platform\"].$field // empty" 2>/dev/null
    else
        echo ""
    fi
}

# ── PATH setup ────────────────────────────────────────────────────────────────
setup_path() {
    mkdir -p "$BIN_LINK_DIR"
    ln -sf "$INSTALL_DIR/bin/kpass" "$BIN_LINK_DIR/kpass"
    ln -sf "$INSTALL_DIR/bin/ksearch" "$BIN_LINK_DIR/ksearch"

    # Check if already on PATH
    if echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_LINK_DIR"; then
        return 0
    fi

    local shell_rc=""
    case "${SHELL:-/bin/bash}" in
        */zsh)  shell_rc="$HOME/.zshrc" ;;
        */bash)
            # Prefer .bashrc, fall back to .bash_profile on macOS
            if [ -f "$HOME/.bashrc" ]; then
                shell_rc="$HOME/.bashrc"
            else
                shell_rc="$HOME/.bash_profile"
            fi
            ;;
        */fish) shell_rc="$HOME/.config/fish/config.fish" ;;
    esac

    if [ -n "$shell_rc" ]; then
        # Don't add if already present
        if [ -f "$shell_rc" ] && grep -q "kpass" "$shell_rc" 2>/dev/null; then
            return 0
        fi

        # Create file if it doesn't exist
        touch "$shell_rc"

        echo "" >> "$shell_rc"
        echo "# Kite Passport" >> "$shell_rc"
        if [[ "$shell_rc" == *fish* ]]; then
            echo "set -gx PATH \"$BIN_LINK_DIR\" \$PATH" >> "$shell_rc"
        else
            echo "export PATH=\"$BIN_LINK_DIR:\$PATH\"" >> "$shell_rc"
        fi
        info "Added $BIN_LINK_DIR to PATH in $(basename "$shell_rc")"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}Kite Passport Installer${NC}"
    echo ""

    detect_downloader
    detect_jq

    local platform
    platform=$(detect_platform)
    info "Platform: $platform"

    # Resolve bundle version
    local bundle_version
    if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
        bundle_version="$TARGET"
    else
        info "Resolving $TARGET version..."
        bundle_version=$(download_text "$BASE_URL/$TARGET" 2>/dev/null) || \
            die "Failed to resolve '$TARGET' version from $BASE_URL/$TARGET"
        bundle_version=$(echo "$bundle_version" | tr -d '[:space:]')
    fi

    if [ -z "$bundle_version" ]; then
        die "Could not determine bundle version"
    fi

    info "Bundle version: $bundle_version"

    # Download manifest
    info "Fetching manifest..."
    local manifest
    manifest=$(download_text "$BASE_URL/bundle/${bundle_version}/manifest.json" 2>/dev/null) || \
        die "Failed to download manifest for bundle $bundle_version"

    local cli_version ksearch_version skills_version
    if $HAS_JQ; then
        cli_version=$(echo "$manifest" | jq -r '.cli.version')
        ksearch_version=$(echo "$manifest" | jq -r '.ksearch.version')
        skills_version=$(echo "$manifest" | jq -r '.skills.version')
    else
        cli_version=$(json_extract "$manifest" "version")
        ksearch_version=""
        skills_version=""
        warn "jq not found. Install jq for best results. Falling back to convention-based install."
    fi

    info "CLI version: $cli_version"
    info "ksearch version: $ksearch_version"
    info "Skills version: $skills_version"
    echo ""

    # Create temp directory (declared at script scope so the EXIT trap can access it)
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    # ── Download and verify CLI ───────────────────────────────────────────────
    local cli_archive cli_checksum
    if $HAS_JQ; then
        cli_archive=$(json_extract_platform_field "$manifest" "cli" "$platform" "archive")
        cli_checksum=$(json_extract_platform_field "$manifest" "cli" "$platform" "checksum")
    else
        # Convention-based fallback (matches GoReleaser naming)
        local go_os go_arch ext="tar.gz"
        go_os="${platform%-*}"
        go_arch="${platform#*-}"
        cli_archive="cli/kpass_${cli_version}_${go_os}_${go_arch}.${ext}"
        cli_checksum=""
    fi

    if [ -z "$cli_archive" ] || [ "$cli_archive" = "null" ]; then
        die "Platform $platform is not available in this release"
    fi

    info "Downloading CLI binary..."
    download_file "$BASE_URL/bundle/${bundle_version}/${cli_archive}" "$tmpdir/cli-archive" || \
        die "Failed to download CLI archive"

    if [ -n "$cli_checksum" ] && [ "$cli_checksum" != "null" ]; then
        info "Verifying CLI checksum..."
        verify_checksum "$tmpdir/cli-archive" "$cli_checksum"
        ok "CLI checksum verified"
    fi

    # ── Download and verify ksearch ──────────────────────────────────────────
    local ksearch_archive ksearch_checksum
    if $HAS_JQ; then
        ksearch_archive=$(json_extract_platform_field "$manifest" "ksearch" "$platform" "archive")
        ksearch_checksum=$(json_extract_platform_field "$manifest" "ksearch" "$platform" "checksum")
    else
        # Convention-based fallback
        local go_os_k go_arch_k ext_k="tar.gz"
        go_os_k="${platform%-*}"
        go_arch_k="${platform#*-}"
        ksearch_archive="ksearch/ksearch_${ksearch_version}_${go_os_k}_${go_arch_k}.${ext_k}"
        ksearch_checksum=""
    fi

    if [ -n "$ksearch_archive" ] && [ "$ksearch_archive" != "null" ]; then
        info "Downloading ksearch binary..."
        download_file "$BASE_URL/bundle/${bundle_version}/${ksearch_archive}" "$tmpdir/ksearch-archive" || \
            die "Failed to download ksearch archive"

        if [ -n "$ksearch_checksum" ] && [ "$ksearch_checksum" != "null" ]; then
            info "Verifying ksearch checksum..."
            verify_checksum "$tmpdir/ksearch-archive" "$ksearch_checksum"
            ok "ksearch checksum verified"
        fi
    else
        warn "ksearch not available for platform $platform, skipping"
    fi

    # ── Download and verify skills ────────────────────────────────────────────
    local skills_archive skills_checksum
    if $HAS_JQ; then
        skills_archive=$(echo "$manifest" | jq -r '.skills.archive // empty')
        skills_checksum=$(echo "$manifest" | jq -r '.skills.checksum // empty')
    else
        skills_archive="skills/passport-skills-${cli_version}.tar.gz"
        skills_checksum=""
    fi

    info "Downloading skills..."
    download_file "$BASE_URL/bundle/${bundle_version}/${skills_archive}" "$tmpdir/skills-archive" || \
        die "Failed to download skills archive"

    if [ -n "$skills_checksum" ] && [ "$skills_checksum" != "null" ]; then
        info "Verifying skills checksum..."
        verify_checksum "$tmpdir/skills-archive" "$skills_checksum"
        ok "Skills checksum verified"
    fi

    echo ""

    # ── Install ───────────────────────────────────────────────────────────────
    info "Installing to $INSTALL_DIR..."

    # CLI binary
    mkdir -p "$INSTALL_DIR/bin"
    if [[ "$cli_archive" == *.zip ]]; then
        unzip -qo "$tmpdir/cli-archive" -d "$tmpdir/cli-extracted"
    else
        mkdir -p "$tmpdir/cli-extracted"
        tar -xzf "$tmpdir/cli-archive" -C "$tmpdir/cli-extracted"
    fi
    # Find the binary (may be at root or in a subdirectory)
    local kpass_bin
    kpass_bin=$(find "$tmpdir/cli-extracted" -name "kpass" -type f | head -1)
    if [ -z "$kpass_bin" ]; then
        die "kpass binary not found in archive"
    fi
    cp "$kpass_bin" "$INSTALL_DIR/bin/kpass"
    chmod +x "$INSTALL_DIR/bin/kpass"

    # ksearch binary
    if [ -f "$tmpdir/ksearch-archive" ]; then
        if [[ "$ksearch_archive" == *.zip ]]; then
            unzip -qo "$tmpdir/ksearch-archive" -d "$tmpdir/ksearch-extracted"
        else
            mkdir -p "$tmpdir/ksearch-extracted"
            tar -xzf "$tmpdir/ksearch-archive" -C "$tmpdir/ksearch-extracted"
        fi
        local ksearch_bin
        ksearch_bin=$(find "$tmpdir/ksearch-extracted" -name "ksearch" -type f | head -1)
        if [ -z "$ksearch_bin" ]; then
            warn "ksearch binary not found in archive, skipping"
        else
            cp "$ksearch_bin" "$INSTALL_DIR/bin/ksearch"
            chmod +x "$INSTALL_DIR/bin/ksearch"
        fi
    fi

    # Skills
    mkdir -p "$INSTALL_DIR/skills"
    # Clear existing skills to avoid stale files
    rm -rf "$INSTALL_DIR/skills/"*
    tar -xzf "$tmpdir/skills-archive" -C "$INSTALL_DIR/skills/"

    # Version metadata
    cat > "$INSTALL_DIR/version.json" <<VEOF
{
  "bundle_version": ${bundle_version},
  "cli_version": "${cli_version}",
  "ksearch_version": "${ksearch_version}",
  "skills_version": "${skills_version}",
  "channel": "${TARGET}",
  "platform": "${platform}",
  "base_url": "${BASE_URL}",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
VEOF

    # PATH
    setup_path

    echo ""
    ok "${BOLD}Kite Passport installed successfully!${NC}"
    echo ""
    echo "  CLI:      $INSTALL_DIR/bin/kpass (v${cli_version})"
    echo "  ksearch:  $INSTALL_DIR/bin/ksearch (v${ksearch_version})"
    echo "  Skills:   $INSTALL_DIR/skills/ (v${skills_version})"
    echo ""

    # Verify the binary works
    if "$INSTALL_DIR/bin/kpass" --version &>/dev/null; then
        local installed_version
        installed_version=$("$INSTALL_DIR/bin/kpass" --version 2>/dev/null || echo "unknown")
        ok "Verified: $installed_version"
    fi

    echo ""
    if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_LINK_DIR"; then
        echo "  Restart your shell or run:"
        echo "    export PATH=\"$BIN_LINK_DIR:\$PATH\""
        echo ""
    fi
    echo "  Get started:"
    echo "    kpass --help"
    echo ""

    # ── Skills setup ──────────────────────────────────────────────────────────
    echo -e "${BOLD}────────────────────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}  Installing Kite Passport skills${NC}"
    echo -e "${BOLD}────────────────────────────────────────────────────────────────${NC}"
    echo ""

    # When a controlling terminal exists, delegate to the CLI's interactive
    # flow (huh TUI) — same scope picker, agent multi-select, and confirmation
    # the user gets from `kpass skills setup` directly. huh opens its own TTY,
    # so no stdin redirection is needed.
    # Without a TTY (CI, fully piped), default to a global install so skills
    # are available across every project.
    if (: < /dev/tty) 2>/dev/null; then
        "$INSTALL_DIR/bin/kpass" skills setup || \
            warn "Skills setup did not complete. Rerun with: kpass skills setup"
    else
        info "No interactive terminal detected — defaulting to global install."
        "$INSTALL_DIR/bin/kpass" skills setup --global --no-interactive || \
            warn "Skills setup did not complete. Rerun with: kpass skills setup"
    fi
}

main
