#!/usr/bin/env bash
# Launcher script for Fluffychat on NixOS
# This script sets up the necessary environment variables to run the built binary

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$SCRIPT_DIR/build/linux/x64/release/bundle"

if [ ! -f "$BUNDLE_DIR/fluffychat" ]; then
    echo "Error: fluffychat binary not found at $BUNDLE_DIR/fluffychat"
    echo "Please run: nix-shell shell.nix && flutter pub get && flutter build linux"
    exit 1
fi

# Set library path to include bundled libraries
export LD_LIBRARY_PATH="$BUNDLE_DIR/lib:$LD_LIBRARY_PATH"

# Run the application
exec "$BUNDLE_DIR/fluffychat" "$@"
