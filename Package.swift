// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AvantGarde",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "AvantGardeCore", targets: ["AvantGardeCore"]),
    ],
    dependencies: [],
    targets: [
        // All source — cross-platform SwiftUI app (no AppKit dependencies remain)
        .target(
            name: "AvantGardeCore",
            dependencies: [],
            path: "src",
            resources: [],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
            ]
        ),

        // Tests
        .testTarget(
            name: "AvantGardeCoreTests",
            dependencies: ["AvantGardeCore"],
            path: "Tests"
        ),
    ]
)
