# Reflex Blitz — Multiple Choice Layout Stabilization, Motion & Typography Enhancement Spec

## 1. Overview & Problem Statement

Tài liệu này đặc tả kiến trúc kỹ thuật và giải pháp thiết kế nhằm khắc phục triệt để 4 vấn đề trải nghiệm người dùng (UX/UI & Animation) phát hiện trong quá trình thử nghiệm thực tế trên iPhone ở chế độ **Trắc nghiệm (Multiple Choice)** của tính năng **Reflex Blitz** trong VocabCraft.

### 1.1 Chi tiết 4 Vấn đề Trải nghiệm Thực tế

1. **Hiện tượng giật nảy layout màn hình (Vertical Layout Shift):**
   - Khi người dùng chọn đáp án (đúng hoặc sai), toàn bộ màn hình bị giật nảy lên trên, nén khoảng cách giữa Card và Header sát Dynamic Island/Status Bar.
   - *Nguyên nhân kỹ thuật:* `CraftFeedbackSheet` (~160pt) được render trực tiếp trong `VStack` chính (`drillingView`) bên dưới `Spacer()`. Khi từ `activeCountdown` sang `reviewed`, Bottom Sheet chèn vào làm mất không gian của `Spacer()`, đẩy toàn bộ cây View lên trên. Đồng thời, `ReflexBlitzCardReviewedView` render thêm nhiều thành phần mới (Lemma lớn, IPA, Loa, nghĩa tiếng Việt câu ví dụ) khiến Card phình to thêm ~120pt, gây ra layout shift kép.

2. **Sự không đồng nhất về UI của các item trắc nghiệm (Choice Items Inconsistency):**
   - Các nút trắc nghiệm ở trạng thái chưa chọn (`activeCountdown`) và đã chấm điểm (`reviewed`) có sự khác biệt rõ rệt về cảm giác thị giác, không tạo được tính liên tục.
   - *Nguyên nhân kỹ thuật:* `ReflexBlitzCardView` phân nhánh `if isReviewed { ReflexBlitzCardReviewedView } else { activeCountdownContentView }`, khiến SwiftUI hủy 4 instance `CraftChoiceCard` cũ và khởi tạo 4 instance mới. Việc này triệt tiêu hoàn toàn animation chuyển trạng thái mượt mà (`.idle` $\rightarrow$ `.correct`/`.wrong`), hiệu ứng squishy tactile bounce và haptic feedback liền mạch của `CraftChoiceCard`.

3. **Bottom Sheet thiếu Animation trượt từ dưới lên (Missing Slide-Up Motion):**
   - Khi có kết quả, Feedback Sheet xuất hiện tức thời (instant pop-in) thay vì trượt spring êm ái từ mép đáy màn hình lên như các bottom sheet khác trong app.
   - *Nguyên nhân kỹ thuật:* Trong `ReflexBlitzViewModel.selectOption()`, việc gán `cardPhase = .reviewed(...)` không nằm trong block `withAnimation`, và `ReflexBlitzView` thiếu explicit `.animation` modifier liên kết với `cardPhase`.

4. **Ký hiệu khuyết từ `[...]` quá tốn diện tích & Cỡ chữ câu ví dụ quá to:**
   - Ký hiệu khuyết từ `"[ • • • • • • ]"` dài tới 17 ký tự monospaced khiến ô khuyết từ chiếm tới 50% bề ngang, làm câu ví dụ bị bẻ gãy và ngắt đôi thành 2 dòng ngay giữa dấu ngoặc vuông (`[ • • •` ở dòng 1 và `• • • ]` ở dòng 2).
   - Cỡ chữ câu ví dụ dùng `titleMedium` Serif (~20-22pt) quá lớn, lấn át định nghĩa chính tiếng Việt (`titleLarge`) và đè nén không gian các nút trắc nghiệm bên dưới.

---

## 2. Mục tiêu Thiết kế (Design Goals & Architecture Principles)

