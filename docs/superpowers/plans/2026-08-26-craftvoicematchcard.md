# CraftVoiceMatchCard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the standalone, reusable `CraftVoiceMatchCard` speaking interaction and word-matching UI component in `CraftUIKit` with real-time text diffing, multi-state tactile mic control, and 100% bilingual parity.

**Architecture:** A pure-UI container component backed by a built-in lightweight text diffing engine (`CraftTextMatchEngine`). It supports dual inputs (raw strings or pre-evaluated tokens), animated flow layout for word chips (`CraftSpeechWordTokenView`), integrated sound waveform (`CraftWaveformView`), and a tactile mic hub (`CraftTactileMicHubView`).

**Tech Stack:** Swift 5.9+, SwiftUI (iOS 17+), XCTest, CraftUIKit Design System Tokens (`CraftTheme`).

**Spec:** `docs/superpowers/specs/2026-08-26-craftvoicematchcard-design-spec.md`

## Global Constraints

- **Strict UI-Only Separation**: No audio hardware recording, speech recognition APIs, or network calls inside `CraftUIKit`.
- **Zero Hardcoded Strings**: All default UI text and accessibility labels must be defined in `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings` (`craft.speech.*`) with 100% EN/VI parity.
- **Design Tokens**: Use `theme.colors`, `theme.radii`, `theme.spacing`, `theme.animations` from `@Environment(\.craftTheme)`.

---

### Task 1: Speech Models & Matching Engine

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftSpeechModels.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftTextMatchEngine.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftSpeechEngineTests.swift`

**Interfaces:**
- Produces: `CraftSpeechWordStatus`, `CraftSpeechWordToken`, `CraftSpeechState`, `CraftTextMatchEngine.match(originText:actualText:isFinal:) -> [CraftSpeechWordToken]`.

- [ ] **Step 1: Write the failing unit test for `CraftTextMatchEngine`**

```swift
import XCTest
@testable import CraftUIKit

final class CraftSpeechEngineTests: XCTestCase {
    func testExactMatchProducesAllMatchedTokens() {
        let origin = "It was a good job."
        let actual = "It was a good job"
        let tokens = CraftTextMatchEngine.match(originText: origin, actualText: actual, isFinal: true)
        
        XCTAssertEqual(tokens.count, 5)
        XCTAssertEqual(tokens.map(\.targetWord), ["It", "was", "a", "good", "job."])
        XCTAssertTrue(tokens.allSatisfy { $0.status == .matched })
    }

    func testPartialStreamingMatchProducesPendingRemainder() {
        let origin = "It was a good job."
        let actual = "It was"
        let tokens = CraftTextMatchEngine.match(originText: origin, actualText: actual, isFinal: false)
        
        XCTAssertEqual(tokens[0].status, .matched)
        XCTAssertEqual(tokens[1].status, .matched)
        XCTAssertEqual(tokens[2].status, .pending)
        XCTAssertEqual(tokens[3].status, .pending)
        XCTAssertEqual(tokens[4].status, .pending)
    }

