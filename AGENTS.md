# VocabCraft Project Guidelines & Agent Rules

This document outlines mandatory rules and standards for AI agents and developers working on the `VocabCraft` codebase. All instructions are strictly enforced.

---

## 1. Superpowers & Workflow Process Compliance

> [!IMPORTANT]
> **Strict 100% Workflow Execution**: When executing any Superpowers skill (e.g. `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `test-driven-development`, `requesting-code-review`, `verification-before-completion`), the agent **MUST follow 100% of the prescribed process** without skipping steps or rushing through stages.
>
> 1. **Specification & Brainstorming**: Understand user requirements, explore constraints, and establish clear design boundaries before writing code.
> 2. **Implementation Planning**: Produce structured implementation plans with explicit review checkpoints.
> 3. **Step-by-Step Execution**: Execute incrementally, applying TDD where applicable, and maintain clean separation of concerns.
> 4. **Rigorous Verification**: Run full verification suites before declaring any task complete.

---

## 2. Skill-Driven Context & Architecture Discovery

Before designing architectures, brainstorming, or writing code, **search and consult relevant skills in `.agents/skills/`** to ground your implementation in project-approved standards:

- **SwiftUI & View Architecture**: `.agents/skills/swiftui-patterns`, `swiftui-layout-components`, `swiftui-animation`, `swiftui-gestures`, `swiftui-performance`, `swiftui-liquid-glass`, `swiftui-navigation`
- **Core Architecture & Data**: `.agents/skills/swift-architecture`, `swift-architecture-skill`, `swiftdata`, `swiftdata-pro`, `swift-codable`
- **Concurrency & Modern Swift**: `.agents/skills/swift-concurrency`, `swift-language`, `swift-api-design-guidelines`
- **iOS Human Interface & Aesthetics**: `.agents/skills/ios-design-guidelines`, `ios-design-agent-skill`, `swiftui-design-skill`
- **Testing & Diagnostics**: `.agents/skills/swift-testing`, `swiftlint`, `debugging-instruments`, `xcode-build-orchestrator`, `xcode-build-fixer`

---

## 3. UI Implementation: CraftUIKit-First & Theme Discipline

### 3.1 CraftUIKit-First Component Hierarchy
- **Always check `CraftUIKit` first**: Prioritize reusing existing UI components, atoms, molecules, and containers from `Packages/CraftUIKit/Sources/CraftUIKit/Components/` (`CraftBadge`, `CraftIcon`, `CraftIconButton`, `CraftCard`, `CraftFlipCard`, `CraftProgressBar`, `CraftProgressRing`, `CraftStreakCard`, `CraftLearningPath`, etc.).
- **Do NOT duplicate components**: Never create custom ad-hoc SwiftUI views in the main app when a matching component already exists in `CraftUIKit`.
- **Mandatory Human Consultation**: If a design requires a component not yet present in `CraftUIKit` or cannot be met by existing components, **stop and discuss with the user** to determine whether to expand `CraftUIKit` or build a controlled app-level view.

### 3.2 Strict Theme, Token & Design System Conformance
- **Zero Raw Styling**: Never hardcode colors (`Color.red`, `Color(hex: ...)`, `Color(red:green:blue:)`), raw typography fonts, hardcoded padding values, or ad-hoc corner radii directly in views.
- **Mandatory Design Tokens**: All styling must strictly utilize `CraftUIKit` tokens:
  - **Colors**: `CraftColor` / `CraftColorTokens` (semantic palettes, surface colors, text tints, accents)
  - **Typography**: `CraftFont` / `CraftTypographyTokens` (display, title, body, caption styles)
  - **Spacing & Radius**: `CraftSpacingTokens`, `CraftRadiusTokens`
  - **Effects & Depth**: `CraftShadowTokens`, `CraftGlassTokens`, `CraftDepthTokens`, `CraftGradientTokens`
- **No Unauthorized Styles**: Never invent new colors, custom fonts, or rogue design patterns without explicit human approval.

---

## 4. Zero Hardcoded Strings Policy & Localization Architecture

### 4.1 Zero Hardcoded Strings Policy
- **Strict No-Hardcode Rule**: Never write raw literal English or Vietnamese string literals directly into SwiftUI view bodies, view models, controllers, component initializers, fallback logic, or Accessibility modifiers (`.accessibilityLabel`, `.accessibilityHint`, `.accessibilityValue`).
- All display text and accessibility content must be declared inside `Localizable.xcstrings` according to the designated layer and taxonomy format.

### 4.2 Two-Layer Localization Architecture

| Criteria | Layer 1: `CraftUIKit` (Design System Package) | Layer 2: `VocabCraftApp` (Main Application) |
| :--- | :--- | :--- |
| **Root Prefix** | `craft.*` | `app.*` |
| **Catalog Resource** | `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings` | `VocabCraftApp/Resources/Localizable.xcstrings` |
| **Bundle & Engine** | `Bundle.module` via `CraftLocalized.string/format` | `Bundle.main` / `LocalizedStringKey` / `String(localized:)` |
| **Content Scope** | UI controls, widget states, token labels, default component VoiceOver | Screen titles, business flows, vocabulary decks, SRS Reflex Drills, Onboarding, Profile, Settings, Notifications |

### 4.3 Key Taxonomy Standards
- **Layer 1 (`craft.*`)**: `craft.<scope>.<element/context>.<role/state/a11y>`
  - Common: `craft.common.action.*`, `craft.common.state.*`, `craft.common.unit.*`
  - Components: `craft.button.*`, `craft.flipcard.*`, `craft.progress.*`, `craft.streak.*`, `craft.learning_path.*`, etc.
- **Layer 2 (`app.*`)**: `app.<feature>.<screen/flow>.<element>.<role/state/a11y>`
  - `app.common.*`, `app.onboarding.*`, `app.study.*`, `app.reflex.*`, `app.deck.*`, `app.profile.*`, `app.settings.*`, `app.notification.*`

### 4.4 Mandatory 100% Bilingual Parity (EN & VI)
1. **Full Pair Completeness**: Both `en` and `vi` translations must be completely provided with accurate phrasing. No language branch may be left empty.
2. **Zero Cross-Language Mixup**: Never store Vietnamese text in `en` entries, and never leave English placeholders in `vi` entries.
3. **Format Specifier Parity**: Format tokens (`%lld`, `%@`, `%%`) must match exactly in type, sequence, and count between English and Vietnamese.
4. **Extraction State**: Always set `extractionState: "manual"` and `state: "translated"`.

### 4.5 Text Rendering Conventions
- **Inside `CraftUIKit`**: Use `CraftLocalized.string("craft...")` or `CraftLocalized.format("craft...", args)`.
- **Inside `VocabCraftApp`**: Use `LocalizedStringKey` or `String(localized: "app...")`.

---

## 5. Strict Quality Gate: Zero Issues, Zero Warnings & Full Verification

> [!CAUTION]
> A task is **NEVER complete** if there are compiler warnings, lint warnings, or broken tests.

Before declaring any task or implementation finished:
1. **Localization Verification**: Run `swift test --filter LocalizationTests` (for `CraftUIKit`).
2. **Unit & Integration Tests**: Run `swift test` and the full app test suite to ensure 100% pass rate.
3. **SwiftLint Compliance**: Run `swiftlint` and resolve all lint errors and warnings.
4. **Zero Compiler Warnings on Xcode**: Compile the project and ensure **0 errors and 0 warnings**. If Xcode produces any warnings (such as Swift Concurrency diagnostics, deprecations, layout ambiguities, or type inference warnings), they must be diagnosed and resolved immediately.

---

## 6. Xcode Auto-Generated Files & Git Commit Discipline

- **Transparency on Xcode Generated Files**: Xcode frequently modifies or generates metadata, workspace configuration, user states, or `.pbxproj` entries automatically without explicit user edits (e.g. `UserInterfaceState.xcuserstate`, scheme settings, package resolution caches, derived assets).
- **Mandatory Explanation & Advice**:
  - **Never silently commit** auto-generated or unexpected file diffs to Git.
  - Inspect any untracked or modified files via `git status` / `git diff`.
  - Clearly explain to the user **why** Xcode generated/modified the files, whether they are safe to commit, should be ignored via `.gitignore`, or should be discarded.
  - Wait for user confirmation or provide a clear rationale before staging unexpected files.

