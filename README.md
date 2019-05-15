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

### Organization Actions

Web sites loaded by the Vocdoni host app need can communicate to it by using a simple interface.

- Messages can be sent using `HostApp.postMessage(JSON.stringify(message));`
- Responses can be handled declaring `window.handleHostResponse = function(message){ /* ... */}`

However, a richer development experience can be achieved by integrating the following lines of code on the global scope:

```html
<script>
	// STATE VARIABLES
	// They should be on the global scope so that handleHostResponse
	// can match requests and responses

	window.requestCounter = 0;
	window.requestQueue = [];

	// SENDING REQUESTS

	/**
	 * Call this function anywhere in your code to request certain actions to the host
	 * 
	 * Returns a promise that resolves when the hosts replies
	 */
	window.sendHostRequest = function(payload) {
		return new Promise((resolve, reject) => {
			const id = window.requestCounter++;
			const newRequest = {
				id,
				resolve,
				reject,
				timeout: setTimeout(() => window.expireRequest(id), 30000)
			};
			window.requestQueue.push(newRequest);

			const message = JSON.stringify({ id, payload });
			HostApp.postMessage(message);
		});
	}

	// Handling timeout
	window.expireRequest = function(id) {
		const idx = window.requestQueue.findIndex(r => r.id === id);
		if (idx < 0) return;
		window.requestQueue[idx].reject(new Error('Timeout'));

		delete window.requestQueue[idx].resolve;
		delete window.requestQueue[idx].reject;
		delete window.requestQueue[idx].timeout;
		window.requestQueue.splice(idx, 1);
	}

	// INCOMING RESPONSE HANDLER

	window.handleHostResponse = function(message) {
		try {
			const msgPayload = JSON.parse(message);
			const { id, data, error } = msgPayload;

			const idx = window.requestQueue.findIndex(r => r.id === id);
			if (idx < 0) return;
			else if (error) {
				if (typeof window.requestQueue[idx].reject === 'function') {
					window.requestQueue[idx].reject(new Error(error));
				}
				else {
					console.error("Could not report a response error:", error);
				}
			}
			else if (typeof window.requestQueue[idx].resolve === 'function') {
				window.requestQueue[idx].resolve(data);
			}
			else {
				console.error("Could not report a response:", data);
			}

			// clean
			clearTimeout(window.requestQueue[idx].timeout);
			delete window.requestQueue[idx].resolve;
			delete window.requestQueue[idx].reject;
			window.requestQueue.splice(idx, 1);
		}
		catch (err) {
			console.error (err);
		}
	}
</script>
```

Now you can run `sendHostRequest(<data>)` from anywhere in your code and get a promise that resolves with the appropriate response.

#### Public Key Request

```javascript
sendHostRequest({ type: "getPublicKey" })
	.then(response => {
		console.log("PUBLIC KEY", response);
	})
	.catch(err => {
		console.error(err);
	});
```

#### Closing the window

```javascript
sendHostRequest({ type: "closeWindow" })
	.then(response => console.log("Good Bye"))
	.catch(err => {
		console.error(err);
	});
```
