# Đặc Tả Kiến Trúc & Thiết Kế Kỹ Thuật: Tối Ưu Hiệu Năng & Triệt Tiêu Nóng Máy Khi Bắt Đầu / Chuyển Bài Học (PR #16)

- **Ngày ban hành**: 2026-09-04
- **Trạng thái**: Đã phê duyệt (Approved)
- **Mục tiêu**: Giải quyết dứt điểm hiện tượng giật lag, đứng khung hình và máy nóng ran trên thiết bị thật (Real Device) khi bắt đầu bài học từ Home Screen và khi chuyển đổi giữa các câu hỏi trong PR #16 (`feature/craft-fluid-journey`).
- **Phạm vi triển khai**: Gói toàn diện P0 + P1 + P2 (Audio Session Architecture, Render Pipeline Optimization, State Invalidation Reduction, Navigation Coordination & In-Place Progress Mutation).

---

## 1. BỐI CẢNH VÀ NGUYÊN NHÂN CỐT LÕI (PROBLEM & ROOT CAUSES)

Khi thử nghiệm bài học tại màn hình chính (`HomepageView` tích hợp `CraftFluidJourney`) trên thiết bị thật (iPhone vật lý), ứng dụng gặp hiện tượng sụt giảm khung hình nghiêm trọng (hitch rate cao), khựng đơ khi vừa bắt đầu bài học, và máy nóng lên rất nhanh sau 1-2 bài học.

Qua điều tra chuyên sâu mã nguồn của PR #16, 7 nguyên nhân gốc rễ sau đã được xác định:

