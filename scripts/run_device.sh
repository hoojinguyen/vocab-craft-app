#!/bin/bash
set -e

WORKSPACE="VocabCraft.xcworkspace"
SCHEME="VocabCraftApp"
APP_NAME="VocabCraftApp"
BUNDLE_ID="com.hoojinguyen.vocabcraft"
DERIVED_DATA=".build/derivedData"

# Find the first connected/paired physical iPhone
DEVICE_ID=$(xcrun devicectl list devices | grep physical | grep iPhone | grep -E -o '[0-9a-fA-F\-]{24,40}' | head -n 1)

if [ -z "$DEVICE_ID" ]; then
    echo "❌ No physical iPhone connected or paired."
    exit 1
fi

echo "📱 Found device: $DEVICE_ID"

echo "🔨 Building $APP_NAME for device..."
if command -v xcpretty &> /dev/null; then
    xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -destination "id=$DEVICE_ID" -derivedDataPath "$DERIVED_DATA" build | xcpretty
else
    xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -destination "id=$DEVICE_ID" -derivedDataPath "$DERIVED_DATA" build -quiet
fi

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphoneos/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App build failed, cannot find $APP_PATH"
    exit 1
fi

echo "📲 Installing app on $DEVICE_ID..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "🚀 Launching $APP_NAME..."
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID"

echo "✅ Done!"
