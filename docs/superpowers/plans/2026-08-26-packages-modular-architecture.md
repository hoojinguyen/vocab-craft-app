# Packages Modular Architecture & Headless SpeechKit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize local packages into a unified `Packages/` monorepo directory, moving `CraftUIKit` to `Packages/CraftUIKit`, extracting `SpeechKit` into `Packages/SpeechKit` as a headless audio/speech engine package, adapting `VocabCraftApp` UI to use `CraftUIKit` speech tokens, and wiring Xcode workspace and SPM manifests.

**Architecture:** A multi-package monorepo under `Packages/` where `CraftUIKit` remains a pure Design System and `SpeechKit` is a headless domain engine. The main app (`VocabCraftApp`) consumes both kits and bridges them via an adapter layer in `VocabSpeechVisualizerView`.

**Tech Stack:** Swift 5.10 / Swift 6 language mode, Swift Package Manager (SPM), Xcode 15/16/26, AVFoundation, Speech framework, SwiftUI.

**Spec:** [docs/superpowers/specs/2026-08-26-packages-modular-architecture-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-26-packages-modular-architecture-design.md)

## Global Constraints

- Platform targets: iOS 17.0+, macOS 14.0+
- Swift Tools Version: `// swift-tools-version: 5.10`
- Zero Hardcoded Strings Policy: Display and a11y text must adhere to `AGENTS.md`
- CraftUIKit Isolation: `CraftUIKit` MUST NOT depend on `SpeechKit` or any audio logic
- SpeechKit Headless: `SpeechKit` MUST NOT depend on `SwiftUI` or `CraftUIKit`
- Test Execution: Standalone packages must run tests via `swift test --package-path Packages/<KitName>` without loading simulator

---

### Task 1: Create `Packages/` Directory and Relocate `CraftUIKit`

**Files:**
- Move directory: `CraftUIKit/` -> `Packages/CraftUIKit/`
- Modify: `Package.swift:21-28`
- Modify: `VocabCraft.xcworkspace/contents.xcworkspacedata:7-9`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj:2021`

**Interfaces:**
- Consumes: Existing `CraftUIKit` package at root
- Produces: `Packages/CraftUIKit` package with updated references in workspace, project, and root `Package.swift`

- [ ] **Step 1: Create `Packages/` directory and move `CraftUIKit`**

```bash
mkdir -p Packages
git mv CraftUIKit Packages/CraftUIKit
```

- [ ] **Step 2: Update root `Package.swift` dependency path**

Edit `Package.swift`:
```swift
    dependencies: [
        .package(path: "Packages/CraftUIKit")
    ],
```

- [ ] **Step 3: Update `VocabCraft.xcworkspace/contents.xcworkspacedata`**

Edit `VocabCraft.xcworkspace/contents.xcworkspacedata`:
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
</Workspace>
```

- [ ] **Step 4: Update `VocabCraftApp.xcodeproj/project.pbxproj` relative path**

In `VocabCraftApp.xcodeproj/project.pbxproj`, update `relativePath`:
```
900000000000000000000001 /* XCLocalSwiftPackageReference "CraftUIKit" */ = {
    isa = XCLocalSwiftPackageReference;
    relativePath = Packages/CraftUIKit;
};
```

- [ ] **Step 5: Run tests in `Packages/CraftUIKit` to verify relocation**

Run:
```bash
swift test --package-path Packages/CraftUIKit --filter LocalizationTests
```
Expected: PASS (11 tests passed, 0 failures)

- [ ] **Step 6: Commit**

```bash
git add Packages/CraftUIKit Package.swift VocabCraft.xcworkspace VocabCraftApp.xcodeproj
git commit -m "refactor: relocate CraftUIKit to Packages/CraftUIKit and update workspace references"
```

---

### Task 2: Scaffold `Packages/SpeechKit` Package and Migrate Headless Engine

