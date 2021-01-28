#!/usr/bin/env bash
CLIPY_SCHEME=${CLIPY_SCHEME:-Clipy}

xcodebuild -workspace Clipy.xcworkspace -scheme "$CLIPY_SCHEME" -destination 'platform=macOS' clean test | xcpretty