# Guided AI Communication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Giúp learner A2–B1 tự vận dụng từ đã học qua nhiệm vụ giao tiếp, giảm trợ giúp và lưu bằng chứng riêng với SRS.

**Architecture:** Giữ cấu trúc domain/data/feature và AppContainer hiện tại. Policy thuần quyết định tiến bộ; repository actor sở hữu giao dịch; coordinator @MainActor sở hữu phiên và tác vụ; adapter tận dụng AI Pack/audio nhưng công bố capability thực tế. Bốn màn hình ghép từ CraftUIKit, dùng chung phiên voice/text.

**Tech Stack:** Swift, SwiftUI Observation, SwiftData, Swift Testing/XCTest hiện có, CraftUIKit, SpeechKit, SwiftLint; giữ iOS 17/macOS 14 và các dependency hiện hành.

**Spec:** `docs/superpowers/specs/2026-10-22-ai-assistant-guided-communication-design.md` — đã được người dùng duyệt ngày 2026-10-22, bao gồm các lựa chọn mục 15.

## Global Constraints

- “Đối tượng đầu tiên: learner A2–B1.”
- “Hai từ trọng tâm, tối đa một từ ôn bổ sung; có thể giảm còn một từ.”
- “Tiến bộ giao tiếp lưu riêng với SRS; không tự tăng mastery hoặc đẩy lịch ôn khi phát hiện từ trong transcript.”
- “Voice và text dùng chung nhiệm vụ nhưng có bằng chứng tiến bộ riêng.”
- “Mỗi phiên chỉ đóng góp tối đa một lần cho mỗi wordId/inputMode.”
- “Request timeout ban đầu: 30 giây cho generation/assessment, 20 giây cho chuẩn bị TTS”.
- “Không lưu audio dài hạn mặc định”; transcript/evidence/exposure lưu cục bộ, không có cloud sync riêng.
- “V1 không thêm component thiết kế hệ thống”; dùng Craft tokens và catalog EN/VI, format parity, extractionState=manual/state=translated.
- Giữ deployment floors và Swift settings trong Package.swift; không nâng toolchain/dependency để phục vụ skill examples.
- TDD mỗi task: test thất bại vì hành vi còn thiếu → implementation tối thiểu → test xanh → review diff → commit phạm vi task.
- Mọi file Swift mới phải có membership đúng trong VocabCraftApp.xcodeproj/project.pbxproj; SwiftPM tự discover không chứng minh Xcode đã include. Chỉnh hẹp, không chạy generator ghi đè project.
- Không commit metadata Xcode bất ngờ. Ghi đủ failure output; warning/test hỏng chặn checkpoint kỹ thuật.

## Review Focus

1. Unicode, dấu nháy và inflection trong câu nói: span phải giữ đúng nội dung gốc, không dùng normalized index trên raw text — Task 7.
2. Từ bị xóa hoặc lemma trùng nghĩa sau cập nhật vocabulary: không ghép nhầm ID/nghĩa; lịch sử vẫn xem được — Task 4.
3. Clock lùi/timezone đổi: không nâng transferred sớm hoặc đặt lịch trước bằng chứng mới nhất — Task 2.
4. Double tap gửi câu/xin giúp khi save đang pending: một lượt logic, mức trợ giúp không vượt ngân sách — Tasks 9–10.
5. Xóa phiên khi callback cũ đang chờ: callback không được tạo lại evidence hoặc progress đã xóa — Task 11.

## Cách chạy và checkpoint

Làm việc từ repository root. Ở execution time dùng using-git-worktrees trước khi thay product code, xác nhận checkout/worktree và baseline. Không tạo worktree trong bước chỉ viết kế hoạch này.

Các lệnh xác minh dùng trong từng task:

- `swift test --filter <SuiteName>`: suite phải thực sự chạy >=1 test, exit 0, không warning; zero matching tests không phải pass.
- `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`.
- `xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftAppTests -destination 'platform=iOS Simulator,id=607AC652-2E92-4BE7-BA18-1B888D79684B' test` cho toàn app, thêm `-only-testing:VocabCraftAppTests/<XCTestClass>` khi task dùng XCTest.
- UUID trên là simulator iPhone 17 Pro iOS 26.5 quan sát khi lập kế hoạch; execution phải kiểm `xcrun simctl list devices available`, chọn thiết bị còn tồn tại và lưu ID thật. Không tự ý xóa/chỉnh các simulator khác.
- Các lệnh Xcode ghi log đầy đủ, xcresult vào thư mục artifacts ngoài source; khi dùng pipe phải bật pipefail. XcodeBuildMCP có thể chạy tương đương theo skill xcodebuildmcp.

Mỗi task có review gate cho diff và bằng chứng test. CP1–CP4 là review kỹ thuật trước khi đi tiếp, không mặc định đòi người dùng xác nhận từng task. Chỉ quay lại người dùng nếu thay đổi scope/spec, cần component CraftUIKit mới, hoặc có quyết định không được ủy quyền. Nếu chọn subagent-driven, tuân thủ đầy đủ các review gates của skill đó.

## File map và dependency

Các đường dẫn dưới đây nằm trong repo; `G` = `VocabCraftApp/Domain/Models/GuidedPractice`, `P` = `VocabCraftApp/Domain/Policies/GuidedPractice`, `U` = `VocabCraftApp/Domain/UseCases/GuidedPractice`, `D` = `VocabCraftApp/Data/GuidedPractice`, `F` = `VocabCraftApp/Features/AIAssistant/GuidedPractice`, `T` = `VocabCraftAppTests/AI/GuidedPractice`. Tasks ghi đường dẫn đầy đủ; ký hiệu này chỉ giúp đọc tổng quan.

| Nhóm | File/trách nhiệm |
|---|---|
| G | PracticeMission.swift, PracticeSession.swift, PracticeTurn.swift, SupportExposure.swift, WordUseEvidence.swift, CommunicationProgress.swift, PracticeContracts.swift: snapshot/schema, enum và payload |
| P | CommunicationProgressPolicy.swift, SupportPolicy.swift, PracticeDifficultyPolicy.swift: quy tắc xác định |
| U | SelectPracticeMissionUseCase.swift, AssessPracticeTurnUseCase.swift: chọn bài và xác minh output |
| D | PracticeTemplateCatalog.swift, PracticeLearningContextReader.swift, PracticeModelActor.swift, PracticeRecordMapper.swift, PracticeAIAdapter.swift, PracticeSpeechAdapter.swift, PracticePrivacyStore.swift: catalog/adapters/persistence |
| F | PracticeSessionCoordinator.swift, PracticeSessionCoordinator+Presentation.swift, PracticeSessionCoordinator+Recovery.swift: cùng một owner, tách trách nhiệm; PracticeHubViewModel.swift; bốn screen và state presentation |
| Database | AppSchemaV3.swift; SharedAppGroupContainer.swift; SwiftDataModels.swift: migration/store |
| Integration | AppContainer.swift; AIAssistantHubView.swift; ResetUserProgressUseCase.swift; SRSRepositoryImpl.swift: entry, DI, reset |
| Resources | VocabCraftApp/Resources/Localizable.xcstrings; Core/Localization/AppStrings+GuidedPractice.swift |
| Evidence | docs/qa/ai-guided-practice-verification.md; docs/qa/ai-guided-practice-pilot.md |