**Files:**
- Create: `Packages/SpeechKit/Package.swift`
- Create: `Packages/SpeechKit/README.md`
- Move from `VocabCraftApp/Core/SpeechKit/`:
  - `Engine/SilenceDetector.swift` -> `Packages/SpeechKit/Sources/SpeechKit/Engine/SilenceDetector.swift`
  - `Engine/SpeechRecognitionEngine.swift` -> `Packages/SpeechKit/Sources/SpeechKit/Engine/SpeechRecognitionEngine.swift`
  - `Evaluation/FuzzySpeechMatcher.swift` -> `Packages/SpeechKit/Sources/SpeechKit/Evaluation/FuzzySpeechMatcher.swift`
  - `Evaluation/SequenceAligner.swift` -> `Packages/SpeechKit/Sources/SpeechKit/Evaluation/SequenceAligner.swift`
  - `Evaluation/StringNormalizer.swift` -> `Packages/SpeechKit/Sources/SpeechKit/Evaluation/StringNormalizer.swift`
  - `Models/SpeechEvaluationResult.swift` -> `Packages/SpeechKit/Sources/SpeechKit/Models/SpeechEvaluationResult.swift`
  - `Models/SpeechKitError.swift` -> `Packages/SpeechKit/Sources/SpeechKit/Models/SpeechKitError.swift`
  - `Models/WordMatchStatus.swift` -> `Packages/SpeechKit/Sources/SpeechKit/Models/WordMatchStatus.swift`
  - `Models/WordTokenResult.swift` -> `Packages/SpeechKit/Sources/SpeechKit/Models/WordTokenResult.swift`
  - `Protocols/SpeechAssessmentProtocol.swift` -> `Packages/SpeechKit/Sources/SpeechKit/Protocols/SpeechAssessmentProtocol.swift`
  - `SpeechAssessmentService.swift` -> `Packages/SpeechKit/Sources/SpeechKit/SpeechAssessmentService.swift`
- Delete: `VocabCraftApp/Core/SpeechKit/UI/SpeechWordHighlightView.swift`
- Delete directory: `VocabCraftApp/Core/SpeechKit`

**Interfaces:**
- Consumes: Audio and Speech frameworks (`AVFoundation`, `Speech`, `Observation`, `Foundation`)
- Produces: Public headless APIs: `SpeechAssessmentService`, `SpeechAssessmentProtocol`, `SpeechEvaluationResult`, `WordTokenResult`, `WordMatchStatus`, `SpeechKitError`

- [ ] **Step 1: Scaffold `Packages/SpeechKit` directory structure**

```bash
mkdir -p Packages/SpeechKit/Sources/SpeechKit/Engine
mkdir -p Packages/SpeechKit/Sources/SpeechKit/Evaluation
mkdir -p Packages/SpeechKit/Sources/SpeechKit/Models
mkdir -p Packages/SpeechKit/Sources/SpeechKit/Protocols
mkdir -p Packages/SpeechKit/Tests/SpeechKitTests
```

- [ ] **Step 2: Create `Packages/SpeechKit/Package.swift`**

Write to `Packages/SpeechKit/Package.swift`:
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

- [ ] **Step 3: Create `Packages/SpeechKit/README.md`**

Write to `Packages/SpeechKit/README.md`:
```markdown
# SpeechKit

Headless speech recognition and pronunciation evaluation engine for VocabCraft.

## Features
- Real-time audio buffer capture with `AVAudioEngine` and silence detection.
- Speech transcription using Apple's `SFSpeechRecognizer`.
- Phonetic & fuzzy token alignment using Needleman-Wunsch sequence aligner and Levenshtein distance.
- Strictly headless: Zero UI dependencies, fast test execution on macOS and iOS.
```

- [ ] **Step 4: Move headless source files from `VocabCraftApp/Core/SpeechKit`**

