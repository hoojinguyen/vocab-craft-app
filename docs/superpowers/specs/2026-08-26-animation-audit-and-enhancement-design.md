# Thiết Kế Kỹ Thuật: Audit, Tối Ưu Hiệu Năng & Nâng Cấp Hệ Thống Animation trong CraftUIKit

## 1. Mục Tiêu & Bối Cảnh
Hệ thống giao diện `CraftUIKit` trong ứng dụng `vocab-craft-app` hiện tại đang gặp tình trạng giật, lag và tụt khung hình (frame drops / scroll hitches) khi các hiệu ứng animation được kích hoạt trên màn hình hoặc trong quá trình cuộn danh sách (đặc biệt là lộ trình học `CraftLearningPath`, thẻ hoạt động `CraftActivityTrackerCard`, và các lớp phủ `CraftToast`, `CraftBottomSheet`, `CraftDialog`).

Tài liệu này đặc tả chi tiết:
1. Các giải pháp kỹ thuật vá triệt để các lỗi rò rỉ animation (animation leakage), bão re-render (invalidation storms) và nghẽn GPU/CPU theo chuẩn `swiftui-performance` và `swiftui-animation`.
2. Mở rộng và chuẩn hóa hệ thống Animation Tokens (`CraftAnimationTokens`) theo chuẩn Apple Human Interface Guidelines (HIG).
3. Bổ sung và tích hợp các bộ animation tương tác hiện đại (Keyframe Squash & Stretch, Path Unlock Surge, Fly-to-Target XP Parabola, Semantic SF Symbol Effects, Native Numeric Text transitions).

---

## 2. Kiến Trúc & Hệ Thống Tokens (`CraftAnimationTokens`)

### 2.1. Mở rộng Giao thức `CraftAnimationTokens`
Mở rộng giao thức `CraftAnimationTokens` để cung cấp đầy đủ các đường cong chuyển động có chủ đích:

```swift
public protocol CraftAnimationTokens: Sendable {
    /// Lò xo phản hồi nhanh cho nút bấm, micro-interactions, chip, toggle (0.22s, damping: 0.68)
    var springSnappy: Animation { get }
    /// Lò xo mượt mà cho sheet, modal, dialog, card transition (0.35s, damping: 0.85)
    var springSmooth: Animation { get }
    /// Lò xo nảy vui nhộn cho chúc mừng, nhận thưởng, mở khóa (0.42s, damping: 0.58)
    var springBouncy: Animation { get }
    /// Lò xo êm ái cho auto-scroll, camera panning, layout re-arrangement (0.55s, damping: 0.90)
    var springGentle: Animation { get }
    /// Lò xo bám sát cử chỉ ngón tay thời gian thực khi kéo thả (0.15s, damping: 0.82)
    var springInteractive: Animation { get }
}
```

### 2.2. Tiện ích `CraftMotionGuard` & Scoped Animation Helpers
* Cung cấp View Modifier `.craftAnimation(_:value:)` tự động kiểm tra `accessibilityReduceMotion`. Nếu Reduce Motion được bật trong hệ điều hành, animation sẽ fallback về `.none` hoặc `.opacity(0.15s)` mà không cần kiểm tra lặp lại tại từng View.
* Cung cấp helper modifier hỗ trợ `.animation(_:body:)` (iOS 17+) giúp cô lập chuyển động chỉ tác động lên các thuộc tính đồ họa (scale, opacity, offset) của lá cây view, không lan truyền layout invalidation ra bên ngoài.

---

## 3. Chi Tiết Khắc Phục Lỗi Hiệu Năng & Rò Rỉ Animation

### 3.1. Loại bỏ Rò Rỉ Animation trên Overlay Containers (`CraftToast`, `CraftBottomSheet`, `CraftDialog`)
* **Vấn đề đã xác định**: Modifier của `CraftToastModifier`, `CraftBottomSheetModifier`, `CraftDialogModifier` đặt `.animation(theme.animations.springSmooth, value: isPresented)` lên `ZStack { content ... }` bao trùm toàn bộ màn hình chủ. Khi toggle `isPresented`, toàn bộ cây view con bên dưới bị re-render và animate ngoài ý muốn.
* **Giải pháp**:
  - Gỡ bỏ hoàn toàn `.animation(...)` ở `ZStack` ngoài cùng.
  - Sử dụng explicit animation `withAnimation` tại điểm dispatch state kết hợp `.transition(...)` cục bộ trên riêng view phủ:
    - Backdrop: `.transition(.opacity)`
    - Toast: `.transition(.move(edge: position == .top ? .top : .bottom).combined(with: .opacity))`
    - Bottom Sheet: `.transition(.move(edge: .bottom).combined(with: .opacity))`
    - Dialog: `.transition(.scale(scale: 0.92).combined(with: .opacity))`
  - Đảm bảo dismiss tap không tạo transaction animation xung đột với các binding bên ngoài.

### 3.2. Triệt Tiêu "Invalidation Storms" Từ `@State` + `.repeatForever`
* **`CraftActivityTrackerCard` & `CraftStepNode`**:
  - **Vấn đề**: `@State private var isPulsing` trong component cha kích hoạt `withAnimation(.easeInOut.repeatForever)` làm re-render toàn bộ body của thẻ liên tục ở 60-120fps.
  - **Giải pháp**: Tách hiệu ứng vòng phát sáng (Aura Pulsing Ring) thành một leaf view riêng (`CraftPulsingAuraRing`). Toàn bộ chu trình `PhaseAnimator` hoặc `TimelineView` được đóng gói bên trong `CraftPulsingAuraRing`, cô lập 100% không làm cha re-render.
