#!/bin/bash

# Avant Garde DMG Build Script
# MDRN Corp — mdrn.app

APP_NAME="AvantGarde"
VERSION="1.0.1"
DMG_NAME="${APP_NAME}_v${VERSION}.dmg"
BUILD_DIR="build"

echo "--- Building Avant Garde v${VERSION} with Branded Icons ---"

# Clean up
rm -rf "${BUILD_DIR}"
rm -f "${DMG_NAME}"

# 1. Generate .icns file
echo "Generating .icns file..."
ICON_SET="${BUILD_DIR}/icon.iconset"
mkdir -p "${ICON_SET}"
SOURCE_PNG="Resources/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png"

sips -z 16 16     "${SOURCE_PNG}" --out "${ICON_SET}/icon_16x16.png" > /dev/null
sips -z 32 32     "${SOURCE_PNG}" --out "${ICON_SET}/icon_16x16@2x.png" > /dev/null
sips -z 32 32     "${SOURCE_PNG}" --out "${ICON_SET}/icon_32x32.png" > /dev/null
sips -z 64 64     "${SOURCE_PNG}" --out "${ICON_SET}/icon_32x32@2x.png" > /dev/null
sips -z 128 128   "${SOURCE_PNG}" --out "${ICON_SET}/icon_128x128.png" > /dev/null
sips -z 256 256   "${SOURCE_PNG}" --out "${ICON_SET}/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "${SOURCE_PNG}" --out "${ICON_SET}/icon_256x256.png" > /dev/null
sips -z 512 512   "${SOURCE_PNG}" --out "${ICON_SET}/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "${SOURCE_PNG}" --out "${ICON_SET}/icon_512x512.png" > /dev/null
sips -z 1024 1024 "${SOURCE_PNG}" --out "${ICON_SET}/icon_512x512@2x.png" > /dev/null

iconutil -c icns "${ICON_SET}" -o "${BUILD_DIR}/AppIcon.icns"

# 2. Build the app
echo "Building target..."
xcodegen generate
xcodebuild -project "${APP_NAME}.xcodeproj" \
    -scheme "${APP_NAME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    build | grep -E "error:|warning:|succeeded"

APP_PATH=$(find "${BUILD_DIR}" -name "${APP_NAME}.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "Could not find ${APP_NAME}.app bundle."
    exit 1
fi

echo "Found app at: ${APP_PATH}"

# 3. Inject the .icns
mkdir -p "${APP_PATH}/Contents/Resources"
cp "${BUILD_DIR}/AppIcon.icns" "${APP_PATH}/Contents/Resources/AppIcon.icns"

# 4. Create DMG
echo "Packaging into DMG..."
DMG_STAGING="${BUILD_DIR}/dmg"
mkdir -p "${DMG_STAGING}"
cp -R "${APP_PATH}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

# Volume Icon
cp "${BUILD_DIR}/AppIcon.icns" "${DMG_STAGING}/.VolumeIcon.icns"
SetFile -a C "${DMG_STAGING}"

hdiutil create -volname "${APP_NAME}" -srcfolder "${DMG_STAGING}" -ov -format UDZO "${DMG_NAME}"

echo "---------------------------------------"
echo "Success: ${DMG_NAME}"
echo "---------------------------------------"
