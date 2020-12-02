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
	@echo " Available actions on "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo

## init: Install missing dependencies.
.PHONY: init
init:
	flutter pub get
	(git remote | grep weblate > /dev/null) || git remote add weblate https://hosted.weblate.org/git/vocdoni/mobile-client/

## :

# ##############################################################################
# # RECIPES
# ##############################################################################

## lang-parse: Extract the string keys into assets/i18n for translation
.PHONY: lang-parse
lang-parse: scripts/node_modules
	node scripts/lang-parse.js

## lang-pull: Pull the translated strings from Weblate
.PHONY: lang-pull
lang-pull: 
	git checkout i18n
	git pull weblate i18n
	#DIR=$$(mktemp -d) && \
	#	cd $$DIR && \
	#	curl "https://hosted.weblate.org/download/vocdoni/mobile-client/?format=zip" > strings.zip && \
	#	unzip strings.zip && \
	#	cd - && \
	#	mv $$DIR/vocdoni/mobile-client/assets/i18n/*.json $$PWD/assets/i18n && \
	#	rm -Rf $$DIR
	#for file in $$(ls $$PWD/assets/i18n/*.json) ; do node -e "require(\"fs\").writeFileSync(process.argv[1], JSON.stringify(require(process.argv[1]), null, 4) + \"\n\")" $$file ; done


scripts/node_modules: scripts/package.json
	npm install
	touch $@

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

## run: Run the app on the active (Android) device or simulator  [DEV]
.PHONY: run
run:
	make config target=dev
	flutter run \
		--flavor dev

## run-ios: Run the app on the active (iOS) device or simulator  [DEV]
.PHONY: run-ios
run-ios:
	make config target=dev
	flutter run

## :

## apk-beta: Compile the Android APK  [BETA]
.PHONY: apk-beta
apk-beta:
	make config target=beta
	flutter build apk \
		--dart-define=APP_MODE=beta \
		--dart-define=GATEWAY_BOOTNODES_URL=https://bootnodes.vocdoni.net/gateways.stg.json \
		--dart-define=NETWORK_ID=xdai \
		--flavor beta \
		--target-platform android-arm,android-arm64,android-x64 \
		--split-per-abi
	@open build/app/outputs/apk/beta/release 2>/dev/null || xdg-open build/app/outputs/apk/beta/release 2>/dev/null || true

## appbundle-beta: Compile the app bundle for Google Play  [BETA]
.PHONY: appbundle-beta
appbundle-beta:
	make config target=beta
	flutter build appbundle \
		--dart-define=APP_MODE=beta \
		--dart-define=GATEWAY_BOOTNODES_URL=https://bootnodes.vocdoni.net/gateways.stg.json \
		--dart-define=NETWORK_ID=xdai \
		--flavor beta \
		--target-platform android-arm,android-arm64,android-x64
	@open build/app/outputs/bundle/betaRelease 2>/dev/null || xdg-open build/app/outputs/bundle/betaRelease 2>/dev/null || true

## :

## apk: Compile the Android APK  [PROD]
.PHONY: apk
apk:
	make config target=production
	flutter build apk \
		--dart-define=APP_MODE=production \
		--dart-define=GATEWAY_BOOTNODES_URL=https://bootnodes.vocdoni.net/gateways.json \
		--dart-define=NETWORK_ID=xdai \
		--dart-define=LINKING_DOMAIN=vocdoni.link \
		--flavor production \
		--target-platform android-arm,android-arm64,android-x64 \
		--split-per-abi
	@open build/app/outputs/apk/production/release 2>/dev/null || xdg-open build/app/outputs/apk/production/release 2>/dev/null || true

## appbundle: Compile the app bundle for Google Play  [PROD]
.PHONY: appbundle
appbundle:
	make config target=production
	flutter build appbundle \
		--dart-define=APP_MODE=production \
		--dart-define=GATEWAY_BOOTNODES_URL=https://bootnodes.vocdoni.net/gateways.json \
		--dart-define=NETWORK_ID=xdai \
		--dart-define=LINKING_DOMAIN=vocdoni.link \
		--flavor production \
		--target-platform android-arm,android-arm64,android-x64
	@open build/app/outputs/bundle/productionRelease 2>/dev/null || xdg-open build/app/outputs/bundle/productionRelease 2>/dev/null || true

## ios: Open the iOS Runner.app for archiving  [PROD]
.PHONY: ios
ios:
	make config target=production
	flutter build ios \
		--dart-define=APP_MODE=production \
		--dart-define=GATEWAY_BOOTNODES_URL=https://bootnodes.vocdoni.net/gateways.json \
		--dart-define=NETWORK_ID=xdai \
		--dart-define=LINKING_DOMAIN=vocdoni.link
	#FLUTTER_BUILD_MODE=release make ios/Flutter/Generated.xcconfig
	open ios/Runner.xcworkspace/

#ios/Flutter/Generated.xcconfig: pubspec.yaml pubspec.lock
#	$$(which flutter | sed 's/bin\/flutter/packages\/flutter_tools\/bin\/xcode_backend.sh/g')

## :

## launch-ios-org: Launch a URI pointing to an Entity on iOS
launch-ios-org:
	/usr/bin/xcrun simctl openurl booted "https://dev.vocdoni.link/entities/0x180dd5765d9f7ecef810b565a2e5bd14a3ccd536c442b3de74867df552855e85"

## launch-android-org: Launch a URI pointing to an Entity on Android
launch-android-org:
	adb shell 'am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://dev.vocdoni.link/entities/0x180dd5765d9f7ecef810b565a2e5bd14a3ccd536c442b3de74867df552855e85"'

# ## launch-ios-sign: Launch a URI requesting to sign a payload on iOS
# launch-ios-sign:
# 	/usr/bin/xcrun simctl openurl booted "vocdoni://vocdoni.app/signature?payload=Hello%20World&returnUri=https%3A%2F%2Fvocdoni.io%2F"

# ## launch-android-sign: Launch a URI requesting to sign a payload on Android
# launch-android-sign:
# 	adb shell 'am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "vocdoni://vocdoni.app/signature?payload=Hello%20World&returnUri=https%3A%2F%2Fvocdoni.io%2F"'

# Firebase config files by environment

config: ios/Runner/GoogleService-Info.plist android/app/google-services.json

.PHONY: ios/Runner/GoogleService-Info.plist
ios/Runner/GoogleService-Info.plist:
	@case "$$target" in \
		production) rm $@ && ln -s ../../notifications/production/GoogleService-Info.plist $@ ;; \
		beta) rm $@ && ln -s ../../notifications/beta/GoogleService-Info.plist $@ ;; \
		dev) rm $@ && ln -s ../../notifications/dev/GoogleService-Info.plist $@ ;; \
		*) echo "Invalid config target" 1>&2 ; false ;; \
	esac


.PHONY: android/app/google-services.json
android/app/google-services.json:
	@case "$$target" in \
		production) rm $@ && ln -s ../../notifications/production/google-services.json $@ ;; \
		beta) rm $@ && ln -s ../../notifications/beta/google-services.json $@ ;; \
		dev) rm $@ && ln -s ../../notifications/dev/google-services.json $@ ;; \
		*) echo "Invalid config target" 1>&2 ; false ;; \
	esac

## :
## clean: Clean build artifacts
clean:
	flutter clean
