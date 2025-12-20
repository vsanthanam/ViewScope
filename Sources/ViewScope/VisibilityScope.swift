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

/// A visibility scope is a type that provides an async context that is cancelled based on the visibilty lifecycle of one or more views attached views.
///
/// You do not create instances of this type yourself.
///
/// Instead, use the provided ``ViewScope`` SwiftUI property wrapper, which creates a new, unbound scope.
///
/// For example:
///
/// ```swift
/// struct MyView: View {
///
///     @ViewScope var myScope
///
///     var body: some View { ... }
///
/// }
/// ```
///
/// ViewScopes must be bound to the visibility lifecycle of one or more SwiftUI views.
///
/// You can do this using the ``SwiftUICore/View/whileVisible(_:)`` view modifier.
///
/// For example:
///
/// ```swift
/// struct MyView: View {
///
///     @ViewScope var myScope
///
///     var body: some View {
///         Text("View")
///             .whileVisible($myScope)
///     }
///
/// }
/// ```
///
/// When none of the bound views are visible, any tasks managed by the scope are cancelled.
/// Tasks that are added to the scope when no attached views are visible are ignored.
///
/// You can attach tasks to the scope using one of several available `.task` instance methods, which mimic Apple's own `Task` API:
///
/// ```swift
/// struct MyView: View {
///
///     @ViewScope var myScope
///
///     var body: some View {
///         Text("Async Work Available")
///             .whileVisible($myScope)
///         Button("Do Something Async") {
///             myScope.task {
///                 // Await stuff here.
///                 // Tasks will be cancelled the `Text` above disappears from the view hierarchy
///             }
///         }
///     }
///
/// }
/// ```
///
/// ### Preventing Duplicate Tasks
///
/// Tasks scoped to a `VisibilityScope` can attached with an optional ID.
/// The behavior is similar to using SwiftUI's built-in `.task` modifier with an ID: when a new task with the same ID as previously known task is started, the previous task with that is is cancelled first.
@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct VisibilityScope {

    // MARK: - API

    /// Attach a task to the scope
    /// - Parameters:
    ///   - name: Human readable name of the task.
    ///   - priority: The priority of the operation task.
    ///   - operation: The operation to perform.
    public mutating func task(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        enqueue(Task(name: name, priority: priority, operation: operation))
    }

    /// Attach a uniquely identified task to the scope
    /// - Parameters:
    ///   - id: A uniqueness identifier. New tasks provided with this identifier will cancel this one.
    ///   - name: Human readable name of the task.
    ///   - priority: The priority of the operation task.
    ///   - operation: The operation to perform.
    public mutating func task(
        id: some Hashable,
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        guard bindCount > 0 else { return }
        enqueue(Task(name: name, priority: priority, operation: operation), with: id)
    }

    /// Attach a task to the scope
    /// - Parameters:
    ///   - name: Human readable name of the task.
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - priority: The priority of the operation task.
    ///   - operation: The operation to perform.
    public mutating func task(
        name: String? = nil,
        executorPreference taskExecutor: (any TaskExecutor)?,
        priority: TaskPriority? = nil,
        operation: sending @escaping () async -> Void
    ) {
        enqueue(Task(name: name, executorPreference: taskExecutor, priority: priority, operation: operation))
    }

    /// Attach a uniquely identified task to the scope
    /// - Parameters:
    ///   - id: A uniqueness identifier. New tasks provided with this identifier will cancel this one.
    ///   - name: Human readable name of the task.
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - priority: The priority of the operation task.
    ///   - operation: The operation to perform.
    public mutating func task(
        id: some Hashable,
        name: String? = nil,
        executorPreference taskExecutor: (any TaskExecutor)?,
        priority: TaskPriority? = nil,
        operation: sending @escaping () async -> Void
    ) {
        enqueue(Task(name: name, executorPreference: taskExecutor, priority: priority, operation: operation), with: id)
    }

    /// Attach a detached task to the scope
    /// - Parameters:
    ///   - name: Human readable name of the task.
    ///   - priority: The priority of the operation task.
    ///   - operation: The operation to perform.
    public mutating func detachedTask(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        enqueue(Task.detached(name: name, priority: priority, operation: operation))
    }

    /// Attached a detached task to the scope
    /// - Parameters:
    ///   - name: Human readable name of the task.
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - priority: The priority of the operation task.
    ///   - operation: The operation to perform.
    public mutating func detachedTask(
        name: String? = nil,
        executorPreference taskExecutor: (any TaskExecutor)?,
        priority: TaskPriority? = nil,
        operation: sending @escaping () async -> Void
    ) {
        enqueue(Task.detached(name: name, executorPreference: taskExecutor, priority: priority, operation: operation))
    }

    /// Attach a uniquely identified detached task to the scope
    /// - Parameters:
    ///   - id: A uniqueness identifier. New tasks provided with this identifier will cancel this one.
    ///   - name: Human readable name of the task.
    ///   - priority: The priority of the operation task.
    ///   - operation: The operation to perform.
    public mutating func detachedTask(
        id: some Hashable,
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        enqueue(Task.detached(name: name, priority: priority, operation: operation), with: id)
    }

    /// Attached a uniquely identified detached task to the scope
    /// - Parameters:
    ///   - id: A uniqueness identifier. New tasks provided with this identifier will cancel this one.
    ///   - name: Human readable name of the task.
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - priority: The priority of the operation task.
    ///   - operation: The operation to perform.
    public mutating func detachedTask(
        id: some Hashable,
        name: String? = nil,
        executorPreference taskExecutor: (any TaskExecutor)?,
        priority: TaskPriority? = nil,
        operation: sending @escaping () async -> Void
    ) {
        enqueue(Task.detached(name: name, executorPreference: taskExecutor, priority: priority, operation: operation), with: id)
    }

    /// Attach an immediate task to the scope
    /// - Parameters:
    ///   - name: The high-level human-readable name given for this task.
    ///   - priority: The priority of the task. Pass nil to use the `basePriority` of the current task (if there is one).
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - operation: The operation to perform.
    @available(macOS 26.0, macCatalyst 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    public mutating func immediateTask(
        name: String? = nil,
        priority: TaskPriority? = nil,
        executorPreference taskExecutor: consuming (any TaskExecutor)? = nil,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        enqueue(Task.immediate(name: name, priority: priority, executorPreference: taskExecutor, operation: operation))
    }

    /// Attach a unquely identified immediate task to the scope
    /// - Parameters:
    ///   - id: A uniqueness identifier. New tasks provided with this identifier will cancel this one.
    ///   - name: The high-level human-readable name given for this task.
    ///   - priority: The priority of the task. Pass nil to use the `basePriority` of the current task (if there is one).
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - operation: The operation to perform.
    @available(macOS 26.0, macCatalyst 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    public mutating func immediateTask(
        id: some Hashable,
        name: String? = nil,
        priority: TaskPriority? = nil,
        executorPreference taskExecutor: consuming (any TaskExecutor)? = nil,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        enqueue(Task.immediate(name: name, priority: priority, executorPreference: taskExecutor, operation: operation), with: id)
    }

    /// Attach an immediate detached task to the scope
    /// - Parameters:
    ///   - name: The high-level human-readable name given for this task.
    ///   - priority: The priority of the task. Pass nil to use the `basePriority` of the current task (if there is one).
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - operation: The operation to perform.
    @available(macOS 26.0, macCatalyst 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    public mutating func immediateDetachedTask(
        name: String? = nil,
        priority: TaskPriority? = nil,
        executorPreference taskExecutor: consuming (any TaskExecutor)? = nil,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        enqueue(Task.immediateDetached(name: name, priority: priority, executorPreference: taskExecutor, operation: operation))
    }

    /// Attach a unquely identified immediate detached task to the scope
    /// - Parameters:
    ///   - id: A uniqueness identifier. New tasks provided with this identifier will cancel this one.
    ///   - name: The high-level human-readable name given for this task.
    ///   - priority: The priority of the task. Pass nil to use the `basePriority` of the current task (if there is one).
    ///   - taskExecutor: The task executor that the child task should be started on and keep using.
    ///   Explicitly passing `nil` as the executor preference is equivalent to no preference, and effectively means to inherit the outer context’s executor preference.
    ///   You can also pass the `globalConcurrentExecutor` global executor explicitly.
    ///   - operation: The operation to perform.
    @available(macOS 26.0, macCatalyst 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    public mutating func immediateDetachedTask(
        id: some Hashable,
        name: String? = nil,
        priority: TaskPriority? = nil,
        executorPreference taskExecutor: consuming (any TaskExecutor)? = nil,
        operation: sending @escaping @isolated(any) () async -> Void
    ) {
        enqueue(Task.immediateDetached(name: name, priority: priority, executorPreference: taskExecutor, operation: operation), with: id)
    }

    // MARK: - Private

    init() {}

    mutating func activate() {
        bindCount += 1
    }

    mutating func deactivate() {
        bindCount -= 1
    }

    private var tasks: [Task<Void, Never>] = []
    private var keyed: [AnyHashable: Task<Void, Never>] = [:]
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
        guard bindCount > 0 else { return }
        tasks.append(task)
    }

    private mutating func enqueue(
        _ task: Task<Void, Never>,
        with id: some Hashable
    ) {
        guard bindCount > 0 else { return }
        keyed[id]?.cancel()
        keyed[id] = task
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
