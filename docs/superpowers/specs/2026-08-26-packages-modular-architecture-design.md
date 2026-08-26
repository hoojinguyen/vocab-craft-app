# Architecture Design: Modular Kit Reorganization & Headless SpeechKit

- **Date:** 2026-08-26
- **Status:** Approved / Ready for Implementation Planning
- **Author:** Solution Architect Agent & hoojinguyen
- **Scope:** `Packages/` Monorepo architecture, `CraftUIKit` relocation, `SpeechKit` extraction as headless package, UI adapter integration in `VocabCraftApp`.

---

## 1. Executive Summary & Problem Statement

### 1.1 Context
In the VocabCraft project, reusable modules are conceptualized as "Kits" (similar to modern web libraries/monorepo packages in Nx/Turborepo). Currently:
- `CraftUIKit`: Exists at the root directory (`/CraftUIKit`) as a standalone local Swift Package Manager (SPM) library.
- `SpeechKit`: Resides deep inside the main application target (`VocabCraftApp/Core/SpeechKit`), containing speech recognition, phonetic/fuzzy evaluation algorithms, and an ad-hoc SwiftUI highlight view.

### 1.2 Problems with Current Organization
1. **Inconsistent Module Topology:** Having one kit at the root and another embedded inside `VocabCraftApp/Core` creates confusion regarding module boundaries and scalability.
2. **Coupled UI & Domain Logic in SpeechKit:** `SpeechKit` embeds `SpeechWordHighlightView`, mixing audio engine code with SwiftUI views. Furthermore, `CraftUIKit` already provides a standardized, design-token-compliant `CraftSpeechWordTokenView` and `CraftSpeechWordFlowLayout`, resulting in duplicated UI implementations.
3. **Slow Feedback Loop:** Testing speech recognition algorithms currently requires compiling and linking the entire `VocabCraftApp` target and `VocabCraftAppTests`.
4. **No Scalable Blueprint:** Future modules (e.g., `SRSKit`, `AudioKit`) lack a clear, standardized location and template for extraction.

### 1.3 Goals
- Establish a dedicated `Packages/` directory housing all local Swift Packages.
- Move `CraftUIKit` to `Packages/CraftUIKit`.
- Extract `SpeechKit` into `Packages/SpeechKit` as a 100% headless (logic/engine-only) local SPM package.
- Maintain `CraftUIKit` as a pure Design System with zero dependency on `SpeechKit`.
- Adapt `VocabCraftApp` (`VocabSpeechVisualizerView`) to bridge `SpeechKit` evaluation tokens into `CraftUIKit` token views via an adapter layer.
- Retain 100% test coverage with sub-2-second standalone package test execution.
- Provide a standardized "Golden Blueprint" for creating future kits.

---

## 2. Target Monorepo Architecture & Directory Topology

