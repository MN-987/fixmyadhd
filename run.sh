#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="FixMyADHD.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/FixMyADHD "$APP/Contents/MacOS/FixMyADHD"
cp Info.plist "$APP/Contents/Info.plist"
chmod +x "$APP/Contents/MacOS/FixMyADHD"
codesign --force --sign - "$APP"

open "$APP"
