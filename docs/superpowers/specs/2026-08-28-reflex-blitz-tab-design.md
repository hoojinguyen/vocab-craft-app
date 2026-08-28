# Reflex Blitz Tab — Free Practice Feature Design Spec

## 1. Overview & Mục tiêu

Tài liệu này đặc tả kiến trúc chi tiết cho **Feature 3: Reflex Blitz Tab — Free Practice** của ứng dụng VocabCraft. 
Tính năng này cung cấp môi trường luyện phản xạ tự do (Free Practice) với 4 chế độ rèn luyện độc lập:
1. **Luyện nói (Speaking)** — 6.0s
2. **Gõ từ (Typing)** — 7.5s
3. **Trắc nghiệm (Multiple Choice)** — 4.5s
4. **Phản xạ nghe (Listening)** — 5.5s

### Mục tiêu cốt lõi
- **Chuẩn hóa 100% CraftUIKit**: Loại bỏ toàn bộ các UI component/styles tự vẽ, sử dụng các component chuẩn (`CraftActionCard`, `CraftChoiceCard`, `CraftTextField`, `CraftCountdownOverlay`, `CraftCountdownTimerBar`, `CraftStepProgressIndicator`, `CraftWaveformView`, `CraftSpeakerButton`, `CraftFeedbackSheet`, `CraftButton`, `CraftCard`) và hệ thống Design Tokens (`CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftShadowTokens`).
- **Phản xạ vô điều kiện**: Mỗi chế độ có giới hạn thời gian nghiêm ngặt, đếm ngược bằng `CraftCountdownTimerBar` kèm các trạng thái cảnh báo (.steady, .warning, .urgent).
- **Hàng đợi thông minh (Smart Priority Queue)**: Chọn lọc 10 từ vựng cross-topic ưu tiên từ yếu, từ đang học trên Learning Path và từ đến hạn ôn tập SRS.
- **Không Hardcode chuỗi (Zero Hardcoded Strings)**: Đảm bảo 100% văn bản hiển thị và nhãn Accessibility đều nằm trong `Localizable.xcstrings` với độ tương thích song ngữ EN/VI hoàn chỉnh.

---

## 2. Kiến trúc Giao diện & CraftUIKit Component Mapping

### 2.1 Bảng Mapping Component

| Vị trí / Mục đích | Component cũ | Component CraftUIKit chuẩn | Ghi chú & Tokens áp dụng |
| :--- | :--- | :--- | :--- |
| **Hub Header Badge** | `Text` + `Capsule` | `CraftBadge` | Text uppercase `REFLEX BLITZ`, icon `bolt.fill`, màu `accentPeach` |
| **Hub Title & Subtitle** | `Text` | `CraftText` | `CraftTypographyTokens.titleLargeSerif` cho tiêu đề, `bodyMedium` cho phụ đề |
| **4 Thẻ Chế độ (Bento)** | Layout tự viết | `CraftActionCard` | Style `.tactile3D`, icon theo chế độ, badge thời gian `stopwatch.fill`, chevron điều hướng |
| **Quick Stats Dashboard** | Thẻ tự vẽ | `CraftCard` mini grid | Style `.elevated` hoặc `.tactile3D`, hiển thị 3 metric (Tuần, Cần củng cố, Tốc độ TB) |
| **Đếm ngược mở đầu (3-2-1)** | `ReflexCountdownOverlayView` | `CraftCountdownOverlay` | Fullscreen modal backdrop mờ, spring bounce, haptic ticks và "GO!" |
| **Drill Header Bar** | Layout `HStack` tự chia | `CraftStepProgressIndicator` + `CraftStreakBadge` + `CraftIconButton` | 10 phân đoạn step tiến trình, huy hiệu streak khi combo ≥ 2, nút đóng `xmark` |
| **Thanh đếm ngược thời gian** | `Capsule` tự tính width | `CraftCountdownTimerBar` | Hỗ trợ 3 giai đoạn (.steady, .warning, .urgent), glowing aura shadow, pause thông minh |
| **Thẻ Câu đố chính** | `ReflexBlitzCardView` | `CraftCard` container + `CraftText` | Áp dụng `radii.xl`, viền highlight theo giai đoạn đếm ngược |
| **Speaking: Audio Input & Waveform**| Capsule bars tự vẽ | `CraftWaveformView` + `CraftTactileMicHubView` | Tự động lắng nghe với `ContinuousReflexSpeechService`, live waveform & transcript |
| **Typing: Text Field Input** | SwiftUI `TextField` thô | `CraftTextField` | Auto-focus, border active highlight, tắt autocap/autocorrect, phím return submit |
| **MC & Listening: Thẻ lựa chọn** | Custom Button grid | `CraftChoiceCard` | 4 trạng thái (.idle, .selected, .correct, .wrong), prefix tròn A/B/C/D, 3D tactile bevel |
| **Listening: Nút phát âm** | Custom button loa | `CraftSpeakerButton` | Nút loa có hiệu ứng sóng âm pulse khi phát TTS |
| **Phản hồi sau mỗi từ** | View inline reviewed tự vẽ | `CraftFeedbackSheet` | Bottom sheet trượt từ đáy màn hình, trạng thái .success/.error/.warning, IPA, nút Tiếp tục |
| **Màn hình Tổng kết (Summary)** | Custom summary view | `CraftCard` Bento Grid + `CraftButton` | Thẻ điểm số, danh sách từ yếu với `CraftSpeakerButton`, nút "Luyện lại" nổi bật |

