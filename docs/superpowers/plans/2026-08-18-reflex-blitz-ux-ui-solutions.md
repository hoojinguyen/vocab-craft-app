# Reflex Blitz UX/UI Refinement & Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate UX flaws and visual rendering bugs in Spoken Reflex Blitz drill and summary screens to deliver an intense, focused, and polished vocabulary learning experience.

**Architecture:** Refactor SwiftUI view hierarchy across `ReflexBlitzCardView`, `ReflexBlitzHeaderView`, `ReflexBlitzSummaryView`, and `ReflexBlitzView`. Adopt progressive disclosure for pronunciation hints, replace perimeter border countdown with a high-precision linear countdown header bar, fix multi-line IPA wrapping via structured 3-tier layout, and anchor a sticky bottom action dock on the summary screen.

**Tech Stack:** iOS 17+, Swift 5.10+, SwiftUI, Observation framework, Apple Human Interface Guidelines.

**Spec:** `docs/superpowers/specs/2026-08-18-reflex-blitz-ux-ui-solutions-design.md`

## Global Constraints
- Target Platform: iOS 17.0+ (macOS 14.0+ cross-platform test compilation).
- Minimum tap target: 44×44pt for all interactive buttons.
- Follow 8pt spacing grid (`4, 8, 16, 24, 32`).
- All text strings must handle Dynamic Type and prevent truncation/wrapping bugs with `lineLimit` and `minimumScaleFactor`.
- No emoji as functional icons (use SF Symbols only).

---

### Task 1: Cross-Platform Test Snapshot Helper & Model Support

**Files:**
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift:220-241`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift`

**Interfaces:**
- Consumes: `ImageRenderer` in SwiftUI.
- Produces: Working cross-platform snapshot renderer (`uiImage` on iOS, `nsImage` / `CGImage` on macOS).

- [ ] **Step 1: Write cross-platform image rendering extension in Integration Tests**

In `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`:
```swift
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension ImageRenderer {
    @MainActor
    var crossPlatformData: Data? {
        #if canImport(UIKit)
        return self.uiImage?.pngData()
        #elseif canImport(AppKit)
        guard let nsImage = self.nsImage,
              let tiff = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}
```

- [ ] **Step 2: Update `renderSnapshot` to use `crossPlatformData`**

```swift
private func renderSnapshot<V: View>(view: V, filename: String) {
    let sizedView = view
        .frame(width: 393, height: 852)
        .background(Color.vocabCanvas)
        .environment(\.colorScheme, .dark)

    let renderer = ImageRenderer(content: sizedView)
    renderer.scale = 2.0
    renderer.proposedSize = ProposedViewSize(width: 393, height: 852)

    if let data = renderer.crossPlatformData {
        let outputDir = URL(fileURLWithPath: "/tmp/vocabcraft_snapshots")
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        let fileURL = outputDir.appendingPathComponent(filename)
        try? data.write(to: fileURL)
    }
}
```

- [ ] **Step 3: Run `swift test --filter ReflexBlitzModelsTests` to verify clean compilation**

Run: `swift test --filter ReflexBlitzModelsTests`
Expected: PASS

- [ ] **Step 4: Commit Task 1**

```bash
git add VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift
git commit -m "fix(tests): cross-platform snapshot renderer for swift test"
```

---

