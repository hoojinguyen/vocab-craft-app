# AI Speaking Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thay toàn bộ AI Assistant cũ bằng module Speaking: gọi thoại realtime với Gemini Live, phân tích sau buổi bằng Gemini Flash, lưu SwiftData V4, Sổ cụm từ; giọng đọc toàn app chỉ còn Apple.

**Architecture:** Gỡ code cũ trước (Task 1–2) để app luôn build được, rồi dựng từ dưới lên: domain thuần → giao thức Live + transport → audio → reducer trạng thái → controller cuộc gọi → lưu trữ → analyzer → UI → wiring. Engine cuộc gọi không biết sư phạm; blueprint và analyzer giữ logic học.

**Tech Stack:** Swift 5.10 (StrictConcurrency), SwiftUI Observation, SwiftData, AVFoundation (`AVAudioEngine` voice processing, `AVAudioConverter`, `AVAudioFile` AAC), `URLSessionWebSocketTask`, `NWPathMonitor`, Swift Testing, CraftUIKit, SpeechKit.

**Spec:** `docs/superpowers/specs/2026-10-27-ai-speaking-rebuild-design.md` (đã duyệt 2026-10-27, có quyết định bổ sung số 9).

## Global Constraints

- Đối tượng learner A2–B1; AI chỉ nói tiếng Anh; tiếng Việt chỉ trong gợi ý và phần giải thích feedback.
- Một provider: Gemini. Live model `gemini-3.8-live`, analyzer model `gemini-3.8-flash`, giọng Live `Kore`. Key lấy từ `UserSettingsStore.geminiApiKey` (giữ nguyên nơi lưu).
- Live endpoint: `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=<KEY>`. Audio vào `audio/pcm;rate=16000` (PCM16 LE mono 16 kHz, base64), audio ra PCM16 LE 24 kHz.
- Analyzer endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent`, header `x-goog-api-key`, audio inline `audio/m4a`, request ≤ 20 MB, timeout 60 giây.
- Thời lượng buổi 360 giây; nhắc chào kết khi còn 30 giây; ngắt cứng tại 390 giây.
- Nối lại tối đa 1 lần, chờ tối đa 8 giây.
- Thang điểm số nguyên 1–5; giới hạn corrections ≤ 5, naturalPhrasings ≤ 3, pronunciation ≤ 3, targetWords ≤ 3. Buổi có < 2 lượt learner → `tooShort`.
- Audio giữ cho 20 buổi gần nhất; phân tích giữ vĩnh viễn. Không ghi ngược SRS.
- Không fallback ngầm; mọi lỗi hiển thị bằng key `app.speaking.*` đủ EN/VI, `extractionState: manual`, `state: translated`, format specifier khớp.
- CraftUIKit-first, chỉ dùng token (`theme.colors`, `theme.spacing`, …); không thêm component vào CraftUIKit trong plan này. Cần component mới → dừng và hỏi người dùng.
- Mọi file Swift mới/bị xoá phải được cập nhật membership trong `VocabCraftApp.xcodeproj/project.pbxproj` (project không dùng synchronized groups). Chỉnh hẹp; không chạy generator.
- TDD từng task; commit theo phạm vi task, kết thúc message bằng `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Không commit metadata Xcode bất ngờ (xcuserstate, scheme) — báo người dùng theo AGENTS.md §6.

## Review Focus

1. Learner nói chen liên tục khi AI đang nói (nhiều `interrupted` liên tiếp): hàng phát bị xả mỗi lần, không phát lại audio cũ, transcript AI không bị dồn vào một lượt — Task 7 và Task 10.
2. Mạng rớt hai lần trong một buổi: chỉ thử nối lại một lần; lần rớt thứ hai kết thúc `connectionLost` và vẫn lưu các lượt đã có — Task 8.
3. Gián đoạn âm thanh (cuộc gọi đến) xảy ra đúng lúc đang `reconnecting`: kết thúc một lần duy nhất, không finalize hai lần — Task 8.
4. Câu trích trong kết quả phân tích khác kiểu dấu (`I’m` vs `I'm`), hoa/thường, dấu câu: vẫn khớp; câu không có trong lời learner bị loại — Task 11.
5. Bấm "Phân tích lại" hoặc "Lưu cụm từ" hai lần liên tiếp: chỉ một phân tích chạy, cụm từ không trùng — Task 4, Task 12 và Task 16.

## Cách chạy và xác minh

- Ở execution time dùng superpowers:using-git-worktrees (hoặc làm trên branch `feat/ai-speaking-rebuild` hiện tại nếu người dùng chọn); chạy baseline trước Task 1 và ghi lại lỗi sẵn có.
- `swift test --filter <SuiteName>` — suite phải chạy ≥ 1 test, exit 0, không warning.
- `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`.
- `xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator' build` — 0 error, 0 warning.
- `xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftAppTests -destination 'platform=iOS Simulator,id=<UUID>' test` — lấy UUID thật từ `xcrun simctl list devices available`.
- `swiftlint --strict`.
- Lệnh có pipe phải bật `set -o pipefail`; log và xcresult ghi ra `$TMPDIR`, không vào repo.

## File map

`D` = `VocabCraftApp/Domain/Speaking`, `S` = `VocabCraftApp/Data/Speaking`, `F` = `VocabCraftApp/Features/Speaking`, `T` = `VocabCraftAppTests/Speaking`.

| Nhóm | File | Trách nhiệm |
|---|---|---|
| D | `SpeakingModels.swift` | Blueprint, level, kind, plan, turn, snapshot, status, end reason, saved phrase |
| D | `SpeakingAnalysis.swift` | Kết quả phân tích Codable |
| D | `SpeakingPromptBuilder.swift` | System instruction, các lượt text ẩn |
| D | `SpeakingCallState.swift` | Reducer thuần trạng thái cuộc gọi |
| D | `SpeakingRepositoryProtocol.swift`, `SpeakingAnalyzing.swift` | Hợp đồng lưu trữ và phân tích |
| D | `AnalyzeSpeakingSessionUseCase.swift` | Phân tích idempotent |
| S | `SpeakingBlueprintCatalog.swift`, `SpeakingWordPicker.swift` | Nội dung biên soạn, chọn từ đã học |
| S | `Live/LiveClientMessage.swift`, `Live/LiveServerEvent.swift`, `Live/LiveTransport.swift`, `Live/URLSessionLiveTransport.swift` | Giao thức Live |
| S | `Audio/PCMConverter.swift`, `Audio/SpeakingAudioIO.swift`, `Audio/VoiceProcessingAudioIO.swift`, `Audio/LearnerRecorder.swift`, `Audio/SpeakingAudioStorage.swift` | Mic/loa, ghi âm, lưu file |
| S | `TranscriptAssembler.swift` | Ghép lượt |
| S | `Analysis/SpeakingAnalysisRequestBuilder.swift`, `Analysis/SpeakingAnalysisValidator.swift`, `Analysis/GeminiSpeakingAnalyzer.swift` | Phân tích sau buổi |
| S | `SpeakingModelActor.swift` | Repository SwiftData |
| F | `SpeakingCallController.swift` | Điều phối cuộc gọi (@MainActor @Observable) |
| F | `SpeakingHubViewModel.swift`, `SpeakingResultViewModel.swift`, `SpeakingPrecheck.swift` | View model |
| F | `Views/SpeakingHubView.swift`, `Views/SpeakingPrepareView.swift`, `Views/SpeakingCallView.swift`, `Views/SpeakingResultView.swift`, `Views/SpeakingPhrasebookView.swift`, `SpeakingRoute.swift` | UI |
| DB | `Core/Database/Schemas/AppSchemaV4.swift`, `SharedAppGroupContainer.swift`, `SwiftDataModels.swift` | Schema V4 + migration |
| Strings | `Core/Localization/AppStrings+Speaking.swift`, `Resources/Localizable.xcstrings` | Chuỗi `app.speaking.*` |
| Audio app | `Core/Audio/TextToSpeechService.swift`, `Domain/Entities/VoiceProfile.swift`, `Data/Audio/VoiceProfileCatalog.swift`, `Features/Settings/Views/VoicePickerSheet.swift` | TTS chỉ Apple |

Thứ tự: 1 → 2 → 3 → 4 → (5, 6, 7 song song được) → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18.

---

### Task 1: Gỡ AI Assistant, Guided Practice, AI Pack và LLM provider

