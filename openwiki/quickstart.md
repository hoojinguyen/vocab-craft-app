---
type: "guide"
title: "Quickstart"
description: "How to run, test, and navigate VocabCraft: setup, daily dev tasks, and where to find system docs for common developer tasks."
tags: ["quickstart", "getting-started", "guide"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-01545979d25a6b33e8e2f3c3
    resource: repo://.swiftlint.yml
  - id: openwiki-source-8037e2358a2c4f9b2c722a11
    resource: repo://AGENTS.md
  - id: openwiki-source-16a6a536c0a5303df5e05c6c
    resource: repo://Package.swift
  - id: openwiki-source-a2faa9b9fbea7c8bca2152b3
    resource: repo://VocabCraftApp/App/Navigation/AppRouter.swift
  - id: openwiki-source-71661d79da6d20d09e06bcfd
    resource: repo://VocabCraftApp/App/VocabCraftApp.swift
generated: { by: "opencode", at: "2026-09-02T08:37:35.164Z" }
---

## What is VocabCraft?

VocabCraft is a SwiftUI + SwiftData iOS vocabulary trainer (iOS 17+, Swift 5.10). It features a CraftUIKit design system, SpeechKit for speaking/listening drills, an SRS engine for spaced repetition, and WidgetKit intents. Targets are declared in `Package.swift` and built via `VocabCraft.xcworkspace`.

## Prerequisites

- Xcode 16+ (see `docs/build-optimization.md` for benchmarked 26.6)
- iOS 17 simulator or device, macOS 14+ for tests
- SwiftLint (via plugin or `brew install swiftlint`)

## Run the App

```bash
# Open workspace (generate if missing)
python3 scripts/generate_workspace.py
open VocabCraft.xcworkspace

# Or build via SPM for logic tests (no device needed)
swift build
```

`VocabCraftApp.swift` bootstraps `SharedAppGroupContainer` → `DatasetEngine` → `AppContainer`; deep links and launch args control initial tab (`-tab-reflex`, `-reflex-mode speaking`, etc.).

## Run Tests and Quality Gate

```bash
swift test --filter LocalizationTests   # bilingual parity
swift test                             # full suite (50+ tests)
swiftlint lint                         # zero warnings required
# In Xcode: Build must show 0 errors, 0 warnings
```

Per `AGENTS.md`, no task is complete without passing all three and a clean Xcode build.

## Common Tasks → Where to Read

| Task | Start here |
|------|------------|
| Understand overall layering | `architecture/overview.md` → `architecture/dependency-injection.md` |
| Add or reuse UI | `architecture/design-system.md` (must check CraftUIKit first) |
| Change vocabulary data | `core/dataset-and-sync.md` + `core/domain-entities.md` |
| Tune SRS intervals | `core/srs-engine.md` |
| Add persistence model | `core/persistence.md` (add `@Model` + migration) |
| Work on speaking/voice | `core/audio-and-speech.md` |
| Build Homepage / streak | `features/homepage-and-learning-path.md` |
| Add drill mode | `features/reflex-drill-system.md` |
| Work on Vault / bookmarks | `features/vocabulary-and-personal-vault.md` |
| Change Settings / theme | `features/settings-and-profile.md` + `operations/localization-and-theming.md` |
| Add widget or intent | `features/widgets-and-intents.md` |
| Fix build or lint | `operations/build-test-and-quality.md` |
| Add strings or theme | `operations/localization-and-theming.md` |

## Navigation and Deep Links

- Tabs: Home, Vocabulary, Reflex, AI Assistant, Settings (see `AppRouter.TabItem`).
- Deep link: `vocabcraft://reflex?mode=speaking&phase=drilling` → autofocuses Reflex; also `vocabcraft://vocabulary`, `vocabcraft://settings`.
- Launch args mirror deep links: `-tab-reflex -reflex-mode speaking -reflex-phase drilling` (used in UI tests).

## CraftUIKit-First and Localization Rules

- **No duplicate components**: Search `Packages/CraftUIKit/Sources/CraftUIKit/Components` before creating Views.
- **No raw styling**: Use `CraftColor`/`CraftTypographyTokens` etc., not `Color.red`.
- **No hardcoded strings**: Use `String(localized: "app...")` or `CraftLocalized.string("craft...")`; every key needs EN+VI with matching format specifiers and `extractionState manual`.

## Where the Code Lives

- `VocabCraftApp/App` — DI + Navigation + entry
- `VocabCraftApp/Core` — SRS, Database, Audio, DesignSystem, Localization
- `VocabCraftApp/Domain` — Entities, UseCases, Policies
- `VocabCraftApp/Features` — Homepage, Reflex, Vocabulary, Settings, AIAssistant
- `Packages/CraftUIKit` — design system
- `Packages/SpeechKit` — speech engine
- `VocabCraftWidgetExtension` — widget + intents

Next: read `architecture/overview.md` for the full system map, then jump to the feature or core page matching your task.
