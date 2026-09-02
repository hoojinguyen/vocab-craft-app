---
type: feature
title: Widgets and App Intents
description: WidgetKit extension, App Intents for next word and mark learned, and SharedAppGroup persistence sync.
tags: ["widget", "app-intents", "widgetkit", "sharing"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-0db61ea7b3551c5ab3c560a0
    resource: repo://VocabCraftApp/Core/Database/SharedAppGroupContainer.swift
  - id: openwiki-source-f91d7fcda3b5a59b6ec76556
    resource: repo://VocabCraftWidgetExtension/AppIntents/MarkLearnedIntent.swift
  - id: openwiki-source-063efaa93db3b8817be2bd00
    resource: repo://VocabCraftWidgetExtension/AppIntents/NextWordIntent.swift
  - id: openwiki-source-a55dab51a7ac10ac834c6876
    resource: repo://VocabCraftWidgetExtension/VocabWidget.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Extends VocabCraft to Home Screen and Lock Screen via WidgetKit, providing glanceable word and quick actions, sharing store with main app.

## Entrypoints

- **Extension**: `VocabCraftWidgetExtension/VocabWidget.swift` — `Widget` + `TimelineProvider`.
- **View**: `VocabWidgetView.swift` — SwiftUI widget body using `CraftUIKit` tokens (or tint-aware fallback).
- **Intents**: `AppIntents/{NextWordIntent, MarkLearnedIntent}.swift` — `AppIntent` with `PerformIntent`.
- **Store**: `SharedAppGroupContainer.swift` + `SwiftDataModels.WidgetCurrentState`.
- **App wiring**: `VocabCraftApp` includes `VocabCraftWidgetExtension` target in Package; widget timeline reload requested via `WidgetCenter`.

## Mechanisms

1. **Timeline**: Provider reads `WidgetCurrentState` from shared `ModelContainer`; builds entry with lemma/ipa/definition; fallback when store empty (onboarding placeholder). `getTimeline` recomputes hourly + after progress updates.
2. **Intents**: `NextWordIntent` fetches next review word via `FetchPersonalVaultUseCase` or dataset fallback, writes new `WidgetCurrentState`, requests timeline reload, returns result. `MarkLearnedIntent` toggles mastery / bookmark via `ToggleWordBookmarkUseCase` / actor and records streak.
3. **Rendering**: `VocabWidgetView` uses `CraftCard`-like styling, supports families `.systemSmall/.Medium`, Lock Screen `.accessoryRectangular` with tinted rendering, and StandBy.
4. **Sync**: `SharedAppGroupContainer.createContainer()` configures `ModelConfiguration(groupContainer: .identifier(...))`; both app and widget link against same store, so intents see same `UserWordProgress`.

## Relationships

- **Upstream**: Main app writes progress → widget reads.
- **Downstream**: Widget intent writes back progress → app sees on next launch/foreground.

## State, Ordering, Lifecycle

- Widget timeline is passive; reload triggered after SRS evaluation or manual nextWord.
- Intent execution is short-lived, must complete <30s, handles background context via ModelActor.

## Invariants

- Widget never writes directly to dataset; only to progress/store.
- Tinted widget mode disables custom colors, using system template.

## Failure

- Missing app-group entitlement falls back to in-memory container (no persistence, widget shows placeholder).
- Data race avoided via actor; intent timeout returns graceful error.

## Configuration

- Widget families declared in `VocabWidget.swift`; app-group ID in entitlements + `SharedAppGroupContainer.swift`.

## Extension

Add intent by adding `AppIntent` in widget target and registering in `AppShortcutsProvider`.

## Tests

- `WidgetIntentsTests.swift` verifies NextWord/MarkLearned logic with mock actor.
- Snapshot-like audition via `CraftUIKitTests` tinted mode checks.
