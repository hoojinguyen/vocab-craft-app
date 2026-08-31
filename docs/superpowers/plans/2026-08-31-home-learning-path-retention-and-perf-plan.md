# Home Learning Path — Retention & Performance Optimization Plan

> **Ngày:** 2026-08-31
> **Tác giả:** Muse Spark — sau khi chạy `xcode-build-orchestrator` + `diagnose_compilation` + review screenshot/simulator
> **Trạng thái:** Proposed — cần approval trước khi implement
> **Benchmark gốc:** `.build-benchmark/20260823T162900Z` (clean 24.799s → 3.722s sau P0 build fixes), `.build-benchmark/20260831T033715Z` (clean 3.827s, incremental 1.726s, SwiftCompile 3.475s)

---

## 0. Evidence Trail

### 0.1 Build benchmark (phase 1 — orchestrator)

| Metric | Trước fix (2026-08-23T162900) | Sau fix P0 (2026-08-23T163731) | Hiện tại (2026-08-31T033715, 1 repeat) |
|--------|------------------------------|-------------------------------|--------------------------------------|
| Clean median | **24.799s** (SwiftCompile 119s aggregated) | **3.722s** (-85%) | **3.827s** (SwiftCompile 3.475s, stable) |
| Incremental / zero-change | 1.117s | 1.041s (-6.8%) | **1.726s** (ValidateEmbeddedBinary 0.35s dominate) |
| Cached clean | — | 18.111s | — |

Build settings audit (31/08): **tất cả PASS** — `COMPILATION_CACHE_ENABLE_CACHING=YES` `DEBUG_INFORMATION_FORMAT=dwarf` `EAGER_LINKING=YES` `SWIFT_COMPILATION_MODE=singlefile` `ONLY_ACTIVE_ARCH=YES` đã đúng sau lần optimize trước. Không còn đề xuất build-settings.

### 0.2 Compilation diagnostics (threshold 100ms)

```
TopicDeckDetailView.swift:43 body — 509ms  (nghiêm trọng)
TopicRoadmapView.swift:47 headerCard — 179ms
CleanWordCardView.swift:27 body — 143ms
SubTopicStudySessionView.swift:22 body — 125ms
HomepageView.swift:30 body — 114ms
SearchNewWordView.swift:18 body — 102ms
ReflexFlipCardView.swift:23 body — 100ms
Total: 7 warnings, ~1.27s type-check stall
```
Trước đó (23/08): 8 warnings >8.2s (ReflexBlitzCardView 4.5s + MixedDrill 3.6s) đã fix sạch (0 warnings ở 23/08T033610 với threshold 100 nhưng raw log vẫn leak 7 warnings nhẹ trên — parser của generate_optimization_report miss). **Hiện tại không còn hotspot >500ms ngoài TopicDeckDetailView.**

### 0.3 SwiftUI / Instruments review (thủ công — code inspection + simulator)

* Không chạy được full SwiftUI Instruments template trên CI, nhưng đã:
  * Screenshot iPhone 17 08:46 + `snapshot_ui` (12 tap targets, 1 scroll) xác nhận Unit 2 bị FloatingTabBar che 40% (`HomepageView.swift:135`).
  * Audit `CraftLearningPath.swift:413` `LazyVStack pinnedViews:.sectionHeaders` + `scrollTransition` + 3 `PhaseAnimator` (bobbing 1.2s, glow 1.5s, pulse) → CPU idle 5-7% theo Debug gauge.
  * Audit `CraftLessonSectionView.swift:164` `GeometryReader onChange(maxY)` per header + `CraftSnakeConnectorLayer.swift:387` `Canvas` + `NodeAnchorPreferenceKey` per node → Geometry churn O(n) per pixel.
  * Simulator swipe `up 0.5` mượt nhưng path dots mờ (opacity 0.35 trên ivory) và rowSpacing 64pt tạo khoảng trống lớn.

---

## 1. Mục tiêu

1. **Retention:** D1 ≥40%, D7 ≥15% (từ ước tính hiện 25%/8%) — bằng cách sửa hierarchy, single metric, và bật vòng lặp reward.
2. **Performance:** Giữ clean <4s, incremental <1.0s, 60fps scroll với 20+ nodes, không wake CPU >2% khi idle.
3. **Quality gate:** 0 hardcoded strings, 0 warnings, `swiftlint 0`, `swift test 100%`.