### 2.1 Repository Layout
```
vocab-craft-app/
├── Packages/
│   ├── CraftUIKit/                               # [MOVED from root /CraftUIKit]
│   │   ├── Package.swift
│   │   ├── Sources/
│   │   │   └── CraftUIKit/
│   │   │       ├── Components/
│   │   │       ├── Tokens/
│   │   │       └── Resources/Localizable.xcstrings
│   │   └── Tests/
│   │       └── CraftUIKitTests/
│   │
│   └── SpeechKit/                                # [NEW standalone headless package]
│       ├── Package.swift
│       ├── README.md
│       ├── Sources/
│       │   └── SpeechKit/
│       │       ├── Engine/
│       │       │   ├── SpeechRecognitionEngine.swift
│       │       │   └── SilenceDetector.swift
│       │       ├── Evaluation/
│       │       │   ├── StringNormalizer.swift
│       │       │   ├── SequenceAligner.swift
│       │       │   └── FuzzySpeechMatcher.swift
│       │       ├── Models/
│       │       │   ├── WordMatchStatus.swift
│       │       │   ├── WordTokenResult.swift
│       │       │   ├── SpeechEvaluationResult.swift
│       │       │   └── SpeechKitError.swift
│       │       ├── Protocols/
│       │       │   └── SpeechAssessmentProtocol.swift
│       │       └── SpeechAssessmentService.swift
│       └── Tests/
│           └── SpeechKitTests/
│               ├── FuzzySpeechMatcherTests.swift
│               ├── SilenceDetectorTests.swift
│               ├── SpeechAssessmentServiceTests.swift
│               ├── SpeechKitModelTests.swift
│               └── StringNormalizerTests.swift
│
├── VocabCraftApp/                               # Main Application
│   ├── App/
│   │   └── DI/AppContainer.swift
│   ├── Core/
│   │   └── DesignSystem/
│   │       └── VocabSpeechVisualizerView.swift  # Adapts SpeechKit -> CraftUIKit
│   └── ...
│
├── VocabCraftAppTests/                          # Feature & Integration Tests
│   └── Core/
│       └── SpeechKitAdapterTests.swift          # Unit tests for adapter mapping
│
├── VocabCraftWidgetExtension/
├── VocabCraftApp.xcodeproj
├── VocabCraft.xcworkspace
└── Package.swift                                # Root manifest coordinating CLI/CI
```

---

## 3. Package Manifests & Workspace Wiring

### 3.1 `Packages/SpeechKit/Package.swift`
```swift
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
```

### 3.2 `Packages/CraftUIKit/Package.swift`
Preserves existing definition, maintaining `defaultLocalization: "en"`, platforms `.iOS(.v17)`, `.macOS(.v14)`, and resource processing for `Localizable.xcstrings`.

### 3.3 Root `Package.swift`
```swift
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
        .package(path: "Packages/CraftUIKit"),
        .package(path: "Packages/SpeechKit")
    ],
    targets: [
        .target(
            name: "VocabCraftApp",
            dependencies: [
                .product(name: "CraftUIKit", package: "CraftUIKit"),
                .product(name: "SpeechKit", package: "SpeechKit")
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
            dependencies: [
                "VocabCraftApp",
                "VocabCraftWidgetExtension",
                .product(name: "CraftUIKit", package: "CraftUIKit"),
                .product(name: "SpeechKit", package: "SpeechKit")
            ],
            path: "VocabCraftAppTests"
        )
    ]
)
```

### 3.4 `VocabCraft.xcworkspace/contents.xcworkspacedata`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:VocabCraftApp.xcodeproj">
   </FileRef>
   <FileRef
      location = "group:Packages/CraftUIKit">
   </FileRef>
   <FileRef
      location = "group:Packages/SpeechKit">
   </FileRef>
</Workspace>
```

### 3.5 `VocabCraftApp.xcodeproj` & `scripts/generate_xcodeproj.py`
- Update `CraftUIKit` local package reference path from `CraftUIKit` to `Packages/CraftUIKit`.
- Add `SpeechKit` local package reference at `Packages/SpeechKit`.
- Link `SpeechKit` product into `VocabCraftApp` framework build phase and `VocabCraftAppTests` build phase.
- Remove deleted `VocabCraftApp/Core/SpeechKit` and `VocabCraftAppTests/SpeechKitTests` source paths from `generate_xcodeproj.py`.

---

## 4. Component Boundaries, Data Flow & Adapter Layer

### 4.1 Dependency Direction
```
                      VocabCraftApp
                      /           \
                     /             \
                    v               v
            Packages/SpeechKit   Packages/CraftUIKit
             (Headless Engine)    (Pure Design System)