---

## 3. Chi tiết Màn hình Hub (Reflex Blitz Launcher)

### 3.1 Bố cục Giao diện

1. **Header Section**:
   - `CraftBadge`: Icon `bolt.fill`, nội dung `REFLEX BLITZ`.
   - Tiêu đề: `app.reflex.hub.title` ("Luyện phản xạ tốc độ" / "Speed Reflex Drill").
   - Tiêu đề phụ: `app.reflex.hub.subtitle` ("Chọn phương pháp phản xạ hôm nay" / "Choose your reflex practice method today").
2. **4 Bento Cards Grid (2x2)**:
   - **Luyện nói**: Icon `waveform.and.mic`, Badge `6.0s`, Title `app.reflex.mode.speaking.title`, Subtitle `app.reflex.mode.speaking.subtitle`, Accent `.vocabPeach` / `theme.colors.accentPeach`.
   - **Gõ từ**: Icon `keyboard`, Badge `7.5s`, Title `app.reflex.mode.typing.title`, Subtitle `app.reflex.mode.typing.subtitle`, Accent `.vocabLavender` / `theme.colors.accentLavender`.
   - **Trắc nghiệm**: Icon `square.grid.2x2.fill`, Badge `4.5s`, Title `app.reflex.mode.mc.title`, Subtitle `app.reflex.mode.mc.subtitle`, Accent `.vocabMint` / `theme.colors.accentMint`.
   - **Phản xạ nghe**: Icon `headphones`, Badge `5.5s`, Title `app.reflex.mode.listening.title`, Subtitle `app.reflex.mode.listening.subtitle`, Accent `.vocabHeroAccent` / `theme.colors.brandPrimary`.
3. **Quick Stats Dashboard (3 Thẻ ngang)**:
   - Thẻ 1: Số từ đã luyện trong tuần (`app.reflex.stats.weekly_words` + số lượng từ).
   - Thẻ 2: Số từ cần củng cố (`app.reflex.stats.weak_words` + số lượng `needsReview`).
   - Thẻ 3: Tốc độ phản xạ trung bình (`app.reflex.stats.avg_speed` + định dạng `X.Xs`).
4. **Footer Scaffolding**:
   - Icon `sparkles` + Văn bản hướng dẫn: `app.reflex.hub.footer_hint`.

---

## 4. Chi tiết 4 Chế độ Luyện phản xạ (Drill Modalities)

### 4.1 Quy tắc Chung của Phiên Drill
- **Số lượng từ**: 10 từ/phiên lấy từ Smart Priority Queue.
- **Đếm ngược mở đầu**: `CraftCountdownOverlay` (3-2-1 GO!).
- **Header**:
  - `CraftIconButton(icon: "xmark")` ở góc trái để hủy phiên/thoát.
  - `CraftStepProgressIndicator` ở giữa (10 steps).
  - `CraftStreakBadge` ở góc phải (hiển thị khi combo ≥ 2).
  - `CraftCountdownTimerBar` nằm sát dưới header bar.

---