---

## 2. Phân rã — 3 phase, 11 tasks

### Phase 0 — P0 Hotfixes (MUST trước TestFlight, ~1.5 ngày)

#### Task 0.1 — Sửa overlap Unit 2 / TabBar che nội dung
* **Files:** `VocabCraftApp/Features/Homepage/Views/HomepageView.swift:33,490` `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift:363,490`
* **Hiện trạng:** `smartBottomPadding 200/220` + `safeAreaInset bottom Color.clear` không đủ cho `CraftFloatingTabBar size .md floating 88pt + shadow`. Screenshot Unit 2 cắt nửa, title `Công S...` tràn.
* **Implement:** Đo tabBar height động: `GeometryReader` ở `CraftFloatingTabBar`, expose `tabBarHeight` via `PreferenceKey`, `HomepageView` set `bottomPadding = tabBarHeight + 32`. Hoặc tạm tăng `smartBottomPadding` 200→280 và thêm `.contentMargins(.bottom, 32, for: .scrollContent)`.
* **Accept:** Screenshot iPhone SE/17/Pro Max Unit cuối scroll hết lên trên tabBar, không cắt chữ. Snapshot_ui không overlap.
* **Test:** `HomepageViewTests.testLastSectionNotObscured()` — render 4 decks, assert last node frame not intersect tabBar frame.
* **Effort:** 0.5d, Risk Low

#### Task 0.2 — Thống nhất metric tiến độ (gỡ 0/3 vs 8/10 vs bar)
* **Files:** `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift:84,96` `VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift:209`
* **Implement:**
  * Header giữ `8/10 từ hôm nay` (thêm label `Từ hôm nay` cạnh ring — dùng `AppStrings.Home.dailyGoalCount` + suffix).
  * Unit card: bỏ `0/3` góc phải (hiện `section.progressText`), chỉ giữ `progressValue` bar + text `1/3 chặng` (hoặc `2/3 hoàn thành`). Mapper đổi `progressText = "\(completed)/\(total) chặng"`.
  * Thêm `accessibilityValue` thống nhất.
* **Accept:** 1 màn hình chỉ còn 2 số: daily 8/10 + unit 1/3. Không còn 0/3 gây nhầm.
* **Effort:** 0.25d

#### Task 0.3 — Bật celebration & XP feedback (đóng vòng lặp reward)
* **Files:** `VocabCraftApp/Features/Homepage/Views/HomepageView.swift:96,229` `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift:57,379`
* **Implement:**
  * `showCelebration: false → true`.
  * `handleReflexSessionFinished` sau `completeLessonUseCase` trigger `celebrationTriggered = true` + `CraftToast` `+25 XP • 3★` + haptic success.
  * Mapper không đổi.
* **Accept:** Học xong 1 chặng thấy confetti + toast + stars trong node, không im lặng.
* **Test:** `HomepageViewModelTests.testStarMapping()` + UI test trigger.
* **Effort:** 0.25d

#### Task 0.4 — Tăng contrast path & giảm spacing
* **Files:** `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftSpacingTokens.swift:35` `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftNodeConnector.swift:299,368` `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftColorTokens.swift:62`
* **Implement:**
  * `pathDotDiameter 4.5→5.5`, `pathDotSpacing 8→6`, `pathRowSpacing 64→44`, `pathEdgeInset 24→16`.
  * `segmentColor locked 0.35→0.55`, `upcoming 0.55→0.65`.
  * Header card `surfaceCard` giữ, nhưng `pathActive = brandPrimary` cho đoạn `completed→active`.
* **Accept:** Screenshot path rõ trên ivory, không cần căng mắt.
* **Effort:** 0.25d, Risk Low (token change ảnh hưởng toàn app — cần snapshot)

#### Task 0.5 — Fix static cache thread-safety & hardcoded economy
* **Files:** `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftSnakePathGeometry.swift:78` `VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift:126,188`
* **Implement:**
  * `segmentCache` → `actor SegmentCache` hoặc `nonisolated(unsafe) + OSAllocatedUnfairLock<[String:SnakePathSegmentGeometry]>`.
  * Extract `xpReward`/`estimatedMinutes` ra `LessonEconomyPolicy` (enum) để A/B test.
