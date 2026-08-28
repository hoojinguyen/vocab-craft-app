# Reflex Blitz — Multiple Choice Layout Stabilization, Motion & Typography Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Khắc phục triệt để lỗi giật nảy màn hình, không đồng nhất UI nút trắc nghiệm, thiếu animation slide-up cho bottom sheet và tối ưu hóa typography/ký hiệu khuyết từ `[...]` trong chế độ trắc nghiệm Reflex Blitz.

**Architecture:** 
- Đưa `CraftFeedbackSheet` ra ngoài luồng `VStack` chính, chuyển thành Bottom Overlay dock độc lập để Header và Card không bị đẩy xô lệch.
- Hợp nhất `CraftChoiceCard` options list thành một cây View duy nhất xuyên suốt vòng đời active $\rightarrow$ reviewed để giữ nguyên trạng thái animation và 3D tactile haptics.
- Chuẩn hóa ô khuyết từ thành `[ • • • ]` ngắn gọn không ngắt dòng và điều chỉnh typography câu ví dụ về `theme.typography.bodySerif` (~16pt).
- Kích hoạt animation spring mượt mà khi đổi trạng thái sang `.reviewed`.

**Tech Stack:** Swift 6, SwiftUI, Observation framework, CraftUIKit Design System, Swift Testing / XCTest.

**Spec:** [`docs/superpowers/specs/2026-08-28-reflex-multiple-choice-layout-and-animation-enhancements-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-28-reflex-multiple-choice-layout-and-animation-enhancements-design.md)

## Global Constraints

- **Design System First:** 100% sử dụng token `CraftUIKit` (`CraftColor`, `CraftFont`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftShadowTokens`). Tuyệt đối không hardcode màu sắc, font size hay padding.
- **Zero Hardcoded Strings:** Không dùng raw string literals; sử dụng `AppStrings.ReflexBlitz.*` và key trong `Localizable.xcstrings`.
- **Zero Warnings / Zero Errors:** Không chấp nhận cảnh báo Swift Concurrency, deprecation hay SwiftLint warnings.

---