```bash
git mv VocabCraftApp/Core/SpeechKit/Engine/SilenceDetector.swift Packages/SpeechKit/Sources/SpeechKit/Engine/
git mv VocabCraftApp/Core/SpeechKit/Engine/SpeechRecognitionEngine.swift Packages/SpeechKit/Sources/SpeechKit/Engine/
git mv VocabCraftApp/Core/SpeechKit/Evaluation/FuzzySpeechMatcher.swift Packages/SpeechKit/Sources/SpeechKit/Evaluation/
git mv VocabCraftApp/Core/SpeechKit/Evaluation/SequenceAligner.swift Packages/SpeechKit/Sources/SpeechKit/Evaluation/
git mv VocabCraftApp/Core/SpeechKit/Evaluation/StringNormalizer.swift Packages/SpeechKit/Sources/SpeechKit/Evaluation/
git mv VocabCraftApp/Core/SpeechKit/Models/SpeechEvaluationResult.swift Packages/SpeechKit/Sources/SpeechKit/Models/
git mv VocabCraftApp/Core/SpeechKit/Models/SpeechKitError.swift Packages/SpeechKit/Sources/SpeechKit/Models/
git mv VocabCraftApp/Core/SpeechKit/Models/WordMatchStatus.swift Packages/SpeechKit/Sources/SpeechKit/Models/
git mv VocabCraftApp/Core/SpeechKit/Models/WordTokenResult.swift Packages/SpeechKit/Sources/SpeechKit/Models/
git mv VocabCraftApp/Core/SpeechKit/Protocols/SpeechAssessmentProtocol.swift Packages/SpeechKit/Sources/SpeechKit/Protocols/
git mv VocabCraftApp/Core/SpeechKit/SpeechAssessmentService.swift Packages/SpeechKit/Sources/SpeechKit/
```

- [ ] **Step 5: Remove obsolete `SpeechWordHighlightView.swift` and clean up `Core/SpeechKit`**

```bash
git rm VocabCraftApp/Core/SpeechKit/UI/SpeechWordHighlightView.swift
rmdir VocabCraftApp/Core/SpeechKit/UI 2>/dev/null || true
rmdir VocabCraftApp/Core/SpeechKit/Models 2>/dev/null || true
rmdir VocabCraftApp/Core/SpeechKit/Engine 2>/dev/null || true
rmdir VocabCraftApp/Core/SpeechKit/Evaluation 2>/dev/null || true
rmdir VocabCraftApp/Core/SpeechKit/Protocols 2>/dev/null || true
rmdir VocabCraftApp/Core/SpeechKit 2>/dev/null || true
```

- [ ] **Step 6: Verify `SpeechKit` compiles independently**

Run:
```bash
swift build --package-path Packages/SpeechKit
```
Expected: `Build complete!` with 0 warnings or errors.

- [ ] **Step 7: Commit**

```bash
git add Packages/SpeechKit VocabCraftApp/Core/SpeechKit
git commit -m "feat(SpeechKit): scaffold Packages/SpeechKit and migrate headless engine"
```

---

### Task 3: Migrate and Run Unit Tests in `Packages/SpeechKit`

**Files:**
- Move from `VocabCraftAppTests/SpeechKitTests/`:
  - `FuzzySpeechMatcherTests.swift` -> `Packages/SpeechKit/Tests/SpeechKitTests/FuzzySpeechMatcherTests.swift`
  - `SilenceDetectorTests.swift` -> `Packages/SpeechKit/Tests/SpeechKitTests/SilenceDetectorTests.swift`
  - `SpeechAssessmentServiceTests.swift` -> `Packages/SpeechKit/Tests/SpeechKitTests/SpeechAssessmentServiceTests.swift`
  - `SpeechKitModelTests.swift` -> `Packages/SpeechKit/Tests/SpeechKitTests/SpeechKitModelTests.swift`
  - `StringNormalizerTests.swift` -> `Packages/SpeechKit/Tests/SpeechKitTests/StringNormalizerTests.swift`
- Delete: `VocabCraftAppTests/SpeechKitTests/SpeechWordHighlightViewTests.swift`
- Delete directory: `VocabCraftAppTests/SpeechKitTests`

**Interfaces:**
- Consumes: `SpeechKit` module
- Produces: 100% passing tests for engine, evaluation, models, and audio handling in `Packages/SpeechKit`

- [ ] **Step 1: Move engine test files to `Packages/SpeechKit/Tests/SpeechKitTests`**

