#!/usr/bin/env bash
# Build a Finder-style macOS installer DMG (app + Applications drop target).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-$(grep '^version:' pubspec.yaml | sed 's/version: //;s/+.*//')}"
APP_NAME="Bamabin"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
DIST_DIR="dist"
DMG_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.dmg"
BG="assets/img/dmg_background.png"
ICON_PNG="macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png"

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "create-dmg is required. Install with: brew install create-dmg" >&2
  exit 1
fi

echo "==> Building macOS release..."
flutter build macos --release

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH" >&2
  exit 1
fi

if [[ ! -f "$BG" ]]; then
  echo "Missing $BG — generate it once, or re-run the packaging setup." >&2
  exit 1
fi

echo "==> Creating installer DMG..."
STAGE="$(mktemp -d)/stage"
ICON_DIR="$(mktemp -d)"
ICON_ICNS="${ICON_DIR}/AppIcon.icns"
mkdir -p "$DIST_DIR" "$STAGE"
rm -f "$DMG_PATH" "${DIST_DIR}"/rw.*.dmg

ditto "$APP_PATH" "$STAGE/${APP_NAME}.app"
sips -s format icns "$ICON_PNG" --out "$ICON_ICNS" >/dev/null

create_args=(
  --volname "Bamabin Installer"
  --volicon "$ICON_ICNS"
  --background "$BG"
  --window-pos 200 120
  --window-size 640 400
  --icon-size 128
  --icon "${APP_NAME}.app" 160 190
  --hide-extension "${APP_NAME}.app"
  --app-drop-link 480 190
  --no-internet-enable
)

set +e
create-dmg "${create_args[@]}" "$DMG_PATH" "$STAGE"
STATUS=$?
set -e

if [[ $STATUS -ne 0 || ! -f "$DMG_PATH" ]]; then
  echo "==> Finder styling timed out; creating DMG with Applications shortcut..."
  rm -f "$DMG_PATH" "${DIST_DIR}"/rw.*.dmg
  create-dmg "${create_args[@]}" --skip-jenkins "$DMG_PATH" "$STAGE"
fi

rm -rf "$(dirname "$STAGE")" "$ICON_DIR"

echo
echo "App: $APP_PATH"
echo "DMG: $DMG_PATH"
ls -lh "$DMG_PATH"
echo
echo "نصب: DMG را باز کنید و Bamabin را روی Applications بکشید، بعد DMG را Eject کنید."
