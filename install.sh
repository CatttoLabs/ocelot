#!/usr/bin/env bash
set -Eeuo pipefail

#######################################
# CONFIG
#######################################
REPO="catttolabs/ocelot"
INSTALL_DIR="$HOME/.ocelot/bin"
GITHUB_API="https://api.github.com/repos/$REPO/releases"
CURL_OPTS=(-fsSL)
START_TIME=$(date +%s)

#######################################
# COLORS & UI
#######################################
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
PURPLE=$'\033[35m'
CYAN=$'\033[36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

log()    { echo -e "${CYAN}→${RESET} $*"; }
success(){ echo -e "${GREEN}✔${RESET} $*"; }
warn()   { echo -e "${YELLOW}⚠${RESET} $*"; }
error()  { echo -e "${RED}✖${RESET} $*" >&2; }
die()    { error "$1"; exit 1; }

#######################################
# ERROR TRAP
#######################################
trap 'echo -e "${RED}✖${RESET} Installation failed. See output above." >&2; exit 1' ERR

#######################################
# ARG PARSING
#######################################
VERSION="latest"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      [[ -z "$VERSION" ]] && die "--version requires a value"
      shift 2
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      shift
      ;;
  esac
done

#######################################
# DEPENDENCY CHECKS
#######################################
command -v curl >/dev/null 2>&1 || die "curl is required"
command -v uname >/dev/null 2>&1 || die "uname is required"

#######################################
# DETECT OS / ARCH
#######################################
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$OS" in
  linux) OS="linux" ;;
  darwin) OS="macos" ;;
  *)
    die "Unsupported OS: $OS"
    ;;
esac

case "$ARCH" in
  x86_64|amd64) ARCH="x86_64" ;;
  arm64|aarch64) ARCH="aarch64" ;;
  *)
    die "Unsupported architecture: $ARCH"
    ;;
esac

BINARY="ocelot-$OS-$ARCH"

#######################################
# OUTPUT BANNER
#######################################
cat <<EOF
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⡴⣆⠀⠀⠀⠀⠀⣠⡀⠀⠀⠀⠀⠀⠀⣼⣿⡗⠀⠀⠀⠀
⠀⠀⠀⣠⠟⠀⠘⠷⠶⠶⠶⠾⠉⢳⡄⠀⠀⠀⠀⠀⣧⣿⠀⠀⠀⠀⠀
⠀⠀⣰⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣤⣤⣤⣤⣤⣿⢿⣄⠀⠀⠀⠀
⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣧⠀⠀⠀⠀⠀⠀⠙⣷⡴⠶⣦        ${DIM}ocelot${RESET}
⠀⠀⢱⡀⠀⠉⠉⠀⠀⠀⠀⠛⠃⠀⢠⡟⠀⠀⠀⢀⣀⣠⣤⠿⠞⠛⠋        ${BOLD}installer${RESET}
⣠⠾⠋⠙⣶⣤⣤⣤⣤⣤⣀⣠⣤⣾⣿⠴⠶⠚⠋⠉⠁⠀⠀⠀⠀⠀⠀       
⠛⠒⠛⠉⠉⠀⠀⠀⣴⠟⢃⡴⠛⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠛⠛⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
EOF

#######################################
# FETCH RELEASE INFO
#######################################
log "Resolving release ${BOLD}$VERSION${RESET}…"

if [[ "$VERSION" == "latest" ]]; then
  RELEASE_JSON="$(curl "${CURL_OPTS[@]}" "$GITHUB_API/latest")"
else
  RELEASE_JSON="$(curl "${CURL_OPTS[@]}" "$GITHUB_API/tags/$VERSION")"
fi

TAG="$(echo "$RELEASE_JSON" | grep -m1 '"tag_name"' | cut -d '"' -f4)"
[[ -z "$TAG" ]] && die "Unable to resolve release tag"

success "Latest release: ${BOLD}$TAG${RESET}"

#######################################
# RESOLVE DOWNLOAD URL
#######################################
ASSET_URL="$(echo "$RELEASE_JSON" \
  | grep -E "\"browser_download_url\".*$BINARY\"" \
  | cut -d '"' -f4)"

[[ -z "$ASSET_URL" ]] && die "No binary found for $OS/$ARCH"

#######################################
# INSTALL
#######################################
log "Installing ${BOLD}$BINARY${RESET}"

mkdir -p "$INSTALL_DIR"

TMP="$(mktemp)"
curl "${CURL_OPTS[@]}" -o "$TMP" "$ASSET_URL"
chmod +x "$TMP"
mv "$TMP" "$INSTALL_DIR/ocelot"

#######################################
# PATH SETUP
#######################################
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
  SHELL_NAME="$(basename "${SHELL:-sh}")"
  PROFILE=""

  case "$SHELL_NAME" in
    bash) PROFILE="$HOME/.bashrc" ;;
    zsh)  PROFILE="$HOME/.zshrc" ;;
    fish) PROFILE="$HOME/.config/fish/config.fish" ;;
  esac

  if [[ -n "$PROFILE" ]]; then
    log "Adding ocelot to PATH in $PROFILE"
    if [[ "$SHELL_NAME" == "fish" ]]; then
      echo "set -gx PATH $INSTALL_DIR \$PATH" >> "$PROFILE"
    else
      echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$PROFILE"
    fi
  else
    warn "Could not detect shell profile; add $INSTALL_DIR to PATH manually"
  fi
fi

#######################################
# FINISH
#######################################
END_TIME=$(date +%s)
TOOK=$((END_TIME - START_TIME))

echo
success "${BOLD}Ocelot installed successfully${RESET}"
echo -e "${DIM}  Version:${RESET} $TAG"
echo -e "${DIM}  Binary:${RESET}  $INSTALL_DIR/ocelot"
echo -e "${DIM}  Took:${RESET}    ${TOOK}s"
echo
echo -e "${PURPLE}Run:${RESET} ocelot --help"