Thứ tự: 1 → 2/3/4 → 5 → 6; 1/4 → 7; 1 → 8; 2/3/6/7/8 → 9 → 10/11; 4/6/9 → 12 → 13 → 14 → 15. Đây là một vertical slice có phụ thuộc, không chia thành các dự án sản phẩm độc lập.

## Contracts dùng xuyên tasks

Task 1 khai báo tất cả DTO trong bảng spec mục 8 cùng các payload sau; tasks sau chỉ mở rộng bằng trường có test và tương thích Codable:

- PracticeClock: Sendable, `func now() -> Date`, `func sleep(for duration: Duration) async throws`; ProductionPracticeClock và fixture ManualPracticeClock.
- PracticePolicyConfiguration.v1: version=1, transferDelay=86400 giây, assistedDelay=86400, familiarDelay=259200, transferredDelay=604800; generationTimeout=30 giây, ttsPreparationTimeout=20 giây.
- PracticeLearningContext: words [PracticeWordSnapshot], progress [UserWordProgressData], communication [CommunicationProgress], evidence [WordUseEvidence], recentReflexWordIds Set<Int64>. Snapshot từ có wordId, lemma, definitionEn/Vi, sourceDeckId/sourceNodeId optional.
- PracticeTemplate: id/version, contextFamily, titleKey/briefKey/roleKeys, objectiveIds, supportedWordSenses [PracticeWordSense], variants, difficultyBounds, optional shadowingVideoId. PracticeWordSense dùng wordId + nghĩa vocabulary; không map theo lemma đơn lẻ.
- PracticeAIRequest: mission, acceptedTurns, supportBudget, providerIdentity; PracticeAIResponse: characterReply, objectiveAssessments, wordAssessments, coachFeedback optional, hintCandidate optional. Word assessment có wordId, objectiveId, usageVerdict, quotedSpan optional; reply có objective ID và context theo mission, không tự đặt.
- PracticeAssessment: evidence [WordUseEvidence], objectiveResults [PracticeObjectiveResult], response PracticeAIResponse; PracticeSummary: sessionId, status, objectiveResults, perWordProgress, evidenceIds, persisted Bool.
- PracticeCheckpoint: pendingTurnId/requestId optional, presentationIntents [PracticePresentationIntent], exposureUncertainWordIds Set<Int64>, currentSupportLevel, objectiveResults, difficultyOutcomes; PracticeOperationToken: sessionId/requestId/revision.
- PracticePresentationIntent: id, sessionId, turnId optional, content, channel, possibleWordIds, proposedLevel, status pending/confirmed/cancelled. Exposure là sự kiện đã trình bày; intent là reservation trước trình bày.
- PracticeCommit: sessionId, expectedRevision, turn, assessment, checkpoint; repository tự tính progress bằng policy. PracticeCompletion: completed/partial. PracticeSpeechEvent: captureStarted, transcript(text, reliability), captureStopped, playbackStarted, playbackFinished, failed(PracticeFailure).
- PracticeCapability: canGenerateDialogue/canAssessUsage/canCaptureSpeech/canPlaySpeech Bool, providerIdentity, unavailableReason optional; PracticeFailure Codable error codes cho capability/schema/network/timeout/storage/staleRevision/audio; text UI ánh xạ localization.
- PracticeSelectionReason: retryAssisted, communicationDue, noCommunicationEvidence; PracticeSelectionResult: mission(PracticeMission), needsVocabulary, noCompatibleTemplate; PracticeSessionState: preparing, awaitingLearner, capturing, processing, playingCharacter, coaching, paused, recoverableError, saving, completed, partial.
- PracticeSessionSnapshot: session, turns, exposures, evidence, progress, pending presentations (declaration Task 1). PracticeOpportunityOutcome/PracticeAdaptationDecision declaration Task 1, fields ở Task 3. PracticeObjectiveResult: objectiveId, intentVerdict, opportunityObserved Bool. SupportOrigin và PracticePresentationChannel theo spec/exposure contract. PracticeInputMode và PracticeSupportLevel là tên type Swift của inputMode/support.
- Enums inputMode=voice/typed/editedTranscript; difficulty ba Int mức 0...2; support none/intent/lexical/frame/model; các verdict/stage/status theo spec. WordUseEvidence bổ sung turnRevision và opportunityId để supersede chính xác.

## Task 1: Domain snapshots và fixtures dùng chung

**Files:** Create `VocabCraftApp/Domain/Models/GuidedPractice/{PracticeMission,PracticeSession,PracticeTurn,SupportExposure,WordUseEvidence,CommunicationProgress,PracticeContracts}.swift`; Create `VocabCraftAppTests/AI/GuidedPractice/{PracticeDomainTests,PracticeFixtures}.swift`.

**Interfaces:** Produces các DTO/contracts ở trên, Codable/Sendable/Equatable khi có giá trị; `PracticeFixtures.mission(wordIds: [Int64] = [101]) -> PracticeMission`, `session() -> PracticeSession`, `evidence(sessionId: UUID, at: Date, mode: PracticeInputMode = .voice, primed: Bool = false) -> WordUseEvidence`, `learningContext() -> PracticeLearningContext`; fixture evidence mặc định appropriate/achieved/usable/none/contextFamily=dining. ManualPracticeClock có `advance(by: Duration)` và `setNow(_ date: Date)`; dùng khóa bảo vệ now()/continuations để giữ Sendable, không @unchecked không có synchronization. Fixture archive là PracticeSessionSnapshot.

- [ ] Viết PracticeDomainTests: round-trip mọi snapshot và checkpoint bằng JSONEncoder/Decoder; assert wordId=101 vẫn Int64, pending intent/revision không mất, editedTranscript khác voice. Fixture clock sleep chỉ hoàn tất khi advance đủ.

