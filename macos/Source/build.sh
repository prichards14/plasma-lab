#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/plasma-build.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT
DEST="$BUILD_DIR/Plasma Lab.saver"
mkdir -p "$DEST/Contents/MacOS" "$DEST/Contents/Resources"
SDK="$(xcrun --show-sdk-path)"
for ARCH in arm64 x86_64; do
 xcrun swiftc -swift-version 5 -O -emit-library -module-name PlasmaLab -module-cache-path "$BUILD_DIR/cache" -target "$ARCH-apple-macosx14.0" -sdk "$SDK" -framework AppKit -framework ScreenSaver PlasmaSaver.swift -o "$BUILD_DIR/PlasmaLab-$ARCH"
done
xcrun lipo -create "$BUILD_DIR/PlasmaLab-arm64" "$BUILD_DIR/PlasmaLab-x86_64" -output "$DEST/Contents/MacOS/PlasmaLab"
cp Info.plist "$DEST/Contents/Info.plist"
# Finder may add metadata to bundles in synced Documents folders.
xattr -dr com.apple.FinderInfo "$DEST" 2>/dev/null || true
xattr -dr com.apple.ResourceFork "$DEST" 2>/dev/null || true
codesign --force --sign - "$DEST"
ditto --norsrc --noextattr "$DEST" "../Plasma Lab.saver"
echo "Built Plasma Lab.saver (Apple silicon + Intel)."
APP="$BUILD_DIR/Plasma Lab Settings.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
for ARCH in arm64 x86_64; do
 xcrun clang -fobjc-arc -arch "$ARCH" -mmacosx-version-min=14.0 -framework AppKit SettingsMain.m -o "$BUILD_DIR/Settings-$ARCH"
done
xcrun lipo -create "$BUILD_DIR/Settings-arm64" "$BUILD_DIR/Settings-x86_64" -output "$APP/Contents/MacOS/PlasmaLabSettings"
cp SettingsInfo.plist "$APP/Contents/Info.plist"
# Copy without file-provider metadata; preserve the signed template.
ditto --norsrc --noextattr "$DEST" "$APP/Contents/Resources/Plasma Lab.saver"
xattr -dr com.apple.FinderInfo "$APP" 2>/dev/null || true
xattr -dr com.apple.ResourceFork "$APP" 2>/dev/null || true
codesign --force --sign - "$APP"
ditto --norsrc --noextattr "$APP" "../Plasma Lab Settings.app"
echo "Built Plasma Lab Settings.app (Apple silicon + Intel)."
