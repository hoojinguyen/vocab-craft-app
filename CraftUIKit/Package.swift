// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CraftUIKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CraftUIKit",
            targets: ["CraftUIKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CraftUIKit",
            dependencies: [],
            path: "Sources/CraftUIKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CraftUIKitTests",
            dependencies: ["CraftUIKit"],
            path: "Tests/CraftUIKitTests"
        )
    ]
)
