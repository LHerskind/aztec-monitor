#!/bin/bash

# Build script for aztec-governance-widget
# This compiles the Swift files to check for errors

cd "$(dirname "$0")"

echo "=== Checking for Xcode ==="
XCODE_PATH="/Applications/Xcode.app/Contents/Developer"
if [ -d "$XCODE_PATH" ]; then
    export DEVELOPER_DIR="$XCODE_PATH"
    echo "Using Xcode at: $XCODE_PATH"
else
    echo "Using command line tools"
fi

SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
echo "SDK: $SDK_PATH"

echo ""
echo "=== File structure ==="
find . -name "*.swift" -type f | grep -v ".git" | sort

echo ""
echo "=== Compiling App files ==="
xcrun swiftc -typecheck \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macos14.0 \
    aztec-governance-widget/Models/Config.swift \
    aztec-governance-widget/Models/RoundData.swift \
    aztec-governance-widget/Models/MonitorState.swift \
    aztec-governance-widget/ContractCalls.swift \
    aztec-governance-widget/EthClient.swift \
    aztec-governance-widget/TransitionDetector.swift \
    aztec-governance-widget/NotificationManager.swift \
    aztec-governance-widget/BackgroundRefresh.swift \
    aztec-governance-widget/ContentView.swift \
    aztec-governance-widget/aztec_governance_widgetApp.swift \
    2>&1

if [ $? -eq 0 ]; then
    echo "✓ App files OK"
else
    echo "✗ App files have errors (Note: #Preview errors are expected)"
fi

echo ""
echo "=== Compiling Widget files ==="
xcrun swiftc -typecheck \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macos14.0 \
    aztec-governance-widget/Models/Config.swift \
    aztec-governance-widget/Models/RoundData.swift \
    aztec-governance-widget/Models/MonitorState.swift \
    aztec-governance-widget/ContractCalls.swift \
    aztec-governance-widget/EthClient.swift \
    aztec-governance-widget/TransitionDetector.swift \
    AztecWidget/Provider.swift \
    AztecWidget/SmallWidgetView.swift \
    AztecWidget/MediumWidgetView.swift \
    AztecWidget/LargeWidgetView.swift \
    AztecWidget/AztecWidget.swift \
    2>&1

if [ $? -eq 0 ]; then
    echo "✓ Widget files OK"
else
    echo "✗ Widget files have errors (Note: #Preview errors are expected)"
fi

echo ""
echo "=== Done ==="
