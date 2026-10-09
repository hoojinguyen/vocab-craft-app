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
    dependencies: [
        .package(url: "https://github.com/k2-fsa/sherpa-onnx", exact: "1.13.8")
    ],
    targets: [
        .target(
            name: "SpeechKit",
            dependencies: [
                .product(name: "sherpa-onnx", package: "sherpa-onnx")
            ],
            path: "Sources/SpeechKit",
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
        .testTarget(
            name: "SpeechKitTests",
            dependencies: ["SpeechKit"],
            path: "Tests/SpeechKitTests"
        )
    ]
)
