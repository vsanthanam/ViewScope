// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility")
]

let package = Package(
    name: "ViewScope",
    platforms: [
        .macOS(.v15),
        .macCatalyst(.v18),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "ViewScope",
            targets: ["ViewScope"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin.git",
            exact: "1.5.0"
        )
    ],
    targets: [
        .target(
            name: "ViewScope",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ViewScopeTests",
            dependencies: ["ViewScope"],
            swiftSettings: swiftSettings
        )
    ]
)
