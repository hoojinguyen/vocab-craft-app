// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SpeechKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SpeechKit",
            targets: ["SpeechKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SpeechKit",
            dependencies: [],
            path: "Sources/SpeechKit"
        ),
        .testTarget(
            name: "SpeechKitTests",
            dependencies: ["SpeechKit"],
            path: "Tests/SpeechKitTests"
        )
    ]
)
