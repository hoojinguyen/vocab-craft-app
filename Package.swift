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
    ],
    targets: [
        .target(
            name: "VocabCraftApp",
            path: "VocabCraftApp"
        ),
        .testTarget(
            name: "VocabCraftAppTests",
            dependencies: ["VocabCraftApp"],
            path: "VocabCraftAppTests"
        ),
    ]
)