### 4.2 Chế độ 1: Luyện nói (Speaking Mode — 6.0s)
- **Mục tiêu**: Bật ra phát âm từ vựng tiếng Anh trong thời gian ngắn nhất.
- **Kích thích (Stimulus)**:
  - Hiển thị từ loại `word.pos` (uppercase capsule).
  - Nghĩa tiếng Việt `word.definitionVi` nổi bật.
  - Câu ví dụ tiếng Anh có khuyết từ `word.clozeSentenceEn` với slot `[ • • • ]`.
  - Khi đếm ngược còn dưới 2.0s (.warning/.urgent stage): Slot hiển thị gợi ý ký tự đầu `[ b • • • ]`.
- **Cơ chế thu âm & Nhận diện**:
  - Tự động kích hoạt microphone thông qua `ContinuousReflexSpeechService` ngay khi card hiển thị.
  - Hiển thị sóng âm `CraftWaveformView` và Live transcript nhận diện thời gian thực.
  - So khớp âm thanh: Không yêu cầu 100% IPA bản xứ, chỉ cần nhận diện đúng từ khóa mục tiêu (`ContinuousReflexSpeechService.matchesTarget(transcript, word.lemma)`).
  - **Không có nút chuyển gõ phím** (giữ trọn vẹn mục đích luyện nói).
- **Điều khiển & Bỏ qua**:
  - Có nút **"Bỏ qua" (Skip)** ở thanh đáy màn hình nếu người dùng không nhớ từ.
- **Kích hoạt Phản hồi**:
  - Khi phát âm đúng từ: Dừng timer, kích hoạt `CraftFeedbackSheet(status: .success)`.
  - Khi hết 6.0s hoặc ấn Bỏ qua: Dừng timer, kích hoạt `CraftFeedbackSheet(status: .error / .warning)`.

---

### 4.3 Chế độ 2: Gõ từ (Typing Mode — 7.5s)
- **Mục tiêu**: Phản xạ gõ phím nhanh và ghi nhớ chính xác mặt chữ.
- **Kích thích (Stimulus)**:
  - Nghĩa tiếng Việt + Từ loại + Câu ví dụ khuyết từ `[ • • • ]`.
- **Cơ chế Nhập liệu**:
  - Sử dụng `CraftTextField` với cấu hình:
    - Auto-focus bàn phím ngay lập tức khi từ xuất hiện (`@FocusState`).
    - Tắt Auto-Capitalization và Auto-Correction.
    - Phím Return/Done trên bàn phím kích hoạt Submit ngay lập tức.
  - Thẩm định kết quả: Case-insensitive (không phân biệt chữ hoa/thường), tự động cắt bỏ khoảng trắng thừa đầu/cuối chuỗi.
- **Điều khiển & Bỏ qua**:
  - Có nút **"Bỏ qua" (Skip)** ở thanh đáy màn hình.
- **Kích hoạt Phản hồi**:
  - Gõ đúng submit: Dừng timer, kích hoạt `CraftFeedbackSheet(status: .success)`.
  - Gõ sai submit hoặc hết 7.5s hoặc ấn Bỏ qua: Dừng timer, kích hoạt `CraftFeedbackSheet(status: .error / .warning)`.

---

### 4.4 Chế độ 3: Trắc nghiệm (Multiple Choice Mode — 4.5s)
- **Mục tiêu**: Nhận diện nhanh nghĩa và từ vựng qua bài toán 1 trong 4.
- **Kích thích (Stimulus)**:
  - Nghĩa tiếng Việt + Từ loại + Câu ví dụ khuyết từ `[ • • • ]`.
- **Thẻ Lựa chọn**:
  - 4 thẻ `CraftChoiceCard` (A, B, C, D) hiển thị **4 từ vựng tiếng Anh** (1 đáp án đúng + 3 từ gây nhiễu lấy từ kho từ vựng).
  - Thẻ sử dụng prefix `.circle`, 3D tactile bevel, hiệu ứng rung lắc `ChoiceShakeEffect` khi sai.
- **Cơ chế Tương tác**:
  - **Instant Select**: Chạm 1 chạm là chốt đáp án ngay lập tức. Thẻ được chọn chuyển sang `.correct` (xanh) hoặc `.wrong` (đỏ kèm rung lắc, đồng thời highlight thẻ đúng).
  - **Không có nút "Bỏ qua"** (tối giản không gian, tập trung phản xạ vào 4 thẻ).
- **Kích hoạt Phản hồi**:
  - Khi chạm đáp án hoặc khi hết 4.5s: Dừng timer, kích hoạt ngay `CraftFeedbackSheet` (.success nếu đúng, .error nếu sai/hết giờ).

