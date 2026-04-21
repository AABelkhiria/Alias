APP_NAME=Alias
APP_BUNDLE=$(APP_NAME).app
MACOS_DIR=$(APP_BUNDLE)/Contents/MacOS

all: clean build

build:
	@echo "Building $(APP_NAME)..."
	@mkdir -p $(MACOS_DIR)
	@swiftc Sources/*.swift -o $(MACOS_DIR)/$(APP_NAME)
	@echo "Creating Info.plist..."
	@cat <<PLIST > $(APP_BUNDLE)/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>$(APP_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>com.alias.app</string>
	<key>CFBundleName</key>
	<string>$(APP_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>LSUIElement</key>
	<true/>
</dict>
</plist>
PLIST
	@echo "Build complete."

clean:
	@rm -rf $(APP_BUNDLE)
