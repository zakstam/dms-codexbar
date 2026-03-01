#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="${HOME}/.config/DankMaterialShell/plugins/CodexBar"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dms-codexbar plugin..."

# Create plugin directory
mkdir -p "$PLUGIN_DIR"

# Copy plugin files
cp "$SCRIPT_DIR/plugin.json" "$PLUGIN_DIR/"
cp "$SCRIPT_DIR/CodexBarWidget.qml" "$PLUGIN_DIR/"
cp "$SCRIPT_DIR/CodexBarSettings.qml" "$PLUGIN_DIR/"

echo "Plugin files installed to $PLUGIN_DIR"

# Check for codexbar CLI
if command -v codexbar &>/dev/null; then
    echo "codexbar CLI found: $(command -v codexbar)"
elif [ -x "$HOME/.local/bin/codexbar" ]; then
    echo "codexbar CLI found: $HOME/.local/bin/codexbar"
else
    echo ""
    echo "WARNING: codexbar CLI not found."
    echo "Install it from: https://github.com/steipete/CodexBar/releases"
    echo ""
    echo "  # Example for Linux x86_64:"
    echo "  gh release download --repo steipete/CodexBar --pattern 'CodexBarCLI-*-linux-x86_64.tar.gz'"
    echo "  tar xzf CodexBarCLI-*-linux-x86_64.tar.gz"
    echo "  install -m 0755 CodexBarCLI ~/.local/bin/codexbar"
fi

echo ""
echo "Done! Restart Quickshell, then enable CodexBar in DMS Settings > Plugins."
