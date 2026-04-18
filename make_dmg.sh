#!/bin/bash

# Avant Garde DMG Build Script
# MDRN Corp — mdrn.app

APP_NAME="AvantGarde"
VERSION="1.0.1"
DMG_NAME="${APP_NAME}_v${VERSION}.dmg"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/Release-iphoneos/${APP_NAME}.app" 

# Note: project.yml specifies iOS platform. 
# For a true macOS build, the platform in project.yml should be macOS.
# This script builds based on current project settings.

echo "--- Building Avant Garde v${VERSION} ---"

# Clean up
rm -rf "${BUILD_DIR}"
rm -f "${DMG_NAME}"

# Build
echo "Building target..."
xcodebuild -project "${APP_NAME}.xcodeproj" \
    -scheme "${APP_NAME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    build | tee "${BUILD_DIR}/build.log" | grep -E "error:|warning:|succeeded"

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo "Build failed. Check ${BUILD_DIR}/build.log"
    exit 1
fi

# Find the app bundle (it might be in a different subfolder depending on platform)
APP_PATH=$(find "${BUILD_DIR}" -name "${APP_NAME}.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "Could not find ${APP_NAME}.app bundle."
    exit 1
fi

echo "Found app at: ${APP_PATH}"

# Create DMG
echo "Packaging into DMG..."
mkdir -p "${BUILD_DIR}/dmg"
cp -R "${APP_PATH}" "${BUILD_DIR}/dmg/"
ln -s /Applications "${BUILD_DIR}/dmg/Applications"

hdiutil create -volname "${APP_NAME} ${VERSION}" -srcfolder "${BUILD_DIR}/dmg" -ov -format UDZO "${DMG_NAME}"

echo "---------------------------------------"
echo "Success: ${DMG_NAME}"
echo "---------------------------------------"
