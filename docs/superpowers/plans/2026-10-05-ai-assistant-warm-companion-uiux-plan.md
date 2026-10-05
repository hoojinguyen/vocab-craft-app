# AI Assistant Warm Companion UI/UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete UI/UX overhaul of the AI Assistant subsystem across Hub, Voice Call, Text Chat, and Summary screens according to the approved "The Warm Companion Hub" spec, resolving layout clipping, replacing raw dev-tool UI, adding conversational scaffolding, and establishing 100% bilingual parity.

**Architecture:** 
- Grounded in `CraftUIKit` tokens (`CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftGlassTokens`) and reusable atoms/containers (`CraftCard`, `CraftBadge`, `CraftIcon`, `CraftIconButton`, `CraftButton`, `CraftVoiceOrbView`).
- Strict Layer 2 localization (`app.ai.*`) in `VocabCraftApp/Resources/Localizable.xcstrings` with typed accessors in `AppStrings.AIAssistant`.
- Modular UI decomposition into focused view components (`CompanionHeroCard`, `EngineStatusPill`, `SentenceStarterChipsBar`, `InteractiveTargetWordsStrip`).

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit, Swift Testing / XCTest, XcodeBuildMCP.

**Spec:** [`docs/superpowers/specs/2026-10-05-ai-assistant-warm-companion-uiux-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-10-05-ai-assistant-warm-companion-uiux-design.md)

## Global Constraints
- Target iOS 18+ SDK with standard iPhone dimensions (375pt SE to 430pt Pro Max).
- Touch targets must measure >= 44x44pt.
- Zero raw styling: strictly use `theme.colors.*`, `theme.spacing.*`, `theme.radii.*`, `theme.typography.*`.
- Zero hardcoded strings: all text must use `AppStrings.AIAssistant.*` backed by `Localizable.xcstrings` with 100% EN & VI parity.
- Zero compiler warnings and 0 SwiftLint violations.

---

### Task 1: Localization Strings & AppStrings Accessors

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/App/Constants/AppStrings.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift`

**Interfaces:**
- Consumes: Existing `AppStrings` namespace.
- Produces:
  - `AppStrings.AIAssistant.engineOnDevice`: LocalizedStringKey
  - `AppStrings.AIAssistant.engineCloud`: LocalizedStringKey
  - `AppStrings.AIAssistant.companionBadge`: LocalizedStringKey
  - `AppStrings.AIAssistant.companionStartCall`: LocalizedStringKey
  - `AppStrings.AIAssistant.companionStartChat`: LocalizedStringKey
  - `AppStrings.AIAssistant.companionGreetingFormat`: String
  - `AppStrings.AIAssistant.scenarioSectionTitle`: LocalizedStringKey
  - `AppStrings.AIAssistant.starterChipsTitle`: LocalizedStringKey
  - `AppStrings.AIAssistant.summaryMasteredWords`: LocalizedStringKey
  - `AppStrings.AIAssistant.summaryUnmasteredWords`: LocalizedStringKey
  - `AppStrings.AIAssistant.summarySaveToVault`: LocalizedStringKey
  - `AppStrings.AIAssistant.summaryActionReflex`: LocalizedStringKey

- [ ] **Step 1: Write the failing localization test**

In `VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift`, add assertions for the new string keys:
```swift
func test_warmCompanion_stringKeys_existInEnglishAndVietnamese() {
    let keys = [
        "app.ai.hub.engine.on_device",
        "app.ai.hub.engine.cloud",
        "app.ai.hub.companion.badge",
        "app.ai.hub.companion.start_call",
        "app.ai.hub.companion.start_chat",
        "app.ai.hub.scenarios.title",
        "app.ai.call.live_badge",
        "app.ai.chat.starter_chips_title",
        "app.ai.summary.mastered_words",
        "app.ai.summary.unmastered_words",
        "app.ai.summary.save_to_vault",
        "app.ai.summary.action_reflex"
    ]
    for key in keys {
        assertLocalizationExists(key: key)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AIAssistantLocalizationTests`
Expected: FAIL due to missing keys in `Localizable.xcstrings`.

- [ ] **Step 3: Update `Localizable.xcstrings` and `AppStrings.swift`**

Add all required keys with complete, polished EN and VI translations into `Localizable.xcstrings` and expose static accessors in `AppStrings.AIAssistant`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AIAssistantLocalizationTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/App/Constants/AppStrings.swift VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift
git commit -m "feat(ai): add bilingual localization keys for Warm Companion UI"
```

---

### Task 2: Engine Status Pill & Companion Hero Card Components

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/Views/Components/EngineStatusPill.swift`
- Create: `VocabCraftApp/Features/AIAssistant/Views/Components/CompanionHeroCard.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`

**Interfaces:**
- Consumes: `CraftUIKit` (`CraftCard`, `CraftBadge`, `CraftButton`, `CraftIcon`), `RoleplayScenario`, `AppStrings`.
- Produces:
  - `EngineStatusPill(isCloudConfigured: Bool, onTap: @escaping () -> Void)`
  - `CompanionHeroCard(scenario: RoleplayScenario, wordsLearnedCount: Int, onStartCall: @escaping () -> Void, onStartChat: @escaping () -> Void)`

- [ ] **Step 1: Write the failing unit test for `CompanionHeroCard` & `EngineStatusPill`**

In `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`:
```swift
@Test func test_engineStatusPill_renders_proper_badge_for_modes() {
    let onDevicePill = EngineStatusPill(isCloudConfigured: false, onTap: {})
    #expect(onDevicePill != nil)
    let cloudPill = EngineStatusPill(isCloudConfigured: true, onTap: {})
    #expect(cloudPill != nil)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AIAssistantViewsTests`
Expected: Compilation failure because components do not exist yet.

- [ ] **Step 3: Implement `EngineStatusPill` and `CompanionHeroCard`**

Create `EngineStatusPill.swift` with touch target >= 44pt and subtle aesthetic.
Create `CompanionHeroCard.swift` featuring avatar icon with pulsing ambient border, contextual progress-based greeting, target word badges, and dual primary/subtle actions.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AIAssistantViewsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/Components/EngineStatusPill.swift VocabCraftApp/Features/AIAssistant/Views/Components/CompanionHeroCard.swift VocabCraftAppTests/AI/AIAssistantViewsTests.swift
git commit -m "feat(ai): create EngineStatusPill and CompanionHeroCard components"
```

---

### Task 3: Re-designed Scenario Card & AIAssistantHubView Layout Remediation

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/Views/Components/ScenarioListCard.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`

**Interfaces:**
- Consumes: `CompanionHeroCard`, `EngineStatusPill`, `ScenarioListCard`.
- Produces:
  - `ScenarioListCard(scenario: RoleplayScenario, onStartVoice: () -> Void, onStartText: () -> Void)`
  - Safe-padded `AIAssistantHubView` with `Spacer(minLength: theme.spacing.xxl + 88)`.

- [ ] **Step 1: Write failing layout test for `ScenarioListCard`**

In `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`, verify `ScenarioListCard` renders without truncation and includes dual 44pt buttons.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AIAssistantViewsTests`
Expected: FAIL.

- [ ] **Step 3: Implement `ScenarioListCard` and update `AIAssistantHubView`**

1. Create `ScenarioListCard`:
   - Left: 48x48 rounded theme-tinted icon container.
   - Middle: Scenario title, character role, target word badge pills.
   - Right: Dual circular 44x44 icon buttons (`.audio` for Voice Call, `.docText` for Chat).
2. Refactor `AIAssistantHubView`:
   - Remove large Gemini API banner.
   - Integrate `EngineStatusPill` into `CraftPageHeader` trailing slot.
   - Integrate `CompanionHeroCard` in hero slot.
   - Add section header: `AppStrings.AIAssistant.scenarioSectionTitle`.
   - Replace list rows with `ScenarioListCard`.
   - Add bottom inset padding `Spacer(minLength: theme.spacing.xxl + 88)` to prevent tab bar clipping.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AIAssistantViewsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/Components/ScenarioListCard.swift VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift VocabCraftAppTests/AI/AIAssistantViewsTests.swift
git commit -m "feat(ai): refactor AIAssistantHubView with ScenarioListCard and safe bottom padding"
```

---

### Task 4: Voice Call Screen Polish (`RoleplayVoiceCallView`)

**Files:**
- Modify: `VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`

**Interfaces:**
- Consumes: `CraftVoiceOrbView`, `RoleplaySuggestedDrawer`, `CraftUIKit`.
- Produces: Polished `RoleplayVoiceCallView` with balanced proportions, translucent subtitles glass, and correct microphone button icons.

- [ ] **Step 1: Write failing test for voice call control properties**

In `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`, verify mute toggle accessibility and icon mappings.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AIAssistantViewsTests`
Expected: FAIL.

- [ ] **Step 3: Update `RoleplayVoiceCallView`**

1. Add animated Pulsing Live Indicator (`timelineView` / green dot) in top header.
2. Upgrade `subtitlesCard` to `.ultraThinMaterial` / `CraftGlassTokens` with subtle border.
3. Update bottom action buttons:
   - Left: `CraftIconButton(symbol: .quoteBubble, size: .lg)`.
   - Middle: `CraftIconButton(symbol: .phoneDown, size: .xl, variant: .danger)`.
   - Right: `CraftIconButton(symbol: viewModel.isMuted ? .micSlash : .mic, size: .lg)` (fixes `.audio` misrepresentation).
4. Re-balance vertical spacing so `CraftVoiceOrbView` (140pt) sits centrally.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AIAssistantViewsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift VocabCraftAppTests/AI/AIAssistantViewsTests.swift
git commit -m "feat(ai): polish RoleplayVoiceCallView with glass subtitles and correct mic controls"
```

---

### Task 5: Conversational Scaffolding in Text Chat (`RoleplayRoomView`)

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/Views/Components/SentenceStarterChipsBar.swift`
- Create: `VocabCraftApp/Features/AIAssistant/Views/Components/InteractiveTargetWordsStrip.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/RoleplayRoomView.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`

**Interfaces:**
- Consumes: `RoleplayScenario`, `AppStrings`.
- Produces:
  - `SentenceStarterChipsBar(prompts: [String], onSelectPrompt: (String) -> Void)`
  - `InteractiveTargetWordsStrip(targetWords: [String], masteredWords: Set<String>, onWordTap: (String) -> Void)`

- [ ] **Step 1: Write failing test for `SentenceStarterChipsBar`**

In `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`, verify selecting a chip dispatches the prompt string.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AIAssistantViewsTests`
Expected: FAIL.

- [ ] **Step 3: Implement components and integrate into `RoleplayRoomView`**

1. Create `SentenceStarterChipsBar`: Horizontal scrolling chips above the input bar with pre-formulated stems (e.g., *"I'd like to order..."*, *"Could I get..."*). Tapping appends to `viewModel.inputText`.
2. Create `InteractiveTargetWordsStrip`: Target badges support tap to show quick definition tooltip.
3. Polish message bubbles with in-line refinement preview cards and audio pronunciation button.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AIAssistantViewsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/Components/SentenceStarterChipsBar.swift VocabCraftApp/Features/AIAssistant/Views/Components/InteractiveTargetWordsStrip.swift VocabCraftApp/Features/AIAssistant/Views/RoleplayRoomView.swift VocabCraftAppTests/AI/AIAssistantViewsTests.swift
git commit -m "feat(ai): add sentence starter chips and interactive target words to RoleplayRoomView"
```

---

### Task 6: Session Summary Redesign & Learning Ecosystem Loop (`RoleplaySummaryView`)

**Files:**
- Modify: `VocabCraftApp/Features/AIAssistant/Views/RoleplaySummaryView.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`

**Interfaces:**
- Consumes: `RoleplaySessionSummary`, `AppRouter`, `AppStrings`.
- Produces: Enriched `RoleplaySummaryView` with mastered words breakdown, 1-tap vault save, and Reflex Blitz deep link CTA.

- [ ] **Step 1: Write failing test for summary action callbacks**

In `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`, verify the view exposes both Reflex Blitz retry and Done dismiss triggers.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AIAssistantViewsTests`
Expected: FAIL.

- [ ] **Step 3: Update `RoleplaySummaryView`**

1. Add Companion praise header with avatar icon and warm encouragement.
2. Group target words into Mastered (`.checkmarkCircle`) vs Needs Practice (`.exclamationmarkTriangle`).
3. Add 1-Tap Save to Vault button on refinement cards.
4. Replace single button with dual strategic CTAs:
   - Primary: `CraftButton(AppStrings.AIAssistant.summaryActionReflex)` triggering navigation to Reflex Blitz drill.
   - Secondary: `CraftButton(AppStrings.Common.done)` dismissing back to Hub.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AIAssistantViewsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/RoleplaySummaryView.swift VocabCraftAppTests/AI/AIAssistantViewsTests.swift
git commit -m "feat(ai): enhance RoleplaySummaryView with word breakdown and Reflex Blitz action"
```

---

### Task 7: Full Verification Suite & Visual Confirmation via Simulator

**Files:**
- Test: Full unit and localization test suite.
- Simulator: Visual capture on iPhone 17 Pro.

- [ ] **Step 1: Run complete test suite**

Run: `swift test`
Expected: 100% PASS with 0 failures.

- [ ] **Step 2: Run SwiftLint audit**

Run: `swiftlint`
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Launch simulator and capture verification screenshots**

Use `XcodeBuildMCP` to build, run and take screenshots of:
1. `AIAssistantHubView` (verify no tab bar overlap and no text truncation).
2. `RoleplayRoomView` (verify sentence starter chips and interactive badges).
3. `RoleplayVoiceCallView` (verify balanced orb, frosted glass subtitles, correct mic icon).
4. `RoleplaySummaryView` (verify mastered words breakdown and dual CTAs).

- [ ] **Step 4: Final commit and verify git clean**

```bash
git status
```
Expected: Working tree clean, all files tracked and committed.