* **Accept:** Swift 6 strict concurrency 0 warning, `swift test` pass.
* **Effort:** 0.25d

---

### Phase 1 — P1 Retention Features (1 sprint, ~3 ngày)

#### Task 1.1 — Weekly streak strip (7 dots) dưới HomeTopHeaderView
* **Files:** new `VocabCraftApp/Features/Homepage/Views/StreakWeekStripView.swift` (dùng `CraftStreakBadge` atoms) `HomeTopHeaderView.swift:62`
* **Spec:** 7 circles Mon-Sun, filled=completed, pending=outline, freeze=blue shield. Data: `UserSettingsStore` + `StageProgressRepository.fetchAllStageProgress()`.
* **Accept:** User thấy “mai mất streak” trong 1 glance.
* **Effort:** 0.5d

#### Task 1.2 — Treasure Chest milestone (cuối mỗi Unit)
* **Files:** `VocabCraftApp/Core/Database/SampleData/VocabularySampleDataset.swift:4` `LearningPathDataMapper.swift:48` `CraftLearningPathModels.swift:15`
* **Spec:** Mỗi deck thêm 1 node `kind: .treasureChest` `state: .locked→bonus` khi `allStandardCompleted`. `LessonNodeKind.treasureChest` đã tồn tại nhưng chưa được map trong sample data.
* **Accept:** Hoàn thành Unit 1 thấy rương vàng 150 XP, tạo curiosity gap sang Unit 2.
* **Effort:** 0.5d

#### Task 1.3 — Node preview thực (2 từ đầu thay vì "7 words")
* **Files:** `LearningPathDataMapper.swift:121` `CraftLessonNode.swift:674`
* **Spec:** `subtitle = words.prefix(2).map(\.lemma).joined(separator:" • ") + " • \(minutes) min"` fallback `wordsDuration`.
* **Accept:** Chặng 1 subtitle `Resilience • Overwhelmed • 3 min` — user biết sẽ học gì.
* **Effort:** 0.25d

#### Task 1.4 — Skeleton + pull-to-refresh (thay ProgressView)
* **Files:** `HomepageView.swift:55,107` new `CraftSkeleton`
* **Spec:** Khi `isLoading && sections.isEmpty` show 2 skeleton Unit cards + 3 skeleton nodes shimmer. Thêm `.refreshable { await loadLearningPath() }`.
* **Accept:** Không thấy spinner thô.
* **Effort:** 0.5d

---

### Phase 2 — P2 Performance & Build Hygiene (~2 ngày, song song)

#### Task 2.1 — Giảm Geometry churn & wake
* **Files:** `CraftLessonSectionView.swift:164` `CraftLessonNode.swift:131,562,666` `CraftLearningPath.swift:525,679`
* **Implement:**
  * Thay `GeometryReader per header onChange(maxY)` bằng single `onScrollGeometryChange` (iOS 18) ở `CraftLearningPath.scrollableView` — tính `dockedSection` 1 lần.
  * Wrap `PhaseAnimator` trong `if isVisible` (track via `onAppear/onDisappear` + `hasTrackedImpression` pattern đã có). Chỉ active node animate.
  * Thay `RowWidthPreferenceKey per row` bằng `containerWidth` từ parent geometry (hoặc `Layout` protocol).
* **Metric:** Idle CPU 5-7% → <2%, scroll FPS 60fps với 40 nodes (đo bằng Instruments SwiftUI hitches <1 per 10s).
* **Effort:** 1d, Risk Medium

#### Task 2.2 — Batch DB fetch & indexing
* **Files:** `VocabCraftApp/Core/Database/SampleData/SampleVocabularyDataSource.swift:16` `VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift:22,43` `VocabCraftApp/Features/Homepage/Views/HomepageView.swift:203`
* **Implement:**
  * Thêm `wordsByStage: [String:[TopicWordDTO]]` cache trong `VocabularySampleDataset` (precomputed Dictionary).
  * `FetchLearningPathUseCase` đổi từ fan-out `withThrowingTaskGroup fetchWordsForStage per stage` sang single batched `fetchAllWords()` hoặc `fetchWordsByDeck`.
  * `startLesson(checkpoint)` tương tự — 1 batch thay vì N tasks.