Test case chuẩn: `roundTripRetainsCheckpoint`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(decoded == original)
#expect(decoded.session.revision == original.session.revision)
```

- [ ] Chạy `swift test --filter PracticeDomainTests`; xác nhận RED vì type/behavior chưa có.
- [ ] Implement snapshots đúng fields spec, immutable domain values; validate difficulty 0...2, ID trùng trong mission và schemaVersion lạ trả lỗi có kiểu. Viết fixtures deterministic, không production defaults.
- [ ] Chạy lại suite; PASS không warning. Review Codable không serialize actor/model context/API key.
- [ ] Stage đúng các file task và project membership; commit `feat(ai): define guided practice domain snapshots`.

## Task 2: Policy bằng chứng và lịch giao tiếp

**Files:** Create `VocabCraftApp/Domain/Policies/GuidedPractice/CommunicationProgressPolicy.swift`; Test `VocabCraftAppTests/AI/GuidedPractice/CommunicationProgressPolicyTests.swift`.

**Interfaces:** Consumes Task 1; produces `CommunicationProgressPolicy.rebuild(wordId: Int64, mode: PracticeInputMode, evidence: [WordUseEvidence], now: Date) -> CommunicationProgress`, init(configuration: PracticePolicyConfiguration = .v1).

- [ ] Viết tests có assertions sau, mỗi scenario dùng evidence fixtures riêng:

```swift
#expect(twoSameSession.stage == .practicing)
#expect(twoDifferentSessions.stage == .independentFamiliar)
#expect(at86399Seconds.stage == .independentFamiliar)
#expect(at86400SecondsNewFamily.stage == .transferred)
#expect(assisted.nextPracticeAt == lastAttempt.addingTimeInterval(86_400))
#expect(familiar.nextPracticeAt == lastEligibleUse.addingTimeInterval(259_200))
#expect(transferred.nextPracticeAt == lastEligibleUse.addingTimeInterval(604_800))
```

Named cases: `sameSessionCountsOnce`, `transferRequires86400SecondsAndNewFamily`, `clockRollbackDoesNotPromote`. Thêm tests primed/edited/uncertain/superseded không tăng độc lập; typed không tăng voice; xóa evidence rebuild về noEvidence; clock lùi/timezone đổi không tạo transfer sớm. Unknown outcome không đổi stage/lịch cũ.
- [ ] Chạy `swift test --filter CommunicationProgressPolicyTests`; xác nhận RED.
- [ ] Implement grouping sessionId/mode, thứ tự timestamp + stable ID; mốc transfer tính từ lần độc lập hợp lệ trước ứng viên, không so với chính ứng viên. Lịch dùng thời điểm event hợp lệ, không đặt trước max event timestamp khi clock lùi.
- [ ] Chạy lại suite, PASS; review mọi ngưỡng khớp spec và không phụ thuộc Calendar.current.
- [ ] Commit `feat(ai): derive communication progress from valid evidence` với đúng file task/membership.

## Task 3: Giảm trợ giúp và điều chỉnh độ khó

**Files:** Create `VocabCraftApp/Domain/Policies/GuidedPractice/{SupportPolicy,PracticeDifficultyPolicy}.swift`; Tests `VocabCraftAppTests/AI/GuidedPractice/{SupportPolicyTests,PracticeDifficultyPolicyTests}.swift`.

**Interfaces:** `SupportPolicy.nextLevel(current: PracticeSupportLevel, requestFullModel: Bool) -> PracticeSupportLevel`; `retryLevel(afterSuccessful level: PracticeSupportLevel) -> PracticeSupportLevel`; `isPrimed(wordId: Int64, exposures: [SupportExposure], uncertainWordIds: Set<Int64>, before: Date) -> Bool`. Mốc before lấy lúc learner bắt đầu tạo câu (capture start/typed composition start); exposure sau mốc đó, gồm hiển thị transcript chính lượt đang chấm, không hồi tố làm primed lượt này, nhưng ảnh hưởng lượt sau. `PracticeDifficultyPolicy.next(current: PracticeDifficulty, outcomes: [PracticeOpportunityOutcome]) -> PracticeAdaptationDecision`; outcome gồm opportunityId, intent/usage, support, primed, eligible Bool; decision gồm difficulty và suggestedSupport.

- [ ] Viết tests: none→intent→lexical→frame→model; requestFullModel→model; successful frame retry→lexical; lexical exposure tồn tại suốt phiên, intent không primed. Hai success hợp lệ tăng đúng một trục theo thứ tự; hai failure giảm constraints trước; min constraints tăng support đề xuất; mixed/technical/synonym/earlyExit giữ mức; difficulty max không vượt 2.

Test case chuẩn: `successfulFrameRetryStillPrimed`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(policy.retryLevel(afterSuccessful: .frame) == .lexical)
#expect(policy.isPrimed(wordId: 101, exposures: earlierModel, uncertainWordIds: [], before: attemptStart))
```

- [ ] Chạy `swift test --filter 'SupportPolicyTests|PracticeDifficultyPolicyTests'`; xác nhận RED và có test matching.
- [ ] Implement policy thuần, deduplicate opportunityId; waiting/silence không tạo outcome. Không sửa mission snapshot đang chạy.
- [ ] Chạy lại suites, PASS; review chống giảm hỗ trợ rồi quên priming.
- [ ] Commit `feat(ai): add support fading and difficulty policies`.

**CP1 — Review domain:** Tasks 1–3 xanh; kiểm A03–A06/A09–A12 và ngưỡng 24h/1–3–7 ngày. Reviewer có thể bác policy trước khi storage/UI phụ thuộc nó.

## Task 4: Catalog và chọn từ từ dữ liệu thật

**Files:** Create `VocabCraftApp/Data/GuidedPractice/{PracticeTemplateCatalog,PracticeLearningContextReader}.swift`; Create `VocabCraftApp/Domain/UseCases/GuidedPractice/SelectPracticeMissionUseCase.swift`; Tests `VocabCraftAppTests/AI/GuidedPractice/{PracticeTemplateCatalogTests,SelectPracticeMissionTests}.swift`; Modify `VocabCraftApp/Resources/Localizable.xcstrings`.

**Interfaces:** `PracticeTemplateCatalog.templates -> [PracticeTemplate]`; `PracticeLearningContextReader.load() async throws -> PracticeLearningContext` inject VocabularyDataSourceProtocol, UserProgressRepositoryProtocol, PracticeRepositoryProtocol (Task 6), optional QuickReflex adapter; implement repository contract declaration here in `VocabCraftApp/Domain/Protocols/PracticeRepositoryProtocol.swift`, signatures hoàn chỉnh ở Task 6. `SelectPracticeMissionUseCase.select(context: PracticeLearningContext, templates: [PracticeTemplate], now: Date) -> PracticeSelectionResult`.

- [ ] Viết tests: bookmark-only bị loại; totalReviews>0 hoặc mastery>0 đủ điều kiện; ưu tiên assisted-due → communication-due → noEvidence, tie-break SRS/date/wordId; tối đa 2+1 từ, một từ nếu không ghép tự nhiên; missing vocabulary/duplicate lemma khác nghĩa không map nhầm; history snapshot vẫn đọc được; context reader lỗi không trả demo. Kiểm sáu template (3 family × basic/transfer), tất cả EN/VI keys có bản dịch và sense bindings resolve từ dữ liệu thật.

Test case chuẩn: `bookmarkOnlyDoesNotBecomeLearnedWord`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(selector.select(context: bookmarkOnly, templates: catalog, now: now) == .needsVocabulary)
#expect(selectedMission.targetWordIds.count <= 3)
```

- [ ] Chạy `swift test --filter 'SelectPracticeMissionTests|PracticeTemplateCatalogTests'`; xác nhận RED.
- [ ] Implement chọn bài deterministic bằng compatibility metadata biên soạn, không cần gọi AI để quyết định ID. Liên kết word senses theo Int64 từ vocabulary hiện hữu; QuickReflex chỉ dùng tín hiệu hỗ trợ trong lời khuyên, không biến thành evidence. Không ép các từ không có binding; trả noCompatibleTemplate rõ ràng.
- [ ] Chạy lại suites và `swift test --filter AIAssistantLocalizationTests`; PASS. Reviewer đọc cả sáu nhiệm vụ để kiểm tự nhiên, không chỉ khóa JSON.
- [ ] Commit `feat(ai): select guided missions from learned vocabulary`.

## Task 5: SchemaV3 và migration tương thích App Group

**Files:** Create `VocabCraftApp/Core/Database/Schemas/AppSchemaV3.swift`; Modify `VocabCraftApp/Core/Database/{SharedAppGroupContainer,SwiftDataModels}.swift`; Create `VocabCraftAppTests/Core/Database/GuidedPracticeMigrationTests.swift`; Modify `VocabCraftAppTests/Core/Database/SchemaMigrationTests.swift` khi cần giữ test V1→V2 pinned.

**Interfaces:** SchemaV3.versionIdentifier=3.0.0, giữ nguyên entity cũ qua reuse SchemaV2 types và thêm PracticeSessionRecord/PracticeTurnRecord/SupportExposureRecord/PracticePresentationRecord/WordUseEvidenceRecord/CommunicationProgressRecord. New records giữ UUID/scalar keys để query; JSON payload có formatVersion=1 cho snapshots. Current-store factory mở V3, migration plan gồm V1→V2→V3; không sửa định nghĩa schema V1/V2 đã phát hành.

- [ ] Viết XCTest với disposable on-disk store: V1→V3 và V2→V3 preserve wordId/mastery/ease/interval/sourceDeck/sourceNode/reflex/widget/stage rows; store mới lưu đủ record; reopen giữ pending presentation. Tests V1→V2 cũ dùng explicit SchemaV2 types, không alias current. Unknown payload version lỗi rõ, không reset store.

Test case chuẩn: `v2ToV3PreservesSourceAndSRS`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
XCTAssertEqual(migrated.sourceDeckId, baseline.sourceDeckId)
XCTAssertEqual(migrated.nextReviewDate, baseline.nextReviewDate)
XCTAssertEqual(migrated.masteryLevel, baseline.masteryLevel)
```

- [ ] Chạy Xcode test class GuidedPracticeMigrationTests và SchemaMigrationTests; xác nhận RED do V3 chưa có.
- [ ] Implement additive schema/migration, explicit defaults; cập nhật current typealiases/store factory cho app và widget, kiểm mọi reference SchemaV2 dùng làm current. Không đổi test pinned lịch sử sang schema mới một cách máy móc.
- [ ] Chạy lại Xcode suites và `swift test --filter GuidedPracticeMigrationTests`; ghi rõ test nào conditional compilation đã chạy. Reopen fixtures so sánh tất cả giá trị, không chỉ row count.
- [ ] Commit `feat(ai): migrate guided practice storage to schema v3`.

## Task 6: Repository transactions, idempotency và rebuild

**Files:** Complete `VocabCraftApp/Domain/Protocols/PracticeRepositoryProtocol.swift`; Create `VocabCraftApp/Data/GuidedPractice/{PracticeModelActor,PracticeRecordMapper}.swift`; Test `VocabCraftAppTests/AI/GuidedPractice/PracticeRepositoryTests.swift`.

**Interfaces:** Protocol Sendable có `create(_ session: PracticeSession) async throws`; `loadSession(id: UUID) async throws -> PracticeSessionSnapshot?`; `activeSession() async throws -> PracticeSessionSnapshot?`; `progress() async throws -> [CommunicationProgress]`; `evidence() async throws -> [WordUseEvidence]`; `savePendingTurn(_ turn: PracticeTurn, checkpoint: PracticeCheckpoint, expectedRevision: Int) async throws`; `commit(_ value: PracticeCommit) async throws -> PracticeSessionSnapshot`; `preparePresentation(_ intent: PracticePresentationIntent, expectedRevision: Int) async throws`; `confirmPresentation(id: UUID, exposure: SupportExposure, expectedRevision: Int) async throws`; `revise(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint) async throws -> Int`; `finalize(sessionId: UUID, completion: PracticeCompletion, expectedRevision: Int) async throws -> PracticeSummary`; `deleteSession(id: UUID) async throws`; `deleteAllPractice() async throws`; `resetAllLearningProgress() async throws` cho Task 11 (cùng actor/store, xóa records tiến độ cũ theo reset contract hiện hữu và toàn bộ practice). PracticeSessionSnapshot gồm session, turns, exposures, evidence, progress, pending presentations.

- [ ] Viết tests idempotent commit/finalize, staleRevision bị từ chối, chỉ một assessment valid/turnRevision/word, transcript revision supersede đúng, rollback toàn transaction khi save lỗi, một active session, finalize persisted=true chỉ sau save. Assert SRS/mastery/sourceDeck/XP/todayWordsLearned trước=sau bằng fixture thật và spies.

Test case chuẩn: `repeatedCommitDoesNotDuplicateEvidence`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(afterRetry.evidence == afterFirst.evidence)
#expect(srsAfter == srsBefore)
```

- [ ] Chạy `swift test --filter PracticeRepositoryTests`; xác nhận RED; chạy thêm cùng suite bằng Xcode nếu SwiftPM không compile SwiftData branch.
- [ ] Implement @ModelActor + mapper, explicit save/rollback; scalar compound logical keys dedup trong transaction. Cache rebuild dùng Task 2; giới hạn một active session theo repository writer. prepare/confirm presentation là hai transaction có durable intent, không giả vờ render và database atomic.
- [ ] Chạy suite, PASS; reopen store kiểm idempotency còn đúng sau process restart. Review không có try? nuốt save lỗi.
- [ ] Commit `feat(ai): persist guided sessions and evidence atomically`.

**CP2 — Review dữ liệu:** Tasks 4–6 xanh, A01/A02/A05/A13–A15/A17 có bằng chứng. Kiểm bản sao migration, SRS/source attribution và đường lưu exposure trước khi tích hợp runtime.

## Task 7: AI adapter, capability và xác minh assessment

**Files:** Create `VocabCraftApp/Domain/Protocols/PracticeAIProtocol.swift`; Create `VocabCraftApp/Data/GuidedPractice/PracticeAIAdapter.swift`; Create `VocabCraftApp/Domain/UseCases/GuidedPractice/AssessPracticeTurnUseCase.swift`; Tests `VocabCraftAppTests/AI/GuidedPractice/{PracticeAIAdapterTests,PracticeAssessmentTests}.swift`; Create `VocabCraftAppTests/AI/GuidedPractice/Fixtures/practice-assessment-cases.json`; Modify `Package.swift` testTarget resources và Xcode test resource membership.

**Interfaces:** PracticeAIProtocol Sendable: `func capability() async -> PracticeCapability`, `func respond(to request: PracticeAIRequest) async throws -> PracticeAIResponse`. PracticeAIAdapter.init(provider: any LLMProviderProtocol, capability: PracticeCapability, clock: any PracticeClock); `AssessPracticeTurnUseCase.validate(response: PracticeAIResponse, request: PracticeAIRequest, turn: PracticeTurn, exposures: [SupportExposure], uncertainWordIds: Set<Int64>) throws -> PracticeAssessment`.

- [ ] Viết fixture tests: đúng nghĩa, sai nghĩa, phủ định hợp nghĩa, đồng nghĩa không target, chỉ nhắc tên từ, đọc mẫu, STT không chắc, prompt injection. Assert foreign wordId/objectiveId, invented quote và reply rỗng bị reject; Unicode “I’d recommend…” giữ nguyên span; inflection hợp lệ chỉ khi span thật có trong raw acceptedText; uncertain không nâng stage. Invalid schema repair đúng một lần, network error không repair loop, timeout 30 giây qua ManualPracticeClock.

Test case chuẩn: `unicodeQuoteMustExistInRawAcceptedText`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(validated.evidence.first?.quotedSpan == "I’d recommend")
#expect(throws: PracticeFailure.self) { try validator.validate(response: foreignWord, request: request, turn: turn, exposures: [], uncertainWordIds: []) }
```

