# Task 4 implementation report

Status: DONE_WITH_CONCERNS (implementation verified; runtime diagnostics and one intermittent macOS audio callback crash prevent a pristine full-suite claim).
Base: `a5fc557c`. Worktree: `/Users/hoojinguyen/.codex/worktrees/ai-speaking-rebuild/vocab-craft-app`.

## Implementation

Read task-4-brief.md first, including persistence lifetime requirements; then constraints.md, AGENTS.md, implementer-prompt.md and applicable Superpowers TDD/verification, SwiftData/concurrency/Swift Testing and XcodeBuildMCP skills. Implemented directly, without subagents. The approved task brief supplies the design. Followed the controller's file-alias correction: the actor is in Data/Speaking. Direct user instruction overrides constraints.md's obsolete fake coauthor footer.

- Added SchemaV4 version 4.0.0 containing the five unchanged V2/V3 progress models plus SpeakingSessionRecord and SavedPhraseRecord. UUID identifiers are unique; JSON payloads hold the Codable domain values; session scores/status/audio/time and phrase dedupe/time have flat columns.
- Historical V1/V2/V3 definitions and historical GuidedPracticeMigrationTests remain unchanged. Production aliases target V4; removed the six Practice aliases. Added the V3→V4 lightweight stage and updated both shared-container creation/reset schema references.
- Added the exact Sendable SpeakingRepositoryProtocol and @ModelActor implementation. All operations explicitly save, pass value snapshots across actor boundaries, and perform fetch/mutation/save without suspension inside actor methods. Upsert synchronizes all flat fields and JSON; repeated analysis updates do not insert another session, and nil analysis clears all four scores. Missing sessions return nil; updating analysis for a missing session is a no-op. Nonpositive limits return an empty list.
- Phrase saves reject normalized suggestion duplicates (temporary lowercase + whitespace/newline trim) and repeated UUIDs; phrase listing is newest first; deletion of a missing UUID is harmless. Concurrent callers to one actor cannot race its dedupe check and insert. QuoteNormalizer integration remains Task 12.
- Audio retention counts the latest sessions, including sessions with no audio, clamps negative retention to zero, clears both JSON and flat filenames, and returns removed names for the caller to delete. Analysis remains intact. All eligible payloads are decoded before any retention mutation, so a decoding failure cannot leave a partially detached batch. This repository does not delete physical files or write SRS records.
- Shared persisted-record detection now checks speaking sessions and phrases rather than removed Practice records.
- Narrow manual Xcode membership changes add five Swift files and the Data/Speaking group; the shared V4 schema is also compiled by the widget. Schema initializers use scalar persistence values, so the widget does not depend on app-only speaking domain types. No generator, platform-floor changes, localization changes or unexpected Xcode metadata changes.

## Migration and lifetime evidence

`SchemaV4MigrationTests.v3StoreWithPracticeDataMigratesAndKeepsProgress` creates an actual temporary V3 SQLite store, seeds all five retained model types and a Practice session, saves, and returns from its seed helper so old context/container references are released before opening V4 at the same URL with AppMigrationPlan. Each context-owning scope explicitly retains its ModelContainer with withExtendedLifetime. Repository actors retain their containers; the direct-context test also explicitly retains its container.

The test verifies word 101 and its SRS/mastery/bookmark/source/streak/mode fields; complete stage, Reflex, widget and QuickReflex values; empty new speaking/phrase tables; the original store still exists; and no backup/reset/quarantine artifact was created. It passes on macOS and iOS. Existing historical migration tests all pass without a prefix migration plan or weakened/skipped assertions.

## TDD evidence

Full outputs are saved beside this report. Commands run from the worktree root unless otherwise noted.

RED: `swift test --filter SpeakingRepositoryTests > .superpowers/sdd/2026-10-27-ai-speaking-rebuild/task-4-red.log 2>&1` exited 1 before production implementation. Expected missing-interface compile errors include `cannot find 'SchemaV4' in scope`, `cannot find type 'SpeakingSessionRecord' in scope`, and `cannot find type 'SavedPhraseRecord' in scope`. These were missing new APIs, not a preexisting test failure. Repository and migration test bodies were written first.

GREEN: `swift test --filter 'SpeakingRepositoryTests|SchemaV4MigrationTests'` passed all initial six tests (`task-4-green.log`). Subsequent focused regression checks passed after membership/path and lifetime refinements. Added concurrency and file-backed repository round-trip coverage to exercise existing implementation beyond the minimum brief. Self-review strengthened the score test to use four distinct values (3, 2, 4, 5), with literal assertions that catch swapped column assignments; final focused/full checks were rerun after this test-only refinement.

