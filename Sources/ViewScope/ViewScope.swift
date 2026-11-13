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
import Synchronization

/// A view scope is a type that provides an async context that is cancelled based on the visibility lifecycle of one or more attached views.
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
/// Like `Task`, an operation inherits the actor isolation of the context that it is created in, unless you provide an executor preference.
///
/// When none of the views bound to the scope are visible, any tasks managed by the scope are cancelled.
/// Tasks that are added to the scope after its bound views have disappeared are ignored.
///
/// Tasks that are added to the scope before it has been bound to a view, for example when a child view appears, are held and start as soon as the scope is bound.
///
/// ### Preventing Duplicate Tasks
///
/// Tasks scoped to a `ViewScope` can be attached with an optional ID.
/// The behavior is similar to using SwiftUI's built-in `.task` modifier with an `id` argument — when a new task with the same ID as a previously known task is attached, the previous task with that ID is cancelled before the new one starts.
///
/// ### Managing a Scope Manually
///
/// If you need more control over the lifecycle of a scope, you can create an unbound scope using the ``Scope`` property wrapper, and bind it to one or more views using the ``SwiftUICore/View/scope(to:)`` view modifier.
///
/// For example:
///
/// ```swift
/// struct MyView: View {
///
///     @Scope var myScope
///
///     var body: some View {
///         Text("Async Work Available")
///             .scope(to: $myScope)
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
/// - Important: Tasks added to a scope that is never bound to a view do not start. In debug builds, a task that is still waiting for its scope to be bound after a short time reports a runtime issue in Xcode.
@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct ViewScope {

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
        @_inheritActorContext @_implicitSelfCapture operation: sending @escaping @isolated(any) () async -> Void
    ) {
        if bindCount > 0 {
            enqueue(
                Task(
                    priority: priority,
                    operation: operation
                )
            )
        } else if !hasBeenBound {
            let activation = activation(fileID: fileID, line: line)
            enqueue(
                Task(
                    priority: priority
                ) {
                    guard await activation.first(where: { _ in true }) != nil, !Task.isCancelled else { return }
                    await operation()
                }
            )
        }
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
        @_inheritActorContext @_implicitSelfCapture operation: sending @escaping @isolated(any) () async -> Void
    ) {
        if bindCount > 0 {
            enqueue(
                Task(
                    priority: priority,
                    operation: operation
                ),
                with: id
            )
        } else if !hasBeenBound {
            let activation = activation(fileID: fileID, line: line)
            enqueue(
                Task(
                    priority: priority
                ) {
                    guard await activation.first(where: { _ in true }) != nil, !Task.isCancelled else { return }
                    await operation()
                },
                with: id
            )
        }
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
        if bindCount > 0 {
            enqueue(
                Task(
                    executorPreference: taskExecutor,
                    priority: priority,
                    operation: operation
                )
            )
        } else if !hasBeenBound {
            let activation = activation(fileID: fileID, line: line)
            enqueue(
                Task(
                    executorPreference: taskExecutor,
                    priority: priority
                ) {
                    guard await activation.first(where: { _ in true }) != nil, !Task.isCancelled else { return }
                    await operation()
                }
            )
        }
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
        if bindCount > 0 {
            enqueue(
                Task(
                    executorPreference: taskExecutor,
                    priority: priority,
                    operation: operation
                ),
                with: id
            )
        } else if !hasBeenBound {
            let activation = activation(fileID: fileID, line: line)
            enqueue(
                Task(
                    executorPreference: taskExecutor,
                    priority: priority
                ) {
                    guard await activation.first(where: { _ in true }) != nil, !Task.isCancelled else { return }
                    await operation()
                },
                with: id
            )
        }
    }

    // MARK: - Private

    init() {}

    mutating func activate() {
        hasBeenBound = true
        bindCount += 1
        gate.open()
    }

    mutating func deactivate() {
        bindCount -= 1
    }

    private var tasks: [Task<Void, Never>] = []
    private var keyed: [AnyHashable: Task<Void, Never>] = [:]
    private var hasBeenBound = false
    private let gate = ActivationGate()
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

    private func activation(
        fileID: StaticString,
        line: UInt
    ) -> AsyncStream<Void> {
        #if DEBUG
            Task { [weak gate] in
                try? await Task.sleep(for: .seconds(1))
                guard let gate, !gate.isOpen else { return }
                runtimeIssue(
                    "A task was attached to a ViewScope that has not been bound to a view, so it has not started. Bind the scope using the scope(to:) modifier, or use ScopedView.",
                    fileID: fileID,
                    line: line
                )
            }
        #endif
        return gate.activation()
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
extension Binding where Value == ViewScope {

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
        @_inheritActorContext @_implicitSelfCapture operation: sending @escaping @isolated(any) () async -> Void
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
        @_inheritActorContext @_implicitSelfCapture operation: sending @escaping @isolated(any) () async -> Void
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

/// A gate that holds tasks attached to a scope before the scope is first bound to a view.
@available(macOS 15.0, macCatalyst 18.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
final class ActivationGate: Sendable {

    // MARK: - API

    /// Whether or not the gate has been opened
    var isOpen: Bool {
        state.withLock { state in
            state.isOpen
        }
    }

    /// Open the gate, releasing every pending activation
    func open() {
        let pending = state.withLock { state in
            state.isOpen = true
            let pending = state.pending
            state.pending = []
            return pending
        }
        for continuation in pending {
            continuation.yield()
            continuation.finish()
        }
    }

    /// Create a stream that yields a single value once the gate opens, or finishes without yielding a value if the gate is discarded before it opens.
    func activation() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let isOpen = state.withLock { state in
            if !state.isOpen {
                state.pending.append(continuation)
            }
            return state.isOpen
        }
        if isOpen {
            continuation.yield()
            continuation.finish()
        }
        return stream
    }

    // MARK: - Private

    private struct State {
        var isOpen = false
        var pending: [AsyncStream<Void>.Continuation] = []
    }

    private let state = Mutex(State())

    deinit {
        let pending = state.withLock { state in
            state.pending
        }
        for continuation in pending {
            continuation.finish()
        }
    }

}