### Task 1: Compact Cloze Token & Balanced Typography in Card Views

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift:145-165, 365-425`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardReviewedView.swift:115-165`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift:285-350`

**Interfaces:**
- `ReflexBlitzCardView.slotRepresentation: String` $\rightarrow$ Trả về `"[ • • • ]"` (unanswered), `"[ f... ]"` hoặc `"[ f • • ]"` (hinted), `word.lemma` (reviewed).
- Typography câu ví dụ: Sử dụng `theme.typography.bodySerif` (hoặc `fontDesign(.serif)` với body size) thay vì `titleMedium`.

- [ ] **Step 1: Write the failing unit test for compact cloze representation**

Mở file `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift` và thêm test case kiểm tra token khuyết từ có độ dài gọn gàng và không nở dài theo số ký tự:

```swift
    @MainActor
    func testCompactClozeSlotRepresentationDoesNotExceedMaxDots() {
        let longWord = ReflexBlitzWordItem(
            id: 99,
            lemma: "comprehension",
            pos: "n.",
            ipa: "/ˌkɒm.prɪˈhen.ʃən/",
            definitionVi: "Sự thấu hiểu",
            exampleSentenceEn: "Reading aids comprehension of language.",
            exampleSentenceVi: "Đọc sách giúp thấu hiểu ngôn ngữ.",
            clozeSentenceEn: "Reading aids [ _____________ ] of language."
        )

        let card = ReflexBlitzCardView(
            word: longWord,
            showHint: false,
            isCorrect: false
        )
        let slot = card.slotRepresentation
        XCTAssertEqual(slot, "[ • • • ]")

        let hintedCard = ReflexBlitzCardView(
            word: longWord,
            showHint: true,
            isCorrect: false
        )
        let hintedSlot = hintedCard.slotRepresentation
        XCTAssertTrue(hintedSlot.hasPrefix("[ c"))
        XCTAssertTrue(hintedSlot.count <= 10)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter testCompactClozeSlotRepresentationDoesNotExceedMaxDots`
Expected: FAIL (vì hiện tại đang tạo chuỗi `[ • • • • • • ]` có nhiều hơn 3 chấm).

- [ ] **Step 3: Implement compact cloze token and refined typography**

Trong `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`:
Cập nhật `slotRepresentation`:
```swift
    public var slotRepresentation: String {
        if isReviewed {
            return word.lemma
        } else if showHint {
            let initial = String(word.lemma.prefix(1)).lowercased()
            return "[ \(initial) • • ]"
        } else {
            return "[ • • • ]"
        }
    }
```

Cập nhật hàm render text câu ví dụ trong `ReflexBlitzCardView.swift`:
```swift
    private func activeClozeText(parts: ClozeSentenceParts) -> Text {
        let prefixText = Text(parts.prefix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        let slotText = Text(parts.slot)
            .font(theme.typography.bodySerif.bold())
            .foregroundColor(slotTextColor)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
    }

    private func reviewedClozeText(parts: ClozeSentenceParts) -> Text {
        let prefixText = Text(parts.prefix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        let slotColor: Color = isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger
        let slotText = Text(parts.slot)
            .font(theme.typography.bodySerif.bold())
            .foregroundColor(slotColor)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
    }
```

Và cập nhật tương ứng trong `ReflexBlitzCardReviewedView.swift`:
```swift
    @ViewBuilder
    private var reviewedSentenceView: some View {
        if let parts = clozeParts {
            Text(parts.prefix)
                .font(theme.typography.bodySerif)
                .foregroundColor(theme.colors.textPrimary)
            +
            Text(parts.slot)
                .font(theme.typography.bodySerif.bold())
                .foregroundColor(isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger)
            +
            Text(parts.suffix)
                .font(theme.typography.bodySerif)
                .foregroundColor(theme.colors.textPrimary)
        } else {
            Text(displayedSentence)
                .font(theme.typography.bodySerif.bold())
                .foregroundColor(isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger)
        }
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter ReflexBlitzComponentsTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardReviewedView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "feat(reflex): compact cloze slot token and refined sentence typography"
```

---

### Task 2: Single-Tree Options List & Seamless State Transitions in Choice Card

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift:245-260, 430-450`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift:490-535`

**Interfaces:**
- `ReflexBlitzCardView.optionsListView: some View`: Một `VStack` duy nhất quản lý 4 thẻ `CraftChoiceCard` xuyên suốt từ lúc chưa chọn đến khi xem kết quả.
- Khi `isReviewed == true`:
  - Thẻ có `option.isCorrect` $\rightarrow$ `state: .correct`, `showsStatusIndicator: true`.
  - Thẻ người dùng chọn sai `isSelected && !option.isCorrect` $\rightarrow$ `state: .wrong`, `showsStatusIndicator: true`.
  - Các thẻ còn lại $\rightarrow$ `state: .disabled` hoặc `.idle`.

- [ ] **Step 1: Write test for choice card single-tree state mapping**

Mở `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift` và thêm test case kiểm tra state derivation cho options list:

```swift
    @MainActor
    func testCardViewChoiceStatesDerivationInReviewedMode() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = [
            ReflexBlitzOption(id: "1", text: "habit", isCorrect: true),
            ReflexBlitzOption(id: "2", text: "focus", isCorrect: false),
            ReflexBlitzOption(id: "3", text: "create", isCorrect: false),
            ReflexBlitzOption(id: "4", text: "relax", isCorrect: false)
        ]

        let card = ReflexBlitzCardView(
            word: word,
            mode: .multipleChoice,
            cardPhase: .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: 2000,
                isTimeout: false,
                selectedOption: "focus"
            )),
            options: options
        )

        XCTAssertTrue(card.isReviewed)
        XCTAssertEqual(card.selectedOptionText, "focus")
        XCTAssertNotNil(card.body)
    }
```

- [ ] **Step 2: Run test to verify**

Run: `swift test --filter testCardViewChoiceStatesDerivationInReviewedMode`
Expected: PASS or verify existing behavior.

- [ ] **Step 3: Refactor ReflexBlitzCardView to unify options list**

Trong `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`, thay thế việc phân nhánh view hoàn toàn bằng cấu trúc card đồng nhất với `optionsListView`:

```swift
    @ViewBuilder
    private var optionsListView: some View {
        VStack(spacing: theme.spacing.sm) {
            ForEach(options, id: \.id) { option in
                let isSelected = (option.text == selectedOptionText)
                let choiceState: CraftChoiceState = {
                    guard isReviewed else { return .idle }
                    if option.isCorrect {
                        return .correct
                    } else if isSelected {
                        return .wrong
                    } else {
                        return .disabled
                    }
                }()

                CraftChoiceCard(
                    prefix: nil,
                    prefixStyle: .none,
                    title: option.text,
                    textAlignment: .leading,
                    state: choiceState,
                    style: .tactile3D,
                    showsStatusIndicator: isReviewed && (option.isCorrect || isSelected),
                    action: {
                        guard !isReviewed else { return }
                        onSelectOption?(option)
                    }
                )
                .frame(minHeight: 52)
                .accessibilityLabel(option.text)
            }
        }
    }
```

Trong `activeMultipleChoiceContent`, sử dụng `optionsListView`. Đồng thời trong trường hợp `.multipleChoice`, giữ cấu trúc card ổn định thay vì hoán đổi hoàn toàn view con.

- [ ] **Step 4: Run tests to verify options rendering**

Run: `swift test --filter ReflexBlitzComponentsTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "refactor(reflex): unify choice card options list into single persistent view tree"
```

---

### Task 3: Zero-Shift Layout Architecture & Floating Overlay Sheet Presentation

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift:340-398, 530-575`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift:115-225`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- `ReflexBlitzView.drillingView`: Cấu trúc `ZStack { mainContent, feedbackOverlay }`.
- `ReflexBlitzViewModel.selectOption()`: Bọc cập nhật state trong `withAnimation(.spring(response: 0.38, dampingFraction: 0.82))`.

- [ ] **Step 1: Write test for animated state transition in ReflexBlitzViewModel**

Mở `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift` và bổ sung test kiểm tra `cardPhase` chuyển sang `.reviewed` chính xác:

```swift
    @MainActor
    func testSelectOptionTransitionsCardPhaseToReviewed() async {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)
        
        guard let correctOption = viewModel.currentOptions.first(where: { $0.isCorrect }) else {
            XCTFail("No correct option found")
            return
        }
        
        viewModel.selectOption(correctOption)
        
        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertEqual(result.selectedOption, correctOption.text)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
    }