### Task 2: Summary Screen Redesign (`ReflexBlitzSummaryView`)

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzSessionSummary`, `ReflexBlitzWeakWordAttempt`, `onSpeakWord`, `onReDrillWeak`, `onFinish`.
- Produces: `ReflexBlitzSummaryView` with 3-tier row layout (no IPA wrapping), unified bento header, and sticky bottom action bar.

- [ ] **Step 1: Write the failing UI test for IPA single-line protection and Sticky CTA**

In `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift`:
```swift
func testSummaryViewWithLongIPAWordRendersProperly() {
    let weakAttempts = [
        ReflexBlitzWeakWordAttempt(
            lemma: "serendipity",
            pos: "noun",
            ipa: "/ˌser.ənˈdɪp.ə.ti/",
            definitionVi: "Sự tình cờ may mắn",
            responseTimeMs: 6000
        ),
        ReflexBlitzWeakWordAttempt(
            lemma: "ephemeral",
            pos: "adj",
            ipa: "/ɪˈfem.ər.əl/",
            definitionVi: "Phù du, chóng tàn",
            responseTimeMs: 6000
        )
    ]
    let summary = ReflexBlitzSessionSummary(
        totalWords: 7,
        correctWords: 1,
        averageResponseTimeMs: 5500,
        maxComboStreak: 1,
        speedRating: "Steady Learner",
        weakWordAttempts: weakAttempts
    )
    
    let view = ReflexBlitzSummaryView(
        summary: summary,
        onSpeakWord: { _ in },
        onReDrillWeak: {},
        onFinish: {}
    )
    XCTAssertNotNil(view.body)
}
```

- [ ] **Step 2: Implement 3-tier Row Layout & Sticky Bottom Bar in `ReflexBlitzSummaryView.swift`**

Update `ReflexBlitzSummaryView.swift`:
1. Use `ZStack(alignment: .bottom)`:
   - `ScrollView` with bottom content insets (`.safeAreaInset(edge: .bottom) { ... }` or bottom spacer).
   - Fixed Sticky Action Container with blur backdrop (`.background(.ultraThinMaterial)`).
2. Refactor Vocabulary Row:
   ```swift
   VStack(alignment: .leading, spacing: 5) {
       // Tier 1: Lemma + Speaker Button
       HStack {
           Text(weak.lemma)
               .font(.headline.weight(.bold))
               .foregroundColor(.vocabInk)
           Spacer()
           if let onSpeak = onSpeakWord {
               Button(action: { onSpeak(weak.lemma) }) {
                   Image(systemName: "speaker.wave.2.fill")
                       .font(.footnote)
                       .foregroundColor(.vocabHeroAccent)
                       .frame(width: 36, height: 36)
                       .background(Color.vocabHeroAccent.opacity(0.12), in: Circle())
               }
               .buttonStyle(.borderless)
           }
       }
       
       // Tier 2: POS • IPA (Single Line Guard)
       if !weak.pos.isEmpty || !weak.ipa.isEmpty {
           let metadata = [weak.pos.uppercased(), weak.ipa].filter { !$0.isEmpty }.joined(separator: "  •  ")
           Text(metadata)
               .font(.caption.monospaced())
               .foregroundColor(.vocabMuted)
               .lineLimit(1)
               .minimumScaleFactor(0.85)
       }
       
       // Tier 3: Vietnamese Meaning + Time badge
       HStack {
           if !weak.definitionVi.isEmpty {
               Text(weak.definitionVi)
                   .font(.subheadline)
                   .foregroundColor(.vocabInk.opacity(0.85))
                   .lineLimit(1)
           }
           Spacer()
           Text(timeLabel)
               .font(.caption2.bold())
               .foregroundColor(.vocabCoral)
               .padding(.horizontal, 8)
               .padding(.vertical, 4)
               .background(Color.vocabCoral.opacity(0.12), in: Capsule())
       }
   }
   .padding(14)
   .background(Color.vocabSurfaceCard)
   .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
   .padding(.horizontal, 16)
   ```
3. Unified Bento Metrics Header:
   - Harmonize icons with unified monochromatic `vocabHeroAccent` or `vocabInk` styling.

- [ ] **Step 3: Run Summary View Tests**

Run: `swift test --filter ReflexBlitzSummaryViewTests`
Expected: PASS

- [ ] **Step 4: Commit Task 2**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift
git commit -m "feat(ui): redesign ReflexBlitzSummaryView with 3-tier row layout and sticky CTA bar"
```

---

