# Reflex Blitz — Multiple Choice & Review Consolidation Redesign Spec

## 1. Overview & Problem Statement

Tài liệu này đặc tả kiến trúc và thiết kế kỹ thuật nhằm khắc phục toàn diện 5 anti-patterns UX/UI và 7 điểm bất cập trên chế độ **Trắc nghiệm (Multiple Choice)** và **Trạng thái Củng cố (Reviewed Consolidation)** trong tính năng **Reflex Blitz** của VocabCraft.

### 1.1 Hiện trạng & Vấn đề Cốt lõi
1. **Lỗi ngắt chữ / vỡ layout (Micro-hyphenation & Layout Breaking):** Layout 2x2 Grid bị bóp nghẹt chiều ngang (< 60pt cho text), khiến các từ vựng phổ biến bị bẻ gãy âm tiết (`con-nect`, `ha-bit`, `im-pro-ve`, `fo-cu-s`). Với các cụm từ (Phrasal Verbs, Collocations), layout bị vỡ hoàn toàn.
2. **Nhiễu thị giác từ Prefix A/B/C/D:** Prefix A/B/C/D chiếm dụng diện tích, không cần thiết cho thao tác chạm trực tiếp (Direct Manipulation) trên mobile.
3. **Anti-pattern "Russian Doll Nesting" (Hộp lồng trong hộp):** Bao bọc toàn bộ đề bài, từ loại, câu ví dụ, và 4 thẻ đáp án vào 1 Card khổng lồ có viền đổi màu, tạo cảm giác chật chội và gò bó.
4. **Sai chuẩn Component Audio:** Sử dụng `CraftSpeakerButton` dạng Pill có chữ `"Pronounce word"`, dẫn đến hiện tượng truncate (`Pronounce...`) khi đặt cạnh Lemma và Badge từ loại.
5. **Trùng lặp Từ vựng & Trạng thái (Cognitive Overload):** Từ vựng mục tiêu và nhãn trạng thái (`Correct!`, `Incorrect`, `Time's up!`) xuất hiện lặp lại 2-3 lần cùng lúc trên màn hình.
6. **Ô nhiễm màu sắc (Sensory Overload):** Có tới 4-5 tín hiệu màu sắc phát sáng đồng thời khi trả lời (Header bar, Card border, Inner badge, Choice card, Bottom sheet).

---

## 2. Mục tiêu Thiết kế (Design Goals & Architecture)

- **Adaptive Dual-Zone Layout:** Tách biệt rành mạch giữa **Hero Stimulus Zone** (Khu vực Đề bài) và **Action Zone** (Khu vực Tương tác).
- **Full-Width Vertical Stack (1 Cột):** Chuyển đổi 4 phương án sang danh sách dọc 1 cột, đảm bảo hiển thị hoàn hảo từ đơn, phrasal verbs, collocations hay idioms dài mà không bao giờ vỡ dòng.
- **Prefix-Free & High Tap Ergonomics:** Loại bỏ prefix A/B/C/D (`prefixStyle: .none`), tối ưu hóa diện tích nhấn theo Fitts's Law.
- **Standardized Circular Audio Button:** Tái sử dụng `CraftSpeakerButton` hình tròn 40x40pt chuẩn Apple HIG với hiệu ứng sóng âm `symbolEffect`.
- **Single Source of Status Truth:** Tập trung thông báo trạng thái vào `CraftFeedbackSheet` và thẻ đáp án đã chọn; loại bỏ viền card đổi màu và các badge nội bộ trùng lặp.
- **100% CraftUIKit & Zero Hardcode:** Tuân thủ triệt để Design Tokens của `CraftUIKit` và chuẩn hóa đa ngôn ngữ (EN/VI).

---

## 3. Kiến trúc Giao diện Chi tiết (Detailed UI/UX Architecture)

### 3.1 Cấu trúc Phân tầng Giao diện (Visual Hierarchy)

