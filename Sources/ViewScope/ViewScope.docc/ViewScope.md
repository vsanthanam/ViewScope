#  ``ViewScope``

Imperactive, cancellable asynchronous contexts in SwiftUI

## Overview

ViewScope is a library that lets you create structured, SwiftUI-friendly async contexts for imperative asynchronous work, such as making a network request when a user taps on a button. It allows you to scope this work to a specific node in the SwiftUI view hiearchy and prevents you from needing to rely on unstructured concurrency to manage task cancellation.

For example:

```swift
import ViewScope

struct MyScreen: View {

    @ViewScope myScope
    
    var body: some View {
        VStack {
            Text("This screen can produce async side effects that need to be cancelled if it ever disappears, for example if the user interacts with a deeplink or dismisses a sheet presentation with a swipe")
            Button("Make Network Request") {
                myScope.task {
                    await makeNetworkRequest()
                }
            }
        }
        .whileVisible($myScope)
    }

    func makeNetworkRequest() async {
        // Await things here
    }

}
```

## Topics

- ``ViewScope``
- ``VisibilityScope``
- ``SwiftUICore/View/whileVisible(_:)``
