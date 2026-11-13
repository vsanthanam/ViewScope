// ViewScope
// Modifier.swift
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

@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension View {

    /// Manage the tasks assigned to the provided scope based on the appearance lifecycle of the upstream view.
    ///
    /// Use this modifier to bind a scope that you created yourself using the ``Scope`` property wrapper. You do not need this modifier when using ``ScopedView``, which binds its scope for you.
    ///
    /// The scope is also made available to the upstream view and its descendants using the ``CurrentScope`` property wrapper.
    ///
    /// For example:
    ///
    /// ```swift
    /// struct SomeView: View {
    ///
    ///     @Scope var myScope
    ///
    ///     var body: some View {
    ///         SomeOtherView()
    ///             .scope(to: $myScope)
    ///             // Tasks assigned to `myScope` will cancel themselves when `SomeOtherView` disappears.
    ///     }
    ///
    /// }
    /// ```
    ///
    /// - Parameter scope: The scope to manage
    /// - Returns: The modified view
    public func scope(
        to scope: Binding<ViewScope>
    ) -> some View {
        modifier(ScopeModifier(scope))
    }

}

@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension EnvironmentValues {

    @Entry
    var currentScope: Binding<ViewScope>? = nil

}

@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
private struct ScopeModifier: ViewModifier {

    // MARK: - Initializers

    init(_ scope: Binding<ViewScope>) {
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
    private var scope: ViewScope

}
