// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "VocabCraftApp",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "VocabCraftApp",
            targets: ["VocabCraftApp"]
        ),
        .library(
            name: "VocabCraftWidgetExtension",
            targets: ["VocabCraftWidgetExtension"]
        )
    ],
    targets: [
        .target(
            name: "VocabCraftApp",
            path: "VocabCraftApp",
            resources: [.process("Resources")]
        ),
        .target(
            name: "VocabCraftWidgetExtension",
            dependencies: ["VocabCraftApp"],
            path: "VocabCraftWidgetExtension"
        ),
        .testTarget(
            name: "VocabCraftAppTests",
            dependencies: ["VocabCraftApp", "VocabCraftWidgetExtension"],
            path: "VocabCraftAppTests"
        )
    ]
)
