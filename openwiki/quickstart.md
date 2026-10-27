---
type: "Reference"
title: "Generate the workspace if it is missing, then open it"
openwiki_generated: true
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-8037e2358a2c4f9b2c722a11
    resource: repo://AGENTS.md
  - id: openwiki-source-16a6a536c0a5303df5e05c6c
    resource: repo://Package.swift
  - id: openwiki-source-5d81637882ca78de29b1c749
    resource: repo://VocabCraftApp/App/Bootstrap/AppBootstrapper.swift
  - id: openwiki-source-a2faa9b9fbea7c8bca2152b3
    resource: repo://VocabCraftApp/App/Navigation/AppRouter.swift
  - id: openwiki-source-71661d79da6d20d09e06bcfd
    resource: repo://VocabCraftApp/App/VocabCraftApp.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---


## What is VocabCraft?

VocabCraft is a SwiftUI and SwiftData vocabulary trainer for iOS 17 and later, written in Swift 5.10. It has five tabs (Home, Vocabulary, Reflex, AI Assistant, and Settings) and includes:

- a CraftUIKit design system (`Packages/CraftUIKit`);
- SpeechKit for speaking and listening (`Packages/SpeechKit`);
- an SRS engine for spaced repetition;
- Shadowing practice and Guided Practice with roleplay;
- a home-screen widget with App Intents.

Targets are declared in `Package.swift` and built through `VocabCraft.xcworkspace`.

## Prerequisites

- Xcode 16 or later. `docs/build-optimization.md` records the benchmarked Xcode version.
- An iOS 17 simulator or device. macOS 14 or later for running tests.
- SwiftLint, from a plugin or `brew install swiftlint`.

## Run the App

```bash
# Generate the workspace if it is missing, then open it
python3 scripts/generate_workspace.py
open VocabCraft.xcworkspace
```

```bash
# Build the Swift packages without a device
swift build
```

Startup goes through `AppBootstrapper` (`VocabCraftApp/App/Bootstrap/AppBootstrapper.swift`). It creates the SwiftData container, validates the bundled catalog, creates the router, and then builds `AppContainer`. See [Dependency Injection](architecture/dependency-injection.md).

To run on a connected iPhone, use `make run-device`, which runs `scripts/run_device.sh`.

## Run Tests and the Quality Gate

```bash
swift test --filter LocalizationTests   # English and Vietnamese parity
swift test                              # full suite
swiftlint                               # zero errors and zero warnings
```

Also build in Xcode and confirm 0 errors and 0 warnings. `AGENTS.md` section 5 requires all of these before a task is complete. See [Build, Test and Quality](operations/build-test-and-quality.md).

## Common Tasks → Where to Read

| Task | Start here |
|------|------------|
| Understand overall layering | `architecture/overview.md`, then `architecture/dependency-injection.md` |
| Add or reuse UI | `architecture/design-system.md` (check CraftUIKit first) |
| Change vocabulary data | `core/dataset-and-sync.md` and `core/domain-entities.md` |
| Tune SRS intervals | `core/srs-engine.md` |
| Add a persistence model | `core/persistence.md` (new schema version and migration) |
| Work on speaking or voice | `core/audio-and-speech.md` |
| Build Homepage or the learning path | `features/homepage-and-learning-path.md` |
| Add a drill mode | `features/reflex-drill-system.md` |
| Work on the vault or bookmarks | `features/vocabulary-and-personal-vault.md` |
| Work on Guided Practice or roleplay | `features/guided-practice.md` |
| Work on Shadowing | `features/shadowing.md` |
| Change Settings | `features/settings-and-profile.md` |
| Add a widget or intent | `features/widgets-and-intents.md` |
| Fix build or lint | `operations/build-test-and-quality.md` |
| Add strings or a theme | `operations/localization-and-theming.md` |

## Navigation and Deep Links

- Tabs are `home`, `vocabulary`, `reflex`, `aiAssistant`, and `settings` in `AppRouter`.
- Deep links use the `vocabcraft://` scheme:
  - `vocabcraft://reflex?mode=speaking&phase=drilling` opens the Reflex tab with a drill configuration. The `state`, `hint`, and `combo` parameters are also read.
  - `vocabcraft://vocabulary` and `vocabcraft://settings` select those tabs.
  - `vocabcraft://review` opens smart review in the Vocabulary tab.
  - `vocabcraft://ai` or `vocabcraft://aiAssistant` opens the AI Assistant tab.
  - `vocabcraft://shadowing?videoId=...` stores the video ID for Shadowing.
  - Any other host opens Home.
- Launch arguments are used by UI tests:
  - `-tab-reflex`, `-reflex-mode <mode>`, and `-reflex-phase <phase>` configure the Reflex tab. They are read in `AppBootstrapper`.
  - `-tab-settings` opens Settings.
  - `-tab-ai` and the `-test-ai-*` arguments open the AI Assistant tab.
  - `-enable-guided-practice` turns on Guided Practice.
  - `-reset-progress` clears learner progress at startup.

## CraftUIKit-First and Localization Rules

- **No duplicate components**: Search `Packages/CraftUIKit/Sources/CraftUIKit/Components` before creating a view.
- **No raw styling**: Use CraftUIKit tokens such as `CraftColorTokens` rather than values like `Color.red`.
- **No hardcoded strings**: Use `AppStrings` for app text and `CraftLocalized` for CraftUIKit text. Each key needs English and Vietnamese values, with matching format specifiers.

## Where the Code Lives

- `VocabCraftApp/App`: bootstrap, DI, navigation, and the root view.
- `VocabCraftApp/Core`: SRS engine, database, audio, design-system bridge, and localization.
- `VocabCraftApp/Domain`: entities, models, policies, protocols, and use cases.
- `VocabCraftApp/Data`: repositories, actors, AI providers, and audio engine adapters.
- `VocabCraftApp/Features`: Homepage, Reflex, Vocabulary, Shadowing, Settings, Lesson, Onboarding, and AIAssistant.
- `Packages/CraftUIKit`: design system.
- `Packages/SpeechKit`: speech assessment and silence detection.
- `VocabCraftWidgetExtension`: widget, App Intents, and review helpers.
- `scripts/`: workspace generation, device runs, database deployment, and the Shadowing catalog generator.

Next, read `architecture/overview.md` for the full system map, then open the feature or core page that matches your task.
