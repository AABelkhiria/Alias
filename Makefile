APP_NAME = Alias
BUNDLE = $(APP_NAME).app

.PHONY: all build clean run help

all: build

build: ## Build the app bundle
	@chmod +x build.sh
	@./build.sh

clean: ## Remove build artifacts
	@rm -rf $(BUNDLE)
	@rm -rf .build/
	@swift package clean
	@echo "Cleaned."

run: build ## Build and run the app
	@open $(BUNDLE)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