- **Zero-Shift Layout Stability:** Neo giữ Header và Challenge Card trên trục tọa độ ổn định, loại bỏ hoàn toàn hiện tượng giật nảy màn hình khi chuyển đổi giữa làm bài và xem kết quả.
- **Continuous Component Lifecycle:** Duy trì duy nhất một cây component `CraftChoiceCard` xuyên suốt vòng đời của câu hỏi, kích hoạt trọn vẹn animation spring và visual feedback trực quan của `CraftChoiceCard`.
- **Fluid HIG-Compliant Motion Choreography:** Sheet kết quả xuất hiện dạng Overlay trượt mượt mà từ đáy (`.spring(response: 0.38, dampingFraction: 0.82)`), hỗ trợ chuẩn xác Reduce Motion.
- **Refined Typography & Compact Cloze Token:** Chuẩn hóa ô khuyết từ thành token cố định `[ • • • ]` không ngắt dòng; hạ tỷ lệ chữ câu ví dụ xuống `bodyLarge` / `bodySerif` (~16pt) tạo phân cấp thị giác trang nhã, tập trung vào từ vựng mục tiêu.
- **100% CraftUIKit Tokens & Zero Hardcoded Strings:** Tuân thủ tuyệt đối design tokens của `CraftUIKit` và chuẩn hóa key localization hai tầng (`craft.*` & `app.*`).

---

## 3. Kiến trúc Giao diện & Giải pháp Chi tiết (Detailed Technical Specifications)

### 3.1 Bố cục Zero-Shift & Tách rời Feedback Overlay (Issue 1 & 3)

#### Cấu trúc Layout mới trong `ReflexBlitzView`:
Thay vì đặt `CraftFeedbackSheet` trong luồng `VStack` chính, chuyển đổi layout thành dạng 2 tầng (Canvas Content + Floating Overlay Dock):

