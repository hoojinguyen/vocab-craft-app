// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SpeechKit",
    defaultLocalization: "en",
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
    targets: [
        .target(
            name: "SpeechKit",
            path: "Sources/SpeechKit"
        ),
        .testTarget(
            name: "SpeechKitTests",
            dependencies: ["SpeechKit"],
            path: "Tests/SpeechKitTests"
        )
    ]
)
