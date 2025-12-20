# ViewScope

[![MIT License](https://img.shields.io/github/license/vsanthanam/ViewScope)](https://github.com/vsanthanam/ViewScope/blob/main/LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/vsanthanam/ViewScope?include_prereleases)](https://github.com/vsanthanam/ViewScope/releases)
[![Build Status](https://img.shields.io/github/check-runs/vsanthanam/ViewScope/main)](https://github.com/vsanthanam/ViewScope/actions)
[![Swift Version](https://img.shields.io/badge/swift-6.1-critical)](https://swift.org)
[![Documentation](https://img.shields.io/badge/Documentation-GitHub-8A2BE2)](https://www.viewsco.pe/docs/documentation/viewscope)

## Overview

ViewScope is a library that lets you create structured, SwiftUI-friendly async contexts for imperative asynchronous work, such as making a network request when a user taps on a button. It allows you to scope this work to a specific node in the SwiftUI view hiearchy and prevents you from needing to rely on unstructured concurrency to manage task cancellation.

For example:

```swift
import ViewScope

struct MyScreen: View {

    @ViewScope myScope
    
    var body: some View {
        VStack {
            Text("This screen can produce async side effects that need to be cancelled if it ever disappears, for example if the user interacts with a deeplink or dismisses a sheet presentation with a swipe")
            Button("Make Network Request") {
                myScope.task {
                    await makeNetworkRequest()
                }
            }
        }
        .whileVisible($myScope)
    }

    func makeNetworkRequest() async {
        // Await things here
    }

}
```

## Installation

ViewScope currently distributed exclusively through the [Swift Package Manager](https://www.swift.org/package-manager/). 

To add ViewScope as a dependency to an existing Swift package, add the following line of code to the `dependencies` parameter of your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/vsanthanam/ViewScope.git", from: "1.0.0")
]
```

To add ViewScope as a dependency to an Xcode Project: 

- Choose `File` → `Add Packages...`
- Enter package URL `https://github.com/vsanthanam/ViewScope.git` and select your release and of choice.

Other distribution mechanisms like CocoaPods or Carthage may be added in the future.

## Usage & Documentation

ViewScope's documentation is built with [DocC](https://developer.apple.com/documentation/docc) and included in the repository as a DocC archive. The latest version is hosted on [GitHub Pages](https://pages.github.com) and is available [here](https://www.viewsco.pe/docs/documentation/viewscope)).

Additional installation instructions are available on the [Swift Package Index](https://swiftpackageindex.com/vsanthanam/ViewScope)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvsanthanam%2FViewScope%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/vsanthanam/ViewScope)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fvsanthanam%2FViewScope%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/vsanthanam/ViewScope)

Explore [the documentation](https://www.viewsco.pe/docs/documentation/viewscope) for more details.

## License

**ViewScope** is available under the [MIT license](https://en.wikipedia.org/wiki/MIT_License). See the [LICENSE](https://github.com/vsanthanam/ViewScope/blob/main/LICENSE) file for more information.
