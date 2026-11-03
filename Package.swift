// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MmpKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "MmpCore", targets: ["MmpCore"]),
        .library(name: "MmpAppsFlyer", targets: ["MmpAppsFlyer"]),
        .library(name: "MmpAdjust", targets: ["MmpAdjust"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MmpCore",
            dependencies: [],
            path: "Sources/MmpCore"
        ),
        .target(
            name: "MmpAppsFlyer",
            dependencies: ["MmpCore"],
            path: "Sources/MmpAppsFlyer"
        ),
        .target(
            name: "MmpAdjust",
            dependencies: ["MmpCore"],
            path: "Sources/MmpAdjust"
        ),
        .testTarget(
            name: "MmpCoreTests",
            dependencies: ["MmpCore", "MmpAppsFlyer", "MmpAdjust"],
            path: "Tests/MmpCoreTests"
        ),
    ]
)
