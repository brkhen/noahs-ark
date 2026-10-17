#!/bin/bash
# Exports the game from Godot, builds it for the iPhone Simulator, and opens it there.
# Run from Terminal:  ~/NoahsArk/tools/run_simulator.sh
#
# Xcode's Run button doesn't work for this (it builds the app for arm64, but Godot's
# simulator library is x86_64 only), so this builds from the command line instead.
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT=/Applications/Godot.app/Contents/MacOS/Godot
BUNDLE_ID=com.brianhennington.noahsark
# Godot's iOS Simulator library is built for Intel (x86_64) only, so the app must be too.
# On an Apple Silicon Mac the Simulator runs it with Rosetta.
ARCH=x86_64

echo "1/4  Exporting from Godot..."
mkdir -p builds/ios
touch builds/.gdignore # Godot must not treat the exported Xcode files as game files
"$GODOT" --headless --path . --export-debug "iOS Simulator" builds/ios/NoahsArk.xcodeproj >/dev/null

echo "2/4  Building for the Simulator (the first time takes a few minutes)..."
cd builds/ios
# Hide the thousands of harmless linker warnings; show anything else.
set +e
xcodebuild -project NoahsArk.xcodeproj -scheme NoahsArk -configuration Debug \
	-sdk iphonesimulator -arch "$ARCH" ARCHS="$ARCH" EXCLUDED_ARCHS= ONLY_ACTIVE_ARCH=NO \
	-derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO -quiet build 2>&1 | grep -v "warning:"
BUILD_STATUS=${PIPESTATUS[0]}
set -e
if [ "$BUILD_STATUS" -ne 0 ]; then
	echo "The build failed. Send Bezalel a screenshot of the lines above."
	exit 1
fi
APP=DerivedData/Build/Products/Debug-iphonesimulator/NoahsArk.app

echo "3/4  Starting the virtual iPhone..."
# The biggest iPhone available (a Pro Max if there is one).
DEVICE=$(xcrun simctl list devices available | grep -E "iPhone .*Pro Max" | tail -1 | grep -oE "[0-9A-F-]{36}" || true)
if [ -z "$DEVICE" ]; then
	DEVICE=$(xcrun simctl list devices available | grep -E "iPhone" | tail -1 | grep -oE "[0-9A-F-]{36}")
fi
xcrun simctl boot "$DEVICE" 2>/dev/null || true # already on is fine
# Open the Simulator app by its ID (its location differs between Xcode versions).
open -b com.apple.iphonesimulator || echo "(Couldn't open the Simulator window. Open Xcode, then Xcode > Open Developer Tool > Simulator.)"

echo "4/4  Installing and opening Noah's Ark..."
xcrun simctl install "$DEVICE" "$APP"
xcrun simctl launch "$DEVICE" "$BUNDLE_ID" >/dev/null
echo "Done. Noah's Ark is running in the Simulator."
