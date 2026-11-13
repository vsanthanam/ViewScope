// ViewScope
// Scope.swift
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

/// A SwiftUI property wrapper used to create a new `ViewScope` that you manage yourself
///
/// In most cases, you should use ``ScopedView`` instead. It creates a scope, binds it to a view, and shares it with child views for you, so there is no way to forget a step.
///
/// Use this property wrapper when you need more control than ``ScopedView`` provides. For example:
///
/// - When methods or properties on your view need to use the scope outside of a `ScopedView` content closure.
/// - When the scope should follow the lifecycle of a specific child view, rather than all of your view's content.
/// - When several views should share a single scope, so that tasks are only cancelled once all of them have disappeared.
///
/// A scope created with this property wrapper is unbound. You must attach it to the visibility lifecycle of a view using the ``SwiftUICore/View/scope(to:)`` modifier. You can then assign tasks to the scope using the various `task` methods on the scope.
///
/// For example:
///
/// ```swift
/// struct MyView: View {
///
///     @Scope var myScope
///
///     var body: some View {
///         Button("Do Something") {
///             myScope.task {
///                 // await something
///             }
///         }
///         .scope(to: $myScope)
///     }
///
/// }
/// ```
///
/// - Important: Tasks assigned to a scope that is never bound to a view do not start. In debug builds, a task that is still waiting for its scope to be bound after a short time reports a runtime issue in Xcode.
///
/// To pass a scope to a child view, use a SwiftUI binding. The property wrapper supports this using projection. For example:
///
/// ```swift
/// struct ParentThatContainsAScope: View {
///
///     @Scope var myScope
///
///     var body: some View {
///         ChildThatNeedsAScope(scope: $myScope)
///             .scope(to: $myScope)
///     }
///
/// }
/// ```
///
/// Views modified with ``SwiftUICore/View/scope(to:)`` can also read the scope using the ``CurrentScope`` property wrapper.
@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@propertyWrapper
public struct Scope: DynamicProperty {

    // MARK: - Initializers

    public init() {}

    // MARK: - Property Wrapper

    public var wrappedValue: ViewScope {
        get {
            scope
        }
        nonmutating set {
            scope = newValue
        }
    }

    public var projectedValue: Binding<ViewScope> {
        $scope
    }

    // MARK: - Private

    @State
    private var scope = ViewScope()

}