**Files:**
- Delete (toàn bộ thư mục): `VocabCraftApp/Features/AIAssistant/`, `VocabCraftApp/Data/AI/`, `VocabCraftApp/Data/AIPacks/`, `VocabCraftApp/Data/GuidedPractice/`, `VocabCraftApp/Core/AI/`, `VocabCraftApp/Domain/Models/GuidedPractice/`, `VocabCraftApp/Domain/Policies/GuidedPractice/`, `VocabCraftApp/Domain/UseCases/GuidedPractice/`, `VocabCraftAppTests/AI/` (gồm `GuidedPractice/` và fixture).
- Delete: `Core/Configuration/GuidedPracticeFeatureConfiguration.swift`, `Core/Localization/AppStrings+GuidedPractice.swift`, `Domain/Models/AIPackIdentifier.swift`, `AIPackError.swift`, `AIPackStatus.swift`, `Domain/Protocols/LLMProviderProtocol.swift`, `AIPackProtocol.swift`, `VoiceConversationEngineProtocol.swift`, `STTEngineProtocol.swift`, `TTSEngineProtocol.swift`, `PracticeAIProtocol.swift`, `PracticeSpeechProtocol.swift`, `PracticeRepositoryProtocol.swift`, `Domain/UseCases/FetchRoleplayScenariosUseCase.swift`, `ExecuteRoleplayTurnUseCase.swift`, `CompleteRoleplaySessionUseCase.swift`, `Domain/Entities/RoleplayScenario.swift`, `RoleplayTurnOutput.swift`, `RoleplayMessage.swift`, `RoleplaySessionSummary.swift`, `Data/Audio/Engines/` (cả 5 adapter), `Data/Repositories/MockPracticeRepository.swift`, `VocabCraftAppTests/App/AppContainerAITests.swift`.
- Modify: `App/DI/AppContainer.swift` (bỏ `practiceRepository`, `aiPackRegistry`, `llmProvider`, các factory Roleplay/Practice/AIAssistant, `makeDefaultAIPackRegistry`), `Domain/UseCases/ResetUserProgressUseCase.swift` (bỏ tham số `practiceRepository`), `App/VocabCraftApp.swift` (bỏ các nhánh `-show-roleplay-room`, `-show-voice-call`, `-show-roleplay-summary`, `-show-ai-config`, `-show-ai-hub`), `Features/Homepage/Views/HomepageView.swift` (tab `.aiAssistant` tạm hiển thị `SpeakingHubPlaceholderView`), `Core/Database/UserSettingsStore.swift` (bỏ `selectedAIPackId`), `Package.swift` (bỏ resource `AI/GuidedPractice/Fixtures/practice-assessment-cases.json`), `project.pbxproj`, `Resources/Localizable.xcstrings` (xoá key `app.ai_assistant.*`, `app.ai_pack.*` không còn tham chiếu).
- Create: `F/Views/SpeakingHubPlaceholderView.swift` — `CraftCard` với tiêu đề `app.speaking.hub.title` và mô tả `app.speaking.hub.coming_soon` (EN "Speaking practice is being rebuilt." / VI "Tính năng luyện nói đang được xây lại."). Task 14 xoá file này.

**Ghi chú:** `Core/Database/Schemas/AppSchemaV3.swift` và các typealias `Practice*Record` trong `SwiftDataModels.swift` **giữ nguyên** — V3 cần cho lịch sử migration; Task 4 xử lý. Các type `Practice*Payload` mà V3 tham chiếu, nếu nằm trong thư mục bị xoá, chuyển vào cuối `AppSchemaV3.swift` dưới dạng `fileprivate`/nested trong `SchemaV3` thay vì xoá. Settings vẫn còn tham chiếu `RoleplayVoiceProfile*`, `AIConfigSheet`, `AIPackStatus`, `OnDemandAIModelManager`: chuyển `RoleplayVoiceProfile.swift` và `RoleplayVoiceProfileCatalog.swift` tạm sang `Domain/Entities`/`Data/Audio`, và tạm bỏ `SettingsAICard` khỏi `SettingsView` (Task 2 thay bằng hàng nhập key). `OnDemandAIModelManager` giữ đến Task 2.

- [ ] **Step 1: Ghi baseline** — chạy full Xcode test + build, lưu kết quả vào `$TMPDIR/baseline.log`.
- [ ] **Step 2: Xoá file theo danh sách, cập nhật pbxproj.**
- [ ] **Step 3: Sửa các file Modify cho đến khi `xcodebuild … VocabCraftApp build` đạt 0 error, 0 warning.**
- [ ] **Step 4: Kiểm tra không còn tham chiếu**

Run: `grep -rnwE "Roleplay(Scenario|Room|VoiceCall|Summary)|AIPack|LLMProvider|PracticeSessionCoordinator|GuidedPractice" VocabCraftApp VocabCraftAppTests VocabCraftWidgetExtension --include='*.swift' | grep -v Schemas/AppSchemaV3.swift`
Expected: không có dòng nào.

- [ ] **Step 5: Chạy full test suite và LocalizationTests** — Expected: pass, số test giảm đúng bằng số test đã xoá; ghi số liệu vào commit message.
- [ ] **Step 6: Commit** — `refactor(ai): remove legacy AI assistant, guided practice and AI packs`.

### Task 2: Giọng đọc toàn app chỉ Apple, Settings nhập Gemini key

**Files:**
- Rename: `RoleplayVoiceProfile` → `VoiceProfile` (`Domain/Entities/VoiceProfile.swift`), `RoleplayVoiceProfileCatalog` → `VoiceProfileCatalog` (`Data/Audio/VoiceProfileCatalog.swift`), `RoleplayVoicePickerSheet` → `VoicePickerSheet` (`Features/Settings/Views/VoicePickerSheet.swift`, nếu Task 1 đã xoá file thì dựng lại tối giản bằng `CraftListRow` + `CraftBottomSheet`).
- Modify: `Core/Audio/TextToSpeechService.swift`, `Domain/Protocols/AudioServiceProtocols.swift`, `Features/Settings/Views/SettingsView.swift`, `Features/Settings/ViewModels/SettingsViewModel.swift`, `Core/Database/UserSettingsStore.swift`.
- Delete: `Core/Audio/GeminiAudioSpeechEngine.swift`, `KokoroTTSEngine.swift`, `KokoroInferenceWorker.swift`, `OnDemandAIModelManager.swift`, `WhisperKitSpeechEngine.swift` và test tương ứng trong `VocabCraftAppTests/Core/Audio/` (`GeminiAudioSpeechEngineTests`, `KokoroTTSEngineTests`, `WhisperKitSpeechEngineTests`, `OnDemandAIModelManagerTests`, `SmartVoiceRouterTests` nếu chỉ kiểm engine bị xoá).
- Create: `Features/Settings/Views/SettingsGeminiKeyCard.swift`.
- Test: `VocabCraftAppTests/Core/Audio/VoiceProfileCatalogTests.swift`, `VocabCraftAppTests/SettingsViewModelTests.swift` (bổ sung).

**Interfaces:**
- Produces: `VoiceProfileCatalog.profiles: [VoiceProfile]` (chỉ `systemAuto` + 7 giọng `.appleEnhanced` hiện có); `VoiceProfileCatalog.defaultProfile`; `VoiceProfileCatalog.resolve(id: String) -> VoiceProfile` (id lạ → `defaultProfile`). `VoiceEngineType` chỉ còn `.system`, `.appleEnhanced`. `VoiceProfile` bỏ `geminiPersona`.
- `UserSettingsStore`: đổi tên thuộc tính `roleplayVoiceId/roleplaySpeechRate/roleplaySpeechPitch` → `voiceProfileId/speechRate/speechPitch`, **giữ nguyên** storage key `roleplay_voice_id`, `roleplay_speech_rate`, `roleplay_speech_pitch` để không mất cài đặt.
- `TextToSpeechService.init(audioSessionCoordinator:settingsStore:appleEngine:)`; bỏ `ActiveEngineType.gemini/.kokoro`, `resolvedApiKey`, mọi nhánh Gemini/Kokoro.

- [ ] **Step 1: Viết test thất bại**

```swift
@Suite("Voice profile catalog") struct VoiceProfileCatalogTests {
    @Test func containsOnlyAppleVoices() {
        #expect(VoiceProfileCatalog.profiles.allSatisfy { $0.engine == .system || $0.engine == .appleEnhanced })
        #expect(VoiceProfileCatalog.profiles.count == 8)
    }
    @Test func unknownLegacyIdFallsBackToAuto() {
        #expect(VoiceProfileCatalog.resolve(id: "gemini_kore").id == VoiceProfileCatalog.defaultProfile.id)
        #expect(VoiceProfileCatalog.resolve(id: "kokoro_af_heart").id == "systemAuto")
    }
}
```

Bổ sung `SettingsViewModelTests`: `@Test func legacyVoiceKeysAreReadAfterRename()` — đặt `roleplay_speech_rate = 1.1` vào `UserDefaults` suite riêng, khởi tạo `UserSettingsStore`, `#expect(store.speechRate == 1.1)`.

- [ ] **Step 2: Chạy `swift test --filter VoiceProfileCatalogTests`** — Expected: FAIL (type chưa tồn tại).
- [ ] **Step 3: Thực hiện rename, lọc catalog, rút gọn TTS** — `previewVoice(profile:rate:pitch:)` và `playProfileIfConfigured` chỉ còn nhánh Apple; `performTestingProfilePlayback` bỏ nhánh Gemini/Kokoro.
- [ ] **Step 4: Settings** — `SettingsAudioCard` bỏ subtitle chất lượng Gemini/Kokoro và alert tải model; `aiSection` dùng `SettingsGeminiKeyCard`: `CraftCard` + `CraftTextField` dạng secure, nhãn `app.settings.gemini_key.title`, mô tả `app.settings.gemini_key.caption` (EN "Used for AI speaking practice. Stored on this device." / VI "Dùng cho luyện nói với AI. Chỉ lưu trên máy này."), binding `store.geminiApiKey`. Xoá key xcstrings `app.settings.voice_quality_gemini`, `…_kokoro`, `voice_preview_needs_download`, `voice_preview_download_action` nếu không còn dùng.
- [ ] **Step 5: Chạy test** — `swift test --filter VoiceProfileCatalogTests`, `--filter SettingsViewModelTests`, full Xcode build. Expected: PASS, 0 warning.
- [ ] **Step 6: Commit** — `refactor(audio): keep app speech on Apple voices only`.

