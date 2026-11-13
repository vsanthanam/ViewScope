// ViewScope
// TestSupport.swift
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

@MainActor
final class Recorder {

    /// The number of tasks that have started
    private(set) var started = 0

    /// The number of tasks that were cancelled while running
    private(set) var cancelled = 0

    /// A long running operation that records when it starts and when it is cancelled
    func run() async {
        started += 1
        try? await Task.sleep(for: .seconds(60))
        if Task.isCancelled {
            cancelled += 1
        }
    }

}

@MainActor
func eventually(
    timeout: Duration = .seconds(5),
    _ condition: @MainActor () -> Bool
) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if condition() {
            return true
        }
        await turn()
    }
    return condition()
}

@MainActor
func settle(
    for duration: Duration = .milliseconds(250)
) async {
    let deadline = ContinuousClock.now + duration
    while ContinuousClock.now < deadline {
        await turn()
    }
}

@MainActor
private func turn() async {
    try? await Task.sleep(for: .milliseconds(10))
}
