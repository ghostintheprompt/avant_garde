#!/bin/bash

# Avant Garde DMG Build Script
# MDRN Corp — mdrn.app

APP_NAME="AvantGarde"
VERSION="1.0.1"
DMG_NAME="${APP_NAME}_v${VERSION}.dmg"
BUILD_DIR="build"
FINAL_DMG="${DMG_NAME}"
TEMP_DMG="${BUILD_DIR}/temp.dmg"

echo "--- Building Avant Garde v${VERSION} with Persistent Branding ---"

# Clean up
rm -rf "${BUILD_DIR}"
rm -f "${FINAL_DMG}"

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
echo "Regenerating project and building..."
xcodegen generate > /dev/null
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
    echo "Could not find app bundle."
    exit 1
fi

# 3. Inject .icns into bundle
mkdir -p "${APP_PATH}/Contents/Resources"
cp "${BUILD_DIR}/AppIcon.icns" "${APP_PATH}/Contents/Resources/AppIcon.icns"

# 4. Create DMG using Mounting Method (Ensures Icon Bits)
echo "Creating persistent DMG volume..."
DMG_SIZE_MB=$(du -sm "${APP_PATH}" | cut -f1)
DMG_SIZE=$((DMG_SIZE_MB + 10))

hdiutil create -megabytes ${DMG_SIZE} -fs HFS+ -volname "${APP_NAME}" -o "${TEMP_DMG}" > /dev/null

# Mount the DMG
echo "Mounting volume..."
MOUNT_PATH=$(hdiutil mount "${TEMP_DMG}" | tail -n1 | perl -ne 'if (/(\/Volumes\/.*)/) { print $1 }')

if [ -z "$MOUNT_PATH" ]; then
    echo "Failed to mount temp DMG."
    exit 1
fi

# Copy files to mounted volume
cp -R "${APP_PATH}" "${MOUNT_PATH}/"
ln -s /Applications "${MOUNT_PATH}/Applications"

# Set volume icon on the MOUNTED volume
cp "${BUILD_DIR}/AppIcon.icns" "${MOUNT_PATH}/.VolumeIcon.icns"
SetFile -a C "${MOUNT_PATH}"
SetFile -a v "${MOUNT_PATH}/.VolumeIcon.icns"

# Unmount
echo "Finalizing volume..."
hdiutil detach "${MOUNT_PATH}" > /dev/null
sleep 2

# Convert to final compressed DMG
hdiutil convert "${TEMP_DMG}" -format UDZO -o "${FINAL_DMG}" > /dev/null
rm "${TEMP_DMG}"

echo "---------------------------------------"
echo "Success: ${FINAL_DMG}"
echo "---------------------------------------"
