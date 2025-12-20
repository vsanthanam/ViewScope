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

/// A SwiftUI property wrapper used to create a new `VisibilityScope`
///
/// Use this property wrapper to create a new ``VisibilityScope``.
///
/// You can then attach the scope to the visibility lifecycle of a view using the ``SwiftUICore/View/whileVisible(_:)`` modifier, and you and assign tasks to the scope using the the various `.task` methods on the scope
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
///         .whileVisible($myScope)
///     }
///
/// }
/// ```
///
/// To pass a scope to a child view, use a SwiftUI binding. The property wrapper supports this using projection. For example:
///
/// ```swift
/// struct ParentThatContainsAScope: View {
///
///     @ViewScope myScope
///
///     var body: some View {
///         ChildThatNeeedsAScope(scope: $myScope)
///     }
///
/// }
/// ```
///
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
