// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "AvantGarde",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "AvantGarde", targets: ["AvantGarde"]),
    ],
    dependencies: [
        // Add external dependencies here if needed in the future
    ],
    targets: [
        .executableTarget(
            name: "AvantGarde",
            path: "src",
            resources: [
                .copy("../Resources")
            ]
        ),
        .testTarget(
            name: "AvantGardeTests",
            dependencies: ["AvantGarde"],
            path: "Tests"
        ),
    ]
)