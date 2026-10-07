#!/bin/bash
set -e

ZST_FILE="$1"
DEVICE_NAME="Hooji"
DEVICE_ID="00008140-0009646C0AC0801C"
APP_BUNDLE_ID="com.hoojinguyen.vocabcraft"
DEST_SQLITE="VocabCraftApp/Resources/Content/vocab_content.sqlite"

if [ -z "$ZST_FILE" ]; then
    echo "Error: No database file provided."
    echo "Usage: make deploy-db DB_FILE=/path/to/file.sqlite.zst"
    exit 1
fi

if [ ! -f "$ZST_FILE" ]; then
    echo "Error: File $ZST_FILE does not exist."
    exit 1
fi

echo "🚀 [1/5] Decompressing database..."
rm -f "$DEST_SQLITE"
# Check if it's zst by extension
if [[ "$ZST_FILE" == *.zst ]]; then
    zstd -d "$ZST_FILE" -o "$DEST_SQLITE"
else
    # if not compressed, just copy
    cp "$ZST_FILE" "$DEST_SQLITE"
fi

echo "🚀 [2/5] Building VocabCraftApp..."
xcodebuild build -scheme VocabCraftApp -destination "id=$DEVICE_ID" | xcpretty || xcodebuild build -scheme VocabCraftApp -destination "id=$DEVICE_ID"

echo "🚀 [3/5] Locating App Bundle..."
BUILD_DIR=$(xcodebuild -scheme VocabCraftApp -destination "id=$DEVICE_ID" -showBuildSettings | grep " TARGET_BUILD_DIR =" | awk -F'=' '{print $2}' | xargs)
APP_PATH="$BUILD_DIR/VocabCraftApp.app"

echo "🚀 [4/5] Installing App to Device '$DEVICE_NAME'..."
xcrun devicectl device install app --device "$DEVICE_NAME" "$APP_PATH"

echo "🚀 [5/5] Launching App..."
xcrun devicectl device process launch --device "$DEVICE_NAME" "$APP_BUNDLE_ID"

echo "✅ Deployment Successful!"