```bash
git mv VocabCraftAppTests/SpeechKitTests/FuzzySpeechMatcherTests.swift Packages/SpeechKit/Tests/SpeechKitTests/
git mv VocabCraftAppTests/SpeechKitTests/SilenceDetectorTests.swift Packages/SpeechKit/Tests/SpeechKitTests/
git mv VocabCraftAppTests/SpeechKitTests/SpeechAssessmentServiceTests.swift Packages/SpeechKit/Tests/SpeechKitTests/
git mv VocabCraftAppTests/SpeechKitTests/SpeechKitModelTests.swift Packages/SpeechKit/Tests/SpeechKitTests/
git mv VocabCraftAppTests/SpeechKitTests/StringNormalizerTests.swift Packages/SpeechKit/Tests/SpeechKitTests/
```

- [ ] **Step 2: Update import statements in migrated test files if needed**

Ensure each migrated test file has:
```swift
import Testing // or import XCTest
@testable import SpeechKit
```
(Replace any `@testable import VocabCraftApp` with `@testable import SpeechKit`).

- [ ] **Step 3: Remove obsolete `SpeechWordHighlightViewTests.swift` and clean directory**

```bash
git rm VocabCraftAppTests/SpeechKitTests/SpeechWordHighlightViewTests.swift
rmdir VocabCraftAppTests/SpeechKitTests 2>/dev/null || true
```

- [ ] **Step 4: Run unit tests in `Packages/SpeechKit`**

Run:
```bash
swift test --package-path Packages/SpeechKit
```
Expected: PASS for all suites (`FuzzySpeechMatcherTests`, `SilenceDetectorTests`, `SpeechAssessmentServiceTests`, `SpeechKitModelTests`, `StringNormalizerTests`). Takes ~1 second.

- [ ] **Step 5: Commit**

```bash
git add Packages/SpeechKit/Tests VocabCraftAppTests/SpeechKitTests
git commit -m "test(SpeechKit): migrate unit tests to Packages/SpeechKit test suite"
```

---

### Task 4: Implement Adapter Layer in `VocabCraftApp` & Wire `CraftUIKit` Tokens

**Files:**
- Create: `VocabCraftAppTests/Core/SpeechKitAdapterTests.swift`
- Modify: `VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift`

**Interfaces:**
- Consumes: `WordTokenResult` from `SpeechKit`, `CraftSpeechWordToken`, `CraftSpeechWordTokenView`, `CraftSpeechWordFlowLayout` from `CraftUIKit`
- Produces: Clean adapter extension `WordTokenResult.asCraftSpeechWordToken` and updated `VocabSpeechVisualizerView`

- [ ] **Step 1: Write the failing test for the adapter mapping in `VocabCraftAppTests`**

Create `VocabCraftAppTests/Core/SpeechKitAdapterTests.swift`:
```swift
import Testing
import Foundation
import SpeechKit
import CraftUIKit
@testable import VocabCraftApp

@Suite("SpeechKitAdapterTests")
struct SpeechKitAdapterTests {
    @Test("Exact match status maps to CraftSpeechStatus.matched")
    func testExactMatchMapping() {
        let token = WordTokenResult(
            targetWord: "hello",
            spokenWord: "hello",
            status: .exactMatch,
            confidence: 0.95
        )
        let craftToken = token.asCraftSpeechWordToken

        #expect(craftToken.targetWord == "hello")
        #expect(craftToken.status == .matched)
        #expect(craftToken.confidence == 0.95)
    }

    @Test("Fuzzy match status maps to CraftSpeechStatus.fuzzy")
    func testFuzzyMatchMapping() {
        let token = WordTokenResult(
            targetWord: "world",
            spokenWord: "word",
            status: .fuzzyMatch,
            confidence: 0.65
        )
        let craftToken = token.asCraftSpeechWordToken

        #expect(craftToken.targetWord == "world")
        #expect(craftToken.status == .fuzzy)
    }

    @Test("Missing status maps to CraftSpeechStatus.mismatched")
    func testMissingMapping() {
        let token = WordTokenResult(
            targetWord: "swift",
            spokenWord: nil,
            status: .missing,
            confidence: nil
        )
        let craftToken = token.asCraftSpeechWordToken

        #expect(craftToken.targetWord == "swift")
        #expect(craftToken.status == .mismatched)
        #expect(craftToken.confidence == nil)
    }
}
```

