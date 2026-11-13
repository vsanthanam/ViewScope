#  ``ViewScope``

Imperative, cancellable asynchronous contexts in SwiftUI

## Overview

ViewScope is a library that lets you create structured, SwiftUI-friendly async contexts for imperative asynchronous work, such as making a network request when a user taps on a button. It allows you to scope this work to a specific node in the SwiftUI view hierarchy and prevents you from needing to rely on unstructured concurrency to manage task cancellation.

Wrap your content in a ``ScopedView``, and use the provided scope to start tasks. When the scoped view disappears, its tasks are cancelled.

For example:

```swift
import ViewScope

struct MyScreen: View {

    var body: some View {
        ScopedView { scope in
            VStack {
                Text("This screen can produce async side effects that need to be cancelled if it ever disappears, for example if the user interacts with a deeplink or dismisses a sheet presentation with a swipe")
                Button("Make Network Request") {
                    scope.task {
                        await makeNetworkRequest()
                    }
                }
            }
        }
    }

    func makeNetworkRequest() async {
        // Await things here
    }

}
```

### Sharing a scope across a view hierarchy

A `ScopedView` isn't just for small views. Place one at the root of a screen, and every view inside it can use the same scope, either by passing along the binding provided to the content closure, or by reading it from the environment with the ``CurrentScope`` property wrapper.

```swift
struct MyScreen: View {

    var body: some View {
        ScopedView { _ in
            VStack {
                Header()
                RefreshButton()
            }
        }
    }

}

struct RefreshButton: View {

    @CurrentScope var scope

    var body: some View {
        Button("Refresh") {
            scope.task {
                // Cancelled if `MyScreen` disappears
                await refresh()
            }
        }
    }

    func refresh() async {
        // Await things here
    }

}
```

### Managing a scope manually

If you need more control, for example to bind a scope to a specific child view or to share one scope between several views, you can create a scope yourself with the ``ViewScope`` property wrapper and bind it with the ``SwiftUICore/View/viewScope(_:)`` modifier.

```swift
struct MyScreen: View {

    @ViewScope var myScope

    var body: some View {
        VStack {
            Text("Tasks are cancelled when this text disappears")
                .viewScope($myScope)
            Button("Make Network Request") {
                myScope.task {
                    await makeNetworkRequest()
                }
            }
        }
    }

    func makeNetworkRequest() async {
        // Await things here
    }

}
```

## Topics

### Creating Scopes

- ``ScopedView``

### Using Scopes

- ``VisibilityScope``
- ``CurrentScope``

### Managing Scopes Manually

- ``ViewScope``
- ``SwiftUICore/View/viewScope(_:)``