---

### 4.5 Chế độ 4: Phản xạ nghe (Listening Mode — 5.5s)
- **Mục tiêu**: Bắt âm thanh và liên kết trực tiếp với nghĩa tiếng Việt mà không phụ thuộc vào mặt chữ tiếng Anh.
- **Kích thích (Stimulus)**:
  - **Ẩn hoàn toàn từ vựng tiếng Anh và câu ví dụ**.
  - Tự động phát âm thanh từ tiếng Anh qua TTS/Audio Service ngay khi từ bắt đầu.
  - Hiển thị sóng âm động `CraftWaveformView` (hiệu ứng pulse) + nút `CraftSpeakerButton` để nghe lại phát âm khi cần.
  - Dòng hướng dẫn: `app.reflex.drill.listening_instruction` ("Chọn nghĩa tiếng Việt của từ vừa nghe").
- **Thẻ Lựa chọn**:
  - 4 thẻ `CraftChoiceCard` (A, B, C, D) hiển thị **4 nghĩa Tiếng Việt** (1 nghĩa đúng + 3 nghĩa gây nhiễu).
- **Cơ chế Tương tác**:
  - Tương tự Trắc nghiệm: Chạm là chốt ngay, **không có nút "Bỏ qua"**.
- **Kích hoạt Phản hồi**:
  - Khi chọn đáp án hoặc hết 5.5s: Kích hoạt `CraftFeedbackSheet`, mở ra toàn bộ từ tiếng Anh, từ loại, phiên âm IPA và câu ví dụ để đối chiếu ngữ cảnh.

---

## 5. Chu trình Phản hồi & Feedback State Machine (`CraftFeedbackSheet`)

Khi một từ kết thúc (Đúng / Sai / Hết giờ / Bỏ qua):

```
┌─────────────────────────────────────────────────────────────┐
│                       CraftFeedbackSheet                    │
├─────────────────────────────────────────────────────────────┤
│  [✓ Chính xác! / ✕ Chưa chính xác / ⚠️ Hết giờ]             │
│                                                             │
│  "capital"  [NOUN]  /ˈkæp.ɪ.təl/  [ 🔊 Nghe lại ]           │
│  thành phố lớn, thủ đô                                      │
│                                                             │
│  "Tokyo is the capital city of Japan."                      │
│  Tokyo là thủ đô của Nhật Bản.                              │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │               [ ➔ Tiếp tục (Space / Enter) ]          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Cấu hình `CraftFeedbackSheet`
- **Trạng thái (Status)**:
  - `.success`: Trả lời đúng từ. Hiển thị badge thời gian phản xạ `⚡ X.Xs`.
  - `.error`: Trả lời sai từ vựng hoặc chọn sai trắc nghiệm.
  - `.warning`: Hết thời gian đếm ngược hoặc nhấn nút Bỏ qua.
- **Nội dung hiển thị bên trong**:
  - Từ vựng tiếng Anh + Từ loại + Phiên âm IPA.
  - Nút `CraftSpeakerButton` nghe lại cách phát âm chuẩn.
  - Câu ví dụ hoàn chỉnh EN kèm bản dịch nghĩa VI.
- **Nút Hành động Chính**:
  - `CraftButton("Tiếp tục", variant: .tactile / .primary)` chuyển sang từ tiếp theo trong hàng đợi.
  - Hỗ trợ keyboard shortcut `.defaultAction` (phím Return/Space) trên iPad/Simulator.

---

## 6. Smart Priority Queue Algorithm (Cross-Topic Free Practice)

Thuật toán chọn lọc đúng **10 từ vựng** cho phiên Free Practice:

```
Input: allLearnedWords, currentLearningPathSubTopic, userWordProgressHistory
Output: queue (10 ReflexBlitzWordItem)

Tier 1 — Weak Words (Tối đa 5 từ):
  - Điều kiện: needsReview == true OR (mistakeCount > 0 AND !isMastered) OR consecutiveCorrectStreak == 0
  - Sắp xếp: mistakeCount DESC, lastReviewDate ASC (từ sai nhiều nhất, lâu chưa ôn)

Tier 2 — Current Learning Path Topic Words (Tối đa 5 từ):
  - Điều kiện: Thuộc SubTopic đang học hoặc vừa hoàn thành gần nhất, !isMastered
  - Loại trừ: Các từ đã có trong Tier 1
  - Sắp xếp: consecutiveCorrectStreak ASC