- [ ] **Step 2: Update `VocabSpeechVisualizerView.swift` to implement the adapter and use `CraftUIKit`**

In `VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift`:
Add imports:
```swift
import SwiftUI
import SpeechKit
import CraftUIKit
```

Add adapter extension:
```swift
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

Replace `SpeechWordHighlightView` usage (lines ~57-65) with:
```swift
            // Word Tokens Highlight using CraftUIKit flow layout and token chips
            if !tokens.isEmpty {
                CraftSpeechWordFlowLayout(spacing: 8, lineSpacing: 8, alignment: .center) {
                    ForEach(tokens) { token in
                        CraftSpeechWordTokenView(token: token.asCraftSpeechWordToken)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            } else {
```

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift VocabCraftAppTests/Core/SpeechKitAdapterTests.swift
git commit -m "feat(app): adapt SpeechKit tokens to CraftSpeechWordTokenView in VocabSpeechVisualizerView"
```

---

### Task 5: Wire `SpeechKit` into Workspace, Project, and Root `Package.swift`

**Files:**
- Modify: `VocabCraft.xcworkspace/contents.xcworkspacedata`
- Modify: `Package.swift`
- Modify: `scripts/generate_xcodeproj.py`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `Packages/SpeechKit`, `Packages/CraftUIKit`
- Produces: Integrated build system across Xcode and CLI

- [ ] **Step 1: Add `Packages/SpeechKit` to `VocabCraft.xcworkspace/contents.xcworkspacedata`**

Edit `VocabCraft.xcworkspace/contents.xcworkspacedata`:
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

- [ ] **Step 2: Add `SpeechKit` to root `Package.swift`**

In root `Package.swift`:
```swift
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
```

- [ ] **Step 3: Update `VocabCraftApp.xcodeproj/project.pbxproj` with `SpeechKit` local package reference**

Add `SpeechKit` XCLocalSwiftPackageReference:
```
		900000000000000000000005 /* XCLocalSwiftPackageReference "SpeechKit" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = Packages/SpeechKit;
		};
		900000000000000000000006 /* SpeechKit */ = {
			isa = XCSwiftPackageProductDependency;
			package = 900000000000000000000005 /* XCLocalSwiftPackageReference "SpeechKit" */;
			productName = SpeechKit;
		};
```
Link product `900000000000000000000006` into `VocabCraftApp` and `VocabCraftAppTests` frameworks build phases and package references.

- [ ] **Step 4: Update `scripts/generate_xcodeproj.py`**

Ensure `generate_xcodeproj.py` includes `CraftUIKit` and `SpeechKit` package references, and clean up any references to deleted `SpeechKit` files.

- [ ] **Step 5: Run full test verification suite**

Run:
```bash
swift test --package-path Packages/SpeechKit
swift test --package-path Packages/CraftUIKit
swift test --filter SpeechKitAdapterTests
```
Expected: All three commands execute with 0 failures and complete in < 5 seconds.

- [ ] **Step 6: Run full application test suite**

Run:
```bash
swift test
```
Expected: All suites build and pass.

- [ ] **Step 7: Commit**

```bash
git add Package.swift VocabCraft.xcworkspace VocabCraftApp.xcodeproj scripts/generate_xcodeproj.py
git commit -m "build: integrate SpeechKit into workspace, project, and root Package.swift"
```

---

### Task 6: Final Clean-up and Verification

**Files:**
- Audit all remaining references to `SpeechWordHighlightView` across repo
- Verify git status is completely clean

- [ ] **Step 1: Grep search for any stale references**

```bash
git grep "SpeechWordHighlightView" || echo "Clean: No stale references found"
```
Expected: Only this plan and git logs mention the old view. Zero code references.

- [ ] **Step 2: Final test check**

```bash
swift test --package-path Packages/SpeechKit
swift test --package-path Packages/CraftUIKit --filter LocalizationTests
```
Expected: All pass.

- [ ] **Step 3: Verification commit if any minor adjustments needed**
