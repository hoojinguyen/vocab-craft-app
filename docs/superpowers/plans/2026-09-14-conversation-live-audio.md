# Conversation Live Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Người học có thể nghe và đọc một hội thoại mẫu từ đầu đến cuối trên Hooji, qua nút lesson trên Home.

**Architecture:** `ConversationLiveSession` điều phối tiến độ qua một audio interface MainActor, evaluator thuần và storage cục bộ. Adapter nối SpeechKit với coordinator chung; `TextToSpeechService` cung cấp kết quả phát rõ ràng. View tái sử dụng CraftUIKit; dữ liệu vẫn là sample, không gọi API.

**Tech Stack:** Swift, SwiftUI, Observation, SpeechKit, AVFoundation, CraftUIKit, Swift Testing/XCTest, XcodeBuildMCP. Giữ platform floor hiện có của project/package.

**Spec:** [Luyện hội thoại mẫu bằng nghe/nói thật](../specs/2026-09-14-conversation-live-audio-design.md).

## Global Constraints

- Nội dung mẫu và lesson thử nghiệm tiếp tục chỉ có trong Debug.
- TTS giữ quyền quản lý playback lease; adapter chỉ quản lý capture lease. Không acquire hai lần cùng một thao tác.
- Mọi callback/timer gắn với một attempt ID. Callback cũ không sửa transcript, tăng tiến độ hoặc dừng attempt mới.
- Transcript tạm không làm chuyển lượt; chỉ đánh giá sau final hoặc trailing inactivity.
- Không gọi `CompleteLessonUseCase`, không phát XP từ bài mẫu.
- Không triển khai backend, schema migration, production stage insertion hoặc API generation.
- Tất cả text/a11y mới có catalog EN/VI đầy đủ, `manual` và `translated`; styling dùng token CraftUIKit.
- Không nhập tiến độ hoặc thành tích từ `debug.conversation.mock.session`.
- Giá trị thử nghiệm: fuzzy `0.78`, minimum coverage/mean similarity `0.82`, initial silence `4s`, trailing inactivity `1.5s`, maximum capture `20s`; chưa phải calibration phát âm.

## Điểm bắt đầu và nguyên tắc tiếp quản

Worktree: `/Users/hoojinguyen/Projects/vocab-craft-app/.worktrees/conversation-ui`, branch `codex/conversation-ui`. Commit chức năng gần nhất: `0c6570f2`.

Đã có bản nháp chưa commit của `ConversationAudioAdapter.swift`, `ConversationTurnEvaluator.swift`, bốn file test Conversation, thay đổi `SpeechRecognitionEngine.swift` và `TextToSpeechService.swift`. Một file test tham chiếu `ConversationLiveSession` chưa có. Toàn bộ working tree chưa được xác nhận build/pass sau thay đổi này.

- [ ] Đọc `git status --short`, `git diff`, các file untracked và ledger trước khi tiếp tục; giữ nguyên phần việc đã có, không reset/clean worktree.
- [ ] Đối chiếu các interface dưới đây với bản nháp. Hoàn thiện tại chỗ; “Create” nghĩa là tạo nếu chưa tồn tại, không ghi đè mù quáng.
- [ ] Ghi điểm bắt đầu mới và manifest các file đang sửa. Không coi test log cũ là bằng chứng cho tree mới.
- [ ] Theo TDD từng nhóm hành vi: chạy RED, thay code tối thiểu, chạy GREEN, self-review và commit đúng file. Task 1 hoàn thiện type session còn thiếu để test target có thể compile; chỉ chạy filter của task hiện tại trong lúc các test hành vi khác còn RED.

## Bản đồ file và trách nhiệm