## Verification

| Check | Result | Evidence |
| --- | --- | --- |
| `swift test --filter 'SpeakingRepositoryTests|SchemaV4MigrationTests|SwiftDataModelsTests|UserProgressModelActorConcurrencyTests|Widget|GuidedPracticeMigrationTests'` | 38 XCTest + 115 Swift Testing = 153 pass | task-4-focused-final.log |
| `swift test` (first full run) | 482 XCTest + 643 Swift Testing = 1,125 pass | task-4-root.log |
| `swift test` (repeat after final edits) | XCTest passed; Swift Testing process SIGSEGV in native audio queue callback, after both new suites passed | task-4-root-final.log; task-4-macos-audio-crash.ips |
| `swift test` (diagnostic reproduction, unchanged code) | 482 XCTest + 643 Swift Testing = 1,125 pass; exit 0 | task-4-root-repeat.log |
| `swift test` (final distinct-score test refinement) | 482 XCTest + 643 Swift Testing = 1,125 pass; exit 0 | task-4-root-score-final.log |
| `swift test --package-path Packages/CraftUIKit --filter LocalizationTests` | 13 pass | task-4-localization.log |
| `swift test --package-path Packages/CraftUIKit` | 654 XCTest + 78 Swift Testing = 732 pass | task-4-craft-full.log |
| `swiftlint lint --strict` | 0 violations, 0 serious, 378 files | task-4-lint-final.log |
| XcodeBuildMCP `build_sim({})`, VocabCraftApp | SUCCEEDED, 0 compiler warnings/errors | build_sim_2026-10-28T17-09-16-934Z_pid88307_d842f38d.log |
| XcodeBuildMCP focused `test_sim`, VocabCraftAppTests | 11 pass, 0 failed/skipped; 5 historical + 6 initial new | test_sim_2026-10-28T17-05-00-663Z_pid88307_c225ceb5.log |
| XcodeBuildMCP full `test_sim({progress:false})`, VocabCraftAppTests | 1,175 pass, 0 failed/skipped (final 8 new tests included) | task-4-ios-final-result.json; test_sim_2026-10-28T17-11-49-029Z_pid88307_bb268b59.log |
| `git diff --check` | Clean | inspected before commit |

Xcode defaults explicitly verified and set: worktree `VocabCraft.xcworkspace`; build scheme `VocabCraftApp`, test scheme `VocabCraftAppTests`; simulator `607AC652-2E92-4BE7-BA18-1B888D79684B` (iPhone 17 Pro); DerivedData `/Users/hoojinguyen/Library/Developer/Xcode/DerivedData/VocabCraftSpeakingRebuild`; suppressWarnings=false. Deployment floors remain iOS 17/macOS 14. These are compile/deployment settings, not proof of running on the oldest OS releases.

Xcode logs/results directory: `/Users/hoojinguyen/Library/Developer/XcodeBuildMCP/workspaces/vocab-craft-app-d3fac97e12bc/`. Final result bundle: `result-bundles/test_sim_2026-10-28T17-11-49-029Z_pid88307_a5a48055.xcresult`.

## Self-review and concerns

Reviewed the complete changed-file diff, new sources/tests and target membership against the brief. Historical schemas and tests are untouched, payload/flat-column writes agree, actor operations do not suspend mid-mutation, audio detachment does not discard analysis, and dedupe has real concurrent-caller coverage. No unrelated source changes or unresolved implementation findings. Self-review only, as explicitly requested; no external reviewer dispatched.

Runtime output is not pristine:

1. Removing Practice entities emits Core Data persistent-history truncation diagnostics (one `CoreData: error` history notice and three `CoreData: warning` lines for indexes, transactions and changes). These accompany a successful real migration preserving all required data. Did not disable history, suppress output, reset a valid store, or weaken migration tests to hide them.
2. First full iOS run reports seven priority-inversion runtime warnings in existing tests: ReflexBlitzViewModelTests.testSelectOptionTransitionsCardPhaseToReviewed; SmartReviewViewModelTests.test_smartReviewFlow_advanceAndComplete; SoundEffectAndTTSTests.testAsyncTTSCompletesSuccessfully, testAsyncTTSDefaultParameters, testSpeakSyncWithCustomRateAndLocale; SpeechServiceTests.testTTSSpeakConfiguresParameters and testTTSSpeakWithCustomRateAndLocale. Existing audio/TTS code was unchanged. This is the previously observed diagnostic family, but this run's seven occurrences are reported exactly rather than assuming the previous count. Combined with the three history warnings, that run reports ten runtime warnings and zero test failures (`task-4-ios-result.json`). The final full iOS rerun after the score-test refinement reports five QoS warnings (the first five tests above; neither SpeechServiceTests occurrence repeats), plus the three history warnings: eight runtime warnings, 1,175 passed, zero failed/skipped. Both complete tool results are preserved.
3. A repeated macOS full run crashed with `Weak reference loaded ... not in the weak references table`, EXC_BAD_ACCESS/SIGSEGV. Saved .ips identifies faulting thread 9: objc_retain → objc_loadWeak → AudioRecorderAQInputCallback → AudioQueue callbacks. Both new suites had already passed (repository 0.062s, migration 1.075s). The stack is in native audio callback teardown, not SwiftData; a precise owning test/root cause is not established. No unrelated audio rewrite, skipped tests, or warning suppression was made. Two subsequent full macOS reruns passed; the crash was not reproduced. Those passes and the full iOS passes do not erase this failed run.

