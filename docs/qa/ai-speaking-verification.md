# AI Speaking Verification and Manual QA

**Verification date:** 2026-10-29

**Code base:** `31a84ceb` (`31a84cebe88de6c3d5f42d397d90c7a213d61582`)

**Platform:** Xcode 27A9275, iOS Simulator 26.5, iPhone 17 Pro (`607AC652-2E92-4BE7-BA18-1B888D79684B`)

## Automated quality gates

The gates below were run in the implementation plan's required order. All commands exited `0`.

| Order | Exact command | Result |
| --- | --- | --- |
| 1 | `swift test` | PASS — 796 tests in 116 suites; 0 failed. |
| 2 | `swift test --package-path Packages/CraftUIKit` | PASS — 78 tests in 7 suites; 0 failed. |
| 3 | `swift test --package-path Packages/SpeechKit` | PASS — 73 XCTest cases; 0 failed. Swift Testing also reported its separate 0-test run. |
| 4 | `swift test --package-path Packages/CraftUIKit --filter LocalizationTests` | PASS — 13 tests; 0 failed. |
| 5 | `swiftlint --strict` | PASS — 0 violations, 0 serious violations, 426 files. |
| 6 | `xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator' build` | PASS — `BUILD SUCCEEDED`, exit 0; no compiler errors or warnings. |
| 7 | `xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftAppTests -destination 'platform=iOS Simulator,id=607AC652-2E92-4BE7-BA18-1B888D79684B' test` | PASS — 826 tests in 120 suites; 0 failed; `TEST SUCCEEDED`, exit 0. |

### Diagnostics observed

- The root SwiftPM run logged CoreData persistent-history truncation and “Dropping Indexes/Transactions/Changes” while `SchemaV4MigrationTests.v3StoreWithPracticeDataMigratesAndKeepsProgress` migrated the V3 fixture after six retired practice entities were removed. The migration test passed. This is recorded as migration-time framework output, not a compiler warning or failed assertion.
- The app simulator suite intentionally loads `corrupt.sqlite` in `DatabaseQuarantineTests.test_corrupt_store_triggers_quarantine_and_throws_typed_error`. CoreData logged the expected corrupt-store load error; the test passed after verifying the typed error/quarantine behavior.
- Simulator app launches logged VoiceDB fixture decode failures followed by fallback voices/locales and `[AXCommon] Potential Structural Swift Concurrency Issue: unsafeForcedSync...`. These are runtime diagnostics; the complete suite still passed. They were not compiler diagnostics and were not attributed to Speaking without evidence.
- Xcode printed `IDESchemeActionSDKRecord ... invalidDigitCount(94232)` twice after the test run. `xcodebuild` still exited 0 and printed `TEST SUCCEEDED`.
- No Speaking-specific test failure or compiler warning was observed. No source correction was needed for these gates.

## Physical-device checklist — pending user run

Run these checks on a physical iPhone with the user's normal audio setup and network. For each run, record the actual result and attach a recording or screen capture only when it is safe and useful. Do not treat simulator tests as a substitute for these checks.

Record shared setup once:

| Date/time | Device and iOS | App build/commit | Audio route | Network | Tester |
| --- | --- | --- | --- | --- | --- |
| Pending user-run |  |  |  |  |  |

| # | Check | Steps | Expected observation | Actual result / evidence | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | Speaker playback and echo | Start a Speaking call on speaker. Let the AI speak, then answer naturally. Listen for the device capturing its own AI audio and creating a reply loop. | AI audio does not feed back as learner speech; no self-answer loop. |  | Pending user-run |
| 2 | AirPods route | Connect AirPods before the call, start a session, speak and listen; disconnect/reconnect once if practical. | Input and AI playback use the expected AirPods route and the call remains usable. |  | Pending user-run |
| 3 | Repeated interruption | Interrupt the AI while it is speaking three times in succession. | Each interruption promptly stops/flushes AI playback and returns the turn to the learner without a stuck state or crash. |  | Pending user-run |
| 4 | Incoming phone call | Start a Speaking session, then receive or place a real phone call during it. After the interruption, inspect Speaking history. | The Speaking session ends safely and the partial/final session appears in history. |  | Pending user-run |
| 5 | Airplane mode beyond reconnect deadline | Start a session, enable Airplane Mode, and leave it on beyond the reconnect window. | “Reconnecting…” is shown, then the call ends with `connectionLost` after the 8-second reconnect deadline; no infinite reconnect. |  | Pending user-run |
| 6 | Network restored within deadline | Start a session, enable Airplane Mode, then disable it before the 8-second reconnect deadline. | The client reconnects and the conversation can continue without duplicate/stale audio. |  | Pending user-run |
| 7 | Maximum duration | Keep a session active through the full duration. Record timestamps for the wrap-up and hard stop. | AI begins its goodbye at 5:30; the call is forcibly ended at 6:30. |  | Pending user-run |
| 8 | Invalid Gemini key | Configure an intentionally invalid key in Settings, start a call, and follow the error action. Do not record or share the key. | The service reports `unauthorized`, offers navigation to Settings, and does not expose the key in UI/logs. |  | Pending user-run |

## Prompt evaluation — five real user-run sessions pending

Run five distinct sessions using the Speaking flow: three at A2 and two at B1. Use real learner speech and retain the corresponding recordings/transcripts securely for review. Complete one row per session; do not score synthetic or simulator-only exchanges as learner evidence.

| Session | Level | Scenario / objective | Recording or transcript reference | Corrections accurate? (examples) | Fabricated quote candidates rejected / total candidates | Vietnamese explanation clear? | Scores reasonable? (1–5 dimensions) | Notes / prompt change needed | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | A2 | Pending selection |  |  |  |  |  |  | Pending user-run |
| 2 | A2 | Pending selection |  |  |  |  |  |  | Pending user-run |
| 3 | A2 | Pending selection |  |  |  |  |  |  | Pending user-run |
| 4 | B1 | Pending selection |  |  |  |  |  |  | Pending user-run |
| 5 | B1 | Pending selection |  |  |  |  |  |  | Pending user-run |

### Evaluation rubric

- **Correction accuracy:** Verify each correction against the learner's actual words and intended meaning. Record any incorrect or unnecessary correction with a short example.
- **Fabricated quotations:** Compare every quoted correction, natural phrasing, or target-word example with the recording/transcript. Count candidate items rejected by the validator and the total candidates returned for review. A rejected item is not evidence that the prompt itself avoided proposing it.
- **Vietnamese clarity:** Rate whether each explanation is accurate, concise, and understandable to an A2–B1 learner; note confusing terminology or missing context.
- **Score reasonableness:** Judge fluency, grammar, vocabulary, and pronunciation against the actual recording and the learner's level. Note a score that is unsupported by audible evidence.
- **Prompt changes:** If a pattern needs a prompt/request-builder change, update the relevant tests and snapshots, rerun the affected gates, and record the resulting revision and evidence here.

## Gemini API smoke — deferred to the user

No Gemini API request was performed during this verification. The user will run the real Gemini Live and Gemini Flash smoke checks later with their own key and a user-recorded sample. Do not put the key in this document, source control, or logs. Record endpoint/model, date, HTTP result, response decoding/validation result, and any schema difference after that user-run check.

## Repository hygiene

After verification, `git status --short` showed only the pre-existing modification to `docs/superpowers/plans/2026-10-27-ai-speaking-rebuild.md`. No Xcode-generated project/workspace metadata or other tracked/untracked repository files were created by these gates. DerivedData, simulator state, and test result bundles are outside the repository. The plan modification is intentionally preserved and is not part of the Task 18 commit.