| File | Trách nhiệm |
|---|---|
| `Features/Conversation/ConversationTurnEvaluator.swift` | Chuẩn hóa/căn chỉnh transcript, quyết định pass/retry/silence |
| `Features/Conversation/ConversationAudioAdapter.swift` | Audio contracts, capture lifecycle, timer và cancellation |
| `Features/Conversation/ConversationLiveAudioClients.swift` | Wrapper cụ thể cho SpeechKit và TextToSpeechService, tách khỏi adapter khi hoàn thiện bản nháp |
| `Features/Conversation/ConversationLiveSession.swift` | MainActor state machine, gọi audio, quản lý role/attempt/progress |
| `Features/Conversation/ConversationLiveView.swift` | Screen live, lifecycle và transcript |
| `Features/Conversation/ConversationLiveControls.swift` | Control theo trạng thái, thông báo lỗi, Settings và nghe mẫu |
| `Core/Audio/TextToSpeechService.swift` | Outcome-bearing playback, caller cũ giữ nguyên hành vi |
| `Packages/SpeechKit/.../SpeechRecognitionEngine.swift` | Opt-out quản lý AVAudioSession cho coordinator bên ngoài |
| `App/DI/AppContainer.swift` | Tạo audio/session với coordinator chung |
| `Features/Homepage/Views/HomepageView.swift` | Start mở màn live Debug thay vì mock |

Đường dẫn app trong bảng nằm dưới `VocabCraftApp/`; test nằm dưới `VocabCraftAppTests/Features/`. Giữ mock view/session hiện có cho preview/route thử nghiệm; không đổi semantics mock để giả làm live.

## Task 1: Evaluator và state machine live qua dependency giả lập

**Files:**
- Complete: `VocabCraftApp/Features/Conversation/ConversationTurnEvaluator.swift`
- Create: `VocabCraftApp/Features/Conversation/ConversationLiveSession.swift`
- Consume/complete contracts: `VocabCraftApp/Features/Conversation/ConversationAudioAdapter.swift`
- Reuse: `ConversationModels.swift`, `ConversationSessionStorage.swift`
- Test: `VocabCraftAppTests/Features/ConversationTurnEvaluatorTests.swift`, `ConversationLiveSessionTests.swift`

**Interfaces:**

```swift
// All audio clients and the session are @MainActor.
protocol ConversationAudioClient: AnyObject {
    func play(text: String, locale: String) async -> ConversationPlaybackResult
    func capture(
        targetSentence: String,
        contextualPhrases: [String],
        onListening: @escaping @MainActor @Sendable () -> Void,
        onPartial: @escaping @MainActor @Sendable (String) -> Void
    ) async -> ConversationCaptureResult
    func stop()
}
// Playback: finished / cancelled / failed.
// Capture: transcript(String) / silence / permissionDenied /
//          unavailable / failed / cancelled.
```

`ConversationLiveSession` init nhận `conversation: ConversationScript`, `role: ConversationRole = .speakerA`, `storage: any ConversationSessionStorage`, `audio: any ConversationAudioClient`, `evaluator: ConversationTurnEvaluator = .init()`.

Expose `conversation`, `role`, `phase`, `passedTurnIDs`, `hasCompletedAchievement`, `liveTranscript`, `activeTurnID`, `progress`, `pendingResolutionToken`, `isPlayingSample`, `regenerationStatus`. Actions: `start()`, `chooseRole(_:)`, `performCurrentTurn() async`, `retry()`, `pause()`, `resume()`, `continueRestoredAttempt()`, `switchRole()`, `playCurrentSample() async`, `requestNewConversation(from:) async`. `restore(conversation:storage:audio:)` trả session optional.

`ConversationLivePhase`: `.ready`, `.preparing(turnID:)`, `.partnerPlayback(turnID:)`, `.listening(turnID:)`, `.evaluating(turnID:)`, `.waitingToRetry(turnID:failure:)`, `.paused`, `.awaitingContinue`, `.completed`.

`ConversationLiveFailure`: `.readAgain`, `.noSpeech`, `.permissionDenied`, `.recognitionUnavailable`, `.captureFailed`, `.playbackFailed`.