### 1.1 Audio Session Thrashing & Hardware DSP Overload
- **Bằng chứng**: Tại [`ResilientReflexSpeechEngine.swift#L278`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift#L278), `inputNode.setVoiceProcessingEnabled(true)` được gọi đồng bộ trên `@MainActor`, kích hoạt chip đồng xử lý âm thanh (Audio DSP Coprocessor của Apple Silicon) để chạy AEC/AGC, tốn 250–400ms.
- **Xung đột Simulator vs Real Device**: Tại [`ResilientReflexSpeechEngine.swift#L311`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift#L311), `teardownEngine()` có chỉ thị `#if !targetEnvironment(simulator)`. Trên Simulator, toàn bộ logic teardown bị bỏ qua, nên lỗi xung đột Audio Session hoàn toàn tàng hình trên máy ảo và chỉ phát tác trên thiết bị thật.
- **Race condition khi chuyển câu**: Trong [`LessonExerciseContainerView.swift#L106-L111`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift#L106-L111), mỗi khi câu hỏi Speaking xuất hiện, `.onAppear` gọi `startSpeechSession()`, và `.onDisappear` gọi `stopSpeechSession()`. Trong animation chuyển câu (0.28s), view mới mount gọi `setActive(true)` trong khi view cũ unmount gọi `session.setActive(false)`. Daemon `mediaserverd` nhận liên tiếp các lệnh IPC trái ngược trong tích tắc, dẫn đến CPU 100%, reset audio server, và máy phát nhiệt dữ dội.
- **Double Init**: Cùng lúc tại [`LessonExerciseContainerView.swift#L188`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift#L188), `.task(id: item.id)` cũng gọi `startListeningForSpeaking(...)`, gây khởi tạo trùng lặp micro trên `@MainActor`.

### 1.2 Xung đột Giữa Spring Animation Đếm Lùi & TTS Khởi Đầu
- **Bằng chứng**: Khi đếm lùi kết thúc (3.2s) trong [`LessonLearningView.swift#L49`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Lesson/Views/LessonLearningView.swift#L49), `withAnimation(.spring)` kích hoạt để trượt [`LessonDiscoveryCardView`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Lesson/Views/Components/LessonDiscoveryCardView.swift) vào.
- Đúng khung hình đầu tiên, dòng 144 chạy `.task(id: word.id) { onPlayAudio() }`. Hàm này gọi `audioSession.setActive(true)` đồng bộ trên `@MainActor`, khóa cứng Main Thread 150–350ms đúng thời điểm CoreAnimation đang nội suy spring curve, tạo cảm giác đứng hình đơ một nhịp trước khi hiện thẻ.

### 1.3 Rò rỉ Render Nền (Background Leaks) của `CraftFluidJourney`
- **Bằng chứng**: `LessonLearningView` hiển thị qua `.fullScreenCover` từ `HomepageView`. SwiftUI không tự động ngắt các animation ở view nằm dưới.
- Các hiệu ứng: [`PhaseAnimator(GlowPhase.allCases)`](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift#L200), [`PhaseAnimator(BobbingPhase.allCases)`](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonNode.swift#L134), và 2 quầng sáng Gaussian Blur khổng lồ (`blur(40)`, `blur(50)`) tại [`CraftFluidJourney.swift#L568, #L585`](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift#L568) vẫn chạy ngầm 120 FPS dưới nền, khiến GPU/CPU tiếp tục sinh nhiệt khi người dùng đang học bài.

### 1.4 Bão State Invalidation Trong `CraftFluidJourney` (`@State milestonePositions`)
- **Bằng chứng**: Tại [`CraftFluidJourney.swift#L89, #L625`](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift#L89), mỗi pixel cuộn đều kích hoạt preference key và gán `milestonePositions = positions` vào biến `@State`.
- Biến `@State` này không hề được bất kỳ view con nào đọc. Việc mutate nó liên tục ép re-render toàn bộ cây View cha 120 lần/giây khi cuộn.

### 1.5 Tra Cứu Tài Nguyên CoreGlyphs Đồng Bộ Trong Hot Render Path
- **Bằng chứng**: [`CraftJourneyNode.swift#L253`](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift#L253) gọi `UIImage(systemName:)` trong computed property `resolvedIconName` của View body. Với 25 node và 120 re-renders/giây, hệ thống thực hiện tới 3,000 lần tra cứu font bundle hệ thống mỗi giây trên `@MainActor`.

### 1.6 Xung Đột Modal Chained Transition (Sheet Dismiss -> FullScreenCover)
- **Bằng chứng**: Commit [`16773c5`](https://github.com/hoojinguyen/vocab-craft-app/commit/16773c5765cc59ed63ea445ee5003c2d8ceae748) đưa `onStartLesson` vào `onDismiss` của Sheet. Khi sheet vừa chạm đáy (0ms nghỉ), `activeLessonLearningVM` lập tức được gán, ép CoreAnimation dựng context toàn màn hình mới ngay khi vừa dọn context cũ, gây sụt giảm khung hình.

### 1.7 Ghép Chuỗi & Regex Thừa Thãi Trong `LessonExerciseContainerView`
- **Bằng chứng**: Tại [`LessonExerciseContainerView.swift#L43, #L69, #L95, #L124`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift#L43), code nối 3 phần của `clozeStages.initialParts` thành 1 chuỗi dài, rồi gọi `extractTemplateParts` dùng Regex bóc tách lại thành chính 3 phần cũ.

---

## 2. NGUYÊN TẮC THIẾT KẾ & KIẾN TRÚC TỔNG THỂ (SYSTEM ARCHITECTURE)

Hệ thống được tái cấu trúc theo 4 trụ cột kiến trúc:

```
+-------------------------------------------------------------------------+
|                              HomepageView                               |
|   - isCovered = (activeLessonLearningVM != nil)                         |
|   - In-place progress mutation (applyCompletedLesson)                   |
|   - Coordinated modal transition with prefetching                       |
+-------------------------------------------------------------------------+
                                    |
            +-----------------------+-----------------------+
            v                                               v
+-----------------------+                       +-----------------------+
|   CraftFluidJourney   |                       |  LessonLearningView   |
| (CraftUIKit Package)  |                       |  (Main Application)   |
|                       |                       |                       |
| - Zero @State scroll  |                       | - Session-Scoped      |
|   invalidation        |                       |   AudioSession        |
| - isSuspended pauses  |                       | - Lazy Mic & DSP      |
|   GPU Blur & Phase    |                       | - Delayed TTS (300ms) |
| - Static cache for    |                       | - Zero Cloze Regex    |
|   SF Symbols          |                       | - No view-level       |
|                       |                       |   audio teardown      |
+-----------------------+                       +-----------------------+
```

---

## 3. ĐẶC TẢ CHI TIẾT TỪNG PHẦN (COMPONENT SPECIFICATIONS)

---

### Phần 1: Kiến trúc Vòng đời Âm thanh & Hardware DSP (P0)

#### 3.1.1 Cấu hình `AVAudioSession` Theo Session-Scoped Architecture
- **Vị trí**: `LessonLearningViewModel` và `ResilientReflexSpeechEngine`.
- **Cơ chế**:
  - Khi bắt đầu một buổi học, cấu hình `AVAudioSession` cố định một lần duy nhất:
    ```swift
    try session.setCategory(
        .playAndRecord,
        mode: .spokenAudio,
        options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP, .duckOthers]
    )
    ```
  - Cấu hình này hỗ trợ đồng thời cả TTS playback và Micro recording mà **không bao giờ chuyển đổi Category qua lại**.
  - Việc kích hoạt `session.setActive(true)` được thực hiện bất đồng bộ ngoài `@MainActor`.

#### 3.1.2 Khởi tạo Micro Theo Nhu Cầu (Lazy Mic Engine)
- **Vị trí**: `ResilientReflexSpeechEngine` và `LessonExerciseContainerView`.
- **Cơ chế**:
  - Tại Discovery Card và các câu hỏi trắc nghiệm / gõ phím: `AVAudioEngine` và bộ lọc phần cứng `setVoiceProcessingEnabled(true)` chưa được cấp phát, Dynamic Island không hiển thị chấm cam micro.
  - Khi gặp câu Speaking đầu tiên: `LessonLearningViewModel` gọi `speechEngine.prepareEngineIfNeeded()`.
  - **Xóa bỏ hoàn toàn**: `.onAppear { viewModel.startSpeechSession() }` và `.onDisappear { viewModel.stopSpeechSession() }` trong `LessonExerciseContainerView.swift`.
  - Khi chuyển từ câu Speaking sang câu khác: Chỉ tạm dừng nhận diện buffer (`bufferRelay.pauseListening()`), **tuyệt đối không gọi `teardownEngine()` hay `session.setActive(false)`**.
  - Khi người dùng hoàn thành hoặc bấm Exit thoát bài học: Mới thực hiện `teardownEngine()` dọn dẹp tài nguyên.

#### 3.1.3 Trì hoãn TTS Tránh Xung Đột Spring Animation
- **Vị trí**: `LessonDiscoveryCardView.swift#L144`.
- **Cơ chế**:
  ```swift
  .task(id: word.id) {
      try? await Task.sleep(for: .milliseconds(300))
      guard !Task.isCancelled else { return }
      onPlayAudio()
  }
  ```
  Nhường hoàn toàn Main Thread cho CoreAnimation hoàn thành spring curve 0.35s với 120 FPS trước khi gọi TTS.

---

### Phần 2: Pipeline Dựng Hình & Kiểm Soát State Invalidation (P1)

#### 3.2.1 Xóa Bỏ Biến `@State milestonePositions` trong `CraftFluidJourney`
- **Vị trí**: `CraftFluidJourney.swift#L89, #L620-L630`.
- **Cơ chế**:
  - Xóa bỏ `@State private var milestonePositions: [String: CGFloat] = [:]`.
  - Trong `.onPreferenceChange(FluidJourneyMilestonePreferenceKey.self)`:
    ```swift
    func handleMilestonePreferenceChange(_ positions: [String: CGFloat]) {
        if let resolved = resolveDockedSection(from: positions), dockedSectionId != resolved.id {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.28)) {
                dockedSectionId = resolved.id
            }
        }
    }
    ```
  - Biến `@State` chỉ thay đổi duy nhất khi người dùng cuộn qua ranh giới một Unit.

#### 3.2.2 Tạm Dừng Render Nền (Zero Background Render Leak)
- **Vị trí**: `CraftFluidJourney.swift`, `CraftJourneyNode.swift`.
- **Cơ chế**:
  - Bổ sung tham số `isSuspended: Bool = false` vào `CraftFluidJourney`.
  - `HomepageView` truyền `isSuspended: activeLessonLearningVM != nil`.
  - Khi `isSuspended == true`:
    - `CraftJourneyNode`: Không chạy `PhaseAnimator`, hiển thị node ở trạng thái bóng đổ tĩnh nhẹ.
    - `ActiveCalloutBubble`: Không chạy `PhaseAnimator` nhấp nhô, giữ offset cố định 0.
    - `ambientEtherealBackground`: Ẩn 2 vòng tròn Gaussian blur 40pt và 50pt, chỉ giữ lại màu nền phẳng `theme.colors.canvasBackground`.

#### 3.2.3 Cache Tra Cứu SF Symbol Trong `CraftJourneyNode`
- **Vị trí**: `CraftJourneyNode.swift`.
- **Cơ chế**:
  - Cung cấp bộ nhớ đệm tĩnh luồng an toàn:
    ```swift
    private static var symbolValidationCache: [String: Bool] = [:]
    private static let cacheLock = NSLock()
    ```
  - Tránh gọi `UIImage(systemName:)` liên tục trong computed property của từng frame render.

#### 3.2.4 Sử Dụng Trực Tiếp `clozeStages.initialParts`
- **Vị trí**: `LessonExerciseContainerView.swift#L43, #L69, #L95, #L124`.
- **Cơ chế**: Thay thế `ReflexClozeFormatter.extractTemplateParts(...)` bằng cách gán trực tiếp `clozeParts: clozeStages.initialParts`.

---

### Phần 3: Điều Hướng Liền Mạch & Luồng Hoàn Thành Bài Học (P2)

#### 3.3.1 Điều Phối Chuyển Cảnh Modal Sheet -> FullScreenCover
- **Vị trí**: `CraftFluidJourney.swift`, `HomepageView.swift`.
- **Cơ chế**:
  - Khi người dùng chạm nút "Start Lesson" trong Bottom Sheet:
    - Kích hoạt song song tác vụ tải trước dữ liệu từ vựng (`prefetchWords`).
    - Đóng sheet một cách êm ái.
    - Chờ một khoảng đệm an toàn (~150ms sau khi dismiss) để CoreAnimation thu hồi render buffer của sheet trước khi kích hoạt `activeLessonLearningVM = vm`.

#### 3.3.2 Cập Nhật Tiến Độ Tại Chỗ (In-Place Progress Mutation)
- **Vị trí**: `HomepageViewModel.swift`, `HomepageView.swift`.
- **Cơ chế**:
  - Khi hoàn thành bài học, `HomepageViewModel` cập nhật trực tiếp trên mảng `sections` trong RAM qua hàm `applyCompletedLesson(stageId:)`:
    - Node của stage hiện tại đổi state thành `.completed`.
    - Node tiếp theo đổi state thành `.active`.
  - Ghi nhận tiến độ xuống CSDL SwiftData diễn ra bất đồng bộ dưới nền, không gọi `loadLearningPath()` làm giật cây View và không nhảy vị trí cuộn màn hình.

#### 3.3.3 Tối Ưu Hạt Hiệu Ứng Confetti & Sparkles
- Rút ngắn thời gian chạy của `CraftSparkleView` xuống 1.0s.
- Hủy ngay lập tức `TimelineView` khi người dùng chạm vào màn hình.

---

### Phần 4: Xử Lý Ngoại Lệ & Tính Đồng Thời (Concurrency & Safety)

#### 3.4.1 An Toàn Luồng (Thread Safety & Swift Concurrency)
- Mọi ViewModel tuân thủ nghiêm ngặt `@MainActor`.
- Toàn bộ thao tác I/O âm thanh (`AVAudioSession`, audio tap setup) được bọc trong các tác vụ bất đồng bộ, kiểm tra kỹ `guard !Task.isCancelled` để tránh rò rỉ tác vụ khi người dùng thoát màn hình đột ngột.

#### 3.4.2 Phục Hồi Gián Đoạn Âm Thanh (Audio Interruption Handling)
- Đăng ký nhận thông báo `AVAudioSession.interruptionNotification`.
- Tự động tạm ngắt thu âm khi có cuộc gọi / báo thức đến, và phục hồi trạng thái khi cuộc gọi kết thúc mà không làm sập ứng dụng.

---

## 4. MA TRẬN TẬP TIN THAY ĐỔI (FILES IMPACT MATRIX)

| STT | Tập tin | Lớp (Layer) | Nội dung thay đổi chính |
| :--- | :--- | :--- | :--- |
| 1 | [`ResilientReflexSpeechEngine.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift) | Core / Audio | Lazy engine preparation, session-scoped retention, bỏ teardown giữa các câu, background session activation. |
| 2 | [`LessonLearningViewModel.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Lesson/ViewModels/LessonLearningViewModel.swift) | Feature / Lesson | Cấu hình AudioSession một lần tại session scope, điều phối lazy speech recognition. |
| 3 | [`LessonDiscoveryCardView.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Lesson/Views/Components/LessonDiscoveryCardView.swift) | Feature / Lesson | Trì hoãn 300ms phát TTS trong `.task(id: word.id)` để nhường frame cho spring animation. |
| 4 | [`LessonExerciseContainerView.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Lesson/Views/Components/LessonExerciseContainerView.swift) | Feature / Lesson | Gỡ bỏ `.onAppear` / `.onDisappear` audio setup; thay thế regex parsing bằng `clozeStages.initialParts`. |
| 5 | [`CraftFluidJourney.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift) | CraftUIKit | Xóa bỏ `@State milestonePositions`, thêm cờ `isSuspended` tắt render GPU nền, tối ưu nhịp đóng sheet. |
| 6 | [`CraftJourneyNode.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift) | CraftUIKit | Thêm cache tĩnh cho `UIImage(systemName:)`, hỗ trợ tạm dừng `PhaseAnimator` khi `isSuspended`. |
| 7 | [`HomepageView.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Homepage/Views/HomepageView.swift) | Feature / Homepage | Truyền `isSuspended` xuống journey, điều phối modal handoff ~150ms, in-place update tiến độ khi xong bài. |
| 8 | [`HomepageViewModel.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift) | Feature / Homepage | Thêm hàm `applyCompletedLesson(stageId:)` cập nhật tại chỗ mảng `sections`. |

---

## 5. KẾ HOẠCH KIỂM THỬ VÀ NGHIỆM THU (VERIFICATION & ACCEPTANCE CRITERIA)

### 5.1 Automated Quality Gates
1. **Localization Verification**:
   ```bash
   swift test --package-path Packages/CraftUIKit --filter LocalizationTests
   ```
   Đảm bảo 100% không vi phạm chuỗi hardcode, song ngữ EN/VI đầy đủ.
2. **Unit Tests Suite**:
   ```bash
   swift test --package-path Packages/CraftUIKit
   ```
   Chạy toàn bộ unit tests cho `CraftUIKit` và app test suite, đảm bảo 100% tests vượt qua.
3. **SwiftLint Verification**:
   ```bash
   swiftlint
   ```
   Đạt 0 lỗi, 0 cảnh báo.
4. **Xcode Compiler Gate**:
   Biên dịch toàn bộ workspace với **0 errors, 0 warnings**.

### 5.2 Real Device Physical Testing
1. **Kiểm tra giật lag lúc Start Lesson**:
   - Bấm Start Lesson từ Home -> Chờ 3.2s đếm lùi -> Thẻ từ vựng Discovery lướt vào với tốc độ 120 FPS không khựng đơ.
2. **Kiểm tra chuyển đổi bài học & Microphone indicator**:
   - Làm bài học có các câu Speaking xen kẽ Listening / Multiple Choice.
   - Chấm cam micro chỉ sáng khi đang làm câu Speaking, tắt khi chuyển sang câu khác.
   - Khung hình chuyển câu mượt mà 0.28s, không có hiện tượng đứng hình.
3. **Kiểm tra nhiệt độ thiết bị (Thermal State)**:
   - Học liên tiếp 5 bài học trên thiết bị thật.
   - Nhiệt độ máy duy trì bình thường, không nóng ran, không tụt pin đột ngột, không bị iOS hạ xung nhịp.