```
┌──────────────────────────────────────────────────────────────────┐
│  REFLEX BLITZ VIEW (CANVAS BACKGROUND)                          │
│                                                                  │
│  [X]                  3 / 12  (Streak x3 🔥)                     │
│  ══════════════════════════════════════════════════ (Timer Bar) │
│                                                                  │
│  ┌── 1. HERO STIMULUS ZONE (VÙNG ĐỀ BÀI) ──────────────────────┐ │
│  │                                                              │ │
│  │  [Trạng thái Đang đếm ngược - Active Countdown]:            │ │
│  │                     [ N. ]  (POS Badge)                      │ │
│  │                   Thói quen (Nghĩa Tiếng Việt)               │ │
│  │        "Reading books daily is a great [ ••••• ]."           │ │
│  │                                                              │ │
│  │  [Trạng thái Củng cố - Reviewed Consolidation]:              │ │
│  │       habit  [ N. ]  [🔊]  /hæb.ɪt/ (Lemma + Loa + IPA)     │ │
│  │                   Thói quen (Nghĩa Tiếng Việt)               │ │
│  │        "Reading books daily is a great habit."               │ │
│  │        (Đọc sách mỗi ngày là một thói quen tuyệt vời)        │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌── 2. ACTION ZONE (VÙNG TƯƠNG TÁC ĐÁP ÁN) ───────────────────┐ │
│  │                                                              │ │
│  │  Vertical Stack (4 Thẻ 1 Cột - Full Width ~340-360pt):       │ │
│  │  ┌────────────────────────────────────────────────────────┐  │ │
│  │  │  simple                                                │  │ │
│  │  └────────────────────────────────────────────────────────┘  │ │
│  │  ┌────────────────────────────────────────────────────────┐  │ │
│  │  │  habit                                            (✓)  │  │ │
│  │  └────────────────────────────────────────────────────────┘  │ │
│  │  ┌────────────────────────────────────────────────────────┐  │ │
│  │  │  journey                                               │  │ │
│  │  └────────────────────────────────────────────────────────┘  │ │
│  │  ┌────────────────────────────────────────────────────────┐  │ │
│  │  │  connect                                               │  │ │
│  │  └────────────────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌── 3. FEEDBACK DOCK (BOTTOM SHEET KHI REVIEW) ───────────────┐ │
│  │  (✓) Chính xác!  +10 XP                                      │ │
│  │  [                      Tiếp tục                        ]   │ │
│  └──────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

---

## 4. Chi tiết Cải tiến Kỹ thuật (Technical Specifications)

### 4.1 Hero Stimulus Zone
- **Container**: Nằm ở nửa trên của màn hình, sử dụng card nền phẳng hoặc bề mặt nhẹ (`theme.colors.surfaceCard` với viền hairline trung tính, không đổi màu rực rỡ theo kết quả).
- **Active State (Đang đếm ngược)**:
  - POS Badge: `CraftBadge(word.pos.uppercased(), variant: .subtle, tone: .primary, size: .sm)`.
  - Định nghĩa tiếng Việt: `CraftText(word.definitionVi, style: .titleLarge, textAlignment: .center)`.
  - Cloze Sentence: Hiển thị câu khuyết từ `word.clozePrefix` + `[ • • • • • ]` (hoặc ký tự gợi ý khi gần hết giờ) + `word.clozeSuffix`.
- **Reviewed State (Sau khi trả lời / Hết giờ)**:
  - Header hàng ngang gọn gàng: `word.lemma` (`.titleLargeSerif`) + `CraftBadge(POS)` + `CraftSpeakerButton(variant: .subtle, size: .md)` + `word.ipa` (`.caption`).
  - Định nghĩa tiếng Việt: `word.definitionVi`.
  - Câu hoàn chỉnh: Từ mục tiêu được highlight tinh tế (`theme.colors.statusSuccess` hoặc `statusDanger`).
  - Bản dịch câu ví dụ: `word.exampleSentenceVi` (`.caption`, màu `textMuted`).
  - **Loại bỏ**: Badge trạng thái `Correct!`/`Incorrect` ở đầu card để tránh trùng lặp với `CraftFeedbackSheet`.

### 4.2 Action Zone (Vertical Options Stack)
- **Layout**: `VStack(spacing: theme.spacing.sm)` thay vì `LazyVGrid(columns: 2)`.
- **Component**: Sử dụng `CraftChoiceCard`:
  - `prefixStyle: .none` (hoặc `rawPrefix: nil`).
  - `textAlignment: .leading` (hoặc căn giữa trang nhã tùy chọn).
  - `style: .tactile3D`.
  - `minHeight: 52pt` (đáp ứng tiêu chuẩn Apple HIG cho touch target).
- **Quy tắc Trạng thái (Review State Rules)**:
  - Phương án đúng: `state: .correct` (Màu xanh `statusSuccess`, hiển thị icon checkmark).
  - Phương án sai người dùng đã chọn: `state: .wrong` (Màu đỏ `statusDanger`, hiển thị icon xmark).
  - Các phương án còn lại: `state: .idle` (hoặc `.disabled` nhẹ), giữ màu trung tính để mắt người dùng tập trung vào đáp án đúng.

### 4.3 Audio Button Optimization
- Chuyển `CraftSpeakerButton` về cấu hình không có nhãn văn bản:
  ```swift
  CraftSpeakerButton(
      variant: .subtle,
      size: .md,
      isPlaying: isAudioPlaying,
      action: {
          onReplayAudio?()
      }
  )
  ```
- Nút loa tròn 40x40pt với animation sóng âm khi phát âm từ vựng.

### 4.4 Feedback Sheet & Sensory Control
- Sử dụng `CraftFeedbackSheet` ở đáy màn hình:
  - Đúng: `status: .success`, title: `app.reflex.feedback.correct`, streak bonus nếu có.
  - Sai: `status: .error`, title: `app.reflex.feedback.incorrect`.
  - Hết giờ: `status: .warning`, title: `app.reflex.feedback.timeout`.
  - Nút bấm: `CraftButton(actionTitle: "Tiếp tục")`.

---

## 5. Danh sách File Cần Thay đổi (Impacted Files)

| File | Loại thay đổi | Chi tiết |
| :--- | :--- | :--- |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift` | Modify | Cấu trúc lại `activeMultipleChoiceContent`, chuyển options sang danh sách dọc, loại bỏ viền đổi màu rực rỡ ở container lớn. |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardReviewedView.swift` | Modify | Loại bỏ status badge trên đỉnh card, tích hợp `CraftSpeakerButton` hình tròn chuẩn, chuyển `reviewedOptionsGrid` sang vertical stack, dọn dẹp trùng lặp từ ngữ. |
| `Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift` | Check/Refine | Đảm bảo `CraftChoiceCard` căn chỉnh hoàn hảo khi `prefixStyle == .none`. |
| `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings` & `VocabCraftApp/Resources/Localizable.xcstrings` | Verify | Kiểm tra tính nhất quán 100% của chuỗi bản dịch EN/VI. |

---

## 6. Kế hoạch Kiểm thử & Đảm bảo Chất lượng (Verification Plan)

1. **Kiểm tra Giao diện trên Thiết bị / Simulator:**
   - Kiểm tra hiển thị của từ đơn ngắn (`habit`, `focus`), từ dài (`pronunciation`, `extraordinary`), và cụm từ (`look forward to`, `take care of`). Đảm bảo 0% lỗi hyphenate/vỡ dòng.
   - Kiểm tra độ nảy và haptic feedback khi chọn đáp án đúng / sai.
   - Kiểm tra nút loa phát âm hoạt động chuẩn xác, không bị giật hay mất layout.
2. **Automated Unit Tests:**
   - Chạy `swift test --filter LocalizationTests` để xác nhận 100% chuỗi bản dịch hợp lệ.
   - Chạy toàn bộ test suite của `CraftUIKit` và `VocabCraftApp`.
3. **SwiftLint & Compiler Diagnostics:**
   - 0 compiler warnings, 0 SwiftLint violations.

---

## 7. Self-Review Spec Checklist

- [x] **Placeholder scan:** Không có TODO, TBD hay các mục chưa hoàn thiện.
- [x] **Internal consistency:** Kiến trúc phân tầng (Dual-Zone) ăn khớp 100% với các component của `CraftUIKit`.
- [x] **Scope check:** Tập trung chính xác vào mode Trắc nghiệm và Review Consolidation của Reflex Blitz.
- [x] **Ambiguity check:** Quy tắc trạng thái màu sắc, padding, và component mapping đã được định nghĩa rõ ràng.
