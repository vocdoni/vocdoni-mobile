# Vocdoni Mobile Client
Official implementation of the Vocdoni core features.

The repository depends on a Git submodule mounted on `lib/models` => `git@gitlab.com:vocdoni/dvote-protobuf.git`

## Integration

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

### Deep linking

The app accepts incoming requests using the `vocdoni:` schema. 


#### Show an organization

On developoment, you can test it by running `make launch-ios-org` or `make launch-android-org`

To point the user to an organization, use:

```
vocdoni://vocdoni.app/entity?resolverAddress=__ADDR__&entityId=__ID__&networkId=__ID__&entryPoints[]=__URI_1__&entryPoints[]=__URI_2__
```

- `resolverAddress`: The address of the entity resolver contract instance
- `entityId`: The ID of the organization. See https://vocdoni.io/docs/#/architecture/components/entity?id=entity-resolver
- `networkId`: The of the network (currently supported 0 => mainnet)
- `entryPoints[]`: Array of entry point URL's to use for connecting to the blockchain

#### Prompt to sign a payload

On developoment, you can test it by running `make launch-ios-sign` or `make launch-android-sign`

To let the user sign a given payload, use:

```
vocdoni://vocdoni.app/signature?payload=__TEXT__&returnUri=__URI__
```

- `payload`: A URI-encoded version of the text to sign
- `returnURI`: A URI-encoded string containing the URI that will be launched after a successful signature. The URI will be appended the query string parameter `?signature=...`

## Development

### Data Architecture and internal Models

The global state of the app is built on top of the [Provider package](https://pub.dev/packages/provider). The provider package allows to track updates on objects that implement the `ChangeNotifier` protocol. 

#### State Container

In addition to this, this project provides the `StateContainer` abstract class. It provides a clean and safe way to consume a data structure that is guaranteed to exist (inspired on Rust's `Option` enum). The state container is ideal for tracking a widget's local data that needs to be fetched remotely.

Basic usage example:

```dart
final myString = StateContainer<String>();
// ...
myString.setToLoading("Optional loading message");
myString.isLoading // true
mString.hasError // false
myString.hasValue // false
myString.value // null

myString.setError("Something went wrong");
myString.isLoading // false
myString.hasError // true
myString.errorMessage  // "Something went wrong"
myString.hasValue // false
myString.value // null

myString.setValue("I am ready!");
myString.isLoading // false
myString.hasError // false
myString.hasValue // true
myString.value // "I am ready!"
```

Additional features:

```dart
// Initial value of 0
// Data will be obsolete after 10 seconds
final myInteger = StateContainer<int>(0).withFreshness(10);
myInteger.isFresh // false   (we have not called setValue yet)
myInteger.lastUpdated // null
myInteger.lastError // null
myInteger.hasValue // true
myInteger.value // 0

myInteger.setValue(5);
myInteger.isFresh // true
myInteger.lastUpdated // (DateTime)
myInteger.lastError // null
myInteger.value // 5

// 5 seconds after
myInteger.isFresh // false
```

#### State Notifier

The `StateNotifier` class extends the functionality of `StateContainer` by implementing the `ChangeNotifier` interface of `Provider`. The method `notifyListeners` is called whenever the internal state changes (`setValue()`, `setError()`, `setToLoading()`). 

State Notifiers are mainly used to build and compose data models used in the global state of the app. 

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

This separation allows for efficient and granular widget tree rebuilds whenever the state is updated. If a single value changes, only the relevant subwidgets should rebuild.

#### Usage

**Global model pools need to be initialized and read their data from the Persistence helpers**

```dart
final globalEntitiesPersistence = EntitiesPersistence();
await globalEntitiesPersistence.readAll();

// ...
await globalEntityPool.readFromStorage();  // will import and arrange the persisted data
```

**Global models need to be provided at the root context**

```dart
final globalEntityPool = EntityPoolModel();

// ...

runApp(MultiProvider(
	providers: [
        Provider<EntityPoolModel>(create: (_) => globalEntityPool),
		// ...
    ],
    child: MaterialApp(
		// ...
	)
```

Then, they can be retrieved later on. 

```dart
// Widget 1
@override
Widget build(BuildContext context) {
	// Consume dynamically
    return Consumer<EntityPoolModel>(
        builder: (BuildContext context, entityModels, _) {
			// Use the fresh version: entityModels

			// Whenever `globalEntityPool` changes, this builder will be executed again
		}
}

// Widget 2
@override
Widget build(BuildContext context) {
	// Retrieve the value at the time of building (may become outdated later on)

	final entityModels = Provider.of<EntityPoolModel>(context);
	if (entityModels == null) throw Exception("Internal error");

    // use `entityModels`
	// ...
}
```

**Local models (not provided on the root context) are consumed locally**

```dart
final globalEntityPool = EntityPoolModel();

// ...

// Widget
@override
Widget build(BuildContext context) {
	final myEntity = globalEntityPool.value.first;

	// Consume feed dynamically
	return ChangeNotifierProvider.value(
      value: myEntity.feed,
      child: Builder(
		  builder: (context) {
			  // Use myEntity.feed.hasValue, myEntity.feed.isLoading, etc.

			  // The type is inferred automatically, but the `value` needs to be 
			  // your StateNotifier or derive from ChangeNotifier

			  // ...
		  }
	  )
	);
}
```

In the example above, if the global Feed pool changes, the component is not going to be rebuilt. Even if the entity is updated, this widget will stay the same. But as soon as we call `myEntity.feed.refresh()` the Builder will be rebuilding upon changes in `isLoading`, `hasError` and `hasValue`.

#### Extra methods

Certain models implement the `StateRefreshable` interface. This ensures that callers can call `refresh()` to request a refetch of remote data, based on the current model's ID or metadata.

Other models (mainly pools) also implement the `StatePersistable` interface, so that `readFromStorage()` and `writeToStorage()` can be called.

#### General

It is important not to mix the models (account, entity, process, feed, app state) with the Persistence classes. The latter map diretly to the Protobuf classes, which allow for binary serialization and consistently have a 1:1 mapping.

Models can contain both data which is persisted (entity metadata, process metadata) as well as data that is ephemeral (current participants on a vote, selected account). When `readFromStorage` is called, data needs to be deserialized and restored properly, often across multiple models.

### Internationalization

- First of all, declare any new string on `lib/lang/index.dart` &gt; `_definitions()`
- Add `import '../lang/index.dart';` on your widget file
- Access the new string with `Lang.of(context).get("My new string to translate")`
- Generate the string template with `make lang-extract`
- Import the translated bundles with `make lang-compile`

### Dependencies

The project makes use of the [DVote Flutter](https://pub.dev/packages/dvote) plugin. Please, refer to [Git Lab](https://gitlab.com/vocdoni/dvote-flutter) for more details. 
