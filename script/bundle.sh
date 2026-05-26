#!/usr/bin/env bash
# Build Intentional.app — a minimal macOS app bundle wrapping the SwiftPM
# release binary. Drop the resulting .app into /Applications (or anywhere
# stable on disk) before enabling Launch at Login.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${1:-release}"
APP="Intentional.app"
BINARY=".build/${CONFIG}/Intentional"
INFO_PLIST="script/Info.plist"

echo "→ swift build -c ${CONFIG}"
swift build -c "$CONFIG"

if [[ ! -f "$BINARY" ]]; then
    echo "Build did not produce $BINARY" >&2
    exit 1
fi

echo "→ assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/Intentional"
cp "$INFO_PLIST" "$APP/Contents/Info.plist"

echo "→ rendering icon"
ICONSET_DIR="$(mktemp -d)/Intentional.iconset"
swift script/make-icon.swift "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$APP/Contents/Resources/Intentional.icns"
rm -rf "$(dirname "$ICONSET_DIR")"

# Ad-hoc sign so SMAppService and Gatekeeper can identify the binary.
codesign --force --sign - --identifier "com.jakubjanousek.intentional" "$APP"

DEST="/Applications/$APP"
echo "→ installing to $DEST"
if pgrep -x Intentional >/dev/null; then
    echo "   quitting running instance"
    osascript -e 'tell application "Intentional" to quit' 2>/dev/null || true
    # Wait briefly for graceful quit, then force.
    for _ in 1 2 3 4 5; do
        pgrep -x Intentional >/dev/null || break
        sleep 0.2
    done
    pkill -x Intentional 2>/dev/null || true
fi
rm -rf "$DEST"
cp -R "$APP" "$DEST"

echo "→ done"
echo "   $DEST"
