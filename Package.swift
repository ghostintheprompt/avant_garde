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
            ],
            path: "src"
        ),
        .target(
            name: "Converters",
            dependencies: [],
            path: "src/converters"
        ),
        .target(
            name: "Parsers",
            dependencies: [],
            path: "src/parsers"
        ),
        .target(
            name: "Audio",
            dependencies: [],
            path: "src/audio"
        ),
        .target(
            name: "UI",
            dependencies: [],
            path: "src/ui"
        ),
        .target(
            name: "Models",
            dependencies: [],
            path: "src/models"
        ),
        .target(
            name: "Editor",
            dependencies: ["Models"],
            path: "src/editor"
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