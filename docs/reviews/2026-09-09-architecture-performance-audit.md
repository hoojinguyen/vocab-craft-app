# Audit kiến trúc và hiệu năng VocabCraft — 09/09/2026

Kết luận: repo có nền tảng MVVM + Observation, dependency injection và packages tốt, nhưng **chưa đạt Clean Architecture nghiêm ngặt và chưa tuân thủ đầy đủ AGENTS.md**. Có các đường xử lý lặp và rủi ro lưu trữ cần xử lý trước khi chứng nhận sẵn sàng cho thiết bị thật. Không có số liệu FPS, CPU, RAM hoặc pin trên iPhone thật trong audit này.

## Phạm vi và phương pháp

Quét inventory, imports, symbol references, task/timer, persistence, styling và localization trên 272 file Swift sản phẩm (57.732 dòng trước cleanup): app, widget, CraftUIKit và SpeechKit. Đọc sâu composition root, Home, Vault, Lesson, Mixed/Blitz Reflex, audio lifecycle, database/repositories, learning path và các test liên quan. Đây là rà soát tĩnh trên toàn repo với đọc sâu các luồng chính, không phải xác minh mọi dòng hay chứng minh vắng hoàn toàn dead code.

Skills áp dụng: swift-architecture, swiftui-patterns, swiftui-performance, swiftui-performance-audit, swift-concurrency, swiftdata, xcodebuildmcp verification-before-completion và systematic-debugging. Đánh giá theo target thực tế iOS 17+, Swift language mode 5; không áp các API Swift 6.3/iOS 26 trong skills một cách máy móc.

Mỗi vấn đề dưới đây tách bằng chứng tĩnh khỏi tác động runtime chưa đo. P1: nên giải quyết trước khi release; P2: nên xử lý trong đợt tối ưu tiếp theo.

## Các phát hiện ưu tiên

### 1. P1 — Recovery database có thể xoá tiến độ học

`SharedAppGroupContainer.createContainer()` bắt mọi lỗi mở/migrate store rồi xoá database, WAL và SHM. Không phân loại lỗi, không giữ bản sao, không yêu cầu thao tác reset. `VocabCraftApp.init()` còn fallback sang in-memory nếu tạo persistent container thất bại.

Bằng chứng: [SharedAppGroupContainer.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Database/SharedAppGroupContainer.swift:67), [VocabCraftApp.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/App/VocabCraftApp.swift:35).

Hệ quả: lỗi I/O hoặc migration có thể chuyển thành mất dữ liệu; fallback RAM có thể khiến người dùng tưởng tiến độ đã được lưu. Đây là lỗi chính sách phục hồi có bằng chứng, không phải khẳng định đã xảy ra mất dữ liệu trên máy người dùng.

Hướng xử lý: giữ nguyên store khi lỗi; trả lỗi có kiểu; cung cấp retry/recovery rõ ràng. Đóng băng model của từng VersionedSchema: V1/V2 hiện cùng trỏ vào các model top-level đang thay đổi, không mô tả độc lập cấu trúc lịch sử. Test migration bằng fixture database cũ thật, mở lại và kiểm tra dữ liệu sau lỗi. Ước lượng 1–2 ngày, phụ thuộc fixture lịch sử.

### 2. P1 — Domain phụ thuộc ngược vào UI và concrete infrastructure

`FetchLearningPathUseCase` import CraftUIKit, trả `LessonSection`, gọi `LearningPathDataMapper` trong Features/Homepage. `FetchPersonalVaultUseCase.swift` import SwiftUI và chứa title/localization cho filter. `PracticeDrillPlanGenerator` dùng model/builder nằm trong Features/Reflex. `InitializeUserRoadmapUseCase` nhận concrete `UserSettingsStore` trong Core.

Bằng chứng: [FetchLearningPathUseCase.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift), [FetchPersonalVaultUseCase.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift), [PracticeDrillPlanGenerator.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/UseCases/PracticeDrillPlanGenerator.swift), [InitializeUserRoadmapUseCase.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/UseCases/InitializeUserRoadmapUseCase.swift).

Các thư mục đang tạo cảm giác phân lớp nhưng compiler chưa bảo vệ hướng dependency: app vẫn là một target. Hướng xử lý: Domain chứa entity/policy/protocol độc lập; mapping sang CraftUIKit và title của filter thuộc Presentation; model kế hoạch luyện tập dùng chung chuyển vào Domain; settings qua protocol hẹp. Giữ MVVM hiện có, không cần chuyển toàn app sang TCA/VIPER. Tách package Domain sau khi làm sạch một lát cắt Home hoặc Vault, không rewrite cả UI lẫn persistence cùng lúc. Ước lượng 2–4 ngày cho lát cắt đầu.

### 3. P1 — SwiftData model vượt ranh giới actor

`StageProgressRepositoryProtocol.fetchAllStageProgress()` chạy MainActor nhưng trả `[UserStageProgress]` là các `@Model`. `FetchLearningPathUseCase.execute()` không MainActor nhận chúng qua `async let` và truyền vào mapper. Trong khi đó, nhánh UserProgress đã dùng `UserWordProgressData: Sendable`, là hướng tốt hơn.

Bằng chứng: [StageProgressRepository.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Database/Repositories/StageProgressRepository.swift:7), [FetchLearningPathUseCase.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift:23).

Đây là lỗ hổng ranh giới isolation; chưa ghi nhận crash/race trong audit. Trả snapshot giá trị Sendable của stage, không đưa model/context ra khỏi actor sở hữu. `@unchecked Sendable` ở repository không làm model SwiftData an toàn khi trao đổi. Build đang ở Swift 5 và không cấu hình explicit strict concurrency complete, nên build xanh chưa chứng minh tương đương Swift 6 data-race safety. Ước lượng 0,5–1 ngày và test cập nhật đồng thời.

### 4. P1 — Nguồn sample và dữ liệu tiến độ thử nghiệm lọt vào luồng thường

`AppContainer` chọn `SampleVocabularyDataSource()` ở cả hai nhánh của `useSampleData`. Dataset hiện có 4 deck, 8 stage, 50 từ. `VocabularyView.task` luôn gọi `SampleVaultDataSeeder.seedIfEmpty`, không giới hạn DEBUG/demo; seeder ghi cả mastery/bookmarks/mistakes và gọi save nhiều lần.

Bằng chứng: [AppContainer.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/App/DI/AppContainer.swift:79), [VocabularyView.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift:291), [SampleVaultDataSeeder.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Database/SampleData/SampleVaultDataSeeder.swift:183).

Không nên xoá SampleVocabularyDataSource ngay vì đó là nguồn đang được dùng thật. Cần wiring production rõ ràng, mode demo riêng và seed chỉ khi được chọn. Với 50 từ, nhiều thuật toán quét toàn bộ vẫn có vẻ nhanh; chưa thể ngoại suy sang hàng nghìn từ. Ước lượng 0,5 ngày để tách cấu hình; adapter production phụ thuộc schema dataset.

### 5. P2 — Vault đọc toàn bộ dữ liệu hai lần cho mỗi lần load

`PersonalVaultViewModel.loadData()` gọi tuần tự `execute()` rồi `fetchVaultWords()`. Mỗi hàm đều fetch toàn bộ progress, lấy toàn bộ word IDs, dựng map và projection rồi mới filter/search. Khi bookmark cũng reload toàn bộ. View đã debounce search 300 ms, nên không đúng nếu nói mỗi phím bấm đều trực tiếp query DB.

Bằng chứng: [PersonalVaultViewModel.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift:72), [FetchPersonalVaultUseCase.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift:121).

Chi phí tĩnh: hai lần đọc progress + hai lần lookup words trên mỗi load, O(N) dữ liệu và nhiều allocation; không có paging. Các lần load từ refresh/bookmark có thể chồng với task search vì không cùng một generation. Hướng xử lý: một snapshot cho metrics + rows; một owner cho request/cancellation; paging/filter ở repository hoặc snapshot cache có invalidation; bookmark cập nhật item rồi đồng bộ. Không chỉ thêm debounce lần nữa. Ước lượng 1–2 ngày; test query count, kết quả mới nhất thắng và cancellation.

### 6. P2 — Timer Mixed Reflex làm thay đổi state cấp màn hình khoảng 33 lần/giây

`startTimer` ngủ 30 ms, ghi `viewModel.elapsedTimeMs` và `fractionRemaining`; body đọc dữ liệu này qua header/hints/mode view. Các computed view functions không tạo ranh giới Observation độc lập. Timer còn không kiểm tra cancellation ngay sau `try? await Task.sleep`, nên task cũ có thể ghi thêm state sau khi bị huỷ.

Bằng chứng: [MixedReflexDrillView.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift:470).

Tần suất được suy ra từ code, không phải FPS đo được. Hướng xử lý: timestamp/deadline và một timeout task; TimelineView chỉ nằm ở leaf timer; hint cập nhật tại các mốc; kiểm tra cancellation/generation trước mọi ghi state sau await. Blitz đã dùng các mốc hint và timeout riêng nên có thể tham khảo contract đó. Ước lượng 0,5–1 ngày; kiểm tra timeout, pause, skip và chuyển câu sát deadline.

### 7. P2 — Startup tạo speech services không có consumer UI hiện hành

Composition root luôn tạo `SpeechRecognitionService` (có AVAudioEngine và recognizer) và `SpeechAssessmentService` (khởi tạo engine/recognizer). `sttService` không được gọi từ Features; environment speechAssessment được inject nhưng không có view đọc. Luồng luyện tập hiện dùng `ResilientReflexSpeechEngine`.

Bằng chứng: [AppContainer.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/App/DI/AppContainer.swift:104), [SpeechRecognitionService.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Audio/SpeechRecognitionService.swift:25), [SpeechAssessmentService.swift](/Users/hoojinguyen/Projects/vocab-craft-app/Packages/SpeechKit/Sources/SpeechKit/SpeechAssessmentService.swift:30).

Có chi phí khởi tạo dư tiềm tàng trên cold launch. Không kết luận các engine này đang ghi âm, không kết luận leak. Nên bỏ wiring không dùng hoặc khởi tạo lazy; giữ phần SpeechKit evaluation/adapter có consumer và tests. Ước lượng 0,5 ngày, đo cold launch trước/sau nếu triển khai.

### 8. P2 — Learning path chưa có giới hạn tải theo quy mô

Use case tải mọi deck, stage và toàn bộ words của mọi stage trước khi trả sections; tạo một task/stage không giới hạn. Mapper chỉ cần count và vài từ preview ở Home. UI lazy theo section nhưng nodes trong mỗi section được dựng bằng VStack; hai lớp ambient blur 40/50 px là chi phí compositing đáng đo trên máy thấp.

Bằng chứng: [FetchLearningPathUseCase.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift:20), [LearningPathDataMapper.swift](/Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift), [CraftFluidJourney.swift](/Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift:453).

Hiện chỉ 4 deck/8 stage nên chưa phải bằng chứng bottleneck nghiêm trọng. Nên có API summary, cache curriculum tĩnh, tải words khi mở bài, giới hạn concurrency khi nguồn dữ liệu tăng. Không đổi mọi VStack thành LazyVStack một cách máy móc vì scrollTo/pinned header có contract cần giữ. Ước lượng 1–2 ngày khi mở rộng dataset.

### 9. P2 — Scroll offset ghi state rộng; styling/localization chưa đúng chuẩn

Vault ghi `lastScrollOffset` ở mỗi preference update, đồng thời show/hide search header làm thay đổi layout. Có threshold cho một số state nhưng raw offset vẫn đi qua view lớn. Đây là giả thuyết về layout/update cost, cần đo hoặc kiểm tra _printChanges khi triển khai.