- [ ] Chạy các test nháp để ghi RED hiện tại; lỗi type session thiếu được ghi nhận, không giả là test đã pass.
- [ ] Hoàn thiện tests đánh giá: câu đầy đủ, fuzzy spelling, contractions, im lặng, thiếu đầu/cuối, thiếu target, thêm/bớt phủ định. Một regression bắt buộc:

```swift
@Test func omittedTargetCannotPass() {
    let result = ConversationTurnEvaluator().evaluate(
        transcript: "We should closely today",
        target: "We should collaborate closely today",
        requiredTerms: ["collaborate"]
    )
    #expect(!result.isPassed)
}
```

- [ ] Hoàn thiện các test session đang có; bổ sung duplicate completion, stale partial, cuối vai còn partner, nghe mẫu không tiến bài, restore, đổi vai, thất bại thay mẫu giữ phiên. Fake audio có continuation chủ động do test điều khiển; không test bằng sleep tùy ý hoặc vòng `Task.yield()` không giới hạn.
- [ ] Triển khai session từ các contract trên. Dùng attempt token qua mọi `await`:

```swift
let token = pendingResolutionToken
let result = await audio.play(text: turn.english, locale: "en-US")
guard token == pendingResolutionToken, !Task.isCancelled else { return }
switch result {
case .finished: advance()
case .cancelled, .failed:
    phase = .waitingToRetry(turnID: turn.id, failure: .playbackFailed)
}
```

`advance()` là helper private: chuyển index, phát token mới, đặt preparing/partnerPlayback hoặc completed, lưu snapshot. Với capture, callback `onListening` mới đổi preparing → listening; `onPartial` chỉ đổi `liveTranscript`. Sau result, kiểm token, đặt evaluating, evaluate và advance hoặc waitingToRetry.
- [ ] `retry()` chỉ đổi waitingToRetry → preparing/partnerPlayback đúng vai của lượt. `pause()` đổi token trước, gọi `audio.stop()`, giữ index và persist. Không gọi lại capture ngay trong vòng retry.
- [ ] `playCurrentSample()` chỉ chạy ở ready/waitingToRetry, giữ nguyên phase/progress, đánh dấu `isPlayingSample`; generation guard bảo vệ cả callback mẫu. Kết thúc mẫu vẫn chờ thao tác người học.
- [ ] Restore với key live riêng; xác thực index/ID/vai so với script. Reopen luôn awaitingContinue trừ phiên đã hoàn tất hợp lệ. Không đọc key mock.
- [ ] Run `swift test --filter 'ConversationTurnEvaluatorTests|ConversationLiveSessionTests'`; kiểm GREEN. Review state transitions và commit chỉ các file thuộc task này.

**Checkpoint:** AC3–AC8 có test hành vi độc lập với microphone thật; chưa tuyên bố audio hoạt động trên máy.

## Task 2: Capture lifecycle có coordinator, cancellation và timer

**Files:**
- Complete: `VocabCraftApp/Features/Conversation/ConversationAudioAdapter.swift`
- Test: `VocabCraftAppTests/Features/ConversationAudioAdapterTests.swift`

**Interfaces:** Giữ `ConversationAudioClient` từ Task 1. Inject `ConversationSpeechRecognizing`, `ConversationSpeechPlaying`, `AudioSessionCoordinating`, `ConversationSleeping` và `ConversationCapturePolicy`. Recognizer cung cấp `requestAuthorization() async -> Bool`, `start(contextualPhrases:onPartial:onFinal:onError:) throws`, `stop()`.

- [ ] Kiểm tra các test nháp và thêm RED cho stop trong lúc chờ quyền, stop trong lúc acquire lease, callback cũ tới attempt mới, duplicated final, final theo sau error và transcript không đổi không kéo dài timer.
- [ ] Test phải điều khiển timer/authorization/lease bằng continuation có timeout test; khẳng định trạng thái quan sát được và release lease thực tế qua coordinator spy, không chỉ gọi fake rồi assert lại giá trị của fake.
- [ ] Implement capture theo thứ tự:

