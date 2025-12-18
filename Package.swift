// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
    targets: [
        .target(
            name: "ViewScope",
            swiftSettings: [
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("ExistentialAny"),
                .treatAllWarnings(as: .error)
            ]
        ),
        .testTarget(
            name: "ViewScopeTests",
            dependencies: ["ViewScope"],
            swiftSettings: [
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("ExistentialAny"),
                .treatAllWarnings(as: .error)
            ]
        )
    ]
)