Tier 3 — SRS Overdue Words (Tối đa 5 từ):
  - Điều kiện: nextReviewDate <= Date.now, !isMastered
  - Loại trừ: Các từ đã có trong Tier 1, Tier 2
  - Sắp xếp: nextReviewDate ASC (quá hạn lâu nhất trước)

Tier 4 — Random Learned / Starter Deck (Lấy bù cho đủ 10):
  - Điều kiện: Từ đã học bất kỳ hoặc từ mẫu cơ bản
  - Loại trừ: Các từ đã lấy ở Tier 1-3

Bước cuối: Xáo trộn ngẫu nhiên (Shuffle) 10 từ để tạo trải nghiệm bất ngờ, tránh học vẹt theo khuôn mẫu.
```

---

## 7. Màn hình Tổng kết & Re-drill Logic (`ReflexBlitzSummaryView`)

### 7.1 Bố cục Giao diện
1. **Header**:
   - Icon phân hạng tốc độ (`bolt.shield.fill`, `flame.fill`, `sparkles`).
   - Danh hiệu: `⚡️ Reflex Master` (≥ 90% chính xác & tốc độ cao), `🔥 Swift Reflex` (≥ 75%), `🌱 Steady Learner` (< 75%).
   - Xếp hạng 1-3 sao đạt được.
2. **Bento Metrics Grid (3 Thẻ `CraftCard`)**:
   - Tốc độ TB (`app.reflex.summary.avg_speed`): `Double(avgMs) / 1000.0`s.
   - Độ chính xác (`app.reflex.summary.accuracy`): `\(correct)/\(total)`.
   - Max Combo (`app.reflex.summary.max_combo`): `x\(maxCombo)`.
3. **Danh sách Từ cần củng cố (Weak Words)**:
   - Chỉ xuất hiện khi có từ làm sai hoặc hết giờ.
   - Mỗi từ là 1 thẻ `CraftCard` với đầy đủ Lemma, IPA, nghĩa tiếng Việt, thời gian phản hồi, và `CraftSpeakerButton` nghe lại.
4. **Sticky Bottom Action Bar**:
   - **Trường hợp có từ yếu**:
     - Nút Chính: `CraftButton("Luyện lại N từ chưa thuộc", customTint: theme.colors.statusDanger)` → Bắt đầu ngay phiên re-drill trong **cùng chế độ** vừa chọn cho danh sách từ yếu.
     - Nút Phụ: `CraftButton("Hoàn thành & Lưu tiến độ", variant: .ghost)` → Lưu dữ liệu và quay về Hub.
   - **Trường hợp đạt 10/10**:
     - Hiệu ứng pháo hoa `CraftSparkleView`.
     - Nút duy nhất: `CraftButton("Hoàn thành & Lưu tiến độ", variant: .primary)`.

### 7.2 Cập nhật Dữ liệu Tiến trình (Data Persistence)
- Ghi nhận `QuickReflexAttempt` vào cơ sở dữ liệu.
- Cập nhật chỉ số từ vựng:
  - **Đúng**: `consecutiveCorrectStreak += 1`, `mistakeCount = max(0, mistakeCount - 1)`, `lastReviewDate = Date()`. Nếu `consecutiveCorrectStreak >= 3` → `isMastered = true`. Nếu trước đó `needsReview == true` và làm đúng liên tiếp → gỡ `needsReview = false`.
  - **Sai / Hết giờ / Bỏ qua**: `consecutiveCorrectStreak = 0`, `mistakeCount += 1`, `lastReviewDate = Date()`, `needsReview = true`, `isMastered = false`.

---

## 8. Quy chuẩn Localization & Taxonomy

Toàn bộ chuỗi ngôn ngữ được lưu tại `VocabCraftApp/Resources/Localizable.xcstrings`:

```json
{
  "app.reflex.hub.badge": { "en": "REFLEX BLITZ", "vi": "REFLEX BLITZ" },
  "app.reflex.hub.title": { "en": "Speed Reflex Practice", "vi": "Luyện phản xạ tốc độ" },
  "app.reflex.hub.subtitle": { "en": "Choose your reflex modality today", "vi": "Chọn phương pháp phản xạ hôm nay" },
  "app.reflex.hub.stats_title": { "en": "Reflex Stats", "vi": "Thống kê phản xạ" },
  "app.reflex.stats.weekly_words": { "en": "%lld practiced", "vi": "%lld từ đã luyện" },
  "app.reflex.stats.weak_words": { "en": "%lld need review", "vi": "%lld từ cần củng cố" },
  "app.reflex.stats.avg_speed": { "en": "Avg Speed", "vi": "Tốc độ TB" },
  "app.reflex.hub.footer_hint": { "en": "Each word has a dedicated countdown to build unconditional reflexes.", "vi": "Mỗi từ có giới hạn đếm ngược riêng biệt để tạo phản xạ vô điều kiện." },

  "app.reflex.mode.speaking.title": { "en": "Speaking Drill", "vi": "Luyện nói" },
  "app.reflex.mode.speaking.subtitle": { "en": "Pronunciation reflex & voice recognition", "vi": "Phản xạ phát âm & nhận diện giọng nói" },
  "app.reflex.mode.typing.title": { "en": "Typing Drill", "vi": "Gõ từ" },
  "app.reflex.mode.typing.subtitle": { "en": "Keyboard reflex & spelling memory", "vi": "Phản xạ gõ phím & nhớ mặt chữ" },
  "app.reflex.mode.mc.title": { "en": "Multiple Choice", "vi": "Trắc nghiệm" },
  "app.reflex.mode.mc.subtitle": { "en": "1-in-4 rapid vocabulary identification", "vi": "Nhận diện từ vựng 1 trong 4" },
  "app.reflex.mode.listening.title": { "en": "Listening Reflex", "vi": "Phản xạ nghe" },
  "app.reflex.mode.listening.subtitle": { "en": "Audio capture & instant translation", "vi": "Bắt âm thanh & dịch nghĩa tức thì" },

  "app.reflex.drill.skip": { "en": "Skip", "vi": "Bỏ qua" },
  "app.reflex.drill.typing_placeholder": { "en": "Type English word...", "vi": "Gõ từ tiếng Anh..." },
  "app.reflex.drill.listening_instruction": { "en": "Select the Vietnamese meaning of the word you heard", "vi": "Chọn nghĩa tiếng Việt của từ vừa nghe" },
  "app.reflex.drill.listening_replay": { "en": "Replay pronunciation", "vi": "Nghe lại phát âm" },
  "app.reflex.drill.speaking_listening": { "en": "Listening for pronunciation...", "vi": "Đang lắng nghe phát âm..." },
  "app.reflex.drill.continue_cta": { "en": "Continue", "vi": "Tiếp tục" },

  "app.reflex.summary.title": { "en": "Reflex Blitz Completed", "vi": "Hoàn thành phiên phản xạ Blitz" },
  "app.reflex.summary.redrill_weak": { "en": "Re-drill %lld weak words", "vi": "Luyện lại %lld từ chưa thuộc" },
  "app.reflex.summary.finish_save": { "en": "Finish & Save Progress", "vi": "Hoàn thành & Lưu tiến độ" },
  "app.reflex.summary.perfect_title": { "en": "Perfect Reflex!", "vi": "Phản xạ hoàn hảo!" },
  "app.reflex.summary.perfect_desc": { "en": "You answered all words quickly and accurately.", "vi": "Bạn đã trả lời chính xác và nhanh chóng toàn bộ từ vựng." }
}
```

---

## 9. Kế hoạch Kiểm thử & Tiêu chuẩn Hoàn thành (Verification Suite)

1. **Unit Tests**:
   - `SmartPriorityQueueTests`: Kiểm tra hàng đợi 10 từ đúng tỷ lệ phân tầng (Tier 1 -> Tier 4) và loại trừ trùng lặp.
   - `ReflexBlitzViewModelTests`: Kiểm tra state machine 4 chế độ, thời gian đếm ngược, chuyển phase, tích lũy điểm và xử lý re-drill.
   - `SpeechServiceMatchingTests`: Kiểm tra so khớp từ vựng qua nhận diện giọng nói.
2. **UI & Component Verification**:
   - Kiểm tra hiển thị màn hình Hub trên Light/Dark mode.
   - Kiểm tra `CraftFeedbackSheet` trượt lên mượt mà và tương thích haptics.
   - Kiểm tra auto-focus `CraftTextField` trên chế độ Gõ từ.
3. **SwiftLint & Xcode Zero Warnings**:
   - Chạy `swiftlint` đảm bảo không có lỗi hoặc warning.
   - Compile Xcode với **0 errors và 0 warnings**.
