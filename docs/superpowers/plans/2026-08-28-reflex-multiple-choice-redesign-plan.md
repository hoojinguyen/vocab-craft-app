# Reflex Blitz — Multiple Choice & Review Consolidation Redesign Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cải tiến toàn diện chế độ Trắc nghiệm (Multiple Choice) và màn hình Củng cố (Reviewed Consolidation) trên Reflex Blitz: chuyển 2x2 Grid sang Vertical Stack 1 cột, loại bỏ prefix A/B/C/D, chuẩn hóa nút loa tròn, triệt tiêu lặp từ/trạng thái và loại bỏ viền màu gây sensory overload.

**Architecture:** Áp dụng Adaptive Dual-Zone Layout (Hero Stimulus Zone ở trên, Action Zone 1-column vertical list ở dưới). Chuẩn hóa 100% tokens và components từ `CraftUIKit` (`CraftChoiceCard`, `CraftSpeakerButton`, `CraftFeedbackSheet`).

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit, XCTest, Swift Testing.

**Spec:** `docs/superpowers/specs/2026-08-28-reflex-multiple-choice-redesign-design.md`

## Global Constraints

- Design System: Sử dụng 100% token từ `CraftUIKit` (`CraftTheme`, `CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`).
- Zero Hardcode: Mọi chuỗi hiển thị và accessibility label phải sử dụng `AppStrings.ReflexBlitz` hoặc `CraftLocalized`.
- Touch Ergonomics: Mỗi thẻ trắc nghiệm tối thiểu 44pt - 52pt chiều cao, hỗ trợ dynamic type và leading alignment.
- Audio Standard: Nút loa sử dụng `CraftSpeakerButton` dạng Circle chuẩn (`size: .md`, không có text label gây tràn).

---

### Task 1: Refine `CraftChoiceCard` for Prefix-Free and Leading Alignment

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

**Interfaces:**
- Consumes: `CraftChoiceCard` existing initializers and `CraftChoicePrefixStyle`.
- Produces: Enhanced `CraftChoiceCard` rendering where `prefixStyle == .none` or `prefix == nil` gracefully spans full available width with leading alignment and zero clipping.

- [ ] **Step 1: Write the failing unit test for prefix-free CraftChoiceCard**

Thêm test case vào `Packages/CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`:
```swift
@MainActor
func testCraftChoiceCardPrefixNoneLeadingAlignment() {
    var didTap = false
    let card = CraftChoiceCard(
        prefix: nil,
        prefixStyle: .none,
        title: "look forward to",
        subtitle: "trông đợi, mong chờ",
        textAlignment: .leading,
        state: .idle,
        style: .tactile3D,
        showsStatusIndicator: false,
        action: { didTap = true }
    )
    XCTAssertNil(card.prefix)
    XCTAssertEqual(card.prefixStyle, .none)
    XCTAssertEqual(card.title, "look forward to")
    XCTAssertEqual(card.subtitle, "trông đợi, mong chờ")
    XCTAssertNotNil(card.body)
    card.action()
    XCTAssertTrue(didTap)
}
```

- [ ] **Step 2: Run test to verify it compiles and passes**

Run: `swift test --package-path Packages/CraftUIKit --filter ControlComponentTests`
Expected: PASS (or update layout logic in `CraftChoiceCard.swift` if alignment issues are detected).

- [ ] **Step 3: Review and refine `CraftChoiceCard.swift` layout**

Đảm bảo khi `prefixStyle == .none` hoặc `rawPrefix == nil`, `prefixBadge` không render khoảng trống thừa, và text content căn `leading` mượt mà.

- [ ] **Step 4: Run all CraftUIKit tests**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift Packages/CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift
git commit -m "feat(CraftUIKit): refine CraftChoiceCard for prefix-free vertical option lists"
```

---

### Task 2: Redesign `ReflexBlitzCardView.swift` for 1-Column Options & De-nested Stimulus

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzWordItem`, `ReflexBlitzOption`, `ReflexCardPhase`, `CraftChoiceCard`.
- Produces: `ReflexBlitzCardView` với `activeMultipleChoiceContent` dạng Vertical Stack 1 cột, không có viền card đổi màu chói mắt, không có prefix A/B/C/D gây vỡ dòng.

- [ ] **Step 1: Write the failing test for 1-column option list in ReflexBlitzCardView**

Thêm test case vào `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`:
```swift
@MainActor
func testMultipleChoiceCardUsesVerticalOptionsStackWithoutPrefix() {
    let word = ReflexBlitzWordItem.defaultStarterWords[0]
    let options = word.generateOptions(mode: .multipleChoice, allPool: ReflexBlitzWordItem.defaultStarterWords)
    var selectedOption: ReflexBlitzOption?
    let card = ReflexBlitzCardView(
        word: word,
        mode: .multipleChoice,
        cardPhase: .activeCountdown,
        options: options,
        onSelectOption: { opt in selectedOption = opt }
    )
    XCTAssertNotNil(card.body)
    XCTAssertEqual(card.options.count, 4)
    card.onSelectOption?(options[1])
    XCTAssertEqual(selectedOption?.id, options[1].id)
}
```

- [ ] **Step 2: Run test to verify current behavior**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests/testMultipleChoiceCardUsesVerticalOptionsStackWithoutPrefix`
Expected: PASS / Setup baseline.

- [ ] **Step 3: Refactor `ReflexBlitzCardView.swift`**

1. Trong `activeOptionsGrid`, đổi tên thành `activeOptionsList` (hoặc giữ tên biến nhưng thay thế layout):
   - Thay thế `LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())])` bằng `VStack(spacing: theme.spacing.sm)`.
   - Cấu hình `CraftChoiceCard`:
     - `prefix: nil`
     - `prefixStyle: .none`
     - `title: option.text`
     - `textAlignment: .leading`
     - `state: .idle`
     - `style: .tactile3D`
     - `showsStatusIndicator: false`
2. Tinh chỉnh `cardBorderColor`:
   - Giữ màu hairline trung tính nhẹ nhàng (`theme.colors.hairline.opacity(0.4)`), không đổi sang màu đỏ/xanh chói lóa làm phân tâm người dùng.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift
git commit -m "refactor(ReflexDrill): convert multiple choice options to 1-column vertical stack in ReflexBlitzCardView"
```