* **`CraftSpinner`**:
  - Chuyển từ việc cập nhật `@State isAnimating` với `repeatForever` sang sử dụng `PhaseAnimator` hoặc `TimelineView` cô lập trong atom view, kết hợp `accessibilityRepresentation { ProgressView() }`.
* **`CraftShimmerModifier`**:
  - Tách layer gradient quét bóng thành `AnimatableModifier` với pha độc lập, không kích hoạt body re-evaluation của view được áp dụng shimmer.

### 3.3. Tối Ưu Hóa GPU Render Pipeline trên `CraftLearningPath`
* **Loại bỏ Dynamic Shadow Computation**: Thay thế việc animate `.shadow(radius: 6)` trên từng frame bằng `RadialGradient` đa điểm cố định và chỉ animate `.opacity` / `.scaleEffect`.
* **Tối ưu hóa Vector Connectors**: Cache các mảng dash `[0, diameter + spacing]` trong `CraftSnakeConnectorLayer`, ngăn chặn việc tái khởi tạo Path trong mỗi sự kiện cuộn.
* **Modern Numeric Text Counter**: Trong `CraftCelebrationSheet`, thay thế vòng lặp đếm số `for ... Task.sleep` bằng `.contentTransition(.numericText(countsDown: false))` kết hợp `.animation(theme.animations.springSmooth, value: displayedValue)`.

---

## 4. Đặc Tả Chi Tiết Các Bộ Animation Mới

### 4.1. `CraftSquashAndStretch` Modifier (Cơ Học Nhún Nảy)
* **Mô hình**: Dùng `KeyframeAnimator` (iOS 17+) điều khiển 3 tracks độc lập (`scaleX`, `scaleY`, `yOffset`) dựa trên trigger:
  - `scaleX`: `SpringKeyframe(1.08, duration: 0.12)` $\rightarrow$ `SpringKeyframe(0.95, duration: 0.15)` $\rightarrow$ `CubicKeyframe(1.0, duration: 0.1)`
  - `scaleY`: `SpringKeyframe(0.92, duration: 0.12)` $\rightarrow$ `SpringKeyframe(1.06, duration: 0.15)` $\rightarrow$ `CubicKeyframe(1.0, duration: 0.1)`
  - `yOffset`: `SpringKeyframe(3.0, duration: 0.12)` $\rightarrow$ `SpringKeyframe(-2.0, duration: 0.15)` $\rightarrow$ `CubicKeyframe(0.0, duration: 0.1)`
* **Áp dụng**: Tích hợp vào `CraftButton`, `CraftLessonNode`, `CraftChoiceCard`.

### 4.2. `CraftPathUnlockSurge` (Luồng Sáng Kích Hoạt Lộ Trình)
* **Mô hình**: Tạo hiệu ứng ánh sáng chạy dọc theo đường cong serpentine Bézier khi ải mới được mở:
  - Custom `Shape` điều khiển `trim(from: max(0, progress - 0.2), to: progress)` kết hợp hạt sáng phát quang (glow spark).
  - Hoạt cảnh chạy từ $0.0 \rightarrow 1.0$ trong $0.65\text{s}$ với `theme.animations.springGentle`.

### 4.3. `CraftFlyToTargetEffect` (Hạt Phần Thưởng Bay Parabol)
* **Mô hình**: Emitter bắn $3\text{--}5$ hạt (XP / Kim cương / Tia lửa) từ tọa độ xuất phát (Node) bay vút lên Header theo quỹ đạo đường cong Bézier bậc 2 ($P(t) = (1-t)^2 P_0 + 2(1-t)t P_1 + t^2 P_2$), thu nhỏ dần và kích hoạt haptic nhẹ tại đích đến.

### 4.4. Semantic SF Symbol Effects Suite
* Cung cấp các View Modifiers tiện ích:
  - `.craftSymbolBounce(value:)`: Nảy biểu tượng khi điểm số thay đổi.
  - `.craftSymbolPulse(isActive:)`: Phát xung biểu tượng (dành cho mic/recording).
  - `.craftSymbolVariableColor(isActive:)`: Chuyển màu tuần hoàn sóng âm (dành cho loa phát âm/wifi).
  - `.craftSymbolReplace()`: Thay thế biểu tượng mượt mà với `.contentTransition(.symbolEffect(.replace.downUp))`.

---

## 5. Kế Hoạch Kiểm Thử & Đo Lường

### 5.1. Automated Test Suite
1. **Token Tests**: Xác thực các giá trị mặc định của `CraftAnimationTokens` (`springSnappy`, `springSmooth`, `springBouncy`, `springGentle`, `springInteractive`).
2. **Reduce Motion Compliance Tests**: Xác thực việc triệt tiêu hoàn toàn chuyển động khi `accessibilityReduceMotion == true`.
3. **Overlay Isolation Tests**: Kiểm tra `CraftToast`, `CraftBottomSheet`, `CraftDialog` khi toggle state không làm thay đổi frame/transaction của content view.
4. **Swift Test Execution**: Toàn bộ test suite của `CraftUIKit` tiếp tục vượt qua $100\%$ ($471+$ tests).

### 5.2. Verification Metrics
* **Scroll 120 FPS**: Đạt $60/120\text{ FPS}$ ổn định khi cuộn `CraftLearningPath` chứa nhiều section và connector.
* **Zero Frame Invalidation**: Không có hiện tượng re-evaluate body của card cha khi `CraftActivityTrackerCard` hoặc `CraftStepNode` đang chạy hiệu ứng nhịp thở.