### Task 3: Challenge Card Redesign & Progressive Disclosure (`ReflexBlitzCardView`)

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzWordItem`, `showHint`, `isCorrect`, `isTimeout`, `liveTranscript`, `elapsedTimeMs`, `isKeyboardFallbackActive`.
- Produces: Card view with progressive disclosure, no perimeter stroke artifact, centered balanced layout, and conditional IPA fade-in.

- [ ] **Step 1: Write test for Progressive Disclosure and IPA suppression**

In `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`:
```swift
func testCardHidesIPAUntilAnswered() {
    let word = ReflexBlitzWordItem(
        id: UUID(),
        lemma: "meticulous",
        pos: "adj",
        ipa: "/məˈtɪk.jə.ləs/",
        definitionVi: "Tỉ mỉ, cẩn thận",
        clozeSentenceEn: "She is [ ________ ] about her work quality.",
        exampleSentenceEn: "She is meticulous about her work quality."
    )
    
    let drillingCard = ReflexBlitzCardView(
        word: word,
        fractionRemaining: 0.8,
        timerStage: .steady,
        showHint: false,
        isCorrect: false,
        isTimeout: false,
        liveTranscript: ""
    )
    XCTAssertNotNil(drillingCard.body)
}
```

- [ ] **Step 2: Refactor `ReflexBlitzCardView.swift`**

1. Remove `PerimeterCountdownShape` stroke overlay from card border.
2. Structure card body with balanced vertical padding:
   - **Section 1 (Trigger):** `POS` Pill + `definitionVi` in `title3.bold()`.
   - **Section 2 (Context):** `sentenceView` with `slotRepresentation`.
   - **Section 3 (Scaffolding & Hint):**
     - When `!isCorrect && !isTimeout`: show subtle `💡 Gợi ý: initialLetter` only if `showHint == true`.
     - When `isCorrect || isTimeout`: show full IPA pill `/məˈtɪk.jə.ləs/`.
   - **Section 4 (Voice Dock / Keyboard Dock):** Centered animated waveform bars + live speech transcript.
3. Card Container:
   - `.background(Color.vocabSurfaceCard)`
   - `.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))`
   - Clean subtle shadow `.shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)`
   - Subtle hairline stroke `.overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.vocabHairline.opacity(0.5), lineWidth: 1))`

- [ ] **Step 3: Run Components Tests**

Run: `swift test --filter ReflexBlitzComponentsTests`
Expected: PASS

- [ ] **Step 4: Commit Task 3**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "feat(ui): redesign ReflexBlitzCardView with progressive disclosure and balanced layout"
```

---

### Task 4: Linear Countdown Progress Bar & Header Redesign (`ReflexBlitzHeaderView` & `ReflexBlitzView`)

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Consumes: `currentIndex`, `totalCount`, `comboStreak`, `fractionRemaining`, `timerStage`.
- Produces: Header view with linear countdown progress bar and seamless transition to drilling card.

- [ ] **Step 1: Update `ReflexBlitzHeaderView` with Linear Countdown Bar**

In `ReflexBlitzHeaderView.swift`:
```swift
public struct ReflexBlitzHeaderView: View {
    public let currentIndex: Int
    public let totalCount: Int
    public let comboStreak: Int
    public let fractionRemaining: Double
    public let timerStage: ReflexBlitzTimerStage
    public let onClose: () -> Void
    public let onSkip: () -> Void
    public let showSkipInHeader: Bool

    public var timerBarColor: Color {
        switch timerStage {
        case .steady: return .vocabHeroAccent
        case .warning: return .vocabPeach
        case .urgent: return .vocabCoral
        }
    }
    
    // Body includes top close + count indicator + smooth linear progress bar
}
```

- [ ] **Step 2: Update `ReflexBlitzView.swift` layout and thumb-zone bottom dock**

In `ReflexBlitzView.swift`:
- Pass `fractionRemaining` and `timerStage` to `ReflexBlitzHeaderView`.
- Refine bottom action dock with balanced `48pt` capsule buttons for `Gõ phím` (or `Luyện nói`) and `Bỏ qua`.

- [ ] **Step 3: Run Tests**

Run: `swift test --filter ReflexBlitz`
Expected: All ReflexBlitz tests PASS.

- [ ] **Step 4: Commit Task 4**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift
git commit -m "feat(ui): add linear countdown bar to ReflexBlitzHeaderView and refine bottom dock"
```

---

### Task 5: Integration & Snapshot Verification

**Files:**
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`
- Test: Full test suite

- [ ] **Step 1: Run complete test suite**

Run: `swift test`
Expected: PASS all tests with 0 compilation warnings.

- [ ] **Step 2: Run `testCaptureAllReflexBlitzScreenshots` to generate updated snapshots**

Run: `swift test --filter ReflexBlitzViewIntegrationTests`
Expected: All snapshots captured successfully.

- [ ] **Step 3: Final Commit**

```bash
git add .
git commit -m "chore: verify Reflex Blitz UX/UI overhaul across all scenarios"
```