- [ ] Chạy `swift test --filter 'PracticeAIAdapterTests|PracticeAssessmentTests'`; xác nhận RED.
- [ ] Implement adapter dùng sendStructuredMessage với schema mới cho provider thực sự hỗ trợ. Capability registry dựa trên implementation đã kiểm: AppleIntelligenceOrLocalDialogueProvider hiện cast RoleplayTurnOutput nên không được quảng cáo hỗ trợ schema mới. Cho pack này dùng adapter hội thoại template được biên soạn/localized, canGenerateDialogue=true/canAssessUsage=false; đóng vai theo objective hiện tại, không giả assessment. Provider khác chỉ canAssessUsage=true sau contract suite. Fixture JSON được `.copy("AI/GuidedPractice/Fixtures/practice-assessment-cases.json")` trong testTarget resources; load Bundle.module dưới SWIFT_PACKAGE, Bundle(for: PracticeFixtureBundleAnchor.self) dưới Xcode, anchor là NSObject class ở PracticeFixtures.swift. Tách system instructions khỏi learner content; history tối đa 8 accepted turns, snapshot mục tiêu giữ riêng, không cắt câu đang chấm.
- [ ] Chạy suites và các test provider/AI Pack hiện có; PASS. Kiểm bằng code rằng không network fallback giữa pack, không expose key/log transcript. Reviewer đọc rubric JSON; ngữ pháp/ý nghĩa cần kiểm người ở Task 15.
- [ ] Commit `feat(ai): validate guided dialogue and assessment capabilities`.

## Task 8: Speech adapter và sự kiện playback thật

**Files:** Create `VocabCraftApp/Domain/Protocols/PracticeSpeechProtocol.swift`; Create `VocabCraftApp/Data/GuidedPractice/PracticeSpeechAdapter.swift`; Modify `VocabCraftApp/Domain/Protocols/TTSEngineProtocol.swift`, `VocabCraftApp/Data/Audio/Engines/{AppleTTSEngineAdapter,KokoroTTSEngineAdapter,GeminiTTSEngineAdapter}.swift`, `VocabCraftApp/Core/Audio/{AppleEnhancedTTSEngine,KokoroTTSEngine,GeminiAudioSpeechEngine}.swift`; Create `VocabCraftAppTests/AI/GuidedPractice/PracticeSpeechAdapterTests.swift`.

**Interfaces:** @MainActor PracticeSpeechProtocol: `func capture(locale: String) -> AsyncThrowingStream<PracticeSpeechEvent, Error>`, `func play(text: String, voice: VoiceConfiguration) -> AsyncThrowingStream<PracticeSpeechEvent, Error>`, `func stop() async`. Thêm opt-in `PlaybackReportingTTSEngineProtocol: TTSEngineProtocol` với `synthesizeAndPlay(text: String, voice: VoiceConfiguration, onPlaybackStarted: @escaping @Sendable () -> Void) async throws`; giữ overload cũ cho callers. Engine không có callback thật được capability canPlaySpeech=false cho luồng mới, thay vì phát event khi bắt đầu synthesize.

- [ ] Viết tests: captureStopped trước playbackStarted, preparation failure không phát started, started chỉ một lần, cancel release mic/TTS/lease, playback started rồi lỗi vẫn có exposure candidate, stop await xong mới capture lại. STT không có confidence vẫn có thể trả usable khi learner chủ động kết thúc và xác nhận text; raw partial không tự biến thành final; empty/interrupted text needsConfirmation. TTS chuẩn bị timeout đúng 20 giây, playback sau started không bị preparation timer cắt ở giây 20.

Test case chuẩn: `captureStopsBeforeActualPlayback`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
let stopped = try #require(events.firstIndex(of: .captureStopped))
let started = try #require(events.firstIndex(of: .playbackStarted))
#expect(stopped < started)
#expect(preparationFailureEvents.contains(.playbackStarted) == false)
```

- [ ] Chạy `swift test --filter PracticeSpeechAdapterTests`; xác nhận RED.
- [ ] Implement bridge STTEngineProtocol/TTSEngineProtocol và AudioSessionCoordinator hiện có. Hook AVSpeechSynthesizerDelegate.didStart trong AppleEnhancedTTSEngine và actual player start trong KokoroTTSEngine/GeminiAudioSpeechEngine thay vì suy ra từ await call. Nếu engine bên dưới không cung cấp start đáng tin, giữ adapter đó text-only với capability rõ ràng và test lý do. Không thêm runtime audio mới; template text luôn khả dụng khi canPlaySpeech=false. Raw recording file optional chỉ khi engine cung cấp; không giả nút nghe lại nếu không có file.
- [ ] Chạy suite và `swift test --filter 'AudioSessionCoordinatorTests|TTSEngineAdapterTests'`; PASS. Kiểm membership của file engine sửa; nếu nằm SpeechKit chạy package suite tương ứng.
- [ ] Commit `feat(ai): report speech capture and actual playback lifecycle`.

## Task 9: Coordinator phiên và giao dịch xử lý lượt

**Files:** Create `VocabCraftApp/Features/AIAssistant/GuidedPractice/PracticeSessionCoordinator.swift`; Test `VocabCraftAppTests/AI/GuidedPractice/PracticeSessionCoordinatorTests.swift`.

**Interfaces:** @Observable @MainActor PracticeSessionCoordinator.init(repository: any PracticeRepositoryProtocol, ai: any PracticeAIProtocol, speech: any PracticeSpeechProtocol, clock: any PracticeClock, policy: PracticePolicyConfiguration); observable state/session/summary/failure/currentSupport. `start(mission: PracticeMission, mode: PracticeInputMode) async`; `submit(text: String, mode: PracticeInputMode) async`; `startCapture() async`; `finishCapture() async`; `finish(_ completion: PracticeCompletion) async`; `pause() async`; `switchInput(to mode: PracticeInputMode) async`. Các methods sau ở extension Tasks 10–11 dùng cùng owner, không tạo view model thứ hai.

- [ ] Viết tests state transitions text và voice: savePendingTurn xảy ra trước gọi AI; commit trước next turn; original mode còn nguyên khi chuyển input; double tap submit trong pending chỉ một turn/request; reply từ token cũ không commit; prompt không có full learner history; partial không đánh fail objective chưa có cơ hội; finish hai lần cùng summary, không XP/SRS writes.

Test case chuẩn: `doubleSubmitUsesOnePendingTurn`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(persistedUserTurns.count == 1)
#expect(aiRequestCount == 1)
```