---

### Task 3: Redesign `ReflexBlitzCardReviewedView.swift` for Clean Consolidation

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardReviewedView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzWordItem`, `ReflexBlitzOption`, `ReflexCardResult`, `CraftSpeakerButton`.
- Produces: `ReflexBlitzCardReviewedView` với header tinh gọn (Lemma + POS + Circular Speaker + IPA), không có duplicate status badge, và options stack 1 cột hiển thị rõ ràng đáp án đúng/sai.

- [ ] **Step 1: Write the failing test for clean reviewed consolidation layout**

Thêm test case vào `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`:
```swift
@MainActor
func testReflexBlitzCardReviewedViewCleanConsolidationLayout() {
    let word = ReflexBlitzWordItem.defaultStarterWords[0]
    let options = [
        ReflexBlitzOption(id: "1", text: "habit", isCorrect: true),
        ReflexBlitzOption(id: "2", text: "focus", isCorrect: false),
        ReflexBlitzOption(id: "3", text: "create", isCorrect: false),
        ReflexBlitzOption(id: "4", text: "relax", isCorrect: false)
    ]
    var didReplay = false
    let reviewedCard = ReflexBlitzCardReviewedView(
        word: word,
        mode: .multipleChoice,
        isReviewed: true,
        isResultCorrect: true,
        isResultTimeout: false,
        options: options,
        reviewResult: ReflexCardResult(isCorrect: true, responseTimeMs: 1200, isTimeout: false, selectedOption: "habit"),
        selectedOptionText: "habit",
        clozeParts: nil,
        displayedSentence: word.completedSentenceWithTargetWord,
        onReplayAudio: { didReplay = true }
    )
    XCTAssertNotNil(reviewedCard.body)
    reviewedCard.onReplayAudio?()
    XCTAssertTrue(didReplay)
}
```

- [ ] **Step 2: Run test to verify baseline**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests/testReflexBlitzCardReviewedViewCleanConsolidationLayout`
Expected: PASS / Baseline.

- [ ] **Step 3: Implement clean consolidation layout in `ReflexBlitzCardReviewedView.swift`**

1. **Loại bỏ `statusHeaderBadge`**: Xóa badge trạng thái `Correct!`/`Incorrect`/`Time's up!` trên đỉnh card (vì đã có `CraftFeedbackSheet` ở dưới đáy màn hình).
2. **Cập nhật `lemmaAndDefinitionSection`**:
   - `HStack(alignment: .center, spacing: theme.spacing.sm)` chứa:
     - `CraftText(word.lemma, style: .titleLarge, color: theme.colors.textPrimary)`
     - `CraftBadge(word.pos.uppercased(), variant: .subtle, tone: .primary, size: .sm)`
     - `CraftSpeakerButton(variant: .subtle, size: .md, isPlaying: false, label: nil, action: { onReplayAudio?() })`
   - Hiển thị IPA và định nghĩa tiếng Việt gọn gàng, cách khoảng cách token `spacing.xs`.
3. **Chuyển `reviewedOptionsGrid` thành `reviewedOptionsList` (1 cột)**:
   - `VStack(spacing: theme.spacing.sm)`
   - `CraftChoiceCard`:
     - `prefix: nil`
     - `prefixStyle: .none`
     - `title: option.text`
     - `textAlignment: .leading`
     - `state: choiceState` (`.correct` nếu `option.isCorrect`, `.wrong` nếu `isSelected && !isCorrect`, `.idle` nếu khác)
     - `style: .tactile3D`
     - `showsStatusIndicator: isCorrect || isSelected`

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardReviewedView.swift
git commit -m "refactor(ReflexDrill): clean up reviewed consolidation layout and standardize circular speaker button"
```

---

### Task 4: Update All Reflex Drill Component & View Integration Tests

**Files:**
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`

**Interfaces:**
- Consumes: Updated `ReflexBlitzCardView` and `ReflexBlitzCardReviewedView`.
- Produces: Updated test assertions verifying prefix-free 1-column vertical list, circular audio replay, and lack of duplicate status badges.

- [ ] **Step 1: Update existing tests in `ReflexBlitzComponentsTests.swift`**

Cập nhật các assertion kiểm tra `cardBorderColor` và reviewed card layout cho khớp với thiết kế mới.

- [ ] **Step 2: Run all Reflex Drill tests**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests -only-testing:VocabCraftAppTests/ReflexBlitzViewIntegrationTests`
Expected: 100% tests PASS.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift
git commit -m "test(ReflexDrill): update component and integration tests for redesigned multiple choice mode"
```

---

### Task 5: Full Verification & Quality Gate (Zero Warnings, 100% Tests Pass)

**Files:**
- All touched files in `CraftUIKit` and `VocabCraftApp`.

- [ ] **Step 1: Run CraftUIKit localization tests**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Expected: PASS.

- [ ] **Step 2: Run full test suites**

Run: `swift test --package-path Packages/CraftUIKit`
Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: 100% tests PASS.

- [ ] **Step 3: Run SwiftLint**

Run: `swiftlint lint --strict`
Expected: 0 errors, 0 warnings.

- [ ] **Step 4: Final commit and summary**

```bash
git status
git commit -m "chore: complete reflex multiple choice and review consolidation redesign"
```
