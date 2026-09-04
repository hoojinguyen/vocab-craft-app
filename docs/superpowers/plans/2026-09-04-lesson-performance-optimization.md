# Lesson Performance Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate real-device frame stutters, lesson start freezing, and device overheating by refactoring the audio lifecycle to session scope, stopping background view leaks in CraftFluidJourney, removing @State preference key invalidations, and coordinating smooth modal transitions.

**Architecture:** Unified session-scoped audio engine with lazy microphone initialization, render pipeline optimization with background suspension in CraftUIKit, static SF Symbol lookup cache, and in-place progress mutation on the homepage.

**Tech Stack:** Swift 5.10+, SwiftUI, AVFoundation, Speech, Swift Testing (`@Test`), CraftUIKit design system.

**Spec:** `docs/superpowers/specs/2026-09-04-lesson-performance-optimization-design.md`

## Global Constraints

- Platform minimum: iOS 17.0, macOS 14.0.
- Zero hardcoded strings: All user-facing strings must use Localizable.xcstrings or CraftLocalized.
- Design token adherence: All UI styling must use CraftUIKit tokens (`CraftColor`, `CraftFont`, `CraftSpacingTokens`).
- 100% Quality gate: Zero compiler warnings, zero lint errors, 100% test pass rate.

---

### Task 1: Fix CraftFluidJourney State Invalidation & Background Suspension (CraftUIKit)

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift:85-115, 543-587, 620-635`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`

**Interfaces:**
- Consumes: `FluidJourneyMilestonePreferenceKey`, `theme.colors.canvasBackground`
- Produces: `CraftFluidJourney.init(..., isSuspended: Bool = false)`, removal of `@State private var milestonePositions`

