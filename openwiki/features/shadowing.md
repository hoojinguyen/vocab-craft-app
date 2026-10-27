---
type: feature
title: Shadowing
description: The Shadowing feature for repeating sentences from curated videos in three rounds (immersion, speed shadowing, echo drill) plus a summary report, backed by the ShadowingCatalog.sqlite catalog, a UserDefaults progress store, and a YouTube player bridge.
tags: ["shadowing", "pronunciation", "video", "sqlite", "speech", "progress"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-50708200bbae0e3f79368a9f
    resource: repo://VocabCraftApp/App/DI/AppContainer.swift
  - id: openwiki-source-efbf3eb0cd7a424f9cb1dd35
    resource: repo://VocabCraftApp/Data/DataSources/ShadowingSQLiteDatabase.swift
  - id: openwiki-source-7a16346a6eca23234d8f3053
    resource: repo://VocabCraftApp/Data/Repositories/ShadowingProgressRepositoryImpl.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

Shadowing helps the learner practice pronunciation by repeating sentences from short, curated videos. Each video is split into sentences with word timestamps. The learner moves through three rounds for a video, records their own voice, gets a score per sentence, and sees a summary. Progress is kept per video, with best score, completion count, and per-sentence scores.

## Entrypoints

- **Hub**: `ShadowingHubView` and `ShadowingHubViewModel` (`VocabCraftApp/Features/Shadowing`). The hub loads topics and videos from the catalog, filters by level (`LevelFilterChipsView`), and shows the daily challenge (`DailyChallengeHeroCard`). The view model is created by `AppContainer.makeShadowingHubViewModel(...)`.
- **Studio**: `ShadowingStudioContainerView` and `ShadowingStudioViewModel` run the rounds for one video. `ShadowingStudioViewModel` defines `ShadowingRoundStage` with `round1Immersion`, `round2SpeedShadowing`, `round3EchoDrill`, and `summaryReport`. Created by `makeShadowingStudioViewModel(for:)`.
- **Practice**: `ShadowingPracticeView` and `ShadowingPracticeViewModel`, created by `makeShadowingPracticeViewModel(for:)`.
- **Rounds**: `ShadowingImmersionView`, `ShadowingSpeedView`, and `ShadowingEchoView` (in `Views/Rounds`).
- **Summary**: `ShadowingSummaryReportView` (in `Views/Summary`).
- **Services**: `ShadowingSessionCoordinator` manages the audio session and playback phases. `ShadowingAudioRecorder` records and plays the learner's sentence.
- **Player**: `CraftYouTubePlayerView` and `YouTubePlayerBridgeScript` embed the video and talk to it through a JavaScript bridge. `CraftShadowingTeleprompterView` and `CraftShadowingWordHighlightToken` highlight the current word.
- **Deep link**: `vocabcraft://shadowing?videoId=...` is parsed by `AppRouter` into `pendingShadowingVideoId`. See [Dependency Injection](../architecture/dependency-injection.md) for the routing rules.

## Domain Model

- **Video**: `ShadowingVideo` and `ShadowingTopicItem` in `Domain/Models/Shadowing/ShadowingVideoModels.swift`. A video has a YouTube ID, title, topic, level, duration, thumbnail, accent, and display order. It also has sentences, and each sentence has key words (`ShadowingKeyWord`).
- **Timestamps**: `ShadowingWordTimestamp` gives the start and end time of each word, used for the teleprompter highlight.
- **Progress**: `ShadowingProgressRecord` (`Domain/Models/Shadowing/ShadowingProgressRecord.swift`) holds `videoId`, `bestScore`, `lastCompletedAt`, `timesCompleted`, and `sentenceScores`.

## Data Sources

- **Catalog database**: `ShadowingSQLiteDatabase` (`VocabCraftApp/Data/DataSources/ShadowingSQLiteDatabase.swift`) opens `ShadowingCatalog.sqlite` from the bundle, or from a given file URL. It reads the `topics`, `videos`, `sentences`, and `sentence_keywords` tables. Sentence word timings are stored as JSON in `words_json` and parsed by `parseWords(from:)`. A missing file throws `databaseNotFound`.
- **Catalog repository**: `ShadowingCatalogRepository` wraps the database. `FallbackShadowingCatalogRepository` is used when the database cannot be opened. `AppContainer` tries the bundle first, then falls back.
- **Curated videos**: `ShadowingVideoRepositoryImpl` holds a built-in list of curated videos (or a list passed in for tests). `fetchCuratedVideos()` and `fetchVideo(byId:)` read from that list.
- **Progress**: `ShadowingProgressRepositoryImpl` is an `actor` that keeps all records as one JSON blob under the `shadowing_progress_records` key in `UserDefaults`. `recordCompletion(videoId:score:sentenceScores:)` keeps the best score, adds a completion, and merges the per-sentence scores.

## Mechanisms

1. **Browse** — `loadCatalog()` fetches topics and videos. `selectLevelFilter(_:)` filters by level.
2. **Round 1, immersion** — The learner listens to the sentence in the video player. The teleprompter uses the word timestamps to highlight words.
3. **Round 2, speed shadowing** — The learner repeats each sentence. `ShadowingAudioRecorder.startRecording(sentenceId:)` records, and `playRecordedAudio(from:)` plays the recording back.
4. **Round 3, echo drill** — The learner repeats each sentence in the echo drill round.
5. **Playback phases** — `ShadowingSessionCoordinator` moves through playback phases, including `listening` and `evaluated`.
6. **Summary** — `ShadowingSummaryReportView` shows the results for the video. Completed results are stored through the progress repository's `recordCompletion`.
7. **Audio handoff** — `prepareForNativePlayback()` and `prepareForSpeechCapture()` switch the audio session between playback and recording. `releaseAll()` releases both.

## Relationships

- **Upstream**: `AppContainer` builds the catalog repository, the curated video repository, and the progress repository (`shadowingProgressRepository` in `AppContainer`). The catalog file comes from the bundle, described in [Dataset and Sync](../core/dataset-and-sync.md).
- **Downstream**: Scores and sentence results are stored through the progress repository. The store is `UserDefaults` based, not SwiftData. See [Persistence](../core/persistence.md).
- **Audio**: The recorder and session coordinator are separate from the reflex and roleplay speech services described in [Audio and Speech](../core/audio-and-speech.md).

## State and Lifecycle

- The hub is loaded when the tab opens. The studio owns the round state for one video, and leaving it releases the audio session.
- Each round advances when its sentences are done. The summary is reached after round 3.
- The progress actor loads its records from `UserDefaults` on demand and writes the whole blob when a completion is recorded.

## Invariants

- `bestScore` never decreases. A new attempt can only raise it.
- Per-sentence scores are merged, so a later attempt updates the sentences it covers and keeps the rest.
- The session coordinator switches the audio session between playback and capture before each mode starts.

## Failure

- A missing or unreadable catalog database falls back to `FallbackShadowingCatalogRepository`, so the hub still opens.
- Progress write errors are thrown from `recordCompletion`.
- The deep link `vocabcraft://shadowing?videoId=...` sets `pendingShadowingVideoId` in `AppRouter` and leaves the selected tab unchanged. No view in the current source reads that value, so the link has no visible effect yet.

## Configuration

- The catalog file is `ShadowingCatalog.sqlite` in the bundle.
- The progress key is `shadowing_progress_records` in `UserDefaults`.
- Test launch arguments `-test-shadowing` and `-test-shadowing-hub` select the AI tab, where the shadowing hub is reachable for testing.

## Extension

- Add a video by adding a row to `videos`, its sentences to `sentences`, and its keywords to `sentence_keywords` in the catalog database.
- Add a round by adding a `ShadowingRoundStage` case and a view under `Views/Rounds`.

## Tests

- `VocabCraftAppTests/Data/ShadowingCatalogRepositoryTests.swift` and `ShadowingProgressRepositoryTests.swift` cover the catalog and progress stores.
- `VocabCraftAppTests/Domain/ShadowingVideoModelsTests.swift` covers the video models.
- `VocabCraftAppTests/Features/Shadowing/` covers the hub, practice, studio, and session coordinator, plus `CraftShadowingTeleprompterTests.swift`.
