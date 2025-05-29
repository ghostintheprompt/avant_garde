// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AvantGarde",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "AvantGarde", targets: ["AvantGarde"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AvantGarde",
            dependencies: [
                "Converters",
                "Parsers",
                "Audio",
                "UI",
                "Models",
                "Editor"
            ]
        ),
        .target(
            name: "Converters",
            dependencies: []
        ),
        .target(
            name: "Parsers",
            dependencies: []
        ),
        .target(
            name: "Audio",
            dependencies: []
        ),
        .target(
            name: "UI",
            dependencies: []
        ),
        .target(
            name: "Models",
            dependencies: []
        ),
        .target(
            name: "Editor",
            dependencies: ["Models"]
        ),
        .testTarget(
            name: "ConverterTests",
            dependencies: ["Converters"]
        ),
        .testTarget(
            name: "AudioTests",
            dependencies: ["Audio"]
        ),
    ]
)