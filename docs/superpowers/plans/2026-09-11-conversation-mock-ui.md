# Conversation Mock UI Implementation Plan

Spec: ../specs/2026-09-10-ai-conversation-ios-design.md

## Global Constraints
- Scope authorized by user: sample-data UI and deterministic mock speech; no real API/audio integration yet.
- Extend CraftUIKit; no external chat dependency; all new styling uses tokens and all UI/a11y copy has manual translated EN/VI catalog entries.
- Debug-only launch route and previews; production must not display sample conversations.
- Keep default speaking/audio, schema and learning path progression unchanged.

## Task 1: Reviewable mock conversation vertical slice

Files: add focused files under VocabCraftApp/Features/Conversation for models, sample repository, mock session state, views; add reusable CraftConversationTurnView under CraftUIKit/Components/Conversation; add sample data as a DEBUG-only Swift fixture and bilingual catalog entries; wire DEBUG launch argument -test-conversation-ui in VocabCraftApp; add focused app and component/localization tests. Inspect pbxproj file membership and include new source files when required.

Requirements:
- Use words drawn from VocabularySampleDataset to author two fixed bilingual, coherent four-to-six-turn conversations. Dataset vocabulary references should be visible in fixture metadata. Keep literals out of views; fixtures may contain educational text.
- Show situation, all dialogue, role A/B choice and Start; tap individual turn to toggle Vietnamese. Auto-scroll active turn until manual scroll, provide return to current.
- After start, simulated partner playback transitions to mock listening automatically. A clearly labeled DEBUG scenario selector controls pass, retry, noSpeech. Mock reading resolves after a short cancellable delay (or developer controls), never purporting to use microphone. Show a persistent localized simulation notice.
- Pass advances immediately; retry/noSpeech stop and await explicit Retry. Both roles supported. One role completes stage only after its required lines and trailing partner line. Optional role switch restarts attempt.
- Pause/resume and background pause; close/reopen restores chosen role and passed turns. Debug-only local persisted mock session is sufficient; do not migrate production SwiftData. On restore do not auto listen, wait Continue.
- New conversation is available outside active playback/listening. Simulate success and failure; failure retains previous snapshot and progress; success resets attempt while preserving completion achievement. Confirm replacement of unfinished attempt.
- Reuse mic/speaker/card/button/progress components. No actual TTS/microphone required in this mock milestone. No automatic launching in normal production flow.

TDD steps:
- [x] Write and run failing session tests for retry waiting, role B start, pause/cancellation stale callback, completion, persisted resume, regeneration failure retaining data.
- [x] Implement smallest model/repository/mock driver to pass tests; inject delay/clock/storage seams for deterministic tests.
- [x] Write component localization/scroll policy tests then implement token-styled turn view and complete practice screen with preview fixtures.
- [x] Wire debug launch, ensure app Xcode target includes changes; test app and package focused suites, full baseline-compatible suites, lint and simulator build.
- [x] Launch simulator mock screen, inspect visible default and retry/completion states and capture screenshots. Root coordinator handles final device UI inspection if tools unavailable to implementer.
- [x] Self-review and commit only intended files. Report exact test commands/results, baseline limitations, full file list and debug launch instructions.

Acceptance: mock UI fully navigable without API or mic access; no fixture leak in release; accurate simulation labeling; all requested state transitions tested. Physical speech quality and production API remain outside this milestone.