- [x] **Step 1: Write the failing test for `isSuspended` and preference key handling**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`:
```swift
@Test("Verify isSuspended parameter propagates and controls background rendering")
func testIsSuspendedConfiguration() {
    let sections = [
        LessonSection(id: "sec-1", title: "Unit 1", nodes: [
            LessonNodeModel(id: "n-1", title: "Node 1", state: .active)
        ])
    ]
    let normalJourney = CraftFluidJourney(sections: sections, isSuspended: false)
    let suspendedJourney = CraftFluidJourney(sections: sections, isSuspended: true)
    #expect(normalJourney.isSuspended == false)
    #expect(suspendedJourney.isSuspended == true)
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftFluidJourneyTests/testIsSuspendedConfiguration`
Expected: FAIL with "value of type 'CraftFluidJourney' has no member 'isSuspended'"

- [x] **Step 3: Write minimal implementation**

In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift`:
1. Remove `@State private var milestonePositions: [String: CGFloat] = [:]`.
2. Add property: `public var isSuspended: Bool`.
3. Add `isSuspended: Bool = false` to initializers and assign `self.isSuspended = isSuspended`.
4. Update `handleMilestonePreferenceChange`:
```swift
func handleMilestonePreferenceChange(_ positions: [String: CGFloat]) {
    if let resolved = resolveDockedSection(from: positions), dockedSectionId != resolved.id {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.28)) {
            dockedSectionId = resolved.id
        }
    }
}
```
5. Update `ambientEtherealBackground` to bypass Gaussian blurs when suspended:
```swift
var ambientEtherealBackground: some View {
    ZStack {
        theme.colors.canvasBackground
            .ignoresSafeArea()

        if !isSuspended {
            GeometryReader { proxy in
                let size = proxy.size
                let topAuraSize = size.width * 1.3
                let bottomAuraSize = size.width * 1.1

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.colors.brandPrimary.opacity(0.18),
                                theme.colors.brandPrimary.opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: topAuraSize * 0.45
                        )
                    )
                    .frame(width: topAuraSize, height: topAuraSize)
                    .blur(radius: 40)
                    .offset(x: -size.width * 0.35, y: -size.height * 0.15)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.colors.accentGold.opacity(0.12),
                                theme.colors.accentGold.opacity(0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: bottomAuraSize * 0.45
                        )
                    )
                    .frame(width: bottomAuraSize, height: bottomAuraSize)
                    .blur(radius: 50)
                    .offset(x: size.width * 0.45, y: size.height * 0.55)
            }
            .allowsHitTesting(false)
        }
    }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftFluidJourneyTests`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift
git commit -m "perf(craft-fluid-journey): drop milestonePositions state and add isSuspended render guard"
```

---

### Task 2: Optimize CraftJourneyNode SF Symbol Cache & Suspended PhaseAnimator (CraftUIKit)

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift:195-265`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonNode.swift:130-145`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftJourneyNodeTests.swift`

**Interfaces:**
- Consumes: `UIImage(systemName:)`
- Produces: `CraftJourneyNode.init(..., isSuspended: Bool = false)`, thread-safe static symbol validation cache, suspended static shadow rendering

- [x] **Step 1: Write the failing test for symbol caching and node suspension**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftJourneyNodeTests.swift`:
```swift
@Test("Verify resolvedIconName caches results and handles isSuspended")
func testResolvedIconNameAndSuspension() {
    let node = LessonNodeModel(id: "node_test", title: "Test", iconName: "star", state: .active)
    let journeyNode = CraftJourneyNode(node: node, isSuspended: true)
    #expect(journeyNode.isSuspended == true)
    let resolved = journeyNode.resolvedIconName
    #expect(resolved == "star.fill" || resolved == "star")
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftJourneyNodeTests/testResolvedIconNameAndSuspension`
Expected: FAIL with "extra argument 'isSuspended' in call"

- [x] **Step 3: Write minimal implementation**

In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift`:
1. Add static cache:
```swift
private static var symbolValidationCache: [String: Bool] = [:]
private static let cacheLock = NSLock()
```
2. Add `public var isSuspended: Bool` property with default `false` in `init`.
3. Update `resolvedIconName`:
```swift
public var resolvedIconName: String {
    let base = displayedIconName
    if base.hasSuffix(".fill") || base.contains(".fill.") {
        return base
    }
    let filled = "\(base).fill"
    #if canImport(UIKit)
    Self.cacheLock.lock()
    if let cached = Self.symbolValidationCache[filled] {
        Self.cacheLock.unlock()
        return cached ? filled : base
    }
    Self.cacheLock.unlock()

    let isValid = UIImage(systemName: filled) != nil

    Self.cacheLock.lock()
    Self.symbolValidationCache[filled] = isValid
    Self.cacheLock.unlock()

    return isValid ? filled : base
    #else
    return base
    #endif
}
```
4. Guard `PhaseAnimator` in `body`:
```swift
if node.state == .active, !reduceMotion, !isSuspended {
    PhaseAnimator(GlowPhase.allCases) { phase in
        nodeFace
            .shadow(
                color: theme.colors.brandPrimary.opacity(phase == .glowing ? 0.45 : 0.20),
                radius: phase == .glowing ? 10 : 5,
                x: 0,
                y: phase == .glowing ? 4 : 2
            )
    } animation: { _ in
        .craftGlow
    }
} else {
    nodeFace
        .shadow(
            color: node.state == .active ? theme.colors.brandPrimary.opacity(0.30) : Color.clear,
            radius: node.state == .active ? 6 : 0,
            x: 0,
            y: node.state == .active ? 3 : 0
        )
}
```
5. Pass `isSuspended` from `CraftFluidJourney` into `CraftJourneyNode`.
6. Similarly guard `ActiveCalloutBubble` bobbing in `CraftLessonNode.swift`.

- [x] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftJourneyNodeTests`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonNode.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CraftJourneyNodeTests.swift
git commit -m "perf(craft-ui): cache SF symbol validation and suspend node animations when backgrounded"
```

---

### Task 3: Session-Scoped Audio Engine & Safe Teardown Lifecycle (VocabCraftApp Core Audio)

**Files:**
- Modify: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift:120-135, 260-327`
- Test: `VocabCraftAppTests/SpeechServiceTests.swift`

**Interfaces:**
- Consumes: `AVAudioSession`, `AVAudioEngine`
- Produces: `prepareEngineIfNeeded()`, `pauseListening()`, `resumeListening()`, safe non-flapping `teardownEngine()`

- [x] **Step 1: Write the failing test for pause/resume listening without teardown**

In `VocabCraftAppTests/SpeechServiceTests.swift`:
```swift
@Test("Verify speech engine pause and resume retains active session")
func testEnginePauseAndResumeRetainsSession() {
    let engine = ResilientReflexSpeechEngine()
    engine.startSession(contextualPhrases: ["test"])
    #expect(engine.isSessionActive == true)
    engine.pauseListening()
    #expect(engine.isSessionActive == true)
    engine.resumeListening()
    #expect(engine.isSessionActive == true)
    engine.stopSession()
    #expect(engine.isSessionActive == false)
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/SpeechServiceTests/testEnginePauseAndResumeRetainsSession`
Expected: FAIL with "value of type 'ResilientReflexSpeechEngine' has no member 'pauseListening'"

- [x] **Step 3: Write minimal implementation**

In `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift`:
1. Add methods to `ResilientReflexSpeechEngine`:
```swift
public func pauseListening() {
    bufferRelay.mute()
    endWord()
}

public func resumeListening() {
    bufferRelay.unmute()
}
```
2. Refactor `setupAndStartEngine()` to ensure `AVAudioSession.setActive(true)` runs asynchronously and does not block `@MainActor`.
3. In `teardownEngine()`:
```swift
private func teardownEngine() {
    #if !targetEnvironment(simulator) && !os(macOS)
    bufferRelay.detachAndEnd()
    if let engine = audioEngine {
        if engine.isRunning {
            engine.stop()
        }
        engine.inputNode.removeTap(onBus: 0)
    }
    audioEngine = nil

    #if os(iOS)
    Task.detached(priority: .userInitiated) {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }
    #endif
    #endif
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/SpeechServiceTests`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift VocabCraftAppTests/SpeechServiceTests.swift
git commit -m "refactor(audio): make speech engine pauseable and move audio session teardown off main actor"
```

---

### Task 4: Refactor LessonLearningViewModel for Single Audio Session Scope (VocabCraftApp Feature Lesson)

**Files:**
- Modify: `VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift:180-245`
- Test: `VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift`

**Interfaces:**
- Consumes: `ResilientReflexSpeechEngine.startSession()`, `pauseListening()`, `stopSession()`
- Produces: `LessonLearningViewModel` manages session-level audio lifecycle without per-card flapping

- [x] **Step 1: Write the failing test for speech transition without session flapping**

In `VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift`:
```swift
@Test("Verify transition from speaking to non-speaking pauses rather than stops speech session")
func testTransitionMaintainsSpeechSession() {
    let mockWord = TopicWordDTO(id: "w1", lemma: "apple", phonetics: "/ˈæp.əl/", meaningVi: "quả táo", exampleEn: "An apple a day", exampleVi: "Một quả táo mỗi ngày", partOfSpeech: "noun")
    let vm = LessonLearningViewModel(stageId: "stage_test", deckId: "deck_test", words: [mockWord])
    vm.startSpeechSession()
    #expect(vm.speechEngine.isSessionActive == true)
    vm.stopListeningForSpeaking()
    #expect(vm.speechEngine.isSessionActive == true)
    vm.cleanup()
    #expect(vm.speechEngine.isSessionActive == false)
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/LessonLearningViewModelTests`
Expected: FAIL if `cleanup()` does not exist or behavior differs

- [x] **Step 3: Write minimal implementation**

In `VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift`:
1. Add `public func cleanup()`:
```swift
public func cleanup() {
    stopListeningForSpeaking()
    speechEngine.stopSession()
}
```
2. Update `stopListeningForSpeaking()`:
```swift
public func stopListeningForSpeaking() {
    speechEngine.pauseListening()
    speechEngine.onMatchDetected = nil
    speechEngine.onTranscriptUpdate = nil
    speechEngine.onError = nil
}
```
3. Update `finishLesson()` to call `cleanup()`.

- [x] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/LessonLearningViewModelTests`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift VocabCraftAppTests/Features/Lesson/LessonLearningViewModelTests.swift
git commit -m "refactor(lesson): manage speech session at lesson scope and pause between steps"
```

---

### Task 5: De-conflict LessonDiscoveryCardView TTS & Remove Redundant Cloze Regex (VocabCraftApp Feature Lesson)

**Files:**
- Modify: `VocabCraftApp/Features/Lesson/Views/Components/LessonDiscoveryCardView.swift:140-150`
- Modify: `VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift:40-130`
- Test: `VocabCraftAppTests/Reflex/ReflexDrillableTests.swift`

**Interfaces:**
- Consumes: `clozeStages.initialParts`
- Produces: Delayed TTS playback on discovery card entry, zero regex overhead in `LessonExerciseContainerView`, zero view-level audio session lifecycle calls

- [x] **Step 1: Write the test verifying clozeParts direct assignment without regex parsing**

In `VocabCraftAppTests/Reflex/ReflexDrillableTests.swift`:
```swift
@Test("Verify initialParts matches cloze sentence structure directly")
func testInitialPartsDirectStructure() {
    let stages = ReflexHintMaskGenerator.generateStages(
        sentence: "She has an apple for breakfast.",
        targetWord: "apple"
    )
    #expect(stages.initialParts.slot == "apple")
    #expect(stages.initialParts.prefix.contains("She has an"))
}
```

- [x] **Step 2: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexDrillableTests`
Expected: PASS

- [x] **Step 3: Write minimal implementation**

1. In `VocabCraftApp/Features/Lesson/Views/Components/LessonDiscoveryCardView.swift`:
```swift
.task(id: word.id) {
    // Give spring transition 300ms to complete smoothly before starting TTS
    try? await Task.sleep(for: .milliseconds(300))
    guard !Task.isCancelled else { return }
    onPlayAudio()
}
```
2. In `VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift`:
Replace:
```swift
clozeParts: ReflexClozeFormatter.extractTemplateParts(from: clozeStages.initialParts.prefix + clozeStages.initialParts.slot + clozeStages.initialParts.suffix)
```
with:
```swift
clozeParts: clozeStages.initialParts
```
across all 4 modes (`.multipleChoice`, `.listening`, `.speaking`, `.typing`).
3. In the `.speaking` case of `LessonExerciseContainerView.swift`:
Remove `.onAppear { viewModel.startSpeechSession() }` and `.onDisappear { viewModel.stopSpeechSession() }`.

- [x] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexDrillableTests`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Lesson/Views/Components/LessonDiscoveryCardView.swift VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift
git commit -m "perf(lesson): delay discovery TTS for spring animation and remove redundant cloze regex"
```

---

### Task 6: Homepage Modal Transition Coordination & In-Place Progress Mutation (VocabCraftApp Feature Homepage)

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift:120-133`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift:80-120, 215-245, 300-410`
- Test: `VocabCraftAppTests/Features/Homepage/HomepageViewModelTests.swift`

**Interfaces:**
- Consumes: `CraftFluidJourney(..., isSuspended:)`
- Produces: `HomepageViewModel.applyCompletedLesson(stageId:)`, coordinated smooth modal transition

- [x] **Step 1: Write the failing test for `applyCompletedLesson` in-place mutation**

In `VocabCraftAppTests/Features/Homepage/HomepageViewModelTests.swift`:
```swift
@Test("Verify applyCompletedLesson marks node completed and unlocks next node in-place")
func testApplyCompletedLessonInPlace() {
    let n1 = LessonNodeModel(id: "node_1", title: "Lesson 1", state: .active)
    let n2 = LessonNodeModel(id: "node_2", title: "Lesson 2", state: .upcoming)
    let section = LessonSection(id: "sec_1", title: "Unit 1", nodes: [n1, n2])
    let vm = HomepageViewModel(sections: [section])

    vm.applyCompletedLesson(stageId: "node_1")

    #expect(vm.sections.first?.nodes[0].state == .completed)
    #expect(vm.sections.first?.nodes[1].state == .active)
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/HomepageViewModelTests/testApplyCompletedLessonInPlace`
Expected: FAIL with "value of type 'HomepageViewModel' has no member 'applyCompletedLesson'"

- [x] **Step 3: Write minimal implementation**

1. In `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`:
```swift
public func applyCompletedLesson(stageId: String) {
    var updatedSections = sections
    var foundLocation: (secIdx: Int, nodeIdx: Int)?

    for (sIdx, sec) in updatedSections.enumerated() {
        if let nIdx = sec.nodes.firstIndex(where: { $0.id == stageId }) {
            foundLocation = (sIdx, nIdx)
            break
        }
    }

    guard let (sIdx, nIdx) = foundLocation else { return }

    var completedNode = updatedSections[sIdx].nodes[nIdx]
    completedNode.state = .completed
    updatedSections[sIdx].nodes[nIdx] = completedNode

    if nIdx + 1 < updatedSections[sIdx].nodes.count {
        var nextNode = updatedSections[sIdx].nodes[nIdx + 1]
        if nextNode.state == .locked || nextNode.state == .upcoming {
            nextNode.state = .active
            updatedSections[sIdx].nodes[nIdx + 1] = nextNode
        }
    } else if sIdx + 1 < updatedSections.count, !updatedSections[sIdx + 1].nodes.isEmpty {
        var nextNode = updatedSections[sIdx + 1].nodes[0]
        if nextNode.state == .locked || nextNode.state == .upcoming {
            nextNode.state = .active
            updatedSections[sIdx + 1].nodes[0] = nextNode
        }
    }

    self.sections = updatedSections
    refreshDailyProgress()
}
```
2. In `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`:
- Pass `isSuspended: activeLessonLearningVM != nil` to `CraftFluidJourney`.
- In `handleLessonFinished`, call `viewModel.applyCompletedLesson(stageId: summary.stageId)` directly instead of `loadLearningPath()`.
- In `startLesson`, introduce a coordinated 150ms post-dismiss buffer to allow CoreAnimation clean buffer recovery before `activeLessonLearningVM` presentation.

- [x] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/HomepageViewModelTests`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftAppTests/Features/Homepage/HomepageViewModelTests.swift
git commit -m "feat(home): add in-place lesson progress mutation and suspend journey during lesson cover"
```

---

### Task 7: Full Quality Gate Verification (Automated Suite & Diagnostics)

**Files:**
- Repository-wide verification

- [x] **Step 1: Run CraftUIKit localization test**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Expected: PASS with 0 failures

- [x] **Step 2: Run full CraftUIKit test suite**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: PASS with 100% tests passing

- [x] **Step 3: Run SwiftLint compliance check**

Run: `swiftlint`
Expected: 0 errors, 0 warnings

- [x] **Step 4: Build project with Xcode to ensure zero errors and zero warnings**

Run: `xcodebuild clean build -workspace VocabCraftApp.xcworkspace -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`
Expected: BUILD SUCCEEDED with 0 warnings and 0 errors

- [x] **Step 5: Final branch verification commit**

```bash
git status
git commit -m "chore(perf): verify zero warnings, zero lint errors, and 100% test pass rate for PR #16"
```