```

- [ ] **Step 2: Run test to verify**

Run: `swift test --filter testSelectOptionTransitionsCardPhaseToReviewed`
Expected: PASS.

- [ ] **Step 3: Update ReflexBlitzViewModel with explicit withAnimation**

Trong `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`:
Bọc cập nhật `cardPhase = .reviewed(...)` trong `withAnimation`:

```swift
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: isCorrect,
                responseTimeMs: responseMs,
                isTimeout: false,
                selectedOption: option.text,
                typedText: nil,
                recognizedSpoken: nil
            ))
        }
```
Thực hiện tương tự cho `handleTimeout()`, `submitTypingAnswer()`, `handleSpokenMatch()`.

- [ ] **Step 4: Refactor ReflexBlitzView layout to Floating Overlay**

Trong `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`:
Cập nhật `drillingView`:
```swift
    @ViewBuilder
    public var drillingView: some View {
        ZStack(alignment: .bottom) {
            // Main stable content area (Header + Card)
            VStack(spacing: theme.spacing.md) {
                ReflexBlitzHeaderView(
                    currentIndex: viewModel.currentWordIndex,
                    totalCount: viewModel.words.count,
                    comboStreak: viewModel.comboStreak,
                    fractionRemaining: viewModel.fractionRemaining,
                    timerStage: viewModel.timerStage,
                    mode: viewModel.selectedMode,
                    attempts: viewModel.attempts,
                    wordStartTime: viewModel.wordStartTime,
                    timeLimitSeconds: viewModel.selectedMode.timeLimitSeconds,
                    isTimerActive: viewModel.cardPhase == .activeCountdown,
                    onClose: {
                        viewModel.cancelSession()
                        viewModel.phase = .modeSelection
                    },
                    onSkip: {
                        viewModel.handleTimeout()
                    },
                    showSkipInHeader: false
                )
                .padding(.top, theme.spacing.sm)

                Spacer(minLength: theme.spacing.xs)

                if let word = viewModel.currentWord {
                    ReflexBlitzCardView(
                        word: word,
                        mode: viewModel.selectedMode,
                        cardPhase: viewModel.cardPhase,
                        options: viewModel.currentOptions,
                        fractionRemaining: viewModel.fractionRemaining,
                        timerStage: viewModel.timerStage,
                        showHint: viewModel.showHint,
                        isCorrect: viewModel.currentAttemptIsCorrect,
                        isTimeout: isReviewedTimeout,
                        liveTranscript: viewModel.liveTranscript,
                        elapsedTimeMs: viewModel.elapsedTimeMs,
                        isKeyboardFallbackActive: viewModel.isKeyboardFallbackActive,
                        keyboardInputText: $typingInput,
                        onSelectOption: { option in
                            viewModel.selectOption(option)
                        },
                        onSubmitKeyboard: {
                            submitKeyboard()
                        },
                        onReplayAudio: {
                            viewModel.speakCurrentWord()
                        }
                    )
                }

                Spacer(minLength: theme.spacing.xs)

                // Reserved spacing for Skip Button or Sheet clearance
                if viewModel.cardPhase == .activeCountdown && (viewModel.selectedMode == .speaking || viewModel.selectedMode == .typing) {
                    CraftButton(
                        AppStrings.ReflexBlitz.skip,
                        iconName: "forward.fill",
                        variant: .outline,
                        size: .md,
                        isFullWidth: true,
                        style: .outlined,
                        action: {
                            viewModel.skip()
                        }
                    )
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.lg)
                    .transition(.opacity)
                } else {
                    Color.clear
                        .frame(height: 52)
                        .padding(.bottom, theme.spacing.lg)
                }
            }

            // Floating Bottom Feedback Sheet Overlay
            if case .reviewed(let result) = viewModel.cardPhase {
                CraftFeedbackSheet(
                    status: result.isCorrect ? .success : (result.isTimeout ? .warning : .error),
                    title: result.isCorrect ? AppStrings.ReflexBlitz.correctTitleText : (result.isTimeout ? AppStrings.ReflexBlitz.timeoutTitleText : AppStrings.ReflexBlitz.incorrectTitleText),
                    actionTitle: AppStrings.ReflexBlitz.continueCTAText,
                    streakCount: nil,
                    style: .tactile3D,
                    onContinue: {
                        typingInput = ""
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.advanceToNextWord()
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: viewModel.cardPhase)
    }
```

- [ ] **Step 5: Run integration tests to verify**

Run: `swift test --filter ReflexBlitz`
Expected: PASS.

- [ ] **Step 6: Commit changes**

```bash
git add VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift
git commit -m "feat(reflex): zero-shift layout architecture with floating feedback sheet overlay"
```

---

### Task 4: Verification, Lint Compliance & Build Validation

**Files:**
- Test: Full project test suites
- Lint: Codebase verification

- [ ] **Step 1: Run CraftUIKit tests**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: PASS (100% test pass rate).

- [ ] **Step 2: Run all VocabCraftApp tests**

Run: `swift test`
Expected: PASS (100% test pass rate).

- [ ] **Step 3: Run SwiftLint**

Run: `swiftlint lint --strict`
Expected: 0 violations, 0 warnings.

- [ ] **Step 4: Commit any final test adjustments**

```bash
git commit -m "chore(reflex): finalize test verification and quality gate for reflex multiple choice"
```
