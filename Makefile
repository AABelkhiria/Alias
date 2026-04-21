APP_NAME = Alias
APP_BUNDLE = $(APP_NAME).app
MACOS_DIR = $(APP_BUNDLE)/Contents/MacOS

all: build

build:
	@mkdir -p $(MACOS_DIR)
	swiftc Sources/*.swift -o $(MACOS_DIR)/$(APP_NAME)
	@echo "Done"

clean:
	rm -rf $(APP_BUNDLE)