```swift
// Private operation generation changes on every start and stop.
let generation = operationGeneration
let authorized = await recognizer.requestAuthorization()
guard generation == operationGeneration, !Task.isCancelled else { return .cancelled }
guard authorized else { return .permissionDenied }
let lease = try await audioSessionCoordinator.acquire(.speechCapture)
// Re-check generation; if stale, release this exact lease and return cancelled.
```

Khi authorization đang chờ mà người học đóng bài, callback đến muộn không được acquire lease. Dừng player và đợi teardown trước khi acquire capture lease; chỉ sau đó mới start recognition. Continuation capture được resolve đúng một lần sau stop và release lease.
- [ ] On actual start, gọi `onListening`, arm initial/max timer. Transcript mới khác transcript cũ mới reset trailing timer; empty partial không hủy initial silence. Final hoặc trailing timer chốt transcript mới nhất. Maximum duration chốt transcript hoặc silence, luôn dừng capture.
- [ ] `stop()` tăng generation cả khi chưa có active capture, hủy timer/player/recognizer và resolve pending capture `.cancelled`. Cancellation handler chỉ được cleanup operation của nó.
- [ ] Run `swift test --filter ConversationAudioAdapterTests`; kiểm GREEN; review ordering/reentrancy, commit task.

**Checkpoint:** AC5–AC7 được chứng minh ở tầng adapter, không acquire capture trước quyền hoặc sau stop.

## Task 3: Nối SpeechKit và TTS thật, bảo toàn caller cũ

**Files:**
- Complete: `Packages/SpeechKit/Sources/SpeechKit/Engine/SpeechRecognitionEngine.swift`
- Complete: `VocabCraftApp/Core/Audio/TextToSpeechService.swift`
- Create/extract: `VocabCraftApp/Features/Conversation/ConversationLiveAudioClients.swift`
- Test: `VocabCraftAppTests/Features/ConversationPlaybackTests.swift`, `ConversationAudioAdapterTests.swift`
- Regression: `VocabCraftAppTests/Core/Audio/AudioSessionCoordinatorTests.swift`, `Packages/SpeechKit/Tests/SpeechKitTests/SpeechAssessmentServiceTests.swift`

**Interfaces:** `SpeechRecognitionEngine.init(locale: Locale, managesAudioSession: Bool = true)`. Live wrapper dùng `false`; caller cũ không đổi. `TextToSpeechService.speakWithCompletion(text:rate:locale:) async -> SpeechPlaybackCompletion` với `.finished/.cancelled/.failed`; `speakAsync` cũ giữ chữ ký/semantics. Giữ tên `speakWithCompletion` và `SpeechPlaybackCompletion` đã có trong draft; không thêm API outcome trùng vai trò.

- [ ] Viết RED cho completed/cancelled/timeout/lease failure và stale delegate của TTS. Test event completion thật qua seam/delegate điều khiển được; không dùng nhánh auto-success dưới XCTest làm bằng chứng playback hoàn tất.
- [ ] Outcome TTS chỉ `.finished` từ delegate didFinish đúng utterance; stop/didCancel → cancelled; timeout/audio acquire failure → failed. Dùng identity/generation qua callback; resolve continuation một lần và release lease trước return.
- [ ] Giữ API cũ bằng delegate vào outcome API rồi bỏ kết quả, nếu chứng minh không đổi behavior qua regression. Không áp timeout 8 giây hiện tại như success cho câu dài; timeout là lỗi phục hồi được, không tiến bài.
- [ ] Implement lifecycle opt-out tại cả configure **và** deactivate của engine:

```swift
if managesAudioSession {
    try configureAudioSession()
}
// stopInternal: only deactivate AVAudioSession when managesAudioSession is true.
```

- [ ] Wrapper `SpeechKitConversationRecognizer` chuyển callback về MainActor, map denied/unavailable/error chính xác; không lưu raw audio. Đưa target sentence đầu contextual phrases, rồi hints từ vựng. Default simulator recognition giả lập phải được caller biết để gắn nhãn.
- [ ] Run `swift test --filter 'ConversationPlaybackTests|ConversationAudioAdapterTests|AudioSessionCoordinatorTests'` và `swift test --package-path Packages/SpeechKit`; đối chiếu warnings mới, review, commit.

