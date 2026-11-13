// ViewScope
// ViewScope.swift
//
// MIT License
//
// Copyright (c) 2025 Varun Santhanam
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the  Software), to deal
//
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import SwiftUI

/// A SwiftUI property wrapper used to create a new `VisibilityScope` that you manage yourself
///
/// In most cases, you should use ``ScopedView`` instead. It creates a scope, binds it to a view, and shares it with child views for you, so there is no way to forget a step.
///
/// Use this property wrapper when you need more control than ``ScopedView`` provides. For example:
///
/// - When methods or properties on your view need to use the scope outside of a `ScopedView` content closure.
/// - When the scope should follow the lifecycle of a specific child view, rather than all of your view's content.
/// - When several views should share a single scope, so that tasks are only cancelled once all of them have disappeared.
///
/// A scope created with this property wrapper is unbound. You must attach it to the visibility lifecycle of a view using the ``SwiftUICore/View/viewScope(_:)`` modifier. You can then assign tasks to the scope using the various `task` methods on the scope.
///
/// For example:
///
/// ```swift
/// struct MyView: View {
///
///     @ViewScope var myScope
///
///     var body: some View {
///         Button("Do Something") {
///             myScope.task {
///                 // await something
///             }
///         }
///         .viewScope($myScope)
///     }
///
/// }
/// ```
///
/// - Important: Tasks assigned to a scope that has not been bound to a view are ignored. In debug builds, this reports a runtime issue in Xcode.
///
/// To pass a scope to a child view, use a SwiftUI binding. The property wrapper supports this using projection. For example:
///
/// ```swift
/// struct ParentThatContainsAScope: View {
///
///     @ViewScope var myScope
///
///     var body: some View {
///         ChildThatNeedsAScope(scope: $myScope)
///             .viewScope($myScope)
///     }
///
/// }
/// ```
///
/// Views modified with ``SwiftUICore/View/viewScope(_:)`` can also read the scope using the ``CurrentScope`` property wrapper.
@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@propertyWrapper
public struct ViewScope: DynamicProperty {

    // MARK: - Initializers

    public init() {}

    // MARK: - Property Wrapper

    public var wrappedValue: VisibilityScope {
        get {
            scope
        }
        nonmutating set {
            scope = newValue
        }
    }

    public var projectedValue: Binding<VisibilityScope> {
        $scope
    }

    // MARK: - Private

    @State
    private var scope = VisibilityScope()

}

/// A SwiftUI property wrapper used to access the nearest enclosing `VisibilityScope`
///
/// Use this property wrapper to read the scope created by the nearest enclosing ``SwiftUICore/View/viewScope(_:)``, without passing a binding through your view initializers.
///
/// For example:
///
/// ```swift
/// struct MyScreen: View {
///
///     var body: some View {
///         ScopedView { _ in
///             RefreshButton()
///         }
///     }
///
/// }
///
/// struct RefreshButton: View {
///
///     @CurrentScope var scope
///
///     var body: some View {
///         Button("Refresh") {
///             scope.task {
///                 // await something
///                 // Tasks will be cancelled when `MyScreen` disappears
///             }
///         }
///     }
///
/// }
/// ```
///
/// When scoped views are nested, the property wrapper provides the scope of the closest one.
///
/// Scopes that you manage yourself using the ``ViewScope`` property wrapper are also available to the views that they are bound to with the ``SwiftUICore/View/viewScope(_:)`` modifier.
///
/// - Important: Accessing the scope when no enclosing scope exists is a programmer error and will trap.
@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@propertyWrapper
public struct CurrentScope: DynamicProperty {

    // MARK: - Initializers

    public init() {}

    // MARK: - Property Wrapper

    public var wrappedValue: VisibilityScope {
        get {
            projectedValue.wrappedValue
        }
        nonmutating set {
            projectedValue.wrappedValue = newValue
        }
    }

    public var projectedValue: Binding<VisibilityScope> {
        guard let currentScope else {
            fatalError("@CurrentScope was used outside of a ScopedView or a view modified with .viewScope(_:)")
        }
        return currentScope
    }

    // MARK: - Private

    @Environment(\.currentScope)
    private var currentScope

}

@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension View {

    /// Manage the tasks assigned to the provided scope based on the appearance lifecycle of the upstream view.
    ///
    /// Use this modifier to bind a scope that you created yourself using the ``ViewScope`` property wrapper. You do not need this modifier when using ``ScopedView``, which binds its scope for you.
    ///
    /// The scope is also made available to the upstream view and its descendants using the ``CurrentScope`` property wrapper.
    ///
    /// For example:
    ///
    /// ```swift
    /// struct SomeView: View {
    ///
    ///     @ViewScope var myScope
    ///
    ///     var body: some View {
    ///         SomeOtherView()
    ///             .viewScope($myScope)
    ///             // Tasks assigned to `myScope` will cancel themselves when `SomeOtherView` disappears.
    ///     }
    ///
    /// }
    /// ```
    ///
    /// - Parameter scope: The scope to manage
    /// - Returns: The modified view
    public func viewScope(
        _ scope: Binding<VisibilityScope>
    ) -> some View {
        modifier(ViewScopeModifier(scope))
    }

}

@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension EnvironmentValues {

    @Entry
    fileprivate var currentScope: Binding<VisibilityScope>? = nil

}

@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
private struct ViewScopeModifier: ViewModifier {

    // MARK: - Initializers

    init(_ scope: Binding<VisibilityScope>) {
        _scope = scope
    }

    // MARK: - ViewModifier

    func body(content: Content) -> some View {
        content
            .environment(
                \.currentScope,
                $scope
            )
            .onAppear {
                scope.activate()
            }
            .onDisappear {
                scope.deactivate()
            }
    }

    // MARK: - Private

    @Binding
    private var scope: VisibilityScope

}
