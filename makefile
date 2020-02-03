.DEFAULT_GOAL := info
.PHONY: info apk ios

SHELL := /bin/bash

###############################################################################
## INFO
###############################################################################

info:
	@echo "Available actions:"
	@echo
	@echo "  $$ make         Runs 'make info' by default"
	@echo "  $$ make info    Shows this text"
	@echo
	@echo "  $$ make lang-extract"
	@echo "  $$ make lang-compile"
	@echo
	@echo "  $$ make launch-ios-link"
	@echo "  $$ make launch-android-link"
	@echo
	@echo "  $$ make run"
	@echo "  $$ make apk"
	@echo "  $$ make ios"
	@echo

###############################################################################
## RECIPES
###############################################################################

lang-extract:
	@flutter pub pub run intl_translation:extract_to_arb --output-dir=lib/lang lib/lang/index.dart
	@echo "Upload ./lib/lang/intl_messages.arb to https://translate.google.com/toolkit/ and translate the files"

lang-compile:
	@flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/lang \
		--no-use-deferred-loading lib/lang/index.dart lib/lang/intl_*.arb

launch-ios-org:
	/usr/bin/xcrun simctl openurl booted "vocdoni://vocdoni.app/entity?entityId=0x180dd5765d9f7ecef810b565a2e5bd14a3ccd536c442b3de74867df552855e85&networkId=1234&entryPoints[]=__URI__&entryPoints[]=__URI2__"

launch-android-org:
	adb shell 'am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "vocdoni://vocdoni.app/entity?entityId=0x180dd5765d9f7ecef810b565a2e5bd14a3ccd536c442b3de74867df552855e85&networkId=1234&entryPoints[]=__URI__&entryPoints[]=__URI2__"'

launch-ios-sign:
	/usr/bin/xcrun simctl openurl booted "vocdoni://vocdoni.app/signature?payload=Hello%20World&returnUri=https%3A%2F%2Fvocdoni.io%2F"

launch-android-sign:
	adb shell 'am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "vocdoni://vocdoni.app/signature?payload=Hello%20World&returnUri=https%3A%2F%2Fvocdoni.io%2F"'

run: 
	flutter run

apk:
	flutter build apk
	@open build/app/outputs/apk/release 2>/dev/null || xdg-open build/app/outputs/apk/release 2>/dev/null || true

ios:
	flutter build ios