* **Metric:** Với 3000 từ, fetch giảm từ O(N*M) scans → O(N).
* **Effort:** 0.5d

#### Task 2.3 — Fix 7 type-check hotspots còn lại
* **Files:** list ở §0.2
* **Implement:**
  * `TopicDeckDetailView.swift:43` body 509ms: tách `headerCard`, `heroCTA`, `roadmap` ra 3 sub-View riêng, annotate type `let totalWords: Int = ...`, thay `Text(A)+Text(B)` chain bằng `Text(verbatim:)` hoặc `AttributedString`.
  * Các body 100-179ms: rút `AppStrings` concatenation ra computed var, thay ternary lồng `isSuccess ? mint : coral` bằng helper `func`.
  * Chạy `diagnose_compilation --threshold 50` sau fix để confirm 0 warnings.
* **Metric:** SwiftCompile 3.475s → ~2.8s, clean 3.827s → ~3.2s. Incremental không đổi.
* **Effort:** 0.5d, Risk Low

---

## 3. Thứ tự thực hiện & Gate

1. **Branch:** `feature/home-retention-perf` từ `main`.
2. **P0 (0.1→0.5) — làm tuần tự, mỗi task TDD: viết test fail → implement → `swift test --filter Homepage` + screenshot verify.**
3. **Re-benchmark sau P0:** `benchmark_builds --repeats 3 --touch-file HomepageView.swift` + `diagnose_compilation`.
4. **P1 (song song sau P0): 1.1/1.2/1.3 có thể làm parallel (3 subagents).**
5. **P2 sau cùng:** 2.1 cần Instruments trace (Time Profiler + SwiftUI View Body).
6. **Gate trước merge:**
   * `swiftlint 0`
   * `swift test 100%`
   * `xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination iOS` 0 warnings
   * Screenshot before/after iPhone 17 + SE, light/dark, vi/en
   * Instruments: Animation Hitches <5% frames, CPU idle <2%

---

## 4. Rủi ro & Mitigation

| Rủi ro | Mitigation |
|--------|------------|
| Token change (spacing/color) ảnh hưởng toàn app | Snapshot test `CraftUIKit` trước/sau, review với designer |
| `onScrollGeometryChange` chỉ iOS 18+ | Guard `if #available` giữ fallback GeometryReader cũ |
| Batch DB đổi API break `VocabularyDataSourceProtocol` | Thêm method mới `fetchAllWordsByDeck` giữ backward compat, deprecate old |

---

## 5. Danh sách duyệt (cần bạn tick)

- [ ] **P0.1 Overlap fix** — Low risk, P0
- [ ] **P0.2 Metric unification** — Low risk
- [ ] **P0.3 Celebration** — Low risk
- [ ] **P0.4 Path contrast** — Low risk (token)
- [ ] **P0.5 Cache thread-safety** — Low risk
- [ ] **P1.1 Streak strip** — Medium
- [ ] **P1.2 Treasure chest** — Medium
- [ ] **P1.3 Node preview** — Low
- [ ] **P1.4 Skeleton** — Low
- [ ] **P2.1 Geometry churn** — Medium (perf)
- [ ] **P2.2 Batch fetch** — Medium
- [ ] **P2.3 Type-check** — Low

> Sau khi bạn approve checklist, tôi sẽ delegate sang `xcode-build-fixer` / subagents để implement từng task theo TDD và re-benchmark.

---

## 6. Phụ lục — Lệnh verify

```bash
# Benchmark wall-clock
python3 .agents/skills/xcode-build-orchestrator/scripts/benchmark_builds.py \
  --project VocabCraftApp.xcodeproj --scheme VocabCraftApp --configuration Debug \
  --destination "platform=iOS Simulator,name=iPhone 17" --output-dir .build-benchmark --repeats 3

# Type-check
python3 .agents/skills/xcode-build-orchestrator/scripts/diagnose_compilation.py \
  --project VocabCraftApp.xcodeproj --scheme VocabCraftApp --configuration Debug \
  --destination "platform=iOS Simulator,name=iPhone 17" --threshold 100 --output-dir .build-benchmark

# Instruments (mở GUI)
xcrun xctrace record --template 'SwiftUI' --device 'iPhone 17' --launch -- VocabCraftApp --args

# Tests + lint
swift test && swiftlint --strict
```
