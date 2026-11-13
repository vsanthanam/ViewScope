// ViewScope
// CurrentScope.swift
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

/// A SwiftUI property wrapper used to access the nearest enclosing `ViewScope`
///
/// Use this property wrapper to read the scope created by the nearest enclosing ``ScopedView``, without passing a binding through your view initializers.
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
/// Scopes that you manage yourself using the ``Scope`` property wrapper are also available to the views that they are bound to with the ``SwiftUICore/View/scope(to:)`` modifier.
///
/// - Important: Accessing the scope when no enclosing scope exists is a programmer error and will trap.
@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@propertyWrapper
public struct CurrentScope: DynamicProperty {

    // MARK: - Initializers

    public init() {}

    // MARK: - Property Wrapper

    public var wrappedValue: ViewScope {
        get {
            projectedValue.wrappedValue
        }
        nonmutating set {
            projectedValue.wrappedValue = newValue
        }
    }

    public var projectedValue: Binding<ViewScope> {
        guard let currentScope else {
            fatalError("@CurrentScope was used outside of a ScopedView or a view modified with .scope(to:)")
        }
        return currentScope
    }

    // MARK: - Private

    @Environment(\.currentScope)
    private var currentScope

}
