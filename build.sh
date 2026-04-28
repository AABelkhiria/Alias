#!/bin/bash
set -e

APP_NAME="Alias"
VERSION=$(cat VERSION | xargs)
APP_BUNDLE="${APP_NAME}.app"
MACOS_DIR="${APP_BUNDLE}/Contents/MacOS"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

ARCH=$1 # arm64, x86_64, or both (default)

echo "Building ${APP_NAME} v${VERSION}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

build_arch() {
    local a=$1
    echo "Building for $a..."
    swift build -c release --arch "$a"
}

if [ "$ARCH" == "arm64" ]; then
    build_arch "arm64"
    cp .build/arm64-apple-macosx/release/${APP_NAME} "${MACOS_DIR}/${APP_NAME}"
elif [ "$ARCH" == "x86_64" ]; then
    build_arch "x86_64"
    cp .build/x86_64-apple-macosx/release/${APP_NAME} "${MACOS_DIR}/${APP_NAME}"
else
    echo "Creating Universal Binary (arm64 + x86_64)..."
    build_arch "arm64"
    build_arch "x86_64"
    lipo -create \
        .build/arm64-apple-macosx/release/${APP_NAME} \
        .build/x86_64-apple-macosx/release/${APP_NAME} \
        -output "${MACOS_DIR}/${APP_NAME}"
fi

# Create PkgInfo
echo -n "APPL????"> "${CONTENTS_DIR}/PkgInfo"

# Create Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>${APP_NAME}</string>
	<key>CFBundleIdentifier</key>
	<string>com.alias.app</string>
	<key>CFBundleName</key>
	<string>${APP_NAME}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSAppleEventsUsageDescription</key>
	<string>Alias needs permission to run commands in your Terminal.</string>
</dict>
</plist>
EOF

# Ad-hoc code sign
echo "Applying ad-hoc signature..."
codesign --force --deep -s - "${APP_BUNDLE}"

echo "Build complete: ${APP_BUNDLE}"
file "${MACOS_DIR}/${APP_NAME}"
