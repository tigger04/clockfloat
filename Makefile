PROJECT ?= clockfloat.xcodeproj
SCHEME ?= clockfloat
APP_NAME ?= clockfloat
CONFIGURATION ?= Debug
RELEASE_CONFIGURATION ?= Release
DESTINATION ?= platform=macOS
DERIVED_DATA ?= DerivedData
DIST_DIR ?= dist

XCODEBUILD ?= xcodebuild

.PHONY: all build test clean release

all: build

build:
	$(XCODEBUILD) \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		build

test:
	$(XCODEBUILD) \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		-destination '$(DESTINATION)' \
		test

clean:
	$(XCODEBUILD) \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		clean
	rm -rf $(DERIVED_DATA)
	rm -rf $(DIST_DIR)

release:
	$(XCODEBUILD) \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(RELEASE_CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		build
	@APP_PATH="$(DERIVED_DATA)/Build/Products/$(RELEASE_CONFIGURATION)/$(APP_NAME).app"; \
	if [ ! -d "$$APP_PATH" ]; then \
		echo "App bundle not found at $$APP_PATH" >&2; \
		exit 1; \
	fi; \
	VERSION=$$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$$APP_PATH/Contents/Info.plist"); \
	mkdir -p $(DIST_DIR); \
	ARCHIVE="$(DIST_DIR)/$(APP_NAME)-$$VERSION.zip"; \
	rm -f "$$ARCHIVE"; \
	ditto -c -k --sequesterRsrc --keepParent "$$APP_PATH" "$$ARCHIVE"; \
	shasum -a 256 "$$ARCHIVE" > "$$ARCHIVE.sha256"; \
	echo "Created $$ARCHIVE"; \
	echo "SHA256 recorded in $$ARCHIVE.sha256";
