// ViewScope
// VisibilityScope.swift
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

/// A visibility scope is a type that provides an async context that is cancelled based on the visibility lifecycle of one or more attached views.
///
/// You do not create instances of this type yourself.
///
/// Instead, use a ``ScopedView``, which creates a new scope, binds it to the visibility lifecycle of the view, and provides it to your content.
///
/// For example:
///
/// ```swift
/// struct MyView: View {
///
///     var body: some View {
///         ScopedView { scope in
///             Button("Do Something Async") {
///                 scope.task {
///                     // Await stuff here.
///                     // Tasks will be cancelled when the scoped view disappears from the view hierarchy
///                 }
///             }
///         }
///     }
///
/// }
/// ```
///
/// Child views can read the scope of the nearest enclosing ``ScopedView`` using the ``CurrentScope`` property wrapper.
///
/// ### Adding Tasks
///
/// You can attach tasks to the scope using one of several available `task` instance methods, which mimic Apple's own `Task` API.
/// The same methods are available on a `Binding` to a scope, so you can call them directly on the value provided by a ``ScopedView``.
///
/// When none of the views bound to the scope are visible, any tasks managed by the scope are cancelled.
/// Tasks that are added to the scope when no bound views are visible are ignored.
///
/// ### Preventing Duplicate Tasks
///
/// Tasks scoped to a `VisibilityScope` can be attached with an optional ID.
/// The behavior is similar to using SwiftUI's built-in `.task` modifier with an `id` argument — when a new task with the same ID as a previously known task is attached, the previous task with that ID is cancelled before the new one starts.
///
/// ### Managing a Scope Manually
///
/// If you need more control over the lifecycle of a scope, you can create an unbound scope using the ``ViewScope`` property wrapper, and bind it to one or more views using the ``SwiftUICore/View/viewScope(_:)`` view modifier.
///
/// For example:
///
/// ```swift
/// struct MyView: View {
///
///     @ViewScope var myScope
///
///     var body: some View {
///         Text("Async Work Available")
///             .viewScope($myScope)
///         Button("Do Something Async") {
///             myScope.task {
///                 // Await stuff here.
///                 // Tasks will be cancelled when the `Text` above disappears from the view hierarchy
///             }
///         }
///     }
///
/// }
/// ```
///
/// - Important: Tasks added to a scope that has not been bound to a view are ignored. In debug builds, this reports a runtime issue in Xcode.
@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct VisibilityScope {

    // MARK: - API

    /// Attach a task to the scope
    /// - Parameters:
    ///   - priority: The priority of the operation task.
    ///   - fileID: The file from which the task was attached. Used for runtime diagnostics.
    ///   - line: The line from which the task was attached. Used for runtime diagnostics.
    ///   - operation: The operation to perform.
    public mutating func task(
        priority: TaskPriority = .userInitiated,
        fileID: StaticString = #fileID,
        line: UInt = #line,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        guard bindCount > 0 else {
            reportIfNeverBound(fileID: fileID, line: line)
            return
        }
        enqueue(Task(priority: priority, operation: operation))
    }

    /// Attach a uniquely identified task to the scope
    /// - Parameters:
    ///   - id: A uniqueness identifier. New tasks provided with this identifier will cancel this one.
    ///   - priority: The priority of the operation task.
    ///   - fileID: The file from which the task was attached. Used for runtime diagnostics.
    ///   - line: The line from which the task was attached. Used for runtime diagnostics.
    ///   - operation: The operation to perform.
    public mutating func task(
        id: some Hashable,
        priority: TaskPriority = .userInitiated,
        fileID: StaticString = #fileID,
        line: UInt = #line,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        guard bindCount > 0 else {
            reportIfNeverBound(fileID: fileID, line: line)
            return
        }
        enqueue(Task(priority: priority, operation: operation), with: id)
    }

    /// Attach a task to the scope
    /// - Parameters:
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - priority: The priority of the operation task.
    ///   - fileID: The file from which the task was attached. Used for runtime diagnostics.
    ///   - line: The line from which the task was attached. Used for runtime diagnostics.
    ///   - operation: The operation to perform.
    public mutating func task(
        executorPreference taskExecutor: (any TaskExecutor)?,
        priority: TaskPriority = .userInitiated,
        fileID: StaticString = #fileID,
        line: UInt = #line,
        operation: sending @escaping () async -> Void
    ) {
        guard bindCount > 0 else {
            reportIfNeverBound(fileID: fileID, line: line)
            return
        }
        enqueue(Task(executorPreference: taskExecutor, priority: priority, operation: operation))
    }

    /// Attach a uniquely identified task to the scope
    /// - Parameters:
    ///   - id: A uniqueness identifier. New tasks provided with this identifier will cancel this one.
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - priority: The priority of the operation task.
    ///   - fileID: The file from which the task was attached. Used for runtime diagnostics.
    ///   - line: The line from which the task was attached. Used for runtime diagnostics.
    ///   - operation: The operation to perform.
    public mutating func task(
        id: some Hashable,
        executorPreference taskExecutor: (any TaskExecutor)?,
        priority: TaskPriority = .userInitiated,
        fileID: StaticString = #fileID,
        line: UInt = #line,
        operation: sending @escaping () async -> Void
    ) {
        guard bindCount > 0 else {
            reportIfNeverBound(fileID: fileID, line: line)
            return
        }
        enqueue(Task(executorPreference: taskExecutor, priority: priority, operation: operation), with: id)
    }

    // MARK: - Private

    init() {}

    mutating func activate() {
        hasBeenBound = true
        bindCount += 1
    }

    mutating func deactivate() {
        bindCount -= 1
    }

    private var tasks: [Task<Void, Never>] = []
    private var keyed: [AnyHashable: Task<Void, Never>] = [:]
    private var hasBeenBound = false
    private var bindCount: Int = 0 {
        didSet {
            flush()
            if bindCount < 0 {
                assertionFailure("Bind count has decremented below zero. This should never happen!")
                bindCount = 0
            }
        }
    }

    private mutating func enqueue(
        _ task: Task<Void, Never>
    ) {
        tasks.append(task)
    }

    private mutating func enqueue(
        _ task: Task<Void, Never>,
        with id: some Hashable
    ) {
        keyed[id]?.cancel()
        keyed[id] = task
    }

    private func reportIfNeverBound(
        fileID: StaticString,
        line: UInt
    ) {
        guard !hasBeenBound else { return }
        runtimeIssue(
            "A task was attached to a VisibilityScope that has not been bound to a view, so it was ignored. Bind the scope using the viewScope(_:) modifier, or use ScopedView.",
            fileID: fileID,
            line: line
        )
    }

    private mutating func flush() {
        guard bindCount == .zero else { return }
        for task in tasks {
            task.cancel()
        }
        tasks = []
        for (_, task) in keyed {
            task.cancel()
        }
        keyed = [:]
    }

}