```
┌──────────────────────────────────────────────────────────────────┐
│  REFLEX BLITZ VIEW (ZStack / Canvas Background)                 │
│                                                                  │
│  ┌── TOP PINNED HEADER ────────────────────────────────────────┐ │
│  │  [X]                  3 / 12  (Streak x3 🔥)                 │ │
│  │  ══════════════════════════════════════════════ (Timer Bar) │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌── STABLE CARD CONTAINER (Centered / Safe Scroll Zone) ──────┐ │
│  │                                                              │ │
│  │  ┌────────────────────────────────────────────────────────┐  │ │
│  │  │  [ v. ]                                                │  │ │
│  │  │  Cải thiện, nâng cao                                   │  │ │
│  │  │                                                        │  │ │
│  │  │  "Practice helps you [ • • • ] your English skills."    │  │ │
│  │  │  ----------------------------------------------------  │  │ │
│  │  │  [ simple                                            ] │  │ │
│  │  │  [ improve                                       (✓) ] │  │ │
│  │  │  [ habit                                             ] │  │ │
│  │  │  [ focus                                             ] │  │ │
│  │  └────────────────────────────────────────────────────────┘  │ │
│  │                                                              │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌── FLOATING OVERLAY (Trượt từ đáy lên bằng Spring Motion) ───┐ │
│  │  (✓) Correct!  +10 XP                                         │ │
│  │  [ Continue ]                                                 │ │
│  └──────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

#### Chi tiết Kỹ thuật:
1. **Header neo cố định:** Đặt ở đỉnh màn hình với khoảng đệm an toàn (`safeAreaInset(edge: .top)`), hoàn toàn độc lập với phần nội dung bên dưới.
2. **Card Container ổn định:** Nằm ở vùng trung tâm. Khi chuyển sang `reviewed`, các thành phần bổ sung (như phiên âm IPA hoặc câu dịch nghĩa) được hiển thị dạng inline reveal tinh gọn với animation nội bộ `.springSmooth` mà không đẩy bung khung card.
3. **Feedback Dock dạng Overlay:** 
   - Đặt trong `ZStack` overlay hoặc sử dụng ViewModifier `.craftFeedbackSheet` chuẩn từ `CraftUIKit`.
   - Neo vào đáy màn hình với `ignoresSafeArea(edges: .bottom)`.
   - Áp dụng transition `.move(edge: .bottom).combined(with: .opacity)`.
   - Trong `ReflexBlitzViewModel`, bọc `cardPhase = .reviewed(...)` trong `withAnimation(.spring(response: 0.38, dampingFraction: 0.82))`.

---

### 3.2 Đồng nhất Danh sách Lựa chọn & Giữ nguyên View Identity (Issue 2)

#### Cơ chế Single-Tree Rendering:
Trong `ReflexBlitzCardView`, loại bỏ việc tách biệt 2 cây View `activeOptionsList` và `reviewedOptionsList`. Duy trì một `VStack` duy nhất chứa 4 `CraftChoiceCard`:

```swift
@ViewBuilder
private var optionsListView: some View {
    VStack(spacing: theme.spacing.sm) {
        ForEach(options, id: \.id) { option in
            let isSelected = (option.text == selectedOptionText)
            let choiceState: CraftChoiceState = {
                guard isReviewed else { return .idle }
                if option.isCorrect {
                    return .correct
                } else if isSelected {
                    return .wrong
                } else {
                    return .disabled // Hoặc .idle mờ nhẹ
                }
            }()

            CraftChoiceCard(
                prefix: nil,
                prefixStyle: .none,
                title: option.text,
                textAlignment: .leading,
                state: choiceState,
                style: .tactile3D,
                showsStatusIndicator: isReviewed && (option.isCorrect || isSelected),
                action: {
                    guard !isReviewed else { return }
                    onSelectOption?(option)
                }
            )
            .frame(minHeight: 52)
            .accessibilityLabel(option.text)
        }
    }
}
```

#### Lợi ích:
- Khi người dùng bấm vào option, `CraftChoiceCard` tương ứng chuyển ngay lập tức sang `.correct` hoặc `.wrong` với animation phóng nhẹ `scaleEffect(1.02)` và rung nhẹ `ChoiceShakeEffect` (nếu sai) cực kỳ sống động.
- Nút đúng tự động phát sáng xanh với icon checkmark `CraftIcon(checkmarkCircle)`.
- Không có bất kỳ hiện tượng chớp/nhấp nháy giao diện hay tái tạo view đột ngột.

---

### 3.3 Tinh gọn Ký hiệu Khuyết từ & Chuẩn hóa Typography Phân cấp (Issue 4)

#### 1. Chuẩn hóa Ô Khuyết từ (Cloze Slot Representation):
- **Trạng thái Mặc định (Chưa có hint):**
  - Sử dụng chuỗi cố định: `"[ • • • ]"` (3 dấu chấm thanh mảnh, khoảng cách chuẩn).
  - Không nhân rộng số lượng dấu chấm theo số ký tự của từ (tránh chuỗi quá dài gây rớt dòng).
  - Bọc bằng cụm Text liền khối, không cho phép ngắt dòng bên trong slot.
- **Trạng thái Gợi ý (Show Hint):**
  - Hiển thị chữ cái đầu kèm 3 chấm gọn gàng: `"[ \(initial) • • ]"` hoặc `"[ \(initial)... ]"`.
- **Trạng thái Reviewed:**
  - Hiển thị chính xác `word.lemma` với định dạng `.bold()` và màu sắc ngữ nghĩa (`statusSuccess` khi đúng, `statusDanger` khi sai).

#### 2. Phân cấp Typography (Visual Hierarchy Scale):

| Thành phần | Style trước đây | Style cải tiến mới | Token CraftUIKit |
| :--- | :--- | :--- | :--- |
| **Từ loại (POS)** | `CraftBadge` (`.sm`) | `CraftBadge` (`.sm`, capsule) | `theme.typography.caption` |
| **Định nghĩa chính (VI)** | `titleLarge` (~22pt) | `titleLarge` (~20-22pt, rounded/serif) | `theme.typography.titleLarge` |
| **Câu ví dụ (EN)** | `titleMedium` (~20pt Serif) | `bodyLarge` / `bodySerif` (~16-17pt Serif, lineSpacing 4) | `theme.typography.bodySerif` |
| **Từ khuyết / Target Word** | `titleMedium.bold()` (~20pt Mono) | `bodySerif.bold()` (~16-17pt Serif, bold) | `theme.typography.bodySerif` |
| **Bản dịch câu ví dụ (VI)** | `caption` (~12pt) | `caption` (~13pt, `textMuted`, lineSpacing 3) | `theme.typography.caption` |
| **Tên phương án trắc nghiệm** | `headline` (~16pt rounded) | `headline` (~16pt rounded/semibold) | `theme.typography.headline` |

---

## 4. Danh sách File và Phạm vi Thay đổi (Files Touched)

1. `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`:
   - Bọc các thay đổi trạng thái sang `.reviewed` trong `withAnimation(.spring(...))`.
   - Đảm bảo `advanceToNextWord()` và `loadWord()` đồng bộ trạng thái animation sạch sẽ.

2. `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`:
   - Tách rời `bottomDockArea` / `CraftFeedbackSheet` ra khỏi `VStack` chính, chuyển thành Overlay neo ở đáy màn hình.
   - Ổn định cấu trúc layout tổng thể, đảm bảo Header không bị xô lệch.

3. `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`:
   - Gộp `activeOptionsList` và `reviewedOptionsList` thành 1 danh sách `optionsListView` duy nhất.
   - Cập nhật hàm tạo `slotRepresentation` thành token gọn nhẹ `[ • • • ]`.
   - Điều chỉnh typography của câu ví dụ về `theme.typography.bodySerif` với lineSpacing cân đối.
   - Tinh giản giao diện khi sang trạng thái `reviewed` (chỉ hiển thị bổ sung thông tin cần thiết một cách thanh lịch, tránh phình to card).

4. `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardReviewedView.swift`:
   - Cập nhật typography và khoảng cách padding tương ứng để giữ vững tính đồng bộ khi xem lại bài tập.

---

## 5. Kế hoạch Kiểm thử & Tiêu chuẩn Nghiệm thu (Verification Plan)

### 5.1 Automated Tests
- Chạy toàn bộ test suite hiện có của Reflex Drill:
  - `swift test --filter ReflexBlitzViewModelTests`
  - `swift test --filter ReflexBlitzComponentsTests`
  - `swift test --filter ReflexBlitzViewIntegrationTests`
- Bổ sung unit tests kiểm tra:
  - Token khuyết từ luôn đảm bảo không vượt quá độ dài chuẩn.
  - Trạng thái `cardPhase` và các options giữ vững tính nhất quán khi chọn đáp án đúng/sai/timeout.

### 5.2 Manual & Visual Verification
- Khởi chạy app trên iOS Simulator (iPhone 16 Pro / iPhone SE).
- Test luồng làm trắc nghiệm:
  1. Bấm chọn đáp án đúng: Bottom sheet trượt lên êm ái, nút trắc nghiệm chuyển xanh có haptic, Header và Card không bị giật nảy lên.
  2. Bấm chọn đáp án sai: Nút được chọn chuyển đỏ kèm rung nhẹ, nút đúng sáng xanh, Bottom sheet trượt lên báo Incorrect, layout giữ nguyên vị trí.
  3. Kiểm tra câu ví dụ dài: Text hiển thị gọn trong 1-2 dòng, ô `[ • • • ]` không bao giờ bị ngắt đôi.
  4. Bấm "Continue": Card mới chuyển vào mượt mà, sheet rút xuống tự nhiên.

---

## 6. Spec Self-Review Checklist

- [x] **Placeholder Scan:** Không chứa "TBD", "TODO" hay các mục chưa hoàn thiện.
- [x] **Internal Consistency:** Đảm bảo kiến trúc Overlay Dock hoàn toàn tương thích với `CraftFeedbackSheet` và `CraftChoiceCard` của `CraftUIKit`.
- [x] **Scope Check:** Đầy đủ và tập trung giải quyết chính xác 4 vấn đề người dùng phản ánh, không mở rộng tính năng ngoài lề.
- [x] **Ambiguity Check:** Quy chuẩn về typography, token khuyết từ và cơ chế animation được xác định tường minh.
