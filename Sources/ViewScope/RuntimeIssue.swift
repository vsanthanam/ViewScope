// ViewScope
// RuntimeIssue.swift
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

#if DEBUG
    import Foundation
    import MachO
    import os
#endif

func runtimeIssue(
    _ message: @autoclosure () -> String,
    fileID: StaticString,
    line: UInt
) {
    #if DEBUG
        os_log(
            .fault,
            dso: runtimeIssueDSO,
            log: runtimeIssueLog,
            "%{public}@",
            "\(message()) (\(fileID):\(line))"
        )
    #endif
}

#if DEBUG
    private let runtimeIssueLog = OSLog(
        subsystem: "com.apple.runtime-issues",
        category: "ViewScope"
    )

    private nonisolated(unsafe) let runtimeIssueDSO: UnsafeRawPointer = {
        for index in 0 ..< _dyld_image_count() {
            guard let name = _dyld_get_image_name(index),
                  String(cString: name).hasSuffix("/SwiftUI"),
                  let header = _dyld_get_image_header(index) else { continue }
            return UnsafeRawPointer(header)
        }
        return UnsafeRawPointer(#dsohandle)
    }()
#endif