**Checkpoint:** AC2/AC6 được hỗ trợ bởi live clients; Speaking/Reflex cũ không mất default behavior.

## Task 4: UI live và entry lesson trên Home

**Files:**
- Create: `VocabCraftApp/Features/Conversation/ConversationLiveView.swift`, `ConversationLiveControls.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`, `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/Core/Localization/AppStrings+Conversation.swift`, `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`
- Reuse: `CraftConversationTurnView`, mock fixture/repository, scroll policy.

**Interfaces:** `AppContainer.makeConversationLiveSession(conversation: ConversationScript, storage: any ConversationSessionStorage) -> ConversationLiveSession`; factory dùng chính `audioSessionCoordinator` của container. `ConversationLiveView(onClose:)` nhận appContainer qua environment, load sample và restore bằng factory. Fixture/repository vẫn DEBUG-only.

- [ ] Viết tests cho factory dùng coordinator chung, lựa chọn key storage live và không tự chạy khi tạo session. Bổ sung regression cho sample-load failure; không tự fallback thành completed.
- [ ] Factory nối `TextToSpeechConversationPlayer`, `SpeechKitConversationRecognizer` và `ConversationAudioAdapter`; dùng cùng coordinator với app, không tạo coordinator độc lập cho bài này.
- [ ] Home Start mở `ConversationLiveView`; mock route riêng còn dùng `ConversationMockView`. Đăng ký file mới vào app/test targets; kiểm Release không chứa sample hoặc entry Debug.
- [ ] Drive phiên qua state-owned task:

```swift
.task(id: session.pendingResolutionToken) {
    await session.performCurrentTurn()
}
.onChange(of: scenePhase) { _, phase in
    if phase == .background { session.pause() }
}
.onDisappear { session.pause() }
```

`performCurrentTurn()` là no-op ngoài preparing/partnerPlayback và khi phát mẫu. Subscription interruption/route mất thiết bị gọi pause trên MainActor; tháo observer khi rời view. Trở về active không tự resume.
- [ ] Render mic preparing/listening theo trạng thái thực; stop action đi qua session. Hiển thị transcript với `Text(verbatim:)`, không auto-announce mỗi partial. Dùng CraftButton cho Retry, Nghe mẫu, Resume và Đóng.
- [ ] Thêm catalog EN/VI:

| Key | en | vi |
|---|---|---|
| `app.conversation.live.notice` | Sample dialogue • Listen and speak | Hội thoại mẫu • Nghe và nói |
| `app.conversation.live.preparing` | Preparing microphone… | Đang chuẩn bị micro… |
| `app.conversation.live.listening` | Your turn — read the highlighted line | Đến lượt bạn — hãy đọc câu được đánh dấu |
| `app.conversation.live.partner` | Listen to your partner | Nghe vai đối phương |
| `app.conversation.live.evaluating` | Checking your reading… | Đang kiểm tra câu đọc… |
| `app.conversation.live.permission` | Allow microphone and speech recognition in Settings, then try again. | Hãy cho phép micro và nhận dạng giọng nói trong Cài đặt, rồi thử lại. |
| `app.conversation.live.unavailable` | Speech recognition is unavailable. Please try again. | Nhận dạng giọng nói hiện không khả dụng. Vui lòng thử lại. |
| `app.conversation.live.capture_error` | Recording stopped unexpectedly. Please try again. | Quá trình thu âm bị gián đoạn. Vui lòng thử lại. |
| `app.conversation.live.playback_error` | The audio could not finish. Please try again. | Không thể phát hết câu. Vui lòng thử lại. |
| `app.conversation.live.hear_sample` | Hear sample | Nghe mẫu |
| `app.conversation.live.open_settings` | Open Settings | Mở Cài đặt |
| `app.conversation.live.another_sample` | Another sample dialogue | Hội thoại mẫu khác |

