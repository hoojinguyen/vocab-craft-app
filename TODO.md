# Reflex Multi-Choice UI/UX Polish - Task Tracker

Kế hoạch cải tiến và tinh chỉnh giao diện & trải nghiệm người dùng cho chế độ Reflex Multi-Choice.

---

## 📋 Danh sách công việc (Task Breakdown)

### 🔹 Group 1: Tối giản Thẻ Câu Hỏi (Loại bỏ CEFR Badge ở Mặt Trước)
- [ ] **Task 1.1**: Cập nhật `ReflexBlitzMultipleChoiceCardView.swift` - Gỡ bỏ `CraftBadge(word.cleanLevel)` khỏi `frontPromptFace`. Chỉ giữ lại `cleanPos` (loại từ) và gợi ý hint (nếu có).
- [ ] **Task 1.2**: Đảm bảo mặt sau (`backResultFace`) vẫn giữ đầy đủ `cleanPos` và `cleanLevel` để người học tổng hợp thông tin sau khi lật.
- [ ] **Task 1.3**: Chạy test kiểm thử cho Group 1.

---

### 🔹 Group 2: Đồng bộ Ngôn ngữ Thiết kế Tactile 3D cho Stimulus Card
- [ ] **Task 2.1**: Áp dụng cấu trúc `tactile3D` đồng bộ cho Stimulus Flip Card (`frontPromptFace` và `backResultFace`) với gờ đáy 3D (`depthSm`), top highlight (`theme.depths.topHighlight`) và bo góc chuẩn `theme.radii.xl`.
- [ ] **Task 2.2**: Đồng bộ phong cách thẻ câu hỏi hài hòa với các thẻ đáp án bên dưới mà không làm phá vỡ hiệu ứng lật 3D `CraftFlipCard`.
- [ ] **Task 2.3**: Chạy test kiểm thử cho Group 2.

---

### 🔹 Group 3: Giảm tải "Visual Noise" & Màu sắc khi Trả lời (Subtle Glow / Shadow Accent)
- [ ] **Task 3.1**: Tinh chỉnh `CraftChoiceCard` với style `.tactile3D`: Giữ mặt thẻ sạch sáng, chuyển điểm nhấn màu Đúng/Sai (`statusSuccess`/`statusDanger`) tập trung vào gờ đáy 3D và bổ sung dải shadow/glow nhẹ nhàng dưới đáy thay vì đổi màu toàn bộ viền và nền quá chói.
- [ ] **Task 3.2**: Loại bỏ viền đổi màu sặc sỡ bao quanh toàn bộ mặt sau của Stimulus Card trong `ReflexBlitzMultipleChoiceCardView`, giữ phân cấp thị giác tập trung vào Bottom Feedback Sheet.
- [ ] **Task 3.3**: Chạy kiểm thử package `CraftUIKit` và app test suite.

---

### 🔹 Group 4: Tối ưu Khoảng cách, Vertical Rhythm & Triệt tiêu Rung Giật Layout khi Lật (Zero-Shift)
- [ ] **Task 4.1**: Cập nhật `ReflexBlitzView.swift` - Cố định khoảng cách giữa `ReflexBlitzHeaderView` và `ReflexBlitzCardView` bằng token `theme.spacing.base` hoặc `theme.spacing.md`, loại bỏ các `Spacer()` co giãn tự do gây khoảng trống quá lớn.
- [ ] **Task 4.2**: Thiết lập clearance ổn định cho vùng chứa Feedback Sheet đáy để Card không bị giật vị trí tọa độ Y khi xuất hiện Sheet.
- [ ] **Task 4.3**: Thiết lập `minHeight` hài hòa cho `CraftFlipCard` để mặt trước và mặt sau có chiều cao tương thích, lật thẻ mượt mà không co giãn màn hình.
- [ ] **Task 4.4**: Chạy kiểm thử toàn bộ test suite và build Xcode xác nhận 0 warning, 0 error.
