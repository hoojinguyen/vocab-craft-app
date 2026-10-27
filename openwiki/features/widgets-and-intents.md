---
type: feature
title: Widgets and Intents
description: The VocabCraft home-screen and lock-screen widget. The app composes a JSON widget deck of due, recent, and upcoming words, the widget renders it from a timeline, and the reveal and grade intents let the learner review a card without opening the app.
tags: ["widget", "widgetkit", "app-intents", "timeline", "app-group", "review"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-0db61ea7b3551c5ab3c560a0
    resource: repo://VocabCraftApp/Core/Database/SharedAppGroupContainer.swift
  - id: openwiki-source-7c97a3a66f7469471a1d8fc0
    resource: repo://VocabCraftWidgetExtension/AppIntents/GradeCardIntent.swift
  - id: openwiki-source-23b982e56d08cb6ff7f58827
    resource: repo://VocabCraftWidgetExtension/Review/WidgetReviewRecorder.swift
  - id: openwiki-source-a55dab51a7ac10ac834c6876
    resource: repo://VocabCraftWidgetExtension/VocabWidget.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

The widget shows one vocabulary card on the Home Screen, in StandBy, or on the Lock Screen. The learner can reveal the answer and grade the card from the widget. The app keeps the card deck up to date, and the widget reads that deck. Review results from the widget update the same SRS progress that the app uses.

## Entrypoints

- **Bundle and configuration**: `VocabCraftWidgetExtension/VocabWidgetBundle.swift` declares the bundle. `VocabCraftWidgetExtension/VocabWidget.swift` declares `VocabWidget` and its supported families. On iOS these are `systemSmall`, `systemMedium`, `accessoryRectangular`, and `accessoryInline`. Other platforms support `systemSmall` and `systemMedium`.
- **Provider**: `VocabWidgetProvider` (`VocabWidget.swift`) is a `TimelineProvider`. `makeTimeline(now:)` builds the entries, and `WidgetTimelineBuilder` (`Timeline/`) defines `VocabWidgetEntry`.
- **Views**: `VocabWidgetView`, `WidgetSystemViews`, `WidgetAccessoryViews`, `WidgetCardComponents`, and `WidgetPresentation` (`VocabCraftWidgetExtension/Views`).
- **Intents**: `RevealCardIntent` and `GradeCardIntent` (`VocabCraftWidgetExtension/AppIntents`).
- **Review helpers**: `WidgetDueQuery` (`Review/`) computes which words are due. `WidgetReviewRecorder` grades a revealed card.
- **Deck store**: `WidgetDeckStore` and `WidgetDeck` (`VocabCraftApp/Core/Widget`). The deck is a JSON file in the app group. `WidgetInteractionState` stores which card is revealed.
- **App-side refresh**: `RefreshWidgetDeckUseCase`, `WidgetDeckComposer`, `WidgetRefreshingCompleteLessonUseCase`, and `WidgetCenterReloader` (`VocabCraftApp/Domain/Widget`).

## Mechanisms

1. **Compose (app)** — `RefreshWidgetDeckUseCase.execute()` runs when the app goes to the background, and after a lesson completes through `WidgetRefreshingCompleteLessonUseCase`. The refresh serializes its runs and loads the active learning path, the learner's progress, and three word groups: due words, recent words, and upcoming words. `WidgetDeckComposer.compose(...)` turns them into a `WidgetDeck` of `WidgetCard` values with a `Source` for each card. It then saves the deck and asks WidgetKit to reload the `VocabWidget` timelines.
2. **Timeline (widget)** — `makeTimeline(now:)` loads the deck and the interaction state. `WidgetDueQuery.dueStatus(for:in:now:)` reads the SwiftData progress for the deck's words to find due words and the next due date. The entries show the card, and the reload policy follows the next due date.
3. **Reveal** — `RevealCardIntent.perform(store:now:)` stores the revealed word ID and the time in `WidgetInteractionState`.
4. **Grade** — `GradeCardIntent.perform(store:context:now:)` calls `WidgetReviewRecorder.grade(...)`. The recorder checks that the word is the revealed one and is still due. It takes the response time from the reveal time, clamped to 1 to 10 seconds, runs `SRSEngine.calculateNextInterval`, and updates the `UserWordProgress` record. After a successful grade the interaction state is cleared.
5. **Shared store** — `WidgetContainerHolder.sharedContainer` creates the SwiftData container with `SharedAppGroupContainer.createContainer()`. In tests it uses an in-memory container. The widget and the app use the same app-group store, so a grade in the widget is visible to the app. See [Persistence](../core/persistence.md).

## Relationships

- **Upstream**: The learning path and progress come from the app's use cases and repositories. See [Homepage and Learning Path](homepage-and-learning-path.md).
- **SRS**: The grade intent uses the same scheduling as the app. See [SRS Engine](../core/srs-engine.md).
- **Shared types**: The widget target links `VocabCraftApp` through `VocabCraftWidgetExtension`, and it also uses CraftUIKit for styling.

## State and Lifecycle

- The widget has no state of its own. The deck and the interaction state are the only state, and they live in files in the app group.
- A reveal stays in the interaction state until a grade clears it.
- The app asks WidgetKit to reload the timelines after each deck refresh.

## Invariants

- A grade is only applied to the word that was revealed, and only when that word is due. Otherwise nothing is written.
- Response times are clamped to between 1 and 10 seconds.
- `WidgetDeck` carries a version number (`currentVersion` is 2, and `minimumSupportedVersion` is 1).

## Failure

- If the shared container cannot be created, the grade intent throws `WidgetIntentError.storeUnavailable` and the grade is dropped.
- A missing deck shows a placeholder entry (`VocabWidgetEntry.placeholder`).
- A refresh failure is logged and leaves the previous deck in place.

## Configuration

- The app group is `group.com.hoojinguyen.vocabcraft`.
- The widget kind is `WidgetKind.vocab`, which is `VocabWidget`.
- Localized strings use `app.widget.*` keys.

## Extension

- Add a family by adding it to `supportedFamilies` and a view under `Views/`.
- Add a card source by adding a `WidgetCard.Source` case and a branch in `WidgetDeckComposer`.
- Add an intent by declaring an `AppIntent` in `AppIntents/` and wiring its perform method to `WidgetReviewRecorder` or `WidgetDeckStore`.

## Tests

- `VocabCraftAppTests/Features/Widget/` covers the deck store, timeline builder, review recorder, presentation, localization, and background contrast.
- `VocabCraftAppTests/WidgetIntentsTests.swift` covers the intents.