### Task 3: Domain Speaking — model, phân tích, prompt

**Files:**
- Create: `D/SpeakingModels.swift`, `D/SpeakingAnalysis.swift`, `D/SpeakingPromptBuilder.swift`.
- Test: `T/SpeakingPromptBuilderTests.swift`, `T/SpeakingModelsCodableTests.swift`.

**Interfaces (Produces):**

```swift
public enum SpeakingSessionKind: String, Codable, Sendable { case scenario, topic }
public enum SpeakingLevel: String, Codable, Sendable, CaseIterable { case a2, b1 }
public struct SpeakingBlueprint: Codable, Sendable, Hashable, Identifiable {
    public let id: String; public let kind: SpeakingSessionKind
    public let titleKey: String; public let briefKey: String       // app.speaking.blueprint.<id>.title/brief
    public let aiRole: String; public let setting: String; public let objective: String? // tiếng Anh, chỉ cho prompt
    public let durationSeconds: Int                                  // mặc định 360
}
public struct SpeakingTargetWord: Codable, Sendable, Hashable { public let wordId: Int64; public let lemma: String; public let definitionVi: String }
public struct SpeakingSessionPlan: Codable, Sendable, Hashable { public let blueprint: SpeakingBlueprint; public let level: SpeakingLevel; public let targetWords: [SpeakingTargetWord] }
public enum SpeakingSpeaker: String, Codable, Sendable { case ai, learner }
public struct SpeakingTurn: Codable, Sendable, Equatable { public var index: Int; public var speaker: SpeakingSpeaker; public var text: String; public var startOffset: TimeInterval; public var endOffset: TimeInterval? }
public enum SpeakingSessionStatus: String, Codable, Sendable { case pendingAnalysis, analyzed, analysisFailed, tooShort }
public enum SpeakingEndReason: String, Codable, Sendable { case learnerEnded, aiEnded, timeLimit, interrupted, connectionLost }
public struct SpeakingSessionSnapshot: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID; public let plan: SpeakingSessionPlan; public let startedAt: Date; public let duration: TimeInterval
    public var status: SpeakingSessionStatus; public let endReason: SpeakingEndReason; public let hintCount: Int
    public var audioFileName: String?; public let turns: [SpeakingTurn]; public var analysis: SpeakingAnalysis?
    public var learnerTurnCount: Int { turns.filter { $0.speaker == .learner }.count }
}
public enum SavedPhraseSource: String, Codable, Sendable { case correction, naturalPhrasing }
public struct SavedPhrase: Codable, Sendable, Equatable, Identifiable { public let id: UUID; public let original: String; public let suggestion: String; public let note: String; public let sessionId: UUID; public let source: SavedPhraseSource; public let createdAt: Date }
```

`SpeakingAnalysis` (Codable, Equatable, Sendable), khoá JSON camelCase đúng như sau — Task 12 dùng làm `responseSchema`:

```swift
public struct SpeakingAnalysis {
    public struct LearnerLine { public let turnIndex: Int; public let text: String }
    public struct Score { public let value: Int; public let reason: String }
    public struct Scores { public let fluency: Score; public let grammar: Score; public let vocabulary: Score; public let pronunciation: Score }
    public enum CorrectionCategory: String { case grammar, wordChoice, other }
    public struct Correction { public let turnIndex: Int; public let original: String; public let corrected: String; public let category: CorrectionCategory; public let explanation: String }
    public struct NaturalPhrasing { public let original: String; public let natural: String; public let note: String }
    public struct PronunciationNote { public let word: String; public let issue: String; public let tip: String }
    public struct TargetWordUse { public let lemma: String; public let used: Bool; public let usedCorrectly: Bool; public let quote: String? }
    public struct Objective { public let met: Bool; public let note: String }
    public struct Summary { public let strengths: [String]; public let focusNext: [String] }
    public let learnerTranscript: [LearnerLine]; public let scores: Scores
    public let corrections: [Correction]; public let naturalPhrasings: [NaturalPhrasing]
    public let pronunciation: [PronunciationNote]; public let targetWords: [TargetWordUse]
    public let objective: Objective?; public let summary: Summary
}
```

`SpeakingPromptBuilder`: `static func systemInstruction(for plan: SpeakingSessionPlan) -> String`; `static let openingTrigger: String`; `static let hintRequest: String`; `static let wrapUpRequest: String`. System instruction phải chứa: vai `aiRole`, `setting`, `objective` (nếu có), mô tả level (A2: "short simple sentences, common everyday words, speak slowly"; B1: "natural everyday English, moderate pace, some idioms explained by context"), quy tắc "Speak only English. Never correct the learner during the conversation. Ask one question at a time. Keep each reply under 3 sentences.", danh sách từ mục tiêu (nếu có) kèm "create natural chances for the learner to use these words; never say them first", và "When the objective is complete or the learner says goodbye, say a short goodbye and call end_session." `hintRequest` yêu cầu một gợi ý ngắn, cho phép tiếng Việt, rồi chờ learner. `wrapUpRequest` yêu cầu chào kết trong một câu và gọi `end_session`.

- [ ] **Step 1: Viết test thất bại**

```swift
@Suite("Speaking prompt builder") struct SpeakingPromptBuilderTests {
    @Test func a2PromptContainsLevelRoleAndNoCorrectionRule() {
        let prompt = SpeakingPromptBuilder.systemInstruction(for: .fixture(level: .a2))
        #expect(prompt.contains("short simple sentences"))
        #expect(prompt.contains("Never correct the learner"))
        #expect(prompt.contains("barista"))
        #expect(!prompt.contains("Target words"))
    }
    @Test func targetWordsAppearOnlyWhenSelected() {
        let prompt = SpeakingPromptBuilder.systemInstruction(for: .fixture(level: .b1, words: ["recommend", "decaf"]))
        #expect(prompt.contains("Target words: recommend, decaf"))
        #expect(prompt.contains("never say them first"))
    }
    @Test func promptSnapshotIsStable() { /* so sánh với T/Fixtures/prompt-cafe-a2.txt */ }
}
```

`SpeakingModelsCodableTests`: decode `T/Fixtures/analysis-valid.json` thành `SpeakingAnalysis` và encode-decode round-trip `SpeakingSessionSnapshot`. Thêm `.copy("Speaking/Fixtures")` vào resources của test target trong `Package.swift`.

- [ ] **Step 2: Chạy `swift test --filter SpeakingPromptBuilderTests`** — Expected: FAIL.
- [ ] **Step 3: Implement ba file; `SpeakingSessionPlan.fixture(level:words:)` đặt trong `T/SpeakingFixtures.swift` (blueprint cafe, aiRole "a friendly barista").**
- [ ] **Step 4: Chạy lại hai suite** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(speaking): add speaking domain models and prompt builder`.

### Task 4: Schema V4 và SpeakingModelActor

**Files:**
- Create: `Core/Database/Schemas/AppSchemaV4.swift`, `S/SpeakingModelActor.swift`, `D/SpeakingRepositoryProtocol.swift`.
- Modify: `SharedAppGroupContainer.swift` (schemas thêm `SchemaV4`, stage `.lightweight(fromVersion: SchemaV3.self, toVersion: SchemaV4.self)`, cả hai chỗ `Schema(versionedSchema: SchemaV3.self)` → `SchemaV4`), `SwiftDataModels.swift` (typealias trỏ sang `SchemaV4`, xoá typealias `Practice*Record`, thêm `SpeakingSessionRecord`, `SavedPhraseRecord`).
- Test: `T/SpeakingRepositoryTests.swift`, `VocabCraftAppTests/Core/SchemaV4MigrationTests.swift`.

**Interfaces:**
- `SchemaV4.models` = 5 model V2/V3 không thuộc Practice (`UserWordProgress`, `UserStageProgress`, `ReflexSessionLog`, `WidgetCurrentState`, `QuickReflexAttemptRecord`) + `SchemaV4.SpeakingSessionRecord` + `SchemaV4.SavedPhraseRecord`. Version `Schema.Version(4, 0, 0)`.
- `SpeakingSessionRecord`: `@Attribute(.unique) id: UUID`, `startedAt: Date`, `status: String`, `audioFileName: String?`, `payload: Data` (JSON của `SpeakingSessionSnapshot`), cột phẳng `fluency: Int?`, `grammar: Int?`, `vocabulary: Int?`, `pronunciation: Int?`.
- `SavedPhraseRecord`: `@Attribute(.unique) id: UUID`, `dedupeKey: String` (`suggestion` đã chuẩn hoá bằng `QuoteNormalizer.normalize` — Task 11; trong task này dùng tạm `lowercased()` + trim, Task 12 thay), `payload: Data`, `createdAt: Date`.

```swift
public protocol SpeakingRepositoryProtocol: Sendable {
    func save(_ session: SpeakingSessionSnapshot) async throws               // upsert theo id
    func session(id: UUID) async throws -> SpeakingSessionSnapshot?
    func sessions(limit: Int?) async throws -> [SpeakingSessionSnapshot]     // mới nhất trước
    func updateAnalysis(sessionId: UUID, status: SpeakingSessionStatus, analysis: SpeakingAnalysis?) async throws
    func savePhrase(_ phrase: SavedPhrase) async throws -> Bool              // false nếu trùng dedupeKey
    func phrases() async throws -> [SavedPhrase]
    func deletePhrase(id: UUID) async throws
    func detachAudio(keepingLatest count: Int) async throws -> [String]      // nil hoá audioFileName của buổi cũ, trả tên file để xoá
}
```

`SpeakingModelActor` là `@ModelActor actor` theo mẫu `UserProgressModelActor`.

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func updateAnalysisFlattensScoresAndIsIdempotent() async throws {
    let repo = try SpeakingModelActor.inMemory()
    try await repo.save(.fixture(id: sid, status: .pendingAnalysis))
    try await repo.updateAnalysis(sessionId: sid, status: .analyzed, analysis: .fixtureScores(3, 2, 4, 3))
    try await repo.updateAnalysis(sessionId: sid, status: .analyzed, analysis: .fixtureScores(3, 2, 4, 3))
    let all = try await repo.sessions(limit: nil)
    #expect(all.count == 1 && all[0].status == .analyzed && all[0].analysis?.scores.grammar.value == 2)
}
@Test func savePhraseRejectsDuplicateSuggestion() async throws {
    #expect(try await repo.savePhrase(.fixture(suggestion: "I'd like a latte")) == true)
    #expect(try await repo.savePhrase(.fixture(suggestion: "  I'd like a latte ")) == false)
    #expect(try await repo.phrases().count == 1)
}
@Test func detachAudioKeepsLatestTwenty() async throws {
    // lưu 22 buổi có audioFileName "s<i>.m4a" với startedAt tăng dần
    let removed = try await repo.detachAudio(keepingLatest: 20)
    #expect(Set(removed) == ["s0.m4a", "s1.m4a"])
    #expect(try await repo.sessions(limit: nil).filter { $0.audioFileName != nil }.count == 20)
}
```

