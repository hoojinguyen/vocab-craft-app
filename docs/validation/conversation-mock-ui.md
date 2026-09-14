# Conversation mock UI validation — 2026-09-13

Branch: `codex/conversation-ui` (isolated worktree `.worktrees/conversation-ui`).

## Try it

Open `VocabCraft.xcworkspace` in this worktree and use the VocabCraftApp scheme in Debug. On Home, tap **Start practice** in **Sample conversation lesson** directly below the header. Close returns to Home. No launch argument is required. The existing `-test-conversation-ui` argument remains available for direct UI debugging.

Choose either role and start. Expand **DEBUG simulated result** to select pass, retry, or no speech; the outcome resolves after a short delay. Tap a turn to reveal Vietnamese. Pause and reopen to test Continue. Switch roles after completion or generate another sample outside active playback/listening. The generation-failure switch preserves the current dialogue/progress.

This milestone uses two fixed bilingual dialogues drawn from sample vocabulary. It simulates playback, recognition, and generation; no microphone, speech grading, or API request occurs. The fixture is compiled only in Debug. API integration and learning-path placement remain future work.

## Evidence

- `swift test`: 432 XCTest +309 Swift Testing passed (`/tmp/conversation-final2-app.log`).
- `swift test --package-path Packages/CraftUIKit`: 653 XCTest +84 Swift Testing passed, including localization (`/tmp/conversation-final2-craft.log`).
- `swiftlint --quiet --no-cache`: no issues (`/tmp/conversation-final3-lint.log`).
- XcodeBuildMCP Debug build/run succeeded. Full simulator test suite succeeded, 787 tests discovered.
- Release build succeeded; bundle inspection found neither the removed JSON fixture resource nor the sample sentence bytes.
- Simulator inspection verified restored Continue, automatic transitions through completion, translation visibility and static accessibility semantics for mock listening. Retry waiting was inspected during the earlier run. Unit coverage checks pause cancellation, retry/no speech, role B, completion, regeneration and restoration.
- Independent review approved after fixing Release fixture packaging, existing Craft controls reuse, and translation/simulation accessibility.

The full Xcode test run still reports 14 pre-existing SwiftData Sendable warnings; earlier full compilation also reported existing concurrency diagnostics elsewhere. This is a reviewable mock, not a claim that the repository meets its zero-warning release gate.

## Scope decisions

The user requested sample-driven UI while the API is pending, so production speech/API tasks were deferred. Debug-only local persistence validates resume without a production schema migration. The coordinator completed implementation after the implementer reached its usage limit, followed by independent review.

The project file changes intentionally add source/test membership and DEBUG compilation conditions. No unrelated Xcode user-state metadata is included.

## Home entry and physical device — 2026-09-14

Added a Debug-only lesson card on Home using CraftCard and CraftButton, with EN/VI copy. Its Start button presents the existing conversation screen; the learning-path animation suspends while the conversation is open. No production learning progress is awarded by this mock.

Verified Start opens the conversation on Simulator. Full simulator suite: 787 passed, zero failures/skips. Full SwiftPM app suite: 432 XCTest +309 Swift Testing passed. CraftUIKit: 653 XCTest +84 Swift Testing passed; focused localization: 13 passed. SwiftLint and diff checks clean. Physical-device Debug build succeeded with existing concurrency warnings outside the changed files.

Installed and launched on the connected iPhone **Hooji** successfully after the user unlocked it. Launch returned process ID 9699, with no special launch arguments. Physical touch interaction remains for the user to try.
