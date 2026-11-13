// ViewScope
// ScopedView.swift
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

/// A SwiftUI view that creates a new `ViewScope` and manages it for you
///
/// A scoped view is the recommended way to use a ``ViewScope/ViewScope``. It creates a new scope, binds the scope to its own visibility lifecycle, and makes the scope available to its content.
/// Tasks assigned to the scope are cancelled when the `ScopedView` disappears.
///
/// For example:
///
/// ```swift
/// struct MyView: View {
///
///     var body: some View {
///         ScopedView { scope in
///             Button("Do Something") {
///                 scope.task {
///                     // await something
///                     // Tasks will be cancelled when the scoped view disappears from the view hierarchy
///                 }
///             }
///         }
///     }
///
/// }
/// ```
///
/// A scoped view can wrap as much or as little of your view hierarchy as you need. Wrap a single control to cancel its work when that control disappears, or place a scoped view at the root of a screen to give every view on that screen a shared scope.
///
/// ### Sharing a Scope with Child Views
///
/// Child views can read the scope of the nearest enclosing scoped view using the ``CurrentScope`` property wrapper. For example:
///
/// ```swift
/// struct MyScreen: View {
///
///     var body: some View {
///         ScopedView { _ in
///             VStack {
///                 Header()
///                 RefreshButton()
///             }
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
/// The content closure also receives a SwiftUI binding to the scope, which you can pass to child views explicitly. For example:
///
/// ```swift
/// struct ParentThatNeedsAScope: View {
///
///     var body: some View {
///         ScopedView { scope in
///             ChildThatNeedsAScope(scope: scope)
///         }
///     }
///
/// }
///
/// struct ChildThatNeedsAScope: View {
///
///     @Binding var scope: ViewScope
///
///     var body: some View { ... }
///
/// }
/// ```
///
/// ### Starting Work When a View Appears
///
/// The scope becomes active when the scoped view appears. Tasks assigned before then are ignored, which includes tasks assigned from the `onAppear` action of a child view. In debug builds, an ignored task reports a runtime issue in Xcode.
/// To start work when a view appears, use SwiftUI's own `task` modifier instead.
///
/// ### Managing a Scope Manually
///
/// If you need more control over how a scope is created and bound, use the ``Scope`` property wrapper and the ``SwiftUICore/View/scope(to:)`` modifier.
@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct ScopedView<T>: View where T: View {

    // MARK: - Initializers

    /// Create a new scoped view
    ///
    /// For example:
    ///
    /// ```swift
    /// ScopedView { scope in
    ///     Button("Make Network Request") {
    ///         scope.task {
    ///             await makeNetworkRequest()
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter content: A view builder that receives a binding to the view's scope and produces the content of the view. The scope is also available to the content using the ``CurrentScope`` property wrapper.
    public init(
        @ViewBuilder content: @escaping @MainActor (Binding<ViewScope>) -> T
    ) {
        self.content = content
    }

    // MARK: - View

    public var body: some View {
        content($scope)
            .scope(to: $scope)
    }

    // MARK: - Private

    private let content: @MainActor (Binding<ViewScope>) -> T

    @Scope
    private var scope

}