@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Binding where Value == VisibilityScope {

    /// Attach a task to the scope
    /// - Parameters:
    ///   - priority: The priority of the operation task.
    ///   - fileID: The file from which the task was attached. Used for runtime diagnostics.
    ///   - line: The line from which the task was attached. Used for runtime diagnostics.
    ///   - operation: The operation to perform.
    public func task(
        priority: TaskPriority = .userInitiated,
        fileID: StaticString = #fileID,
        line: UInt = #line,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        wrappedValue.task(
            priority: priority,
            fileID: fileID,
            line: line,
            operation: operation
        )
    }

    /// Attach a uniquely identified task to the scope
    /// - Parameters:
    ///   - id: A uniqueness identifier. New tasks provided with this identifier will cancel this one.
    ///   - priority: The priority of the operation task.
    ///   - fileID: The file from which the task was attached. Used for runtime diagnostics.
    ///   - line: The line from which the task was attached. Used for runtime diagnostics.
    ///   - operation: The operation to perform.
    public func task(
        id: some Hashable,
        priority: TaskPriority = .userInitiated,
        fileID: StaticString = #fileID,
        line: UInt = #line,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        wrappedValue.task(
            id: id,
            priority: priority,
            fileID: fileID,
            line: line,
            operation: operation
        )
    }

    /// Attach a task to the scope
    /// - Parameters:
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - priority: The priority of the operation task.
    ///   - fileID: The file from which the task was attached. Used for runtime diagnostics.
    ///   - line: The line from which the task was attached. Used for runtime diagnostics.
    ///   - operation: The operation to perform.
    public func task(
        executorPreference taskExecutor: (any TaskExecutor)?,
        priority: TaskPriority = .userInitiated,
        fileID: StaticString = #fileID,
        line: UInt = #line,
        operation: sending @escaping () async -> Void
    ) {
        wrappedValue.task(
            executorPreference: taskExecutor,
            priority: priority,
            fileID: fileID,
            line: line,
            operation: operation
        )
    }

    /// Attach a uniquely identified task to the scope
    /// - Parameters:
    ///   - id: A uniqueness identifier. New tasks provided with this identifier will cancel this one.
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - priority: The priority of the operation task.
    ///   - fileID: The file from which the task was attached. Used for runtime diagnostics.
    ///   - line: The line from which the task was attached. Used for runtime diagnostics.
    ///   - operation: The operation to perform.
    public func task(
        id: some Hashable,
        executorPreference taskExecutor: (any TaskExecutor)?,
        priority: TaskPriority = .userInitiated,
        fileID: StaticString = #fileID,
        line: UInt = #line,
        operation: sending @escaping () async -> Void
    ) {
        wrappedValue.task(
            id: id,
            executorPreference: taskExecutor,
            priority: priority,
            fileID: fileID,
            line: line,
            operation: operation
        )
    }

}
