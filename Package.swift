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
    dependencies: [
        .package(path: "CraftUIKit")
    ],
    targets: [
        .target(
            name: "VocabCraftApp",
            dependencies: [
                .product(name: "CraftUIKit", package: "CraftUIKit")
            ],
            path: "VocabCraftApp",
            exclude: [
                "App/Info.plist",
                "App/VocabCraftApp.entitlements"
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "VocabCraftWidgetExtension",
            dependencies: ["VocabCraftApp"],
            path: "VocabCraftWidgetExtension",
            exclude: [
                "Info.plist"
            ]
        ),
        .testTarget(
            name: "VocabCraftAppTests",
            dependencies: ["VocabCraftApp", "VocabCraftWidgetExtension"],
            path: "VocabCraftAppTests"
        )
    ]
)
