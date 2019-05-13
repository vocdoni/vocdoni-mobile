.DEFAULT_GOAL := info
.PHONY: info build

PATH  := node_modules/.bin:$(PATH)
SHELL := /bin/bash

###############################################################################
## INFO
###############################################################################

info:
	@echo "Available actions:"
	@echo
	@echo "  $$ run         Runs 'run info' by default"
	@echo "  $$ run info    Shows this text"
	@echo
	@echo "  $$ run lang-extract"
	@echo "  $$ run lang-compile"
	@echo "  $$ run run"
	@echo

###############################################################################
## RECIPES
###############################################################################

lang-extract:
	@flutter pub run intl_translation:extract_to_arb --output-dir=lib/lang lib/lang/index.dart
	@echo "Upload ./lib/lang/intl_messages.arb to https://translate.google.com/toolkit/ and translate the files"

lang-compile:
	@flutter pub run intl_translation:generate_from_arb --output-dir=lib/lang \
		--no-use-deferred-loading lib/lang/index.dart lib/lang/intl_*.arb

run: 
	flutter run