`SchemaV4MigrationTests.v3StoreWithPracticeDataMigratesAndKeepsProgress`: tạo store V3 trên file tạm (seed một `UserWordProgress` wordId 101 + một `PracticeSessionRecord`), mở lại bằng `ModelContainer(for: Schema(versionedSchema: SchemaV4.self), migrationPlan: AppMigrationPlan.self, …)`, `#expect` `UserWordProgress` 101 còn nguyên `masteryLevel`/`nextReviewDate`, và fetch `SpeakingSessionRecord` trả về rỗng.

- [ ] **Step 2: Chạy `swift test --filter SpeakingRepositoryTests`** — Expected: FAIL.
- [ ] **Step 3: Implement schema, migration, actor.**
- [ ] **Step 4: Chạy `SpeakingRepositoryTests`, `SchemaV4MigrationTests`, `SwiftDataModelsTests`, `UserProgressModelActorConcurrencyTests`, widget tests** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(speaking): add schema v4 with speaking sessions and phrasebook`.

### Task 5: Catalog blueprint và chọn từ đã học

**Files:**
- Create: `S/SpeakingBlueprintCatalog.swift`, `S/SpeakingWordPicker.swift`.
- Modify: `Resources/Localizable.xcstrings` (title/brief cho mỗi blueprint).
- Test: `T/SpeakingBlueprintCatalogTests.swift`, `T/SpeakingWordPickerTests.swift`.

**Interfaces:**
- `enum SpeakingBlueprintCatalog { static let all: [SpeakingBlueprint]; static func blueprint(id: String) -> SpeakingBlueprint? }` — 6 scenario (`cafe_order`, `hotel_checkin`, `ask_directions`, `doctor_visit`, `job_interview_intro`, `return_item_shop`) và 6 topic (`topic_daily_routine`, `topic_travel`, `topic_work_study`, `topic_movies_music`, `topic_food`, `topic_weekend_plans`). Scenario có `objective`, topic có `objective = nil`. Tất cả `durationSeconds = 360`.
- `struct SpeakingWordPicker { init(progressRepository: any UserProgressRepositoryProtocol, vocabulary: any VocabularyDataSourceProtocol); func pick(limit: Int = 3) async throws -> [SpeakingTargetWord] }` — lọc `totalReviews > 0 || masteryLevel > 0`, sắp theo `masteryLevel` tăng dần, rồi `mistakeCount` giảm dần, rồi `lastReviewDate` tăng dần; lấy `limit` từ mà `fetchWordsByIds` resolve được (bỏ từ không resolve).

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func everyBlueprintHasLocalizedTitleAndBriefInBothLanguages() { /* đọc xcstrings từ bundle, kiểm en + vi cho titleKey/briefKey */ }
@Test func idsAreUniqueAndScenariosHaveObjectives() {
    #expect(Set(SpeakingBlueprintCatalog.all.map(\.id)).count == 12)
    #expect(SpeakingBlueprintCatalog.all.filter { $0.kind == .scenario }.allSatisfy { $0.objective != nil })
}
@Test func pickerExcludesBookmarkOnlyAndOrdersWeakestFirst() async throws {
    // progress: 1 (mastery 0, reviews 0, bookmarked) · 2 (mastery 3) · 3 (mastery 1, mistakes 4) · 4 (mastery 1, mistakes 1) · 5 (mastery 0, reviews 2, không resolve)
    #expect(try await picker.pick().map(\.wordId) == [3, 4, 2])
}
```

- [ ] **Step 2: Chạy hai suite** — Expected: FAIL.
- [ ] **Step 3: Implement + thêm chuỗi EN/VI.**
- [ ] **Step 4: Chạy lại + `LocalizationTests`** — Expected: PASS.
- [ ] **Step 5: Commit** — `feat(speaking): add blueprint catalog and learned word picker`.

### Task 6: Giao thức Gemini Live và transport

**Files:**
- Create: `S/Live/LiveClientMessage.swift`, `S/Live/LiveServerEvent.swift`, `S/Live/LiveTransport.swift`, `S/Live/URLSessionLiveTransport.swift`.
- Create fixtures: `T/Fixtures/live/*.json` (setupComplete, audio chunk, input/output transcription, interrupted, turnComplete, toolCall end_session, goAway, sessionResumptionUpdate, serverContent kết hợp modelTurn + outputTranscription).
- Test: `T/LiveMessagesTests.swift`.

**Interfaces:**

```swift
public struct LiveSetup: Sendable, Equatable { public let model: String /* "models/gemini-3.8-live" */; public let voiceName: String /* "Kore" */; public let systemInstruction: String; public let resumptionHandle: String? }
public enum LiveClientMessage: Sendable, Equatable {
    case setup(LiveSetup)
    case audio(Data)                       // PCM16 16 kHz → realtimeInput.audio {data(base64), mimeType "audio/pcm;rate=16000"}
    case hiddenText(String)                // clientContent {turns:[{role:"user", parts:[{text}]}], turnComplete:true}
    case toolResponse(id: String, name: String) // toolResponse.functionResponses [{id, name, response:{ok:true}}]
    public func encoded() throws -> Data
}
public enum LiveServerEvent: Sendable, Equatable {
    case setupComplete, audio(Data), inputTranscript(String), outputTranscript(String)
    case interrupted, turnComplete, toolCall(id: String, name: String)
    case goAway(timeLeft: TimeInterval?), resumptionUpdate(handle: String?, resumable: Bool)
    public static func decode(_ data: Data) throws -> [LiveServerEvent]   // một message có thể sinh nhiều event, đúng thứ tự: audio → outputTranscript → inputTranscript → interrupted → turnComplete
}
public enum LiveTransportError: Error, Equatable { case unauthorized, quotaExceeded, network, closed(code: Int, reason: String) }
public protocol LiveTransport: Sendable {
    func connect(apiKey: String) async throws -> AsyncThrowingStream<Data, Error>
    func send(_ message: LiveClientMessage) async throws
    func close() async
}
```