- [ ] Chạy `swift test --filter PracticeSessionCoordinatorTests`; xác nhận RED.
- [ ] Implement state-machine guards và lưu Task handles tại coordinator; inject Task 2/3 policy và Task 7 validator. Before await đổi state ngay; sau mỗi await kiểm operation token. Không nhận objective mới ngoài mission. Provider canAssessUsage=false trả summary chưa đánh giá được, không sinh evidence appropriate giả.
- [ ] Chạy suite và `swift test --filter PracticeRepositoryTests`; PASS; review actor reentrancy và cancellation giữa từng await.
- [ ] Commit `feat(ai): orchestrate guided practice turns with durable checkpoints`.

## Task 10: Presentation intent, ghi exposure và trợ giúp

**Files:** Create `VocabCraftApp/Features/AIAssistant/GuidedPractice/PracticeSessionCoordinator+Presentation.swift`; Test `VocabCraftAppTests/AI/GuidedPractice/PracticePresentationTests.swift`.

**Interfaces:** `requestHelp(fullModel: Bool = false) async`; `preparePresentation(content: String, channel: PracticePresentationChannel, origin: SupportOrigin, wordIds: Set<Int64>, level: PracticeSupportLevel) async -> PracticePresentationIntent?`; `confirmPresented(intentId: UUID, at: Date) async`; `retryWithLessSupport() async`. Prepared content được UI hiển thị chỉ sau prepare thành công; UI onAppear hoặc speech playbackStarted gọi confirm.

- [ ] Viết tests: generation chưa render không exposure; prelessonReview/characterSpeech/correction/transcriptReplay có từ tạo exposure đúng; unknown mapping primed toàn targets; prepare save lỗi không present; confirm save lỗi giữ pending intent + block independence; crash sau render trước confirm resume bảo thủ; double tap help không nhảy hai mức; fullModel request đi thẳng model; intent-only không lexical priming.

Test case chuẩn: `failedConfirmationRetainsConservativeExposure`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(restored.session.checkpoint.exposureUncertainWordIds.contains(101))
#expect(rebuilt.independentEvidenceIds.isEmpty)
```

- [ ] Chạy `swift test --filter PracticePresentationTests`; xác nhận RED.
- [ ] Implement durable intent trước giao diện/audio; mọi display content đi qua cùng boundary, kể cả greeting và transcript chứa target. Khi resume, pending intent chưa rõ có trình bày được giữ exposureUncertain; không tự xóa cờ để đạt độc lập. Một lần thử lại thay chi tiết trong biến thể template, giảm một mức nhưng giữ priming của phiên.
- [ ] Chạy suite cùng SupportPolicyTests; PASS; reviewer trace một từ từ ôn trước đến summary và kiểm không sót đường render.
- [ ] Commit `feat(ai): track presented support and conservative priming`.

## Task 11: Recovery, xóa dữ liệu và reset toàn app

**Files:** Create `VocabCraftApp/Features/AIAssistant/GuidedPractice/PracticeSessionCoordinator+Recovery.swift`; Create `VocabCraftApp/Data/GuidedPractice/PracticePrivacyStore.swift`; Modify `VocabCraftApp/Domain/UseCases/ResetUserProgressUseCase.swift`, `VocabCraftApp/Data/Repositories/SRSRepositoryImpl.swift` và method resetAllProgress trong `VocabCraftApp/Data/Local/Actors/UserProgressModelActor+Mutations.swift`; Tests `VocabCraftAppTests/AI/GuidedPractice/{PracticeRecoveryTests,PracticeDeletionTests}.swift`.

**Interfaces:** Coordinator `resume(sessionId: UUID) async`, `retryPendingTurn() async`, `retrySave() async`, `replaceTranscript(turnId: UUID, text: String) async`, `switchProvider(to ai: any PracticeAIProtocol) async`, `deleteCurrentSession() async`. PracticePrivacyStore.init(directory: URL); `removeTemporaryAudio(sessionId: UUID) throws`, `removeAllTemporaryAudio() throws`. Reset initializer giữ API cũ hoặc cập nhật mọi caller; production bắt buộc inject practice repo, không optional bypass.

- [ ] Viết tests app background dừng audio/checkpoint; resume không tự bật mic; crash sau pending chỉ một user turn; edited transcript supersede assessment và loại khỏi voice progress; provider switch revision bỏ callback cũ. Delete trong pending rồi complete callback không tái tạo rows; xóa một session rebuild word progress; full reset xóa communication + SRS; injected failure không được báo reset thành công và retry hoàn tất.

Test case chuẩn: `lateCallbackCannotResurrectDeletedSession`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(try await repository.loadSession(id: deletedID) == nil)
let remainingEvidence = try await repository.evidence()
#expect(remainingEvidence.isEmpty)
```

- [ ] Chạy `swift test --filter 'PracticeRecoveryTests|PracticeDeletionTests'`; xác nhận RED.
- [ ] Implement deletion tombstone/revision guard trong repository; xóa session và rebuild một transaction. Full reset cùng store dùng một actor-owned transaction xóa cả records cũ cần reset và practice records; SRSRepositoryImpl delegate reset tới writer đó, không delete hai store contexts rồi giả atomic. Dọn audio tạm sau commit, có retry cleanup và chặn playback; không log transcript. Khi task đang pending, cancel + revision trước delete.
- [ ] Chạy suites, ResetUserProgressUseCaseTests hiện có nếu có, và Xcode storage tests; PASS; kiểm remove temp files chỉ dưới directory của practice, không chạm recordings khác.
- [ ] Commit `feat(ai): recover and delete guided practice sessions safely`.

**CP3 — Review runtime:** Tasks 7–11 xanh; trace A03/A04/A08/A09/A13–A16 qua fake clock/STT/TTS/repository failures. Gate bắt buộc: không có đường UI/audio hoặc retry lách exposure, không đánh giá giả khi provider không hỗ trợ. Review đây là điều kiện để nối entry point.

## Task 12: Hub và màn chuẩn bị bằng CraftUIKit

