#!/bin/bash
# Exports the game from Godot, builds it for the iPhone Simulator, and opens it there.
# Run from Terminal:  ~/NoahsArk/tools/run_simulator.sh
#
# Xcode's Run button doesn't work for this on an Intel Mac (it builds for the wrong chip),
# so this builds from the command line instead, the same way as Backyard Dominoes.
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT=/Applications/Godot.app/Contents/MacOS/Godot
BUNDLE_ID=com.brianhennington.noahsark
ARCH=$(uname -m) # x86_64 on an Intel Mac, arm64 on Apple Silicon

echo "1/4  Exporting from Godot..."
mkdir -p builds/ios
"$GODOT" --headless --path . --export-debug "iOS Simulator" builds/ios/NoahsArk.xcodeproj >/dev/null

echo "2/4  Building for the Simulator (the first time takes a few minutes)..."
cd builds/ios
xcodebuild -project NoahsArk.xcodeproj -scheme NoahsArk -configuration Debug \
	-sdk iphonesimulator -arch "$ARCH" ONLY_ACTIVE_ARCH=NO -derivedDataPath DerivedData \
	CODE_SIGNING_ALLOWED=NO -quiet build
APP=DerivedData/Build/Products/Debug-iphonesimulator/NoahsArk.app

echo "3/4  Starting the virtual iPhone..."
# The biggest iPhone available (a Pro Max if there is one).
DEVICE=$(xcrun simctl list devices available | grep -E "iPhone .*Pro Max" | tail -1 | grep -oE "[0-9A-F-]{36}" || true)
if [ -z "$DEVICE" ]; then
	DEVICE=$(xcrun simctl list devices available | grep -E "iPhone" | tail -1 | grep -oE "[0-9A-F-]{36}")
fi
xcrun simctl boot "$DEVICE" 2>/dev/null || true # already on is fine
open -a Simulator

echo "4/4  Installing and opening Noah's Ark..."
xcrun simctl install "$DEVICE" "$APP"
xcrun simctl launch "$DEVICE" "$BUNDLE_ID" >/dev/null
echo "Done. Noah's Ark is running in the Simulator."
