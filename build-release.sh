#!/bin/bash

set -e

APP_NAME="aztec-monitor"
SCHEME="aztec-monitor"
CONFIGURATION="Release"
DIST_DIR="dist"

echo "🔨 Building $APP_NAME..."

# Build the app
xcodebuild -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath build \
    -allowProvisioningUpdates \
    clean build

# Find the built app
BUILT_APP="build/Build/Products/$CONFIGURATION/$APP_NAME.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Build failed - app not found at $BUILT_APP"
    exit 1
fi

echo "📦 Creating distributable..."

# Create dist folder
mkdir -p "$DIST_DIR"

# Copy app to dist
rm -rf "$DIST_DIR/$APP_NAME.app"
cp -R "$BUILT_APP" "$DIST_DIR/"

# Create zip for sharing
cd "$DIST_DIR"
rm -f "$APP_NAME.zip"
zip -r -q "$APP_NAME.zip" "$APP_NAME.app"
cd ..

# Clean up build folder
echo "🧹 Cleaning up build artifacts..."
rm -rf build

echo ""
echo "✅ Build complete!"
echo ""
echo "Distributable files in '$DIST_DIR/':"
echo "  - $APP_NAME.app  (the app itself)"
echo "  - $APP_NAME.zip  (zipped for sharing)"
echo ""
echo "To share with friends:"
echo "  1. Send them '$DIST_DIR/$APP_NAME.zip'"
echo "  2. They unzip and drag to /Applications"
echo "  3. First launch: right-click → Open (to bypass Gatekeeper)"
echo ""
