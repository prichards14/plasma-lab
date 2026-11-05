#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/plasma-verify.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT
xcrun clang -fobjc-arc -framework AppKit -framework ScreenSaver verify.m -o "$BUILD_DIR/verify"
"$BUILD_DIR/verify" "$(cd .. && pwd)/Plasma Lab.saver" "$(cd .. && pwd)/Preview.png" "$BUILD_DIR/Configured.saver"
codesign --verify --strict --verbose=2 "$BUILD_DIR/Configured.saver"
"$BUILD_DIR/verify" "$BUILD_DIR/Configured.saver" "$BUILD_DIR/configured.png" --exported
ditto --norsrc --noextattr "../Plasma Lab.saver" "$BUILD_DIR/Plasma Lab.saver"
ditto --norsrc --noextattr "../Plasma Lab Settings.app" "$BUILD_DIR/Plasma Lab Settings.app"
codesign --verify --strict --verbose=2 "$BUILD_DIR/Plasma Lab.saver"
codesign --verify --strict --verbose=2 "$BUILD_DIR/Plasma Lab Settings.app"
if [[ "${PLASMA_LAB_VERIFY_APP_UI:-0}" == "1" ]]; then
 "$BUILD_DIR/Plasma Lab Settings.app/Contents/MacOS/PlasmaLabSettings" --self-test
fi
xcrun lipo -archs "../Plasma Lab.saver/Contents/MacOS/PlasmaLab"
xcrun lipo -archs "../Plasma Lab Settings.app/Contents/MacOS/PlasmaLabSettings"
plutil -lint "../Plasma Lab.saver/Contents/Info.plist" "../Plasma Lab Settings.app/Contents/Info.plist"
