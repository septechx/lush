BUILD_DIR := $(CURDIR)/build
PACKAGE_DIR := $(BUILD_DIR)/package
VERSION := $(shell grep 'pub const version =' modules/core/src/globals.zig | cut -d'"' -f2)

.PHONY: build merge publish set-version all

default: set-version

build:
	@echo "Building project..."
	cd modules/core && zig build

set-version: merge
	@echo "Setting version to $(VERSION) in package files..."
	sed -i 's/"version": "[^"]*"/"version": "$(VERSION)"/' $(PACKAGE_DIR)/package.json
	sed -i 's/"version": "[^"]*"/"version": "$(VERSION)"/' $(PACKAGE_DIR)/jsr.json

merge: build
	@echo "Merging directories..."
	mkdir -p $(PACKAGE_DIR)
	cp -r modules/core/package $(BUILD_DIR)/
	cp -r modules/core/scripts $(PACKAGE_DIR)/
	cp modules/core/README.md $(PACKAGE_DIR)/
	cp modules/core/zig-out/bin/lush $(PACKAGE_DIR)/
	chmod +x $(PACKAGE_DIR)/lush

publish: set-version
	@echo "Publishing package..."
	cd $(PACKAGE_DIR) && bunx jsr publish --allow-dirty

print-version:
	@echo "Current version: $(VERSION)"