Reuse keys noSpeech/retry/start/continue đã có nếu nội dung phù hợp. Simulator dùng notice mô phỏng hiện có. `UIApplication.openSettingsURLString` chỉ gọi khi người dùng bấm Mở Cài đặt, không tự mở.
- [ ] Run focused session/home/localization tests, `swiftlint --quiet --no-cache`; dùng XcodeBuildMCP build/run Debug và inspect Home → Start → role → trạng thái → Close, Dynamic Type và VoiceOver. Self-review và commit UI/membership/catalog.

**Checkpoint:** AC1/AC7/AC8/AC9. Không khẳng định nhận dạng thật dựa trên simulator.

## Task 5: Kiểm chứng đầy đủ và bàn giao bản trên Hooji

**Files:** Create `docs/validation/conversation-live-audio.md`; bổ sung regression đúng file khi gặp lỗi thực tế.

- [ ] Run từng lệnh, lưu đầy đủ output và kiểm exit code:

```bash
swift test --filter Conversation
swift test --package-path Packages/CraftUIKit --filter LocalizationTests
swift test --package-path Packages/CraftUIKit
swift test --package-path Packages/SpeechKit
swift test
swiftlint --quiet --no-cache
git diff --check
```

- [ ] Gọi XcodeBuildMCP `session_show_defaults`, xác nhận workspace/scheme/Debug; dùng `list_devices` để lấy Hooji hiện tại, không giả định UDID cũ luôn đúng. Run full `test_sim` và kiểm số pass/fail cùng diagnostics.
- [ ] Build Release và kiểm bundle không chứa sample; trả defaults về Debug trước khi build thiết bị.
- [ ] `build_device` → `get_device_app_path` → `install_app_device` → `launch_app_device` không có launch flag mock. Nếu iPhone khóa, yêu cầu người dùng mở khóa; không coi build thành công là cài/chạy thành công.
- [ ] Thử máy thật với user: vai B nghe partner trước; vai A nói ngay; nói trọn câu, bỏ cuối câu, bỏ target, nói lệch nhẹ, im lặng, pause/close giữa câu. Ghi expected/observed của từng ca, không ghi “pass” nếu chưa quan sát hoặc chưa được người dùng xác nhận.
- [ ] Kiểm quyền bị từ chối, Settings rồi Retry, interruption/background/foreground, loa và tai nghe. Mỗi khi phát hiện lỗi, thêm regression trước khi sửa và chạy lại nhóm bị ảnh hưởng.
- [ ] Ghi false acceptance/false retry từ câu đọc thực, điều chỉnh policy cấu hình nếu cần. Không công bố threshold đã calibrated chỉ từ transcript unit tests.
- [ ] Đối chiếu tất cả AC1–AC10 và ghi trạng thái. Review độc lập spec compliance và code quality; sửa findings quan trọng, scoped re-review. Kiểm diff metadata Xcode, commit đúng file, giữ nhánh riêng nếu chưa được yêu cầu merge/push.

**Checkpoint cuối:** phân biệt ba kết quả: test/build đã pass; đã cài/chạy trên Hooji; hành vi audio thực đã được nghiệm thu. Các warning baseline và ca device chưa kiểm phải ghi rõ. Không merge hoặc phát hành như một tính năng production đã xong khi API/calibration/quality gate còn thiếu.

## Kiểm tra nhất quán của tài liệu

| Spec | Task |
|---|---|
| Luồng role/progress/retry/sample/restore | 1, 4 |
| Độ phủ, fuzzy, phủ định và end-of-utterance | 1, 2 |
| Audio leases, callback cũ, quyền và interruption | 2, 3, 4 |
| UI, bilingual, Settings, Home entry | 4 |
| Debug isolation, hồi quy, device và calibration | 3, 5 |

Tài liệu này chỉ lập kế hoạch. Không tự khởi động các task sau khi viết xong; chờ yêu cầu triển khai tiếp theo của người dùng.
