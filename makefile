.DEFAULT_GOAL := help
PROJECTNAME=$(shell basename "$(PWD)")
SOURCES=$(sort $(notdir $(wildcard {./lib/**/*,./text/**/*}.dart)))
ROUND_ICONS=$(sort $(wildcard android/app/src/main/res/mipmap-*/launcher_icon.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-[2-9]*.png))
SQUARE_ICONS=$(sort $(wildcard ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png))

SHELL := /bin/bash

# ##############################################################################
# # GENERAL
# ##############################################################################

.PHONY: help
help: makefile
	@echo
	@echo " Available actions in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo

## init: Install missing dependencies.
.PHONY: init
init:
	flutter pub get

## :

# ##############################################################################
# # RECIPES
# ##############################################################################

## lang-extract: Parse the string literals and extract them into lib/lang
lang-extract: ./lib/lang/intl_messages.arb

./lib/lang/intl_messages.arb: $(SOURCES)
	@flutter pub pub run intl_translation:extract_to_arb --output-dir=lib/lang lib/lang/index.dart
	@echo "Upload ./lib/lang/intl_messages.arb to https://translate.google.com/toolkit/ and translate the files"

## lang-compile: Parse the ARB files and import them as Dart translations
.PHONY: lang-compile
lang-compile:
	@flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/lang \
		--no-use-deferred-loading lib/lang/index.dart lib/lang/intl_*.arb

## icons: Scale assets/icon/* for Android/iOS
icons: round-icons square-icons

round-icons: $(ROUND_ICONS)
square-icons: $(SQUARE_ICONS)

$(ROUND_ICONS): assets/icon/icon-round.png assets/icon/icon.png
	cd assets/icon && rm icon.png && ln -s icon-round.png icon.png
	flutter pub run flutter_launcher_icons:main
	@git checkout -- $(SQUARE_ICONS)
	@git add $(ROUND_ICONS)

$(SQUARE_ICONS): assets/icon/icon-square.png assets/icon/icon.png
	cd assets/icon && rm icon.png && ln -s icon-square.png icon.png
	flutter pub run flutter_launcher_icons:main
	@git checkout -- $(ROUND_ICONS)
	@git add $(SQUARE_ICONS)

## : 

# ##############################################################################
# # HELPER TASKS
# ##############################################################################

## launch-ios-org: Launch a URI pointing to an Entity on iOS
launch-ios-org:
	/usr/bin/xcrun simctl openurl booted "vocdoni://vocdoni.app/entity?entityId=0x180dd5765d9f7ecef810b565a2e5bd14a3ccd536c442b3de74867df552855e85&networkId=1234&entryPoints[]=__URI__&entryPoints[]=__URI2__"

## launch-android-org: Launch a URI pointing to an Entity on Android
launch-android-org:
	adb shell 'am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "vocdoni://vocdoni.app/entity?entityId=0x180dd5765d9f7ecef810b565a2e5bd14a3ccd536c442b3de74867df552855e85&networkId=1234&entryPoints[]=__URI__&entryPoints[]=__URI2__"'

## launch-ios-sign: Launch a URI requesting to sign a payload on iOS
launch-ios-sign:
	/usr/bin/xcrun simctl openurl booted "vocdoni://vocdoni.app/signature?payload=Hello%20World&returnUri=https%3A%2F%2Fvocdoni.io%2F"

## launch-android-sign: Launch a URI requesting to sign a payload on Android
launch-android-sign:
	adb shell 'am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "vocdoni://vocdoni.app/signature?payload=Hello%20World&returnUri=https%3A%2F%2Fvocdoni.io%2F"'

## :

## run: Run the app in development mode on a currently active device or simulator
run: 
	flutter run

## apk: Compile the Android APK
apk:
	flutter build apk
	@open build/app/outputs/apk/release 2>/dev/null || xdg-open build/app/outputs/apk/release 2>/dev/null || true
appbundle:
	flutter build appbundle --target-platform android-arm,android-arm64,android-x64
	@open build/app/outputs/bundle/release 2>/dev/null || xdg-open build/app/outputs/bundle/release 2>/dev/null || true

## ios: Compile the iOS package
ios:
	flutter build ios

## :
## clean: Clean build artifacts
clean:
	flutter clean