    func testMismatchedWordDetection() {
        let origin = "It was a good job."
        let actual = "It was a bad job"
        let tokens = CraftTextMatchEngine.match(originText: origin, actualText: actual, isFinal: true)
        
        XCTAssertEqual(tokens[0].status, .matched) // It
        XCTAssertEqual(tokens[1].status, .matched) // was
        XCTAssertEqual(tokens[2].status, .matched) // a
        XCTAssertEqual(tokens[3].status, .mismatched) // good vs bad
        XCTAssertEqual(tokens[4].status, .matched) // job.
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftSpeechEngineTests`
Expected: FAIL with compilation error (types not found).

- [ ] **Step 3: Implement `CraftSpeechModels.swift` and `CraftTextMatchEngine.swift`**

`CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftSpeechModels.swift`:
```swift
import Foundation

public enum CraftSpeechWordStatus: String, Sendable, Equatable, CaseIterable {
    case pending
    case matched
    case fuzzy
    case mismatched
}

public struct CraftSpeechWordToken: Identifiable, Sendable, Equatable {
    public let id: String
    public let targetWord: String
    public let status: CraftSpeechWordStatus
    public let spokenWord: String?
    public let confidence: Double?

    public init(
        id: String = UUID().uuidString,
        targetWord: String,
        status: CraftSpeechWordStatus = .pending,
        spokenWord: String? = nil,
        confidence: Double? = nil
    ) {
        self.id = id
        self.targetWord = targetWord
        self.status = status
        self.spokenWord = spokenWord
        self.confidence = confidence
    }
}

public enum CraftSpeechState: Equatable, Sendable {
    case idle
    case listening(audioLevels: [CGFloat] = [])
    case processing
    case evaluated(overallScore: Double)
}
```

`CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftTextMatchEngine.swift`:
```swift
import Foundation

public enum CraftTextMatchEngine {
    public static func normalizeWord(_ word: String) -> String {
        let punctuation = CharacterSet.punctuationCharacters.union(.symbols)
        return word.trimmingCharacters(in: punctuation).lowercased()
    }

    public static func match(
        originText: String,
        actualText: String?,
        isFinal: Bool = false
    ) -> [CraftSpeechWordToken] {
        let originWords = originText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard let actualText = actualText?.trimmingCharacters(in: .whitespacesAndNewlines), !actualText.isEmpty else {
            return originWords.enumerated().map { index, word in
                CraftSpeechWordToken(id: "\(index)_\(word)", targetWord: word, status: .pending)
            }
        }

        let actualWords = actualText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var tokens: [CraftSpeechWordToken] = []

        var actualIndex = 0
        for (originIdx, originWord) in originWords.enumerated() {
            let normalizedOrigin = normalizeWord(originWord)

            if actualIndex < actualWords.count {
                let actualWord = actualWords[actualIndex]
                let normalizedActual = normalizeWord(actualWord)

                if normalizedOrigin == normalizedActual {
                    tokens.append(CraftSpeechWordToken(
                        id: "\(originIdx)_\(originWord)",
                        targetWord: originWord,
                        status: .matched,
                        spokenWord: actualWord,
                        confidence: 1.0
                    ))
                    actualIndex += 1
                } else if normalizedActual.hasPrefix(normalizedOrigin) || normalizedOrigin.hasPrefix(normalizedActual) {
                    tokens.append(CraftSpeechWordToken(
                        id: "\(originIdx)_\(originWord)",
                        targetWord: originWord,
                        status: .fuzzy,
                        spokenWord: actualWord,
                        confidence: 0.75
                    ))
                    actualIndex += 1
                } else {
                    let nextOriginMatches = (actualIndex + 1 < actualWords.count) &&
                        (normalizeWord(actualWords[actualIndex + 1]) == normalizedOrigin)
                    
                    if nextOriginMatches {
                        actualIndex += 1
                        tokens.append(CraftSpeechWordToken(
                            id: "\(originIdx)_\(originWord)",
                            targetWord: originWord,
                            status: .matched,
                            spokenWord: actualWords[actualIndex],
                            confidence: 1.0
                        ))
                        actualIndex += 1
                    } else {
                        tokens.append(CraftSpeechWordToken(
                            id: "\(originIdx)_\(originWord)",
                            targetWord: originWord,
                            status: isFinal ? .mismatched : .pending,
                            spokenWord: actualWord,
                            confidence: 0.0
                        ))
                        actualIndex += 1
                    }
                }
            } else {
                tokens.append(CraftSpeechWordToken(
                    id: "\(originIdx)_\(originWord)",
                    targetWord: originWord,
                    status: .pending
                ))
            }
        }

        return tokens
    }
}
```

- [ ] **Step 4: Run unit tests to verify they pass**

Run: `swift test --package-path CraftUIKit --filter CraftSpeechEngineTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftSpeechModels.swift CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftTextMatchEngine.swift CraftUIKit/Tests/CraftUIKitTests/CraftSpeechEngineTests.swift
git commit -m "feat(craftuikit): add speech models and CraftTextMatchEngine"
```

---

### Task 2: Localization Keys for Speech (`craft.speech.*`)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift`

**Interfaces:**
- Produces: Localized strings for `craft.speech.tap_to_speak`, `craft.speech.listening`, `craft.speech.analyzing`, `craft.speech.try_again`, `craft.speech.mic_start_a11y`, `craft.speech.mic_stop_a11y`, `craft.speech.score_format`.

- [ ] **Step 1: Write the failing localization tests in `LocalizationTests.swift`**

Add `testSpeechLocalizationKeys()` to `LocalizationTests.swift`:
```swift
    func testSpeechLocalizationKeys() {
        XCTAssertEqual(CraftLocalized.string("craft.speech.tap_to_speak"), "Tap to speak")
        XCTAssertEqual(CraftLocalized.string("craft.speech.tap_to_speak", language: "vi"), "Chạm để nói")

        XCTAssertEqual(CraftLocalized.string("craft.speech.listening"), "Listening...")
        XCTAssertEqual(CraftLocalized.string("craft.speech.listening", language: "vi"), "Đang lắng nghe...")

        XCTAssertEqual(CraftLocalized.string("craft.speech.analyzing"), "Analyzing pronunciation...")
        XCTAssertEqual(CraftLocalized.string("craft.speech.analyzing", language: "vi"), "Đang phân tích phát âm...")

        XCTAssertEqual(CraftLocalized.string("craft.speech.try_again"), "Try speaking again")
        XCTAssertEqual(CraftLocalized.string("craft.speech.try_again", language: "vi"), "Thử nói lại")

        XCTAssertEqual(CraftLocalized.string("craft.speech.mic_start_a11y"), "Start speaking")
        XCTAssertEqual(CraftLocalized.string("craft.speech.mic_start_a11y", language: "vi"), "Bắt đầu nói")

        XCTAssertEqual(CraftLocalized.string("craft.speech.mic_stop_a11y"), "Stop recording")
        XCTAssertEqual(CraftLocalized.string("craft.speech.mic_stop_a11y", language: "vi"), "Dừng ghi âm")

        XCTAssertEqual(CraftLocalized.format("craft.speech.score_format", 95), "Score: 95%")
        XCTAssertEqual(CraftLocalized.format("craft.speech.score_format", language: "vi", 95), "Điểm: 95%")
    }
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --package-path CraftUIKit --filter LocalizationTests/testSpeechLocalizationKeys`
Expected: FAIL (keys return key identifiers).

- [ ] **Step 3: Add `craft.speech.*` entries to `Localizable.xcstrings`**

Add the 7 keys with 100% EN & VI translations to `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`.

- [ ] **Step 4: Run localization tests to verify pass**

Run: `swift test --package-path CraftUIKit --filter LocalizationTests`
Expected: PASS with 0 failures.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift
git commit -m "feat(craftuikit): add craft.speech localization keys for EN and VI"
```

---

### Task 3: Word Flow Layout & Word Token View

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftSpeechWordFlowLayout.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftSpeechWordTokenView.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftSpeechUIComponentTests.swift`

**Interfaces:**
- Produces: `CraftSpeechWordFlowLayout`, `CraftSpeechWordTokenView(token:)`.

- [ ] **Step 1: Write test for Word Token rendering states**

In `CraftSpeechUIComponentTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftSpeechUIComponentTests: XCTestCase {
    func testTokenViewVisualPropertiesForStatuses() {
        let pending = CraftSpeechWordToken(targetWord: "hello", status: .pending)
        let matched = CraftSpeechWordToken(targetWord: "world", status: .matched)
        let fuzzy = CraftSpeechWordToken(targetWord: "good", status: .fuzzy)
        let mismatched = CraftSpeechWordToken(targetWord: "job", status: .mismatched)
        
        XCTAssertEqual(pending.status, .pending)
        XCTAssertEqual(matched.status, .matched)
        XCTAssertEqual(fuzzy.status, .fuzzy)
        XCTAssertEqual(mismatched.status, .mismatched)
    }
}
```

- [ ] **Step 2: Run test to verify it compiles and runs**

Run: `swift test --package-path CraftUIKit --filter CraftSpeechUIComponentTests`

- [ ] **Step 3: Implement `CraftSpeechWordFlowLayout.swift` and `CraftSpeechWordTokenView.swift`**

`CraftSpeechWordFlowLayout.swift`:
```swift
import SwiftUI

public struct CraftSpeechWordFlowLayout: Layout {
    public var spacing: CGFloat
    public var lineSpacing: CGFloat
    public var alignment: HorizontalAlignment

    public init(
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 8,
        alignment: HorizontalAlignment = .center
    ) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.alignment = alignment
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)

        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for (index, row) in rows.enumerated() {
            totalHeight += row.height
            if index < rows.count - 1 {
                totalHeight += lineSpacing
            }
            maxRowWidth = max(maxRowWidth, row.width)
        }

        return CGSize(width: min(maxWidth, maxRowWidth), height: totalHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var currentY = bounds.minY

        for row in rows {
            let startX: CGFloat
            switch alignment {
            case .leading:
                startX = bounds.minX
            case .trailing:
                startX = bounds.maxX - row.width
            default: // .center
                startX = bounds.minX + max(0, (bounds.width - row.width) / 2)
            }

            var currentX = startX
            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: currentX, y: currentY + (row.height - item.size.height) / 2),
                    proposal: ProposedViewSize(item.size)
                )
                currentX += item.size.width + spacing
            }
            currentY += row.height + lineSpacing
        }
    }

    private struct RowItem {
        let subview: LayoutSubview
        let size: CGSize
    }

    private struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()

        for subview in subviews {
            let itemProposal = maxWidth.isFinite ? ProposedViewSize(width: maxWidth, height: nil) : .unspecified
            let rawSize = subview.sizeThatFits(itemProposal)
            let constrainedWidth = maxWidth.isFinite ? min(rawSize.width, maxWidth) : rawSize.width
            let size = CGSize(width: constrainedWidth, height: rawSize.height)

            let itemSpacing = currentRow.items.isEmpty ? 0 : spacing

            if !currentRow.items.isEmpty && (currentRow.width + itemSpacing + size.width) > maxWidth {
                rows.append(currentRow)
                currentRow = Row()
            }

            let addedSpacing = currentRow.items.isEmpty ? 0 : spacing
            currentRow.items.append(RowItem(subview: subview, size: size))
            currentRow.width += addedSpacing + size.width
            currentRow.height = max(currentRow.height, size.height)
        }

        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}
```

`CraftSpeechWordTokenView.swift`:
```swift
import SwiftUI

public struct CraftSpeechWordTokenView: View {
    @Environment(\.craftTheme) private var theme
    public let token: CraftSpeechWordToken

    public init(token: CraftSpeechWordToken) {
        self.token = token
    }

    public var body: some View {
        HStack(spacing: 4) {
            if token.status == .matched {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.colors.statusSuccess)
            }

            Text(token.targetWord)
                .font(theme.typography.titleMedium)
                .foregroundColor(foregroundColor)
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .animation(theme.animations.springSnappy, value: token.status)
    }

    private var foregroundColor: Color {
        switch token.status {
        case .pending:
            return theme.colors.textPrimary
        case .matched:
            return theme.colors.statusSuccess
        case .fuzzy:
            return theme.colors.statusWarning
        case .mismatched:
            return theme.colors.statusDanger
        }
    }

    private var backgroundColor: Color {
        switch token.status {
        case .pending:
            return theme.colors.surfaceCard.opacity(0.6)
        case .matched:
            return theme.colors.statusSuccess.opacity(0.12)
        case .fuzzy:
            return theme.colors.statusWarning.opacity(0.12)
        case .mismatched:
            return theme.colors.statusDanger.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch token.status {
        case .pending:
            return theme.colors.borderDefault.opacity(0.4)
        case .matched:
            return theme.colors.statusSuccess.opacity(0.4)
        case .fuzzy:
            return theme.colors.statusWarning.opacity(0.4)
        case .mismatched:
            return theme.colors.statusDanger.opacity(0.4)
        }
    }
}
```

- [ ] **Step 4: Run unit tests**

Run: `swift test --package-path CraftUIKit --filter CraftSpeechUIComponentTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftSpeechWordFlowLayout.swift CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftSpeechWordTokenView.swift CraftUIKit/Tests/CraftUIKitTests/CraftSpeechUIComponentTests.swift
git commit -m "feat(craftuikit): add CraftSpeechWordFlowLayout and CraftSpeechWordTokenView"
```

---

### Task 4: Tactile Mic Control Hub (`CraftTactileMicHubView`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftTactileMicHubView.swift`
- Test: Modify `CraftUIKit/Tests/CraftUIKitTests/CraftSpeechUIComponentTests.swift`

**Interfaces:**
- Produces: `CraftTactileMicHubView(speechState:onTapMic:)`.

- [ ] **Step 1: Implement `CraftTactileMicHubView.swift`**

```swift
import SwiftUI

public struct CraftTactileMicHubView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let speechState: CraftSpeechState
    public let onTapMic: () -> Void

    @State private var isPulsing: Bool = false

    public init(speechState: CraftSpeechState, onTapMic: @escaping () -> Void) {
        self.speechState = speechState
        self.onTapMic = onTapMic
    }

    private var isListening: Bool {
        if case .listening = speechState { return true }
        return false
    }

    private var isProcessing: Bool {
        if case .processing = speechState { return true }
        return false
    }

    public var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Button(action: onTapMic) {
                ZStack {
                    if isListening && !reduceMotion {
                        Circle()
                            .stroke(theme.colors.brandPrimary.opacity(0.35), lineWidth: 4)
                            .frame(width: 104, height: 104)
                            .scaleEffect(isPulsing ? 1.25 : 1.0)
                            .opacity(isPulsing ? 0.15 : 0.8)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                    isPulsing = true
                                }
                            }
                            .onDisappear {
                                isPulsing = false
                            }
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isListening
                                    ? [theme.colors.statusDanger, theme.colors.statusDanger.opacity(0.85)]
                                    : [theme.colors.brandPrimary, theme.colors.brandPrimary.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: isListening ? theme.colors.statusDanger.opacity(0.35) : theme.colors.brandPrimary.opacity(0.35),
                            radius: 12,
                            x: 0,
                            y: 6
                        )

                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: isListening ? "waveform.and.mic" : "mic.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                            .symbolEffect(.bounce, value: isListening)
                    }
                }
                .frame(width: 108, height: 108)
                .contentShape(Circle())
            }
            .buttonStyle(CraftTactileButtonStyle())
            .accessibilityLabel(isListening ? CraftLocalized.string("craft.speech.mic_stop_a11y") : CraftLocalized.string("craft.speech.mic_start_a11y"))

            Text(statusSubtitle)
                .font(theme.typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(isListening ? theme.colors.statusDanger : theme.colors.textSecondary)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isListening)
    }

    private var statusSubtitle: String {
        switch speechState {
        case .idle:
            return CraftLocalized.string("craft.speech.tap_to_speak")
        case .listening:
            return CraftLocalized.string("craft.speech.listening")
        case .processing:
            return CraftLocalized.string("craft.speech.analyzing")
        case .evaluated:
            return CraftLocalized.string("craft.speech.try_again")
        }
    }
}

private struct CraftTactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
```

- [ ] **Step 2: Add test & run**

Run: `swift test --package-path CraftUIKit --filter CraftSpeechUIComponentTests`
Expected: PASS.

- [ ] **Step 3: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Feedback/Speech/CraftTactileMicHubView.swift CraftUIKit/Tests/CraftUIKitTests/CraftSpeechUIComponentTests.swift
git commit -m "feat(craftuikit): add CraftTactileMicHubView"
```

---

### Task 5: Master Container View (`CraftVoiceMatchCard`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftVoiceMatchCard.swift`
- Test: Modify `CraftUIKit/Tests/CraftUIKitTests/CraftSpeechUIComponentTests.swift`

**Interfaces:**
- Produces: `CraftVoiceMatchCard`.

- [ ] **Step 1: Implement `CraftVoiceMatchCard.swift`**

```swift
import SwiftUI

public struct CraftVoiceMatchCard: View {
    @Environment(\.craftTheme) private var theme

    public let originText: String
    public let actualText: String?
    public let explicitTokens: [CraftSpeechWordToken]?
    public let subtitle: String?
    public let speechState: CraftSpeechState
    public let customInstruction: String?
    public let onTapMic: () -> Void
    public let onReset: (() -> Void)?

    public init(
        originText: String,
        actualText: String? = nil,
        explicitTokens: [CraftSpeechWordToken]? = nil,
        subtitle: String? = nil,
        speechState: CraftSpeechState = .idle,
        customInstruction: String? = nil,
        onTapMic: @escaping () -> Void,
        onReset: (() -> Void)? = nil
    ) {
        self.originText = originText
        self.actualText = actualText
        self.explicitTokens = explicitTokens
        self.subtitle = subtitle
        self.speechState = speechState
        self.customInstruction = customInstruction
        self.onTapMic = onTapMic
        self.onReset = onReset
    }

    private var activeTokens: [CraftSpeechWordToken] {
        if let explicitTokens {
            return explicitTokens
        }
        let isFinal: Bool
        if case .evaluated = speechState {
            isFinal = true
        } else {
            isFinal = false
        }
        return CraftTextMatchEngine.match(originText: originText, actualText: actualText, isFinal: isFinal)
    }

    private var isListening: Bool {
        if case .listening = speechState { return true }
        return false
    }

    private var audioLevels: [CGFloat] {
        if case let .listening(levels) = speechState { return levels }
        return []
    }

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Header / Instruction & Score
            HStack(alignment: .center) {
                if let customInstruction {
                    Text(customInstruction)
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)
                } else if let subtitle {
                    Text(subtitle)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                if case let .evaluated(score) = speechState {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                        Text(CraftLocalized.format("craft.speech.score_format", Int(score)))
                            .font(theme.typography.labelSmall)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xs / 2)
                    .background(score >= 80 ? theme.colors.statusSuccess.opacity(0.12) : theme.colors.statusWarning.opacity(0.12))
                    .foregroundColor(score >= 80 ? theme.colors.statusSuccess : theme.colors.statusWarning)
                    .clipShape(Capsule())
                }
            }

            // Word Tokens Flow
            CraftSpeechWordFlowLayout(spacing: theme.spacing.xs, lineSpacing: theme.spacing.xs) {
                ForEach(activeTokens) { token in
                    CraftSpeechWordTokenView(token: token)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.sm)

            // Waveform & Transcript feedback
            if isListening {
                VStack(spacing: theme.spacing.xs) {
                    CraftWaveformView(
                        audioLevels: audioLevels,
                        barCount: 16,
                        isRecording: true
                    )

                    if let actualText, !actualText.isEmpty {
                        Text(actualText)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Tactile Mic Hub
            CraftTactileMicHubView(
                speechState: speechState,
                onTapMic: onTapMic
            )
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                .stroke(isListening ? theme.colors.statusDanger.opacity(0.4) : theme.colors.borderDefault, lineWidth: 1.5)
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 12,
            x: 0,
            y: 4
        )
        .animation(theme.animations.springSnappy, value: speechState)
    }
}
```

- [ ] **Step 2: Add integration tests in `CraftSpeechUIComponentTests.swift`**

```swift
    func testCraftVoiceMatchCardInitializesCleanly() {
        let card = CraftVoiceMatchCard(
            originText: "It was a good job.",
            actualText: "It was",
            subtitle: "Đó là một công việc tốt.",
            speechState: .idle,
            onTapMic: {}
        )
        XCTAssertNotNil(card)
    }
```

- [ ] **Step 3: Run unit tests**

Run: `swift test --package-path CraftUIKit --filter CraftSpeechUIComponentTests`
Expected: PASS.

- [ ] **Step 4: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftVoiceMatchCard.swift CraftUIKit/Tests/CraftUIKitTests/CraftSpeechUIComponentTests.swift
git commit -m "feat(craftuikit): add CraftVoiceMatchCard container component"
```

---

### Task 6: Catalog Integration & Full Verification

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Catalog/CraftCatalogView.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

**Interfaces:**
- Verifies full catalog build and zero regressions across all test suites.

- [ ] **Step 1: Add `CraftVoiceMatchCard` sample to `CraftCatalogView.swift`**

Integrate a live preview section for `CraftVoiceMatchCard` with toggleable state (`.idle`, `.listening`, `.evaluated`).

- [ ] **Step 2: Run all CraftUIKit tests**

Run: `swift test --package-path CraftUIKit`
Expected: All tests pass with 0 errors.

- [ ] **Step 3: Commit catalog integration**

```bash
git add CraftUIKit/Sources/CraftUIKit/Catalog/CraftCatalogView.swift CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift
git commit -m "feat(craftuikit): integrate CraftVoiceMatchCard into CraftCatalogView"
```
