// ViewScope
// ViewScopeTests.swift
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
import Testing
@testable import ViewScope

@MainActor
@Suite
struct ViewScopeTests {

    // MARK: - Binding

    @Test
    func tasksRunWhileBound() async {
        let recorder = Recorder()
        var scope = ViewScope()
        scope.activate()
        scope.task { await recorder.run() }
        #expect(await eventually { recorder.started == 1 })
        #expect(recorder.cancelled == 0)
        scope.deactivate()
    }

    @Test
    func tasksAreCancelledWhenUnbound() async {
        let recorder = Recorder()
        var scope = ViewScope()
        scope.activate()
        scope.task { await recorder.run() }
        #expect(await eventually { recorder.started == 1 })
        scope.deactivate()
        #expect(await eventually { recorder.cancelled == 1 })
    }

    @Test
    func tasksAreIgnoredAfterUnbinding() async {
        let recorder = Recorder()
        var scope = ViewScope()
        scope.activate()
        scope.deactivate()
        scope.task { await recorder.run() }
        await settle()
        #expect(recorder.started == 0)
    }

    @Test
    func scopeCanBeReboundAfterUnbinding() async {
        let recorder = Recorder()
        var scope = ViewScope()
        scope.activate()
        scope.deactivate()
        scope.activate()
        scope.task { await recorder.run() }
        #expect(await eventually { recorder.started == 1 })
        scope.deactivate()
        #expect(await eventually { recorder.cancelled == 1 })
    }

    @Test
    func tasksSurviveUntilEveryBindingIsRemoved() async {
        let recorder = Recorder()
        var scope = ViewScope()
        scope.activate()
        scope.activate()
        scope.task { await recorder.run() }
        #expect(await eventually { recorder.started == 1 })
        scope.deactivate()
        await settle()
        #expect(recorder.cancelled == 0)
        scope.deactivate()
        #expect(await eventually { recorder.cancelled == 1 })
    }

    @Test
    func tasksAreIgnoredBeforeBinding() async {
        let recorder = Recorder()
        var scope = ViewScope()
        scope.task { await recorder.run() }
        scope.task(id: "id") { await recorder.run() }
        scope.activate()
        await settle()
        #expect(recorder.started == 0)
        scope.deactivate()
    }

    // MARK: - Identified Tasks

    @Test
    func tasksWithTheSameIDReplaceEachOther() async {
        let first = Recorder()
        let second = Recorder()
        var scope = ViewScope()
        scope.activate()
        scope.task(id: "id") { await first.run() }
        #expect(await eventually { first.started == 1 })
        scope.task(id: "id") { await second.run() }
        #expect(await eventually { first.cancelled == 1 })
        #expect(await eventually { second.started == 1 })
        #expect(second.cancelled == 0)
        scope.deactivate()
        #expect(await eventually { second.cancelled == 1 })
    }

    @Test
    func tasksWithDifferentIDsRunTogether() async {
        let recorder = Recorder()
        var scope = ViewScope()
        scope.activate()
        scope.task(id: "a") { await recorder.run() }
        scope.task(id: "b") { await recorder.run() }
        #expect(await eventually { recorder.started == 2 })
        await settle()
        #expect(recorder.cancelled == 0)
        scope.deactivate()
        #expect(await eventually { recorder.cancelled == 2 })
    }

    // MARK: - Overloads

    @Test
    func executorPreferenceOverloadsRunAndCancel() async {
        let recorder = Recorder()
        var scope = ViewScope()
        scope.activate()
        scope.task(executorPreference: nil) { await recorder.run() }
        scope.task(id: "id", executorPreference: nil) { await recorder.run() }
        #expect(await eventually { recorder.started == 2 })
        scope.deactivate()
        #expect(await eventually { recorder.cancelled == 2 })
    }

    @Test
    func bindingOverloadsRunAndCancel() async {
        let recorder = Recorder()
        let storage = Storage()
        let binding = Binding {
            storage.scope
        } set: { newValue in
            storage.scope = newValue
        }
        storage.scope.activate()
        binding.task { await recorder.run() }
        binding.task(id: "a") { await recorder.run() }
        binding.task(executorPreference: nil) { await recorder.run() }
        binding.task(id: "b", executorPreference: nil) { await recorder.run() }
        #expect(await eventually { recorder.started == 4 })
        storage.scope.deactivate()
        #expect(await eventually { recorder.cancelled == 4 })
    }

    @Test
    func operationsInheritTheIsolationOfTheCaller() async {
        let recorder = Recorder()
        let unsendable = Unsendable()
        var scope = ViewScope()
        scope.activate()
        // Compiles only because the operation inherits the main actor from this test.
        scope.task {
            unsendable.value += 1
            await recorder.run()
        }
        #expect(await eventually { recorder.started == 1 })
        #expect(unsendable.value == 1)
        scope.deactivate()
    }

    @Test
    func operationsCaptureSelfImplicitly() async {
        let owner = Owner()
        owner.scope.activate()
        owner.start()
        owner.startThroughBinding()
        #expect(await eventually { owner.recorder.started == 2 })
        owner.scope.deactivate()
        #expect(await eventually { owner.recorder.cancelled == 2 })
    }

    @Test
    func explicitlyIsolatedAsyncOperationsAreSupported() async {
        let recorder = Recorder()
        var scope = ViewScope()
        scope.activate()
        // Regression test: this closure shape used to fail to compile.
        scope.task { @MainActor in
            await Task.yield()
            await recorder.run()
        }
        #expect(await eventually { recorder.started == 1 })
        scope.deactivate()
        #expect(await eventually { recorder.cancelled == 1 })
    }

    // MARK: - CurrentScope

    @Test
    func currentScopeTrapsWithoutAnEnclosingScope() async {
        await #expect(processExitsWith: .failure) {
            _ = CurrentScope().projectedValue
        }
    }

}

@MainActor
private final class Storage {
    var scope = ViewScope()
}

@MainActor
private final class Owner {

    var scope = ViewScope()

    let recorder = Recorder()

    func start() {
        scope.task { await recorder.run() }
    }

    func startThroughBinding() {
        let binding = Binding {
            self.scope
        } set: { newValue in
            self.scope = newValue
        }
        binding.task(id: "id") { await recorder.run() }
    }

}

private final class Unsendable {
    var value = 0
}