The strict global zero-runtime-warning/pristine-run gate remains unmet; DONE_WITH_CONCERNS describes verified Task 4 implementation, not unconditional project acceptance. No hardware, real Gemini, deployment, push or merge performed.

## Fix round 1 diagnostic checkpoint (2026-10-29)

The original implementer exhausted its usage allowance during a bounded diagnostic pass and was closed before any replacement was started. Its uncommitted probe edits were fully removed; no diagnostic logging or test serialization changes remain in tracked source. The preserved probe artifacts are `task-4-r1-probe.diff`, `task-4-r1-exclusive-experiment.diff`, `task-4-r1-native-focused-1.log` through `task-4-r1-native-focused-3.log`, and `task-4-r1-native-exclusive.log`.

The final bounded run completed all 52 tests across five suites, including the speaking persistence/migration tests and existing recorder tests. It did not reproduce the crash. During that run, AVAudioRecorder reported authorization status raw value 3 and `record()` returned false (`nativeRecording=false`), so the recorder tests did not establish a successful native recording. The exclusive gate only covered selected test bodies and cannot establish that global audio overlap is or is not causal. Therefore the run is non-reproduction evidence only; it is not a root-cause finding, fix, or resolution of the Important review finding. The saved `.ips` and original failed full-suite log remain the authoritative failure evidence. Task 4 remains open pending a grounded cause or explicit disposition of the quality gate.

### Fix round 1 disposition (2026-10-29)

**Status: OPEN — 0 addressed, 1 unresolved. No source fix or scoped re-review.** The original finding remains verbatim in effect: an intermittent macOS full SwiftPM run SIGSEGVs in native `AudioRecorderAQInputCallback` / AudioQueue teardown with an invalid weak reference; the owning test and root cause are not established. Inspection of all saved round-1 artifacts confirms the bounded exclusive-gate run passed 52/52 but `AVAudioRecorder.record()` returned false (`authorization raw=3`, `nativeRecording=false`); the ungated probe logs likewise show unsuccessful native recording. Thus neither run exercised a confirmed active native capture, and the gate does not cover every audio-producing test. Passing reruns and this non-reproduction cannot identify a cause. Probe edits are absent from the source tree, which is clean at `80bbc31f`. No recorder rewrite, test skip/suppression, or broad serialization is justified by this evidence. The precise limitation is that there is no reproducible crash under an environment that successfully starts the native recorder, nor a trace attributing the original callback teardown to a particular test/object lifetime. Keep the finding OPEN and preserve the original `.ips` plus full-suite crash log.

### Replacement implementer investigation (2026-10-29)

**Status: OPEN — investigation narrowed the candidate lifetime path, but does not establish causality. No source changes.**

The original crash report was parsed again. It records `EXC_BAD_ACCESS` / `SIGSEGV`, `KERN_INVALID_ADDRESS` at `0x45970`, on queue `AQClient@0x8ce8bda58`; the faulting frames are `objc_retain` → `objc_loadWeak` → `AudioRecorderAQInputCallback` → AudioQueue callback delivery. The report has no Swift/app frame in that thread. The failed full-run log shows V4 migration and repository suites had already passed; when the helper crashed, Swift Testing was still running multiple tests concurrently. The last output includes Shadowing recording tests, but concurrent completion order does not identify which test owned the callback.

Source lifetime audit:

- `ShadowingAudioRecorder.startRecording(sentenceId:)` creates one `AVAudioRecorder`, sets its delegate, ignores the Boolean from `record()`, stores it, and marks `isActivelyRecording = true` even if native recording did not start.
- `stopRecording()` calls `stop()` then immediately sets the strong `audioRecorder` property to `nil`; it does not wait for `audioRecorderDidFinishRecording` or implement that delegate callback.
- `ShadowingPracticeViewModel.startRecordingAsync()` starts the real `ShadowingAudioRecorder` before invoking the injected assessment service. Several tests inject `MockSpeechAssessmentService`; their passing, failing, error, and token-mapping paths complete or error the mock without calling `stopRecording()`. The local view model/session/recorder then leaves scope. Studio tests also directly start the native recorder and one path stops it on simulated headphone removal.
- The invalid weak load during `AudioRecorderAQInputCallback` is consistent with a recorder/callback lifetime race, and the missing stop in mock-driven test paths plus immediate release after `stop()` are concrete candidate paths. However, the saved instrumented runs show `record()` returned `false` for every observed start (`authorization raw=3`, `nativeRecording=false`). Those test paths therefore did not demonstrate an active capture being destroyed, and the `.ips` has no owner/test attribution. The candidate is not a proven root cause.

Commands/evidence reviewed from the worktree:

- `jq '{exception, faultingThread, threads: [.threads[] | select(.triggered == true or .id == 9)]}' .superpowers/sdd/2026-10-27-ai-speaking-rebuild/task-4-macos-audio-crash.ips` — `EXC_BAD_ACCESS`, `SIGSEGV`, invalid address `0x45970`, faulting thread 9, `AQClient` queue, weak-load/AudioQueue frames above.
- `sed -n '2870,3095p' .superpowers/sdd/2026-10-27-ai-speaking-rebuild/task-4-root-final.log` — confirms V4 suites passed before the helper exited on signal 11; overlapping Swift Testing work includes Shadowing recording test completions, so no unique owner can be assigned.
- `rg -n -i 'audioRecorder|ShadowingAudioRecorder\\(|startRecording\\(' VocabCraftAppTests/Features/Shadowing` — direct native recorder starts are in `ShadowingSessionCoordinatorTests.testRecorderFileGeneration` and `ShadowingStudioViewModelTests.testHeadphoneDisconnectionDuringRound2StopsRecording`; additional real starts flow through `ShadowingPracticeViewModel.startRecordingAsync()` and Studio recording tests.
- `sed -n '100,225p' VocabCraftAppTests/Features/Shadowing/ShadowingPracticeViewModelTests.swift` and `sed -n '260,325p' VocabCraftAppTests/Features/Shadowing/ShadowingStudioViewModelTests.swift` — document mock completion/error paths and direct recorder/test cleanup behavior.
- `rg -n -C 2 'authorization|nativeRecording|record\\(\\)|AVAudioRecorder|passed|crash' .superpowers/sdd/2026-10-27-ai-speaking-rebuild/task-4-r1-native-focused-*.log .superpowers/sdd/2026-10-27-ai-speaking-rebuild/task-4-r1-native-exclusive.log` — each observed `record()` call returned false; bounded tests passed without exercising active native capture.

No minimal active-capture reproducer could be run because this host's recorder attempts did not start native recording. No change was made to production recorder ownership or tests: adding cleanup or retaining the recorder until a delegate callback would be a plausible mitigation, but without a successful recording reproducer or ownership trace it would convert a candidate into an unverified fix. No tests were skipped, output suppressed, or globally serialized. Task 4 fix round 1 remains open; needed next evidence is a reproducible run with `record() == true` that ties callback delivery to a specific recorder/test lifetime, or an explicit disposition of the quality finding.

### User-directed fix-round implementation (2026-10-29)

**Status: testability and false-start behavior addressed in source; Apple callback cause remains unresolved. Do not describe the original AudioQueue crash as fixed.** The user authorized a narrow seam after the source audit found mocked Shadowing tests constructing the concrete recorder. The implementation keeps this scope limited to the recorder device boundary and does not change the AVAudioQueue lifecycle or claim a native crash correction.

Changes:

- Added an internal MainActor-isolated `AudioRecordingDevice` protocol with only `isRecording`, `record()` and `stop()`. `AVAudioRecordingDevice` is the production adapter and remains the default created by `ShadowingAudioRecorder.init()`; it wraps `AVAudioRecorder` using the existing AAC settings.
- Added an internal factory initializer for `ShadowingAudioRecorder`. On `record() == false`, the recorder now calls `stop()`, does not store the failed device, leaves `isRecording == false` and `lastRecordedURL == nil`, and throws `ShadowingAudioRecorderError.failedToStartRecording`. Successful starts store the device and publish the URL as before. Removed the prior logical `isActivelyRecording` fallback, which could report success even when the native start returned false.
- Added a fake device in `ShadowingSessionCoordinatorTests.swift` and a test coordinator/recorder factory. Practice, Studio and coordinator tests now inject the fake when exercising record flows; they no longer construct `AVAudioRecorder` or an input AudioQueue. No new source/test files or Xcode project membership changes were needed. Production call sites retain the default AVFoundation adapter.
- The failure test checks exactly one `stop()`, a released weak device reference, `isRecording == false`, and no published URL. The successful fake-path test checks a device was created by the injected factory, file naming remains unchanged, and stop clears recording state.

TDD and verification evidence (commands from the worktree root):

- RED: `swift test --filter ShadowingSessionCoordinatorTests` exited nonzero while the new test-first API references were unresolved. Expected diagnostics: `cannot find type 'AudioRecordingDevice' in scope`, `argument passed to call that takes no arguments` for `audioRecorderFactory`, and `cannot find 'ShadowingAudioRecorderError' in scope`.
- GREEN: `swift test --filter ShadowingSessionCoordinatorTests` — 6 tests in 1 suite passed, including `Failed recorder start stops and releases the device`.
- Shadowing set: `swift test --filter 'Shadowing|YouTubePlayerBridgeTests'` — 87 tests in 12 suites passed. This includes Practice/Studio flows and confirms these tests execute through the fake factory.
- Full macOS SwiftPM: `swift test` — exit 0; 482 XCTest passed, 644 Swift Testing tests in 99 suites passed. The preserved complete output is `task-4-r1-full-swiftpm.log`. This run did not contain the invalid-weak-reference crash signature. This is one post-change non-reproduction; it is not proof the Apple callback issue is fixed.
- `swiftlint lint --strict` — 0 violations, 0 serious across 378 files.
- XcodeBuildMCP full iOS Simulator tests — succeeded, 1,176 passed, 0 failed, 0 skipped in 81.3s. The tool reported 1,175 discovered tests and 1,176 passed, so its discovery/pass totals differ by one. It reported 10 runtime warnings: seven existing QoS priority-inversion diagnostics and the three persistent-history diagnostics already present on V3→V4 migration. Result bundle: `/Users/hoojinguyen/Library/Developer/XcodeBuildMCP/workspaces/vocab-craft-app-d3fac97e12bc/result-bundles/test_sim_2026-10-29T03-11-51-353Z_pid69234_a397920c.xcresult`.
- `git diff --check` — clean. Repository source change list is limited to `ShadowingAudioRecorder.swift` and the three Shadowing test files; `project.pbxproj` and localization catalogs are unchanged.

The original crash's faulting native frame and owner attribution are unchanged. The seam removes the identified automated-test route to real native capture and gives `record() == false` deterministic failure semantics. A successful native capture reproducer, identification of the original callback owner, and scoped independent re-review remain outstanding; keep the crash finding OPEN.

## Files changed

1. `VocabCraftApp/Core/Database/Schemas/AppSchemaV4.swift` — new V4 schema and persistence records.
2. `VocabCraftApp/Core/Database/SharedAppGroupContainer.swift` — migration stage, active schema, speaking/phrase record detection.
3. `VocabCraftApp/Core/Database/SwiftDataModels.swift` — active V4 aliases; remove Practice aliases.
4. `VocabCraftApp/Data/Speaking/SpeakingModelActor.swift` — actor repository implementation.
5. `VocabCraftApp/Domain/Speaking/SpeakingRepositoryProtocol.swift` — exact asynchronous value interface.
6. `VocabCraftAppTests/Speaking/SpeakingRepositoryTests.swift` — seven real repository tests and local fixtures/factory.
7. `VocabCraftAppTests/Core/SchemaV4MigrationTests.swift` — file-backed preservation test and lifetime-scoped seeding.
8. `VocabCraftApp.xcodeproj/project.pbxproj` — manual app/widget/test source membership and Data/Speaking group.

Report/logs are ignored orchestration artifacts under `.superpowers/sdd/2026-10-27-ai-speaking-rebuild/`, intentionally not forced into the product commit.

## Commit and final inspection

`80bbc31f` — `feat(speaking): add schema v4 with speaking sessions and phrasebook`.

Committed exactly the eight scoped files above. Post-commit diff inspection (`git diff a5fc557c..HEAD --check`) is clean, working tree is clean, commit metadata has no Co-Authored-By footer, and historical schema/migration-test paths have no diff. Changed-file manifest: `task-4-changed-files.txt`. Final score-focused tests, root full tests and full iOS tests passed before commit; no production/test edits followed those runs. Report and complete output remain available in the ignored SDD workspace. Task is ready for controller review with the runtime concerns explicitly retained.
