# Vocdoni Mobile Client
Official implementation of the Vocdoni core features.

## Development

### Data Architecture and internal Models

The State Management architecture of the app is built on top of the [Eventual package](https://pub.dev/packages/eventual). Eventual allows to track updates on objects and rebuild their corresponding UI accordingly. 

#### Model classes

They can be of the type:
* Single models
  * AppStateModel, AccountModel, EntityModel, ProcessModel, FeedModel
  * A model can contain references to other models
* Pools of data
  * Typically, they contain a collection of single models
  * Usually used as global variables
  * Their goal is to track whether the collection changes, but not the individual items
  * They contain all the model instances known to the system
  * Any modification on a model should happen in models obtained from a global pool, since the pool manages persistence

This separation allows for efficient and granular widget tree rebuilds whenever the state is updated. If a single value changes, only the relevant children should rebuild.

#### Usage

**Initialize and read Global Model's data from the Persistence helpers**

```dart
final globalEntitiesPersistence = EntitiesPersistence();
await globalEntitiesPersistence.readAll();

// ...
final globalEntityPool = EntityPoolModel();
await globalEntityPool.readFromStorage();  // will import and arrange the persisted data
```

**Consume Models in specific places**

Typically, you will have a `globalEntityPool` with all the EntityModel's known to the app and then, individual `EntityModel` instances when the user selects one. 

```dart
final globalEntityPool = EntityPoolModel();

// ...

// Widget
@override
Widget build(BuildContext context) {
	// From the pool, we grab the first entity model
	final myEntity = globalEntityPool.value.first;

	// Consume many values (EventualNotifier) locally
	return EventualBuilder(
    	notifiers: [myEntity.feed, myEntity.processes],  // EventualNotifier<T> values that may change over time
		builder: (context) {
			// rebuilt whenever either of myEntity.feed or myEntity.processes change

			// ...
		)
	);
}
```

In the example above, updates on specifig Feed items, will not affect the current widget. But as soon as we call `myEntity.feed.refresh()` on this instance, the Builder will be triggered because of the changes in `isLoading`, `hasError` and `hasValue`.

#### Extra methods

Certain models implement the `ModelRefreshable` interface. This ensures that callers can call `refresh()` to request a refetch of remote data, based on the current model's ID or metadata.

Other models (mainly pools) also implement the `ModelPersistable` interface, so that `readFromStorage()` and `writeToStorage()` can be called.

#### General

It is important not to mix the models (account, entity, process, feed, app state) with the Persistence classes. Persistence classes map diretly to `dvote-protobuf` classes, which allow for binary serialization and consistently have a 1:1 mapping.

Models can contain both data which is persisted (entity metadata, process metadata) as well as data that is ephemeral (current participants on a vote, selected account). When `readFromStorage` is called, data needs to be deserialized and restored properly, often across multiple models.

### Internationalization

- First of all, declare any new string on `lib/lang/index.dart` &gt; `_definitions()`
- Add `import '../lang/index.dart';` on your widget file
- Access the new string with `Lang.of(context).get("My new string to translate")`
- Generate the string template with `make lang-extract`
- Import the translated bundles with `make lang-compile`

### Dependencies

The project makes use of the [DVote Flutter](https://pub.dev/packages/dvote) plugin. Please, refer to [Git Lab](https://gitlab.com/vocdoni/dvote-flutter) for more details. 

## Integration

### Deep linking

The app accepts incoming requests using the `vocdoni:` schema. 

#### Show an organization

On developoment, you can test it by running `make launch-ios-org` or `make launch-android-org`

To point the user to an organization, use:

```
vocdoni://vocdoni.app/entity?entityId=__ID__&entryPoints[]=__URI_1__&entryPoints[]=__URI_2__
```

- `entityId`: The ID of the organization. See https://vocdoni.io/docs/#/architecture/components/entity?id=entity-resolver
- `entryPoints[]`: Array of entry point URL's to use for connecting to the blockchain

#### Prompt to sign a payload

On developoment, you can test it by running `make launch-ios-sign` or `make launch-android-sign`

To let the user sign a given payload, use:

```
vocdoni://vocdoni.app/signature?payload=__TEXT__&returnUri=__URI__
```

- `payload`: A URI-encoded version of the text to sign
- `returnURI`: A URI-encoded string containing the URI that will be launched after a successful signature. The URI will be appended the query string parameter `?signature=...`

### Entity Actions

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

Ask the host to provide the public key of the current account.

```javascript
sendHostRequest({ method: "getPublicKey" })
	.then(response => {
		console.log("PUBLIC KEY", response);
	})
	.catch(err => {
		console.error(err);
	});
```

#### Signature request

Ask the host to sign a string payload using the private key of the current identity

```javascript
sendHostRequest({ method: "signPayload", payload: "Hello world" })
	.then(response => {
		console.log("SIGNATURE", response);
	})
	.catch(err => {
		console.error(err);
	});
```

#### Closing the window

Ask the host to close the browser window.

```javascript
sendHostRequest({ method: "closeWindow" })
	.then(() => console.log("Good Bye"))
	.catch(err => {
		console.error(err);
	});
```
