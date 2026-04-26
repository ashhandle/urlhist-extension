#!/usr/bin/env bash
# Usage: ./install.sh <CHROME_EXTENSION_ID>
# Registers the native messaging host for Chrome and/or Edge on macOS/Linux.

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <EXTENSION_ID>"
  echo "  Find your Extension ID at chrome://extensions after loading the extension."
  exit 1
fi

EXTENSION_ID="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST_SCRIPT="$SCRIPT_DIR/native-host/urlhist_host.py"
HOST_JSON_TEMPLATE="$SCRIPT_DIR/native-host/com.urlhist.host.json"
HOST_NAME="com.urlhist.host"

# Make the Python host executable
chmod +x "$HOST_SCRIPT"

# Ensure Python 3 shebang works
PYTHON=$(command -v python3 || command -v python)
if [ -z "$PYTHON" ]; then
  echo "Error: Python 3 is required but not found in PATH."
  exit 1
fi
sed -i.bak "1s|.*|#!${PYTHON}|" "$HOST_SCRIPT" && rm -f "${HOST_SCRIPT}.bak"

# Build the resolved JSON manifest
RESOLVED_JSON=$(
  sed \
    -e "s|__PLACEHOLDER__|${HOST_SCRIPT}|g" \
    -e "s|__EXTENSION_ID__|${EXTENSION_ID}|g" \
    "$HOST_JSON_TEMPLATE"
)

install_for_browser() {
  local BROWSER_NAME="$1"
  local HOSTS_DIR="$2"

  if [ -d "$(dirname "$HOSTS_DIR")" ]; then
    mkdir -p "$HOSTS_DIR"
    echo "$RESOLVED_JSON" > "$HOSTS_DIR/${HOST_NAME}.json"
    echo "[OK] Installed for $BROWSER_NAME: $HOSTS_DIR/${HOST_NAME}.json"
  else
    echo "[SKIP] $BROWSER_NAME not found ($(dirname "$HOSTS_DIR") does not exist)"
  fi
}

# macOS paths
install_for_browser "Google Chrome" \
  "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"

install_for_browser "Microsoft Edge" \
  "$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"

# Linux paths (also checked on macOS — harmless if absent)
install_for_browser "Google Chrome (Linux)" \
  "$HOME/.config/google-chrome/NativeMessagingHosts"

install_for_browser "Chromium (Linux)" \
  "$HOME/.config/chromium/NativeMessagingHosts"

echo ""
echo "Done. Restart Chrome/Edge, then browse — URLs will be appended to:"
python3 -c "import tempfile; print(tempfile.gettempdir() + '/URLHIST.txt')" 2>/dev/null \
  || echo "  <OS temp dir>/URLHIST.txt"