```
- **Strict Rule:** `Packages/CraftUIKit` has ZERO dependency on `Packages/SpeechKit`.
- **Strict Rule:** `Packages/SpeechKit` has ZERO dependency on `Packages/CraftUIKit` or `SwiftUI`.
- All integration occurs inside `VocabCraftApp` (Feature/Adapter layer).

### 4.2 UI Standardization & Redundant Code Elimination
1. **Deleted:** `VocabCraftApp/Core/SpeechKit/UI/SpeechWordHighlightView.swift`.
   - Reason: Hardcoded hex colors and duplicate flow layout.
2. **Adopted:** `CraftSpeechWordTokenView` and `CraftSpeechWordFlowLayout` from `CraftUIKit`.
3. **Adapter Implementation in `VocabCraftApp` (`VocabSpeechVisualizerView.swift`):
```swift
import SwiftUI
import SpeechKit
import CraftUIKit

extension WordTokenResult {
    /// Adapts a headless SpeechKit evaluation token into a standardized CraftUIKit display token.
    public var asCraftSpeechWordToken: CraftSpeechWordToken {
        let craftStatus: CraftSpeechStatus
        switch status {
        case .exactMatch:
            craftStatus = .matched
        case .fuzzyMatch:
            craftStatus = .fuzzy
        case .missing:
            craftStatus = .mismatched
        }
        return CraftSpeechWordToken(
            id: id.uuidString,
            targetWord: targetWord,
            status: craftStatus,
            confidence: confidence
        )
    }
}
```

In `VocabSpeechVisualizerView.body`:
```swift
if !tokens.isEmpty {
    CraftSpeechWordFlowLayout(spacing: 8, lineSpacing: 8, alignment: .center) {
        ForEach(tokens) { token in
            CraftSpeechWordTokenView(token: token.asCraftSpeechWordToken)
        }
    }
    .frame(maxWidth: .infinity, minHeight: 44)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
}
```

---

## 5. Testing & Verification Strategy

### 5.1 Test Suites Partitioning
| Target | Location | Dependencies | Command | Speed |
| :--- | :--- | :--- | :--- | :--- |
| **SpeechKitTests** | `Packages/SpeechKit/Tests/` | `SpeechKit` | `swift test --package-path Packages/SpeechKit` | ~1.0s |
| **CraftUIKitTests** | `Packages/CraftUIKit/Tests/` | `CraftUIKit` | `swift test --package-path Packages/CraftUIKit` | ~1.5s |
| **VocabCraftAppTests** | `VocabCraftAppTests/` | App, Widgets, Kits | `swift test` | Full run |

### 5.2 Test Migration & Creation
1. Move 5 test files from `VocabCraftAppTests/SpeechKitTests/` to `Packages/SpeechKit/Tests/SpeechKitTests/`:
   - `FuzzySpeechMatcherTests.swift`
   - `SilenceDetectorTests.swift`
   - `SpeechAssessmentServiceTests.swift`
   - `SpeechKitModelTests.swift`
   - `StringNormalizerTests.swift`
2. Add `SpeechKitAdapterTests.swift` in `VocabCraftAppTests`:
   - Validates `.exactMatch` -> `.matched`
   - Validates `.fuzzyMatch` -> `.fuzzy`
   - Validates `.missing` -> `.mismatched`
   - Validates token ID and targetWord preservation.
3. Remove obsolete `SpeechWordHighlightViewTests.swift`.

---

## 6. Golden Blueprint for Future Kits

When creating any new kit (e.g. `Packages/SRSKit`, `Packages/AudioKit`):
1. **Directory Structure:** Place under `Packages/<KitName>/` with `Package.swift`, `Sources/<KitName>/`, `Tests/<KitName>Tests/`, and `README.md`.
2. **Dependency Direction:** Leaf kits must not import higher layers. Domain engines must remain headless unless explicitly designed as a UI component kit.
3. **Public Interface:** Only expose necessary facade services (`SpeechAssessmentService`), protocols (`SpeechAssessmentProtocol`), and models. Mark internal engine classes as `internal`.
4. **Registration:** Register in `VocabCraft.xcworkspace`, root `Package.swift`, and `VocabCraftApp.xcodeproj`.
