# Vocdoni Mobile Client
Official implementation of the Vocdoni core features.

## Development

### Internationalization

- First of all, declare any new string on `lib/lang/index.dart` &gt; `_definitions()`
- Add `import '../lang/index.dart';` on your widget file
- Access the new string with `Lang.of(context).get("My new string to translate")`
- Generate the string template with `make lang-extract`
- Import the translated bundles with `make lang-compile`

### WebRuntime

- See [https://github.com/vocdoni/dvote-js-runtime-flutter](DVote JS Runtime for Flutter)
- See `lib/util/web-runtime.dart`

### Deep linking

- Simulate deep links by running `make launch-ios-link` or `make launch-android-link`
