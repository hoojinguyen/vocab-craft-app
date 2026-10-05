#!/usr/bin/env bash
set -euo pipefail

# VocabCraft Physical Device Build & Run Script
# Builds, installs, and launches VocabCraftApp on a connected iOS device.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

SCHEME="VocabCraftApp"
WORKSPACE="VocabCraft.xcworkspace"
CONFIGURATION="Debug"
BUNDLE_ID="com.hoojinguyen.vocabcraft"
BUILD_DIR="$REPO_ROOT/.build/derived_data"
APP_PATH="$BUILD_DIR/Build/Products/Debug-iphoneos/VocabCraftApp.app"

echo "📱 VocabCraft Device Runner"
echo "============================="

# 1. Discover connected physical device
TARGET_DEVICE_NAME="${1:-Hooji}"
echo "🔍 Searching for device '${TARGET_DEVICE_NAME}'..."

# Query devicectl for available physical devices
DEVICE_LINE=$(xcrun devicectl list devices | grep -i "${TARGET_DEVICE_NAME}" | grep "physical" | head -n 1 || true)

if [ -z "$DEVICE_LINE" ]; then
    echo "⚠️ Device '${TARGET_DEVICE_NAME}' not found. Looking for any connected physical device..."
    DEVICE_LINE=$(xcrun devicectl list devices | grep "physical" | head -n 1 || true)
fi

if [ -z "$DEVICE_LINE" ]; then
    echo "❌ No physical iOS device found connected or paired."
    echo "   Please connect your iPhone via USB cable or ensure Wi-Fi sync is enabled,"
    echo "   unlock the device, and check: xcrun devicectl list devices"
    exit 1
fi

DEVICE_NAME=$(echo "$DEVICE_LINE" | awk '{print $1}')
DEVICE_UDID=$(echo "$DEVICE_LINE" | awk '{print $2}')

# Retrieve CoreDevice Identifier (UUID) for devicectl commands
DEVICE_UUID=$(xcrun devicectl device info details --device "$DEVICE_UDID" 2>/dev/null | grep -E "^• Identifier:" | head -n 1 | awk '{print $3}' || true)
if [ -z "$DEVICE_UUID" ]; then
    DEVICE_UUID="$DEVICE_UDID"
fi

echo "✅ Found Target Device: ${DEVICE_NAME}"
echo "   UDID: ${DEVICE_UDID}"
echo "   CoreDevice ID: ${DEVICE_UUID}"
echo ""

# 2. Build for device
echo "🔨 Building ${SCHEME} for ${DEVICE_NAME}..."
xcodebuild -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "id=${DEVICE_UDID}" \
    -derivedDataPath "$BUILD_DIR" \
    -allowProvisioningUpdates \
    build

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Build artifact not found at: ${APP_PATH}"
    exit 1
fi

echo "✅ Build succeeded! App binary: ${APP_PATH}"
echo ""

# 3. Install App to Device
echo "📦 Installing to ${DEVICE_NAME}..."
xcrun devicectl device install app --device "$DEVICE_UUID" "$APP_PATH"
echo "✅ App installed successfully!"
echo ""

# 4. Launch App
echo "🚀 Launching ${BUNDLE_ID} on ${DEVICE_NAME}..."
if xcrun devicectl device process launch --device "$DEVICE_UUID" --terminate-existing "$BUNDLE_ID"; then
    echo ""
    echo "🎉 VocabCraft launched successfully on ${DEVICE_NAME}!"
else
    echo ""
    echo "⚠️  Launch notice:"
    echo "   If this is the first time running on your device, iOS requires you to trust your Developer Profile:"
    echo "   👉 On your iPhone: Settings > General > VPN & Device Management"
    echo "   👉 Tap your Apple ID / Developer Certificate and tap 'Trust'"
    echo "   👉 Once trusted, tap the VocabCraft app icon on your Home Screen or re-run this script!"
fi
