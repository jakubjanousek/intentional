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

# Ad-hoc sign so SMAppService and Gatekeeper can identify the binary.
codesign --force --sign - --identifier "com.jakubjanousek.intentional" "$APP"

echo "→ done"
echo "   $(pwd)/$APP"