Catalog app có 578 keys, 235 không theo prefix `app.*`; `Testing...` không có đủ EN/VI. Catalog CraftUIKit có 153 entries, trong đó một key rỗng cần phân biệt metadata/extraction artifact với nội dung thật. Nhiều view vẫn dùng raw padding, animation và chuỗi fallback; ví dụ `HOT`, các defaultValue tiếng Anh/Việt, `theme.spacing.xxl + 40` trong Vault. SwiftLint config hiện không bao gồm hai packages nên lint xanh không chứng minh chúng tuân thủ rules. Workflow GitHub hiện thấy chỉ OpenWiki, chưa có quality gate build/test/lint tương ứng AGENTS.

Hướng xử lý: tách scroll tracking/header thành view riêng; thay raw styling bằng tokens; migration key localization có kiểm tra mọi call site; bổ sung CI cho app và packages. Không thay đổi thiết kế chỉ để giảm số dòng.

## Điểm tốt cần giữ

- View models chính đã dùng @Observable + @MainActor, có injection và test nghiệp vụ.
- Audio controller mới có actor, generation, preparation deduplication, pause/resume và teardown tests. Không nên gộp/xoá engine mới chỉ vì còn implementation cũ.
- SampleVocabularyDataSource đã có dictionary indexes cho lookup; không còn scan từng stage cho mỗi word.
- Vault rows có stable identity; UI đã lazy, search có debounce.
- Home giữ view model/sections và cập nhật tiến độ sau bài học; CraftFluidJourney suspend background khi lesson cover xuất hiện.
- Widget kế thừa entitlement App Group từ project; Release packaging log xác nhận group đúng. Không có bằng chứng thiếu entitlement trong cấu hình hiệu lực.
- Countdown/particles có giới hạn hoặc pause; không có căn cứ để nói mọi animation luôn chạy nền.

## Cleanup đã thực hiện

Xoá DynamicPulseTimerBar và ReflexCardContainerView: không có caller sản phẩm, chỉ có test khởi tạo/chỉ kiểm tra thuộc tính. Xoá đúng hai test tương ứng. Xoá BentoCardButtonStyle không có reference. Xoá state private activeLessonNode chỉ được khởi tạo/gán nil và nhánh xử lý Home→Reflex cũ không thể tới; giữ hành vi tạo phiên Reflex mới khi hoàn tất.

Diff code: 285 dòng xoá, 4 dòng thêm, bảy file thay đổi trước khi thêm báo cáo. Tám dòng project.pbxproj được xoá có chủ đích để bỏ build/file/group references của hai source đã xoá. Không regenerate project, không sửa metadata Xcode bất ngờ, không commit. Ngoài cleanup, thêm COPY_PHASE_STRIP[sdk=iphonesimulator*] = NO riêng cho app Release trong project và generator: copy phase không nên strip widget đã ký trên simulator; cấu hình device giữ nguyên. Đây là sửa build configuration có chủ đích.

Không xoá hàng loạt public API CraftUIKit, models/schema lịch sử hoặc mocks dùng trong tests. VocabTheme cùng token types còn tests nhưng không có app runtime consumer trực tiếp; speech wiring cũ còn dependency tests. Đây là nhóm cleanup tiếp theo cần migration call sites/tests có chủ đích, không được coi là đã dọn sạch toàn repo.

## Kiểm chứng

