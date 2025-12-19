# ViewScope

A view scope is a type that provides an async context that is cancelled based on the visibilty lifecycle of one or more views attached views.

You do not create instances of this type yourself.

Instead, use the provided ``Scope`` SwiftUI property wrapper, which creates a new, unbound scope.

For example:

```swift
struct MyView: View {

    @Scope var myScope

    var body: some View { ... }

}
```

ViewScopes must be bound to the visibility lifecycle of one or more SwiftUI views.
You can do this using the ``SwiftUICore/View/scope(_:)`` view modifier.

For example:

```swift
struct MyView: View {

    @Scope var myScope

    var body: some View {
        Text("View")
            .scope($myScope)
    }

}
```

When none of the bound views are visible, any tasks managed by the scope are cancelled.
Tasks that are added to the scope when no attached views is visible are ignored.

You can attach tasks to the scope using one of several available `.task` instance methods, which mimic Apple's own `Task` API:

```swift
struct MyView: View {

    @Scope var myScope

    var body: some View {
        Text("Async Work Available")
            .scope($myScope)
        Button("Do Something Async") {
            scope.task {
                // Await stuff here. Tasks will be cancelled the `Text` above disappears.
            }
        }
    }

}
```