**Files:** Create `VocabCraftApp/Features/AIAssistant/GuidedPractice/{PracticeHubViewModel,PracticeHubView,PracticePreparationView}.swift`; Create `VocabCraftApp/Core/Localization/AppStrings+GuidedPractice.swift`; Modify `VocabCraftApp/Resources/Localizable.xcstrings`; Tests `VocabCraftAppTests/AI/GuidedPractice/{PracticeHubTests,GuidedPracticeLocalizationTests}.swift`.

**Interfaces:** @Observable @MainActor PracticeHubViewModel.init(contextReader: PracticeLearningContextReader, repository: any PracticeRepositoryProtocol, selector: SelectPracticeMissionUseCase, clock: any PracticeClock); `load() async`; state loading/recommended/resumable/needsVocabulary/noCompatibleTemplate/error. Views nhận model và closures `onStart: (PracticeMission, PracticeInputMode) -> Void`, `onResume: (UUID) -> Void`, `onOpenLesson: () -> Void`. Preparation nhận coordinator và mission, gọi prepare/confirm exposure cho ôn trước.

- [ ] Viết tests resume ưu tiên recommended, data failure không demo, no compatible template khác chưa học từ; capability kiểm voice permission đúng lúc, thiếu LLM không được quảng cáo text recovery. Localization tests duyệt app.ai_assistant.guided.*: EN/VI, manual/translated, placeholders và a11y parity.

Test case chuẩn: `resumableSessionWinsOverRecommendation`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(model.state == .resumable(existingID))
#expect(shownTargetWords.isEmpty)
```

- [ ] Chạy `swift test --filter 'PracticeHubTests|GuidedPracticeLocalizationTests'`; xác nhận RED.
- [ ] Implement với CraftActionCard/Card/ListRow/EmptyState/ChoiceCard/Button/Badge hiện có, không raw styling. CTA chính “Bắt đầu luyện” / “Start practice”, resume “Tiếp tục” / “Continue”, ôn trước “Ôn từ trước” / “Review words first”; phần còn lại EN/VI tự nhiên theo chức năng spec. Không hiện target list mặc định; không dùng chuỗi raw trong fallback/a11y. Tạo previews loaded/loading/error/empty/resumable qua fixtures.
- [ ] Chạy suites và CraftUIKit LocalizationTests; PASS. Review API components, Dynamic Type và quyền bị từ chối ở preview/runtime; nếu thiếu component, dừng phần đó để trao đổi theo AGENTS.md.
- [ ] Commit `feat(ai): build guided practice hub and preparation flow`.

## Task 13: Screen thực hành và summary có bằng chứng

**Files:** Create `VocabCraftApp/Features/AIAssistant/GuidedPractice/{PracticeSessionView,PracticeSummaryView,PracticePresentationState}.swift`; Modify `VocabCraftApp/Resources/Localizable.xcstrings`; Tests `VocabCraftAppTests/AI/GuidedPractice/{PracticePresentationStateTests,PracticeSummaryTests}.swift`.

**Interfaces:** `PracticeSessionView(coordinator: PracticeSessionCoordinator, onClose: () -> Void)` và `PracticeSummaryView(summary: PracticeSummary, onContinue: () -> Void, onDelete: (UUID) -> Void)`; `PracticePresentationState.make(from state: PracticeSessionState, capability: PracticeCapability) -> PracticePresentationState` có canSubmit/canCapture/canRequestHelp/showUnsaved/messageKey; summary rows dùng evidenceId để mở quotedSpan cùng support/inputMode, không re-assess trong view.

- [ ] Viết tests state processing vô hiệu submit; paused không capture tự động; error storage hiện chưa lưu; noAssessment không stage badge giả; summary không fluency/XP, partial không báo fail objective chưa thử, text/voice/edited phân biệt. Mỗi presented content confirm đúng intentId; repeat render không nhân support level.

Test case chuẩn: `unsavedSummaryNeverLooksCompleted`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(presentation.showUnsaved)
#expect(summary.persisted == false)
```

- [ ] Chạy `swift test --filter 'PracticePresentationStateTests|PracticeSummaryTests'`; xác nhận RED.
- [ ] Implement CraftTactileMicHubView/TextField/Button/Card/Badge/ListRow/FeedbackSheet; một NavigationStack cho flow, không stack modal. Coach inline tối đa một trọng tâm; mục tiêu theo objectives; help progressive, full model theo yêu cầu; render text reply cả khi TTS lỗi; nghe lại chỉ khi có audio hợp lệ. .task/.onChange scenePhase gọi coordinator, không tạo owner/task ngầm trong body.
- [ ] Chạy suites + GuidedPracticeLocalizationTests. Preview mỗi runtime state; kiểm VoiceOver reading order, AX Dynamic Type không che controls, Reduce Motion không mất trạng thái, bàn phím không che nút gửi. Xác minh runtime bằng Task 15, unit tests không thay visual evidence.
- [ ] Commit `feat(ai): present guided conversation and evidence summaries`.

## Task 14: DI, entry flag và end-to-end regression

**Files:** Modify `VocabCraftApp/App/DI/AppContainer.swift`, `VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`; Create `VocabCraftApp/Core/Configuration/GuidedPracticeFeatureConfiguration.swift`; Tests `VocabCraftAppTests/AI/GuidedPractice/GuidedPracticeIntegrationTests.swift`; Modify `VocabCraftAppTests/App/AppContainerAITests.swift`.

**Interfaces:** GuidedPracticeFeatureConfiguration.enabled Bool (default false, developer setting/launch argument only); AppContainer `makePracticeHubViewModel() -> PracticeHubViewModel`, `makePracticeSessionCoordinator() -> PracticeSessionCoordinator`. Existing hub routes to new experience when enabled; disabled path hiểu schema V3, không xóa dữ liệu mới. AI Pack selection do người dùng quyết định; adapter capability derives từ pack/provider thật.

- [ ] Viết integration tests create mission→ôn trước→submit→retry→summary→reopen→delete; assert same session ID voice/text, exposure chain và SRS nguyên vẹn. Flag off vẫn mở V3, old roleplay/Shadowing routes giữ được; reset wired repo thật; provider switch không key leakage. Template version cập nhật không rewrite snapshot cũ; history chỉ có lemma string trùng nghĩa không backfill evidence.

Test case chuẩn: `flagOffPreservesV3StoreAndLegacyRoutes`; phần arrange dùng scenario được mô tả ở bước trên, assertions bắt buộc:

```swift
#expect(reopenedEvidence == storedEvidence)
#expect(srsAfter == srsBefore)
```

- [ ] Chạy `swift test --filter 'GuidedPracticeIntegrationTests|AppContainerAITests'`; xác nhận RED.
- [ ] Implement DI/flag/routes, dùng một repository writer và coordinator trên mỗi active session; giữ strong ownership xuyên screen. Không gọi CompleteRoleplaySessionUseCase từ luồng mới; không vô tình cập nhật todayWordsLearned. Feature flag chỉ mở pilot/internal sau CP4, không tự bật public.
- [ ] Chạy suites và regression AI/Shadowing hiện có. Review project diff để app/test/widget include đúng files; giải thích mọi generated diff trước staging.
- [ ] Commit `feat(ai): integrate guided practice behind an internal flag`.

