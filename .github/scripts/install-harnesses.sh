#!/usr/bin/env bash
# Install every skore-cli harness using vendor artifacts (not PATH stubs).
set -euo pipefail

OS="${RUNNER_OS:-$(uname -s)}"

append_path() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    echo "$dir" >> "${GITHUB_PATH:-/dev/null}"
    export PATH="$dir:$PATH"
  fi
}

need_cmd() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "missing required command: $name" >&2
    exit 1
  fi
}

install_claude() {
  case "$OS" in
    Windows)
      powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
        "irm https://claude.ai/install.ps1 | iex"
      ;;
    *)
      curl -fsSL https://claude.ai/install.sh | bash
      ;;
  esac
}

install_opencode() {
  case "$OS" in
    Windows)
      npm install -g opencode-ai
      ;;
    *)
      curl -fsSL https://opencode.ai/install | bash
      ;;
  esac
}

install_pi() {
  case "$OS" in
    Windows)
      powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
        "irm https://pi.dev/install.ps1 | iex"
      ;;
    *)
      curl -fsSL https://pi.dev/install.sh | sh
      ;;
  esac
}

install_codex() {
  npm install -g @openai/codex
}

install_vscode() {
  case "$OS" in
    Linux)
      curl -fsSL "https://update.code.visualstudio.com/latest/linux-deb-x64/stable" \
        -o /tmp/vscode.deb
      sudo apt-get update
      sudo apt-get install -y /tmp/vscode.deb
      ;;
    macOS)
      brew install --cask visual-studio-code
      ;;
    Windows)
      winget install --id Microsoft.VisualStudioCode -e --disable-interactivity \
        --accept-package-agreements --accept-source-agreements
      ;;
    *)
      echo "unsupported OS for VS Code: $OS" >&2
      exit 1
      ;;
  esac
}

install_cursor() {
  case "$OS" in
    Linux)
      python3 - <<'PY'
import json, urllib.request, pathlib
url = "https://cursor.com/api/download?platform=linux-x64&releaseTrack=stable"
with urllib.request.urlopen(url) as response:
    data = json.load(response)
deb = data.get("debUrl")
if not deb:
    raise SystemExit("cursor API did not return debUrl")
path = pathlib.Path("/tmp/cursor.deb")
with urllib.request.urlopen(deb) as response:
    path.write_bytes(response.read())
print(path)
PY
      sudo apt-get install -y /tmp/cursor.deb
      ;;
    macOS)
      brew install --cask cursor
      ;;
    Windows)
      winget install --id Anysphere.Cursor -e --disable-interactivity \
        --accept-package-agreements --accept-source-agreements
      ;;
    *)
      echo "unsupported OS for Cursor: $OS" >&2
      exit 1
      ;;
  esac
}

install_bob_shell() {
  case "$OS" in
    Windows)
      powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
        "irm -Uri https://bob.ibm.com/download/bobshell.ps1 | iex"
      ;;
    *)
      curl -fsSL https://bob.ibm.com/download/bobshell.sh | bash
      ;;
  esac
}

install_bob_ide() {
  # IBM Bob IDE is a desktop package. Query params match the public download page.
  local dest="/tmp/bob-ide-installer"
  local url
  case "$OS" in
    Linux)
      url="https://bob.ibm.com/download?bob=ide&os=linux&arch=amd64&format=deb"
      curl -fsSL "$url" -o "${dest}.deb"
      sudo apt-get install -y "${dest}.deb"
      ;;
    macOS)
      local arch
      arch="$(uname -m)"
      if [[ "$arch" == "arm64" ]]; then
        url="https://bob.ibm.com/download?bob=ide&os=macos&arch=arm64&format=pkg"
      else
        url="https://bob.ibm.com/download?bob=ide&os=macos&arch=x64&format=pkg"
      fi
      curl -fsSL "$url" -o "${dest}.pkg"
      sudo installer -pkg "${dest}.pkg" -target /
      ;;
    Windows)
      url="https://bob.ibm.com/download?bob=ide&os=windows&arch=x64&format=exe"
      curl -fsSL "$url" -o "${dest}.exe"
      installer="$(cygpath -w "${dest}.exe")"
      powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
        "Start-Process -FilePath '${installer}' -ArgumentList '/S' -Wait"
      ;;
    *)
      echo "unsupported OS for Bob IDE: $OS" >&2
      exit 1
      ;;
  esac
}

install_claude
install_opencode
install_pi
install_codex
install_vscode
install_cursor
install_bob_shell
install_bob_ide

append_path "$HOME/.local/bin"
append_path "$HOME/.opencode/bin"
append_path "$HOME/.cursor/bin"
append_path "$HOME/bin"
if command -v npm >/dev/null 2>&1; then
  append_path "$(npm prefix -g)/bin"
fi
if [[ "$OS" == "Windows" ]]; then
  append_path "${LOCALAPPDATA:-}/Programs/Microsoft VS Code/bin"
  append_path "${LOCALAPPDATA:-}/Programs/cursor"
  append_path "/c/Program Files/Microsoft VS Code/bin"
  append_path "/c/Program Files/cursor"
  append_path "${LOCALAPPDATA:-}/Programs/IBM Bob"
  append_path "/c/Program Files/IBM Bob"
fi

need_cmd claude
need_cmd opencode
need_cmd pi
need_cmd codex
need_cmd cursor
need_cmd bob
if ! command -v code >/dev/null 2>&1 && ! command -v code-insiders >/dev/null 2>&1; then
  echo "missing required command: code or code-insiders" >&2
  exit 1
fi

case "$OS" in
  macOS)
    if [[ ! -d "/Applications/IBM Bob.app" ]]; then
      echo "missing Bob IDE app bundle at /Applications/IBM Bob.app" >&2
      exit 1
    fi
    ;;
  *)
    need_cmd bobide
    ;;
esac

echo "harness binaries are on PATH"
command -v claude
command -v opencode
command -v pi
command -v codex
command -v cursor
command -v bob
command -v code || command -v code-insiders
if [[ "$OS" != "macOS" ]]; then
  command -v bobide
fi
