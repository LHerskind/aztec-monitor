#!/bin/bash

set -e

APP_NAME="aztec-governance-widget"
SCHEME="aztec-governance-widget"
CONFIGURATION="Release"
DESTINATION="/Applications"

echo "🔨 Building $APP_NAME..."

# Build the app
xcodebuild -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath build \
    clean build

# Find the built app
BUILT_APP="build/Build/Products/$CONFIGURATION/$APP_NAME.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Build failed - app not found at $BUILT_APP"
    exit 1
fi

echo "📦 Installing to $DESTINATION..."

# Remove old version if exists
if [ -d "$DESTINATION/$APP_NAME.app" ]; then
    echo "   Removing old version..."
    rm -rf "$DESTINATION/$APP_NAME.app"
fi

# Copy to Applications
cp -R "$BUILT_APP" "$DESTINATION/"

# Register with Launch Services (makes widget available)
echo "📝 Registering app..."
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f "$DESTINATION/$APP_NAME.app"

# Clean up build folder
echo "🧹 Cleaning up..."
rm -rf build

echo ""
echo "✅ Installation complete!"
echo ""
echo "To use the widget:"
echo "  1. Open '$APP_NAME' from Applications"
echo "  2. Configure your RPC endpoint and contract addresses"
echo "  3. Click 'Save Configuration' then 'Refresh Now'"
echo "  4. Add the widget to Notification Center:"
echo "     - Click the date/time in menu bar"
echo "     - Scroll to bottom and click 'Edit Widgets'"
echo "     - Find 'Aztec Governance' and add it"
echo ""