**CP4 — Review tích hợp:** Tasks 12–14 xanh; reviewer chạy text flow visible, voice với fake engine, inspect localization/token conformance và dữ liệu trước/sau. Mọi A01–A18 có test owner trước full verification. Chưa coi CP4 là chứng nhận thiết bị thật hoặc pilot.

## Task 15: Full verification, thiết bị thật và pilot learner

**Files:** Create `docs/qa/ai-guided-practice-verification.md`, `docs/qa/ai-guided-practice-pilot.md`. Product fixes phát hiện ở bước này quay về task sở hữu, RED→GREEN và review lại; không gom vào commit tài liệu.

**Interfaces:** Verification record ghi git SHA, toolchain, command, destination, thời gian, exit code, warning/error count, result/artifact path và trạng thái verified/failed/unavailable. Pilot record dùng participant ID giả danh, mức A2/B1 tự khai, session timestamps, actual provider/device và consent cho việc reviewer đọc câu nói; không lưu tên/API keys.

- [ ] Chạy baseline ở execution trước Task 1 và ghi lỗi sẵn có. Sau Task 14, chạy `swift test`, `swift test --package-path Packages/CraftUIKit`, `swift test --package-path Packages/SpeechKit`, CraftUIKit LocalizationTests, `swiftlint --strict`, full Xcode VocabCraftAppTests scheme test và `xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator' build`. Với package thiếu nền tảng, ghi failure và xử lý, không biến suite skipped thành pass.
- [ ] Ghi log/xcresult đầy đủ; mỗi lệnh phải exit 0, tất cả tests pass, compiler/lint 0 warnings/0 errors. Chạy thêm `git diff --check` và review membership/generated metadata. Không claim complete nếu còn lỗi baseline.
- [ ] Thực hiện visible EN và VI flow trên simulator: happy path text, help cả năm mức, partial, missing vocabulary, permission denial, invalid schema, retry save, resume pending, delete. Kiểm Dynamic Type mức accessibility, VoiceOver trên thiết bị và Reduce Motion; lưu captures cùng bước tái hiện. Kiểm app và widget cùng mở store V3.
- [ ] Chạy thiết bị thật với mic/TTS/route change/headphone/background/cuộc gọi gián đoạn; capture stop trước TTS start; permission denied; network loss; model local unavailable/ready theo pack thực tế. Chỉ kiểm inference local bằng thiết bị hỗ trợ, không thay bằng simulator hay mock. Ghi capability thực tế và phản hồi chưa đánh giá nếu provider không hỗ trợ.
- [ ] Human rubric review bộ assessment fixture Task 7 và sample cloud/local thực tế: kiểm nghĩa mục tiêu, synonym, negation, quote, một trọng tâm sửa. Mọi false promotion phải có root cause và test bổ sung. Chỉ mở pilot khi review kỹ thuật toàn branch không còn finding ảnh hưởng correctness/data loss.
- [ ] Thực hiện pilot 6 learner A2–B1 thật, mỗi người ba phiên trên thiết bị thật, các phiên cách nhau >=24 giờ. Ghi completion, help level từng từ, tự dùng buổi sau, AI assessment corrections và gián đoạn. Reviewer kiểm mọi transferred bằng quoted evidence. >=5/6 tự tìm trợ giúp và kết thúc mà không được chỉ thao tác; 0 mất dữ liệu/cộng trùng trong QA scenarios. Thiếu người/thiết bị/thời gian thì ghi unavailable và chờ điều kiện thực; không dùng bot thay.
- [ ] Review CP5 release: đủ kỹ thuật + rubric + pilot mới xét mở rộng rollout. Pilot chỉ chứng minh usability ban đầu, không tuyên bố hiệu quả thống kê. Commit hai tài liệu với kết quả thật, `docs(ai): record guided practice verification and learner pilot`; không điền sẵn pass.

## Coverage và checkpoint cuối

| Acceptance | Task/test owner | Runtime/human evidence |
|---|---|---|
| A01–A02 | 4: SelectPracticeMissionTests/TemplateCatalogTests | 15: empty/compatibility visible |
| A03–A04 | 3,10: SupportPolicyTests/PracticePresentationTests | 15: ôn trước, nhân vật nhắc từ |
| A05–A06 | 2,3,6,10: policy/repository/presentation | 15: câu mẫu, retry giảm gợi ý |
| A07 | 7: PracticeAssessmentTests | 15: human rubric synonym |
| A08–A09 | 2,8,11: progress/speech/recovery | 15: STT/edited/text thiết bị |
| A10–A12 | 2: CommunicationProgressPolicyTests | 15: phiên sau + context mới |
| A13–A15 | 6,9,10,11: storage/coordinator/recovery | 15: fault injection/crash/save |
| A16 | 7,14: adapter/integration | 15: pack capability thật |
| A17 | 5,6,11: migration/deletion | 15: reopen app/widget |
| A18 | 4,12,13: localization/presentation | 15: EN/VI, AX, VoiceOver |

CP5 gồm full-branch review và xác minh trước khi báo hoàn thành. Thực hiện requesting-code-review và verification-before-completion theo execution method đã chọn; xử lý findings theo receiving-code-review. Nếu pilot còn unavailable, báo rõ phần implementation đã xác minh và phần nghiệm thu đang chờ, không đánh dấu toàn feature complete.

## Tự review kế hoạch

- Spec 1–6 → Tasks 1–4; spec 7 → Tasks 12–13; spec 8–9 → Tasks 1,5,6,9,14; spec 10 → Task 7; spec 11 → Tasks 8–11; spec 12 → Tasks 5,11,14; spec 13–14 → coverage table/Task 15; spec 15 → handoff bên dưới.
- Đã kiểm type/signature dùng chung; repo protocol khai báo Task 4 để context reader compile, implementation Task 6; các tasks không phụ thuộc file chưa khai báo.
- Review Focus có test ở đúng task sở hữu. Không có subagent dispatch trong bước lập kế hoạch; self-review được thực hiện inline.
- Đây là kế hoạch thực thi, các checkbox còn mở có chủ ý. Không có kết quả test/pilot được giả định đã pass.

## Handoff

Kế hoạch cần người dùng review trước khi viết product code. Chọn một execution method:

1. **Subagent-driven:** implementer mới và reviewer mới cho từng task, review toàn branch cuối. Đề xuất cho kế hoạch này vì các sai lệch ở exposure/storage có thể làm sai bằng chứng học; review ngay từng interface giúp bắt lỗi trước khi lan sang UI.
2. **Native:** agent hiện tại thực hiện mọi task, review kỹ thuật ở CP1–CP4, một fresh reviewer kiểm toàn branch cuối. Giảm số context nhưng không có independent reviewer từng task.

Chỉ sau khi người dùng duyệt kế hoạch và chọn cách thực thi mới invoke subagent-driven-development hoặc executing-plans. Không thực thi Tasks 1–15 trong lượt lập kế hoạch.