- iOS simulator iPhone 17 / iOS 26.5, workspace VocabCraft.xcworkspace, scheme VocabCraftApp, Debug: trước cleanup 697 passed; sau cleanup 695 passed, 0 failed, 0 skipped. Giảm đúng hai test cho components đã xoá. Diagnostics của test build: 0 warnings/errors.
- `swift test` tại root: 360 XCTest + 289 Swift Testing passed, không có compiler diagnostics. Một dòng log lỗi speech là trường hợp lỗi chủ động trong test, không phải compiler/test failure.
- CraftUIKit: 653 XCTest + 82 Swift Testing passed; LocalizationTests riêng: 13 passed.
- SpeechKit: 67 XCTest passed.
- SwiftLint `lint --quiet --no-cache`: exit 0, output rỗng trong phạm vi .swiftlint.yml hiện có.
- Lần đầu SwiftPM/SwiftLint bị chặn ghi cache bởi sandbox; đã chạy lại SwiftPM với quyền cache tiêu chuẩn và SwiftLint không cache. Không xem lỗi môi trường đó là lỗi source.
- Release simulator build: thành công, 0 warnings/errors sau khi sửa copy-phase strip riêng cho simulator. Lần build trước có warning “not stripping binary because it is signed”; log xác định builtin-copy cố strip widget đã ký, lần build sau không còn strip ở copy phase.

Test audio trên simulator chọn SimulatorSpeechAudioHardware no-op, nên không xác nhận latency microphone/route/Bluetooth trên real device. Không có benchmark before/after; cleanup này không được quảng bá là đã tăng FPS.

## Thứ tự triển khai đề xuất

1. An toàn persistence/migration và tách demo khỏi production.
2. Stage snapshot Sendable và ranh giới Domain↔Presentation; giữ pattern MVVM hiện tại.
3. Một đường load Vault, xử lý latest-request/cancellation; timer Mixed cập nhật hẹp.
4. Dọn wiring speech cũ, tổng hợp summary curriculum, tối ưu GPU chỉ khi có bằng chứng.
5. Chốt CI và thử Release trên iOS thấp nhất hỗ trợ cùng máy RAM thấp: cold launch, cuộn Vault 1.000/10.000 từ, chuyển tab, hoàn thành bài nhiều lỗi, luyện nói nhiều vòng, background/foreground.

| Chỉ số runtime | Trước cleanup | Sau cleanup |
|---|---|---|
| Cold launch, search p95 | Chưa đo | Chưa đo |
| FPS/hitches, CPU, peak RSS, pin | Chưa đo | Chưa đo |
| Tác động của cleanup lên hiệu năng | Không có baseline | Không công bố mức cải thiện |

Chưa đo: cold-launch p50/p95, thời gian load/search p95, hitches, CPU, peak RSS và pin. Dùng cùng dataset/thiết bị/build cho trước và sau; không dùng thời gian test simulator làm số đo hiệu năng iPhone. Việc giữ iOS 17+ đồng nghĩa máy không chạy iOS 17 nằm ngoài phạm vi hỗ trợ hiện tại.

## Tài liệu chính thức đối chiếu

- [Apple: Understanding and improving SwiftUI performance](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance) — kiểm tra phạm vi/tần suất view updates và đối chiếu trace.
- [Apple: ModelActor](https://developer.apple.com/documentation/swiftdata/modelactor) và [Apple DTS: SwiftData concurrency](https://developer.apple.com/forums/thread/805409) — context thuộc actor sở hữu, trao đổi dữ liệu Sendable qua ranh giới.

## Artifacts kiểm chứng của phiên audit

- [iOS test build log](/Users/hoojinguyen/Library/Developer/XcodeBuildMCP/workspaces/vocab-craft-app-95b73110bcd6/logs/test_sim_2026-09-09T04-47-24-105Z_pid81064_cda7c337.log).
- [Release build log cuối](/Users/hoojinguyen/Library/Developer/XcodeBuildMCP/workspaces/vocab-craft-app-95b73110bcd6/logs/build_sim_2026-09-09T04-52-53-666Z_pid81064_9c938893.log).
- Logs SwiftPM của phiên này: `/tmp/vocab-audit-root-final.log`, `/tmp/vocab-audit-craft-confirmed.log`, `/tmp/vocab-audit-localization-unrestricted.log`, `/tmp/vocab-audit-speech-tests-unrestricted.log`. Các log /tmp là tạm thời, không được commit.