Setup JSON gồm: `generationConfig.responseModalities ["AUDIO"]`, `generationConfig.speechConfig.voiceConfig.prebuiltVoiceConfig.voiceName`, `systemInstruction.parts[0].text`, `tools[0].functionDeclarations[0] = {name:"end_session", description:"End the conversation after a goodbye.", parameters:{type:"OBJECT", properties:{reason:{type:"STRING"}}}}`, `inputAudioTranscription {}`, `outputAudioTranscription {}`, `realtimeInputConfig.automaticActivityDetection.silenceDurationMs 700`, `sessionResumption {handle?}`. `URLSessionLiveTransport` ánh xạ lỗi: HTTP upgrade 401/403 hoặc close reason chứa "API key" → `.unauthorized`; close reason chứa "RESOURCE_EXHAUSTED" hoặc "quota" → `.quotaExceeded`; `URLError` → `.network`. Message nhị phân và text đều đưa vào stream dưới dạng `Data`.

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func setupEncodesVoiceToolsTranscriptionAndResumption() throws {
    let json = try JSONSerialization.jsonObject(with: LiveClientMessage.setup(.fixture(handle: "h1")).encoded()) as! [String: Any]
    let setup = json["setup"] as! [String: Any]
    #expect(setup["model"] as? String == "models/gemini-3.8-live")
    #expect((setup["sessionResumption"] as? [String: Any])?["handle"] as? String == "h1")
    #expect(setup["inputAudioTranscription"] != nil && setup["outputAudioTranscription"] != nil)
}
@Test func audioEncodesBase64WithPcmMime() throws { /* realtimeInput.audio.mimeType == "audio/pcm;rate=16000", data decode == input */ }
@Test func combinedServerContentDecodesInOrder() throws {
    #expect(try LiveServerEvent.decode(fixture("live/model-turn-with-transcript")) == [.audio(Data([1, 0, 2, 0])), .outputTranscript("Hi there"), .turnComplete])
}
@Test func toolCallAndGoAwayDecode() throws { /* .toolCall(id: "c1", name: "end_session"); .goAway(timeLeft: 30) từ "30s" */ }
@Test func unknownFieldsAreIgnored() throws { #expect(try LiveServerEvent.decode(Data(#"{"usageMetadata":{}}"#.utf8)).isEmpty) }
```

- [ ] **Step 2: Chạy `swift test --filter LiveMessagesTests`** — Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Chạy lại** — Expected: PASS.
- [ ] **Step 5: Smoke thật (thủ công, cần key người dùng)** — tạo `scripts/speaking/live-smoke.swift` (không thuộc target app): mở socket bằng `URLSessionLiveTransport`, gửi setup + `hiddenText("Say hello in one sentence.")`, in các event đã decode trong 10 giây. Yêu cầu: thấy `setupComplete`, ≥ 1 `audio`, `outputTranscript`, `turnComplete`. Nếu tên trường thực tế khác fixture, sửa fixture + decoder và ghi lại khác biệt vào commit message. Chỉ chạy khi người dùng cung cấp key qua biến môi trường `GEMINI_API_KEY`; không lưu key vào repo.
- [ ] **Step 6: Commit** — `feat(speaking): add gemini live protocol and websocket transport`.

### Task 7: Ghép transcript

**Files:** Create `S/TranscriptAssembler.swift`; Test `T/TranscriptAssemblerTests.swift`.

**Interfaces:** `struct TranscriptAssembler: Sendable { private(set) var turns: [SpeakingTurn]; mutating func ingest(_ event: LiveServerEvent, at offset: TimeInterval) }`.

Quy tắc: `outputTranscript` nối vào lượt AI đang mở (mở lượt mới nếu lượt cuối là learner hoặc đã đóng); `inputTranscript` nối vào lượt learner đang mở (mở mới nếu lượt cuối là AI hoặc đã đóng; đồng thời đóng lượt AI đang mở); `turnComplete` và `interrupted` đóng lượt AI đang mở (`endOffset = offset`); lượt learner đóng khi lượt AI kế tiếp mở. Nối chuỗi bằng một khoảng trắng, trim; bỏ lượt rỗng. `index` tăng liên tục từ 0.

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func alternatingTurnsAreSplitAndIndexed() {
    var a = TranscriptAssembler()
    a.ingest(.outputTranscript("Hi, what"), at: 0); a.ingest(.outputTranscript("can I get you?"), at: 1); a.ingest(.turnComplete, at: 2)
    a.ingest(.inputTranscript("A latte"), at: 3); a.ingest(.inputTranscript("please"), at: 4)
    a.ingest(.outputTranscript("Sure."), at: 5)
    #expect(a.turns.map(\.text) == ["Hi, what can I get you?", "A latte please", "Sure."])
    #expect(a.turns.map(\.speaker) == [.ai, .learner, .ai])
    #expect(a.turns[1].endOffset == 5)
}
@Test func repeatedInterruptionsDoNotMergeAITurns() {
    // AI "One" → interrupted → learner "wait" → AI "Two" → interrupted → learner "sorry"
    #expect(a.turns.map(\.text) == ["One", "wait", "Two", "sorry"])
}
```

- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS** (`swift test --filter TranscriptAssemblerTests`).
- [ ] **Step 5: Commit** — `feat(speaking): assemble live transcripts into turns`.

### Task 8: Reducer trạng thái cuộc gọi

**Files:** Create `D/SpeakingCallState.swift`; Test `T/SpeakingCallReducerTests.swift`.

**Interfaces:**

```swift
public enum SpeakingCallFailure: Error, Equatable, Sendable { case missingKey, unauthorized, quotaExceeded, offline, network, microphoneDenied, unknown }
public enum SpeakingCallPhase: Equatable, Sendable { case idle, connecting, live, reconnecting, ended(SpeakingEndReason), failed(SpeakingCallFailure) }
public enum SpeakingCallInput: Equatable, Sendable {
    case start, setupComplete, transportDropped, reconnectTimedOut, goAway
    case resumptionHandle(String), aiRequestedEnd, learnerEnded, wrapUpDue, hardLimitReached
    case audioInterrupted, connectFailed(SpeakingCallFailure)
}
public enum SpeakingCallEffect: Equatable, Sendable {
    case openSocket(resumptionHandle: String?), sendOpeningTrigger, startAudio, stopAudio
    case closeSocket, startReconnectTimer(seconds: Int), cancelReconnectTimer, sendWrapUp, finalize(SpeakingEndReason)
}
public struct SpeakingCallState: Equatable, Sendable {
    public private(set) var phase: SpeakingCallPhase = .idle
    public private(set) var reconnectAttempts = 0
    public private(set) var resumptionHandle: String?
    public private(set) var hasBeenLive = false
    public mutating func reduce(_ input: SpeakingCallInput) -> [SpeakingCallEffect]
}
```

Bảng chuyển trạng thái (mọi input không có trong bảng → không đổi, không effect):

| Phase | Input | Phase mới | Effects |
|---|---|---|---|
| idle | start | connecting | openSocket(nil) |
| connecting | setupComplete (lần đầu) | live | startAudio, sendOpeningTrigger |
| connecting | connectFailed(f) (chưa từng live) | failed(f) | closeSocket |
| live | resumptionHandle(h) | live | — (lưu h) |
| live | transportDropped, reconnectAttempts == 0 | reconnecting | stopAudio, startReconnectTimer(8), openSocket(h) |
| live | transportDropped, reconnectAttempts ≥ 1 | ended(.connectionLost) | stopAudio, closeSocket, finalize(.connectionLost) |
| live | goAway | reconnecting (không tăng attempts) | startReconnectTimer(8), openSocket(h) — giữ audio chạy |
| reconnecting | setupComplete | live | cancelReconnectTimer, startAudio nếu đã stop (không gửi opening trigger) |
| reconnecting | reconnectTimedOut / connectFailed | ended(.connectionLost) | closeSocket, finalize(.connectionLost) |
| live | wrapUpDue | live | sendWrapUp |
| live, reconnecting | aiRequestedEnd / learnerEnded / hardLimitReached / audioInterrupted | ended(.aiEnded / .learnerEnded / .timeLimit / .interrupted) | stopAudio, closeSocket, cancelReconnectTimer (nếu reconnecting), finalize(…) |
| connecting | learnerEnded | ended(.learnerEnded) | closeSocket (không finalize: chưa có nội dung, UI đóng màn hình) |
| ended/failed | bất kỳ | không đổi | — |

`transportDropped` từ `live` tăng `reconnectAttempts`. `finalize` chỉ được phát đúng một lần trong đời state.

- [ ] **Step 1: Viết test thất bại** — mỗi hàng bảng một test, cộng thêm:

```swift
@Test func secondDropEndsWithConnectionLost() {
    var s = SpeakingCallState(); _ = s.reduce(.start); _ = s.reduce(.setupComplete)
    _ = s.reduce(.transportDropped); _ = s.reduce(.setupComplete)
    #expect(s.reduce(.transportDropped).contains(.finalize(.connectionLost)))
    #expect(s.phase == .ended(.connectionLost))
}
@Test func interruptionWhileReconnectingFinalizesOnce() {
    // live → transportDropped → audioInterrupted → reconnectTimedOut
    // tổng số .finalize trong mọi effect == 1, phase == .ended(.interrupted)
}
@Test func reconnectDoesNotResendOpeningTrigger() { /* sau setupComplete thứ hai không có .sendOpeningTrigger */ }
```

- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS** (`swift test --filter SpeakingCallReducerTests`).
- [ ] **Step 5: Commit** — `feat(speaking): model the live call as a pure reducer`.

### Task 9: Audio — chuyển đổi PCM, I/O khử vọng, ghi âm learner

**Files:**
- Create: `S/Audio/PCMConverter.swift`, `S/Audio/SpeakingAudioIO.swift`, `S/Audio/VoiceProcessingAudioIO.swift`, `S/Audio/LearnerRecorder.swift`, `S/Audio/SpeakingAudioStorage.swift`.
- Test: `T/PCMConverterTests.swift`, `T/LearnerRecorderTests.swift`, `T/SpeakingAudioStorageTests.swift`.

**Interfaces:**

```swift
public struct PCMConverter {
    public init(inputFormat: AVAudioFormat) throws
    public func pcm16kMono(from buffer: AVAudioPCMBuffer) throws -> Data   // Int16 LE, 16 kHz, mono
    public static func playbackBuffer(fromPCM24k data: Data) -> AVAudioPCMBuffer? // Float32 24 kHz mono, nil nếu data lẻ byte
}
public protocol SpeakingAudioIO: AnyObject, Sendable {
    func start(onCapture: @escaping @Sendable (AVAudioPCMBuffer) -> Void) async throws
    func enqueuePlayback(_ pcm24k: Data)
    func flushPlayback()
    var isPlaying: Bool { get }
    func stop() async
    func restartAfterRouteChange() async throws
}
public final class LearnerRecorder: @unchecked Sendable {
    public init(storage: SpeakingAudioStorage)
    public func begin(sessionId: UUID, format: AVAudioFormat) throws -> String   // "<uuid>.m4a"
    public func append(_ buffer: AVAudioPCMBuffer)
    public var elapsed: TimeInterval { get }                                      // tính từ số frame đã ghi
    public func finish() -> URL?
}
public struct SpeakingAudioStorage: Sendable {
    public init(directory: URL)      // production: Application Support/VocabCraft/SpeakingAudio
    public func url(for fileName: String) -> URL
    public func delete(fileNames: [String])
}
```

`VoiceProcessingAudioIO`: `AVAudioEngine`; `try engine.inputNode.setVoiceProcessingEnabled(true)` trước khi start; tap input bus 0 với format của input node; `AVAudioPlayerNode` gắn vào `mainMixerNode` với format Float32 24 kHz mono; `flushPlayback()` gọi `player.stop()` rồi `player.play()`. Recorder ghi AAC: `AVFormatIDKey: kAudioFormatMPEG4AAC`, 16 kHz, 1 kênh, `AVEncoderBitRateKey: 32_000`.

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func converts48kFloatTo16kInt16() throws {
    let input = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    let data = try PCMConverter(inputFormat: input).pcm16kMono(from: .sine(format: input, frames: 4_800))
    #expect(data.count == 1_600 * 2)
}
@Test func oddLengthPlaybackDataIsRejected() { #expect(PCMConverter.playbackBuffer(fromPCM24k: Data([1, 2, 3])) == nil) }
@Test func recorderWritesPlayableM4AWithElapsedTime() throws {
    // ghi 2 giây sine 48 kHz → finish() → AVAudioFile(forReading:) đọc được, duration ≈ 2 ± 0.1, elapsed ≈ 2
}
@Test func storageDeletesOnlyNamedFiles() { /* tạo a.m4a, b.m4a; delete(["a.m4a"]); chỉ còn b */ }
```

- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS** (ba suite).
- [ ] **Step 5: Commit** — `feat(speaking): add voice-processed audio io and learner recorder`.

### Task 10: SpeakingCallController

**Files:** Create `F/SpeakingCallController.swift`; Test `T/SpeakingCallControllerTests.swift`, `T/Fakes/FakeLiveTransport.swift`, `T/Fakes/FakeSpeakingAudioIO.swift`.

**Interfaces:**
- Consumes: `LiveTransport`, `SpeakingAudioIO`, `LearnerRecorder`, `AudioSessionCoordinating` (intent `.duplexSpeech`), `SpeakingCallState`, `TranscriptAssembler`, `SpeakingPromptBuilder`.
- Produces:

```swift
@MainActor @Observable public final class SpeakingCallController {
    public init(plan: SpeakingSessionPlan, apiKey: String, transport: any LiveTransport, audio: any SpeakingAudioIO,
                recorder: LearnerRecorder, audioSession: any AudioSessionCoordinating, clock: any Clock<Duration> = ContinuousClock(), now: @escaping () -> Date = Date.init)
    public private(set) var phase: SpeakingCallPhase
    public private(set) var turns: [SpeakingTurn]
    public private(set) var elapsed: TimeInterval
    public private(set) var hintCount: Int
    public private(set) var isAISpeaking: Bool
    public private(set) var result: SpeakingSessionSnapshot?   // có giá trị khi finalize, status .pendingAnalysis
    public func start() async
    public func requestHint() async      // gửi .hiddenText(hintRequest), hintCount += 1; bỏ qua nếu phase != .live
    public func end() async              // input .learnerEnded
}
```

Hành vi: thực thi mọi `SpeakingCallEffect` từ reducer; luồng nhận `Data` → `LiveServerEvent.decode` → audio vào `enqueuePlayback`, `interrupted` → `flushPlayback()`, transcript → assembler với `recorder.elapsed`, `toolCall(end_session)` → gửi `.toolResponse` rồi input `.aiRequestedEnd`, `resumptionUpdate` → input `.resumptionHandle`, `goAway` → input `.goAway`; stream kết thúc/lỗi khi đang live → `.transportDropped`, lỗi lúc connect → `.connectFailed(map)`. Đồng hồ: `wrapUpDue` tại `durationSeconds - 30`, `hardLimitReached` tại `durationSeconds + 30`, tính từ lần `live` đầu tiên. Lắng nghe `audioSession.events`: `.interruptionBegan` → `.audioInterrupted`; `.routeChanged` → `audio.restartAfterRouteChange()`. `UIApplication.didEnterBackgroundNotification` → `.audioInterrupted`. `finalize` → `recorder.finish()`, release lease, dựng `result`. Mỗi gói mic: `PCMConverter` → `transport.send(.audio)` và `recorder.append`.

- [ ] **Step 1: Viết test thất bại** (fake transport phát fixture từ Task 6; `TestClock` tự viết trong `T/Fakes`)

```swift
@Test func happyPathProducesPendingSnapshot() async {
    // fake phát: setupComplete, outputTranscript, turnComplete, inputTranscript ×2, toolCall end_session
    await controller.start()
    #expect(fake.sent.first == .setup(...) && fake.sent.contains(.hiddenText(SpeakingPromptBuilder.openingTrigger)))
    #expect(fake.sent.contains(.toolResponse(id: "c1", name: "end_session")))
    #expect(controller.result?.status == .pendingAnalysis && controller.result?.endReason == .aiEnded)
}
@Test func interruptedFlushesPlaybackEachTime() async { /* 3 lần interrupted → audio.flushCount == 3 */ }
@Test func wrapUpSentAt330sAndHardStopAt390s() async { /* TestClock advance */ }
@Test func unauthorizedOnConnectFailsWithoutSnapshot() async { #expect(controller.phase == .failed(.unauthorized) && controller.result == nil) }
@Test func hintIncrementsCountAndSendsHiddenText() async { }
@Test func audioInterruptionEndsAndSavesPartialTurns() async { #expect(controller.result?.endReason == .interrupted && !(controller.result?.turns.isEmpty ?? true)) }
```

- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS** (`swift test --filter SpeakingCallControllerTests`).
- [ ] **Step 5: Commit** — `feat(speaking): orchestrate live calls with audio, transcript and timers`.

### Task 11: Phân tích sau buổi — request, validator, analyzer

**Files:**
- Create: `D/SpeakingAnalyzing.swift`, `S/Analysis/SpeakingAnalysisRequestBuilder.swift`, `S/Analysis/SpeakingAnalysisValidator.swift`, `S/Analysis/GeminiSpeakingAnalyzer.swift`.
- Fixtures: `T/Fixtures/analysis-valid.json` (đã có từ Task 3), `analysis-fabricated-quote.json`, `analysis-score-out-of-range.json`, `analysis-over-caps.json`, `analysis-curly-apostrophe.json`, `generate-content-response.json` (bọc kết quả trong `candidates[0].content.parts[0].text`).
- Test: `T/SpeakingAnalysisValidatorTests.swift`, `T/GeminiSpeakingAnalyzerTests.swift`.

**Interfaces:**

```swift
public enum SpeakingAnalysisError: Error, Equatable { case missingKey, unauthorized, quotaExceeded, network, invalidResponse, audioUnavailable }
public protocol SpeakingAnalyzing: Sendable { func analyze(_ session: SpeakingSessionSnapshot, audioURL: URL) async throws -> SpeakingAnalysis }
public enum QuoteNormalizer { public static func normalize(_ text: String) -> String } // lowercased; ’‘ → '; “” → "; bỏ dấu câu trừ '; gộp khoảng trắng; trim
public enum SpeakingAnalysisValidator { public static func validate(_ raw: SpeakingAnalysis, plan: SpeakingSessionPlan) throws -> SpeakingAnalysis }
public struct SpeakingAnalysisRequestBuilder { public static func makeRequest(apiKey: String, session: SpeakingSessionSnapshot, audio: Data) throws -> URLRequest }
public struct GeminiSpeakingAnalyzer: SpeakingAnalyzing { public init(apiKey: @escaping @Sendable () -> String, session: URLSession = .shared) }
```

Request: `contents[0].role "user"`, `parts` = [prompt text, `inline_data {mime_type "audio/m4a", data base64}`]; `generationConfig.responseMimeType "application/json"`, `generationConfig.responseSchema` dựng từ cấu trúc `SpeakingAnalysis` (type OBJECT, các trường `required` trừ `objective`; `targetWords` chỉ yêu cầu khi plan có từ). Prompt (tiếng Anh, yêu cầu viết giải thích bằng tiếng Việt) gồm: level, blueprint (vai, setting, objective), danh sách lượt dạng `[index] SPEAKER: text`, `hintCount`, từ mục tiêu, và chỉ dẫn: "First transcribe the learner's audio verbatim into learnerTranscript using the turn indexes. Quote only from that transcript. Score 1–5 aligned to CEFR A2–B1. At most 5 corrections, 3 natural phrasings, 3 pronunciation notes. Write explanation, note, tip, reason, strengths and focusNext in Vietnamese." Thêm `Fixtures/prompt-analysis-cafe-a2.txt` làm snapshot. Request > 20 MB → `invalidResponse` trước khi gửi. Timeout 60 giây. HTTP 401/403 → `unauthorized`, 429 → `quotaExceeded`.

Validator: điểm ngoài 1…5 → throw `invalidResponse`; loại correction/naturalPhrasing có `original` không khớp (`QuoteNormalizer` substring của transcript learner ghép); loại `targetWords.quote` không khớp (giữ mục nhưng đặt `used = false`, `quote = nil`); cắt theo caps; `targetWords` bỏ trống nếu plan không có từ. `SavedPhraseRecord.dedupeKey` của Task 4 đổi sang `QuoteNormalizer.normalize`.

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func curlyApostropheQuoteStillMatches() throws { /* transcript "I’m want a latte", correction.original "I'm want a latte" → giữ */ }
@Test func fabricatedQuoteIsDropped() throws { #expect(try validate(fixture("analysis-fabricated-quote")).corrections.count == 1) }
@Test func scoreOutOfRangeThrows() { #expect(throws: SpeakingAnalysisError.invalidResponse) { try validate(fixture("analysis-score-out-of-range")) } }
@Test func capsAreEnforced() throws { let a = try validate(fixture("analysis-over-caps")); #expect(a.corrections.count == 5 && a.naturalPhrasings.count == 3 && a.pronunciation.count == 3) }
@Test func requestUsesFlashModelInlineAudioAndSchema() throws { /* URL path kết thúc "gemini-3.8-flash:generateContent", header x-goog-api-key, inline_data.mime_type "audio/m4a", responseMimeType "application/json" */ }
@Test func analyzerMaps429ToQuota() async { /* URLProtocol stub trả 429 */ }
@Test func analyzerDecodesCandidateTextAndValidates() async throws { /* stub trả generate-content-response.json */ }
```

- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS**.
- [ ] **Step 5: Smoke thật (thủ công, cần `GEMINI_API_KEY`)** — `scripts/speaking/analysis-smoke.swift` gửi một file m4a mẫu ~20 giây do người dùng ghi; yêu cầu: HTTP 200, decode + validate thành công. Ghi khác biệt schema (nếu có) vào commit.
- [ ] **Step 6: Commit** — `feat(speaking): analyze sessions with gemini flash and validate quotes`.

### Task 12: AnalyzeSpeakingSessionUseCase

**Files:** Create `D/AnalyzeSpeakingSessionUseCase.swift`; Test `T/AnalyzeSpeakingSessionUseCaseTests.swift`.

**Interfaces:**

```swift
public actor AnalyzeSpeakingSessionUseCase {
    public init(repository: any SpeakingRepositoryProtocol, analyzer: any SpeakingAnalyzing, storage: SpeakingAudioStorage)
    @discardableResult public func execute(sessionId: UUID) async -> SpeakingSessionStatus
}
```

Hành vi: nếu đang có phân tích cho cùng `sessionId` → chờ và trả kết quả của lần đó (không chạy lại). `learnerTurnCount < 2` → `tooShort`. Không có `audioFileName` hoặc file không tồn tại → `analysisFailed` (UI hiển thị "không còn bản ghi âm", Task 16). Thành công → `updateAnalysis(.analyzed, analysis)`; lỗi → `updateAnalysis(.analysisFailed, nil)`. Sau khi lưu buổi mới, gọi `repository.detachAudio(keepingLatest: 20)` rồi `storage.delete(fileNames:)`.

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func concurrentExecuteRunsAnalyzerOnce() async { /* hai Task gọi execute cùng id; analyzer.callCount == 1; cả hai trả .analyzed */ }
@Test func shortSessionIsMarkedTooShortWithoutCallingAnalyzer() async { }
@Test func failureThenRetrySucceedsWithSingleRecord() async { /* lần 1 analyzer throw → .analysisFailed; lần 2 OK → .analyzed; sessions(limit:nil).count == 1 */ }
@Test func missingAudioFileFails() async { }
@Test func pruningDeletesDetachedFiles() async { }
```

- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS**.
- [ ] **Step 5: Commit** — `feat(speaking): add idempotent session analysis use case`.

### Task 13: Chuỗi `app.speaking.*` và precheck

**Files:**
- Create: `Core/Localization/AppStrings+Speaking.swift`, `F/SpeakingPrecheck.swift`.
- Modify: `Resources/Localizable.xcstrings`, `App/Info.plist` (kiểm `NSMicrophoneUsageDescription` đã có; nếu nội dung nói về nhận dạng giọng nói cũ thì cập nhật cho luyện nói với AI, cả EN/VI trong `InfoPlist.xcstrings` nếu dự án dùng).
- Test: `VocabCraftAppTests/Localization/SpeakingLocalizationTests.swift`, `T/SpeakingPrecheckTests.swift`.

**Interfaces:**
- `AppStrings.Speaking` theo mẫu `AppStrings+GuidedPractice` cũ (cặp `LocalizedStringKey` + `…Text: String`). Nhóm key: `app.speaking.hub.*` (title, subtitle, scenarios, topics, progress, phrasebook, history, empty), `app.speaking.prepare.*` (level, vocab_toggle, words, goal, start, check_key, check_mic, check_network), `app.speaking.call.*` (connecting, reconnecting, hint, end, subtitles_show, subtitles_hide, time_left `%lld`), `app.speaking.result.*` (analyzing, failed, retry, too_short, audio_missing, scores, fluency, grammar, vocabulary, pronunciation, corrections, natural, pronunciation_notes, target_words, objective_met, objective_not_met, strengths, focus_next, save_phrase, saved), `app.speaking.phrasebook.*` (title, empty, delete), `app.speaking.error.*` (missing_key, unauthorized, quota, offline, network, microphone_denied, unknown, open_settings, try_again, exit). Thêm `app.speaking.tab` (EN "Speaking" / VI "Luyện nói") cho Task 14. Key `app.speaking.hub.coming_soon` được xoá ở Task 17.
- `struct SpeakingPrecheck { enum Issue: Equatable { case missingKey, microphoneDenied, offline }; init(settings: UserSettingsStore, microphone: @escaping () async -> Bool, isOnline: @escaping () -> Bool); func run() async -> [Issue] }`. Production: `AVAudioApplication.requestRecordPermission()` và `NWPathMonitor` (một monitor dùng chung, `currentPath.status == .satisfied`).

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func everySpeakingKeyHasEnglishAndVietnamese() { /* duyệt catalog, mọi key prefix app.speaking có en + vi, state translated, specifier khớp */ }
@Test func precheckReportsAllMissingRequirements() async {
    #expect(await SpeakingPrecheck(settings: .withKey(""), microphone: { false }, isOnline: { false }).run() == [.missingKey, .microphoneDenied, .offline])
}
@Test func precheckTreatsWhitespaceKeyAsMissing() async { }
```

- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS** (+ `LocalizationTests` của CraftUIKit).
- [ ] **Step 5: Commit** — `feat(speaking): add speaking strings and call precheck`.

### Task 14: Hub, Chuẩn bị và điều hướng

**Files:**
- Create: `F/SpeakingRoute.swift`, `F/SpeakingHubViewModel.swift`, `F/Views/SpeakingHubView.swift`, `F/Views/SpeakingPrepareView.swift`.
- Delete: `F/Views/SpeakingHubPlaceholderView.swift`.
- Modify: `Features/Homepage/Views/HomepageView.swift` (tab `.aiAssistant` → `SpeakingHubView`), `App/DI/AppContainer.swift` (factory), `App/Navigation/TabItem.swift` (giữ case `.aiAssistant`, đổi nhãn sang `app.speaking.tab`), `project.pbxproj`.
- Test: `T/SpeakingHubViewModelTests.swift`.

**Interfaces:**
- `enum SpeakingRoute: Hashable { case prepare(blueprintId: String), call(SpeakingSessionPlan), result(UUID), phrasebook }`.
- `@MainActor @Observable final class SpeakingHubViewModel { init(repository:, wordPicker:, precheck:); var scenarios: [SpeakingBlueprint]; var topics: [SpeakingBlueprint]; var history: [SpeakingSessionSnapshot]; var progress: SpeakingProgressSummary?; func load() async; func makePlan(blueprintId: String, level: SpeakingLevel, includeWords: Bool) async -> SpeakingSessionPlan?; func runPrecheck() async -> [SpeakingPrecheck.Issue] }`.
- `struct SpeakingProgressSummary: Equatable { let fluency, grammar, vocabulary, pronunciation: Double; let sessionCount: Int }` — trung bình 5 buổi `analyzed` gần nhất; `nil` khi chưa có buổi nào.
- AppContainer: `makeSpeakingHubViewModel() -> SpeakingHubViewModel`, `makeSpeakingCallController(plan:) -> SpeakingCallController?` (nil khi key trống), `makeSpeakingResultViewModel(sessionId:) -> SpeakingResultViewModel`, `speakingRepository: any SpeakingRepositoryProtocol` (`SpeakingModelActor` trên `modelContainer`, mock in-memory khi `useMockData`), `analyzeSpeakingSessionUseCase`.
- UI: Hub dùng `CraftCard`/`CraftListRow` cho danh sách blueprint (hai nhóm Tình huống/Chủ đề), `CraftProgressBar` cho 4 tiêu chí (giá trị/5), hàng Sổ cụm từ, lịch sử với `CraftBadge` trạng thái. Prepare dùng `CraftSegmentedControl` (A2/B1), `CraftToggle` (bám từ vựng), `CraftPill` cho từ, thẻ mục tiêu `CraftCard`, `CraftButton` gọi; hiển thị từng issue precheck kèm hành động (mở Settings app cho key: chuyển tab `.settings` qua `AppRouter`; mic: `UIApplication.openSettingsURLString`). Nút gọi bị khoá khi còn issue.

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func progressAveragesLatestFiveAnalyzedSessions() async { /* 6 analyzed + 1 failed; trung bình chỉ 5 analyzed mới nhất */ }
@Test func makePlanIncludesWordsOnlyWhenToggled() async { }
@Test func makePlanWithToggleButNoLearnedWordsReturnsEmptyWords() async { }
```

- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS**, build 0 warning.
- [ ] **Step 5: Commit** — `feat(speaking): add speaking hub and preparation screens`.

### Task 15: Màn hình cuộc gọi

**Files:** Create `F/Views/SpeakingCallView.swift`; Modify `AppContainer.swift`; Test `T/SpeakingCallViewTests.swift` (kiểm tra mapping trạng thái → nội dung qua hàm thuần `SpeakingCallViewContent.make(phase:elapsed:duration:)`).

**Interfaces:** `struct SpeakingCallViewContent: Equatable { let statusKey: String; let timeLeft: Int?; let showsHint: Bool; let showsReconnecting: Bool; let failure: SpeakingCallFailure? ; static func make(phase:elapsed:duration:) -> Self }`.

UI: `CraftPulsingAuraRing` phản ánh `isAISpeaking`; đồng hồ đếm ngược `app.speaking.call.time_left`; nút Gợi ý (`CraftButton` secondary), nút Kết thúc (`CraftIconButton` destructive); phụ đề ẩn mặc định, bật bằng `CraftToggle`, danh sách lượt bằng `CraftText`; lớp phủ "Đang nối lại…"; `CraftDialog` cho `failed(...)` với hành động theo bảng lỗi spec mục 7. `.task { await controller.start() }`; khi `result != nil` → lưu `repository.save(result)`, chạy `analyzeSpeakingSessionUseCase.execute` trong `Task` tách rời, điều hướng `.result(id)`. `.onDisappear` khi chưa kết thúc → `controller.end()`. Giữ màn hình sáng (`UIApplication.shared.isIdleTimerDisabled`) trong lúc gọi.

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func liveShowsHintAndTimeLeft() { #expect(SpeakingCallViewContent.make(phase: .live, elapsed: 300, duration: 360).timeLeft == 60) }
@Test func reconnectingHidesHint() { }
@Test func failedQuotaExposesFailure() { }
```

- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS**, build 0 warning.
- [ ] **Step 5: Commit** — `feat(speaking): add live call screen`.

### Task 16: Kết quả và Sổ cụm từ

**Files:** Create `F/SpeakingResultViewModel.swift`, `F/Views/SpeakingResultView.swift`, `F/Views/SpeakingPhrasebookView.swift`; Test `T/SpeakingResultViewModelTests.swift`.

**Interfaces:**

```swift
@MainActor @Observable final class SpeakingResultViewModel {
    init(sessionId: UUID, repository: any SpeakingRepositoryProtocol, analyze: AnalyzeSpeakingSessionUseCase, storage: SpeakingAudioStorage)
    private(set) var session: SpeakingSessionSnapshot?
    private(set) var isAnalyzing: Bool
    private(set) var savedSuggestions: Set<String>      // khoá chuẩn hoá
    var canRetry: Bool { get }                          // status == .analysisFailed && file audio còn
    func load() async                                   // nếu .pendingAnalysis → chờ execute
    func retry() async                                  // bỏ qua nếu isAnalyzing
    func save(correction: SpeakingAnalysis.Correction) async
    func save(phrasing: SpeakingAnalysis.NaturalPhrasing) async
}
```

UI kết quả theo trạng thái: `pendingAnalysis` → `CraftSpinner` + `app.speaking.result.analyzing`; `analysisFailed` → lỗi + nút thử lại (ẩn và hiện `audio_missing` khi `!canRetry`); `tooShort` → thông báo; `analyzed` → điểm (4 `CraftProgressBar` kèm lý do), tóm tắt, sửa lỗi (gốc gạch, sửa nổi bật bằng token màu, nút lưu), diễn đạt tự nhiên (nút lưu), phát âm, từ mục tiêu (`CraftBadge` dùng đúng/chưa), mục tiêu. Sổ cụm từ: danh sách `CraftListRow`, `CraftSpeakerButton` phát `suggestion` qua `ttsService`, vuốt xoá.

- [ ] **Step 1: Viết test thất bại**

```swift
@Test func doubleRetryRunsSingleAnalysis() async { /* gọi retry() hai lần đồng thời; analyzer.callCount == 1 */ }
@Test func savingSamePhraseTwiceKeepsOne() async { /* savedSuggestions.count == 1, repository.phrases().count == 1 */ }
@Test func retryHiddenWhenAudioPruned() async { #expect(vm.canRetry == false) }
@Test func pendingSessionTriggersAnalysisOnLoad() async { }
```

- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS**, build 0 warning.
- [ ] **Step 5: Commit** — `feat(speaking): show session feedback and phrasebook`.

### Task 17: Wiring cuối, deep link và dọn dẹp

**Files:** Modify `App/VocabCraftApp.swift` (thêm route kiểm thử `-show-speaking-hub`), `App/Navigation/AppRouter.swift` (deep link `vocabcraft://speaking` cùng `ai`/`aiAssistant` cũ → tab `.aiAssistant`), `AppRouterTests.swift`; xoá key xcstrings không còn tham chiếu (chạy script dò `app.ai_assistant.`, `app.ai_pack.`, `app.speaking.hub.coming_soon`).

- [ ] **Step 1: Viết test thất bại** — `AppRouterTests.speakingDeepLinkSelectsSpeakingTab`.
- [ ] **Step 2: FAIL** → **Step 3: Implement** → **Step 4: PASS**.
- [ ] **Step 5: Dò key mồ côi**

Run: `grep -oE '"app\.(ai_assistant|ai_pack)[^"]*"' VocabCraftApp/Resources/Localizable.xcstrings | sort -u`
Expected: rỗng.

- [ ] **Step 6: Commit** — `feat(speaking): wire speaking tab, deep link and remove stale strings`.

### Task 18: Xác minh toàn bộ, checklist thiết bị, đánh giá prompt

**Files:** Create `docs/qa/ai-speaking-verification.md`.

- [ ] **Step 1: Quality gate** — chạy theo thứ tự: `swift test`, `swift test --package-path Packages/CraftUIKit`, `swift test --package-path Packages/SpeechKit`, CraftUIKit `LocalizationTests`, `swiftlint --strict`, Xcode build `VocabCraftApp` (0 error/0 warning), Xcode test `VocabCraftAppTests`. Ghi số test và kết quả vào tài liệu QA. Bất kỳ warning/fail nào → sửa trước khi đi tiếp.
- [ ] **Step 2: Checklist thiết bị thật (người dùng chạy, agent chuẩn bị)** — loa ngoài: AI không tự trả lời chính mình; AirPods; ngắt lời AI ba lần liên tiếp; cuộc gọi đến giữa buổi → buổi kết thúc và có trong lịch sử; bật chế độ máy bay giữa buổi → "Đang nối lại…" rồi `connectionLost` sau 8 giây; tắt máy bay trong 8 giây → nối lại thành công; gọi đủ 6 phút → AI chào kết ở 5:30, ngắt cứng ở 6:30; key sai → lỗi `unauthorized` dẫn tới Settings. Ghi kết quả từng mục vào `docs/qa/ai-speaking-verification.md`.
- [ ] **Step 3: Đánh giá prompt (thủ công)** — 5 buổi mẫu (3 A2, 2 B1) do người dùng nói; với mỗi buổi chấm: sửa lỗi đúng không, có trích dẫn bịa không (validator đã loại bao nhiêu mục), giải thích tiếng Việt dễ hiểu không, điểm có hợp lý không. Ghi bảng kết quả; nếu prompt cần chỉnh, cập nhật `SpeakingPromptBuilder`/request builder và snapshot tương ứng.
- [ ] **Step 4: Kiểm tra git status** — báo người dùng mọi file Xcode tự sinh, không commit chúng khi chưa được đồng ý.
- [ ] **Step 5: Commit** — `docs(speaking): record verification and prompt evaluation`.
