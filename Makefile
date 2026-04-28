APP_NAME = Alias
BUNDLE = $(APP_NAME).app

.PHONY: all build build-arm64 build-x86_64 clean run help

all: build

build: ## Build the app bundle (Universal Binary)
	@chmod +x build.sh
	@./build.sh

build-arm64: ## Build for Apple Silicon (arm64)
	@chmod +x build.sh
	@./build.sh arm64

build-x86_64: ## Build for Intel (x86_64)
	@chmod +x build.sh
	@./build.sh x86_64

clean: ## Remove build artifacts
	@rm -rf $(BUNDLE)
	@rm -rf .build/
	@swift package clean
	@echo "Cleaned."

run: ## Build for current architecture and run the app
	@chmod +x build.sh
	@ARCH=$$(uname -m); \
	if [ "$$ARCH" = "arm64" ]; then \
		echo "Detected Apple Silicon (arm64)..."; \
		./build.sh arm64; \
	else \
		echo "Detected Intel (x86_64)..."; \
		./build.sh x86_64; \
	fi
	@open $(BUNDLE)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
