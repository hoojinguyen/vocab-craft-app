# Design Specification: CraftUIKit Streak UI Component Suite

- **Date:** 2026-08-23
- **Status:** Approved / Ready for Implementation Plan
- **Scope:** `CraftUIKit` (Pure UI Library) & `VocabCraftApp` (Feature Integration)

---

## 1. Overview & Objectives

Streak (chuỗi ngày học liên tiếp) là một cơ chế gamification quan trọng giúp duy trì thói quen học tập của người dùng. Tài liệu này đặc tả kiến trúc, thành phần UI, design tokens, chuyển động (motion), phản hồi xúc giác (haptics), khả năng tiếp cận (accessibility), và ranh giới kiến trúc phân định rõ ràng giữa **UI Library (`CraftUIKit`)** và **Consumer App (`VocabCraftApp`)**.

### Guiding Principles
1. **Dumb / Presentational UI**: `CraftUIKit` chỉ nhận dữ liệu đã được tính sẵn (Pure View State) và bắn callbacks; toàn bộ logic tính toán ngày tháng, múi giờ, cơ sở dữ liệu và trừ khiên thuộc về `VocabCraftApp`.
2. **Apple HIG & SwiftUI Craft**: Tuân thủ chuẩn 44×44pt touch targets, Dynamic Type, 8pt spacing grid, native SF Symbols (không dùng emoji làm icon chức năng), hỗ trợ Reduce Motion và Dark Mode.
3. **Anti-AI-Slop Visuals**: Bảng màu ấm áp, chân thực (Warm Coral / Blaze Orange / Radiant Amber / Frost Ice), hiệu ứng Spring motion tinh tế, loại bỏ gradient neon tím/xanh rẻ tiền.

---

## 2. Architecture & Separation of Concerns

```
┌────────────────────────────────────────────────────────────────────────┐
│                          VocabCraftApp (Consumer)                      │
│  - Domain / Business Logic:                                            │
│    • Quản lý lịch sử học trong SwiftData (`UserProgressModelActor`)    │
│    • Tính toán số ngày streak liên tiếp & kiểm tra timezone            │
│    • Quản lý số lượng khiên bảo vệ (Streak Freezes)                    │
│    • Quyết định thăng hạng Tier & kích hoạt Celebration                │
│  - Presentation Mapping:                                               │
│    • Map Domain Entity ➔ `CraftStreakData` DTO                         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ (Pure View State)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        CraftUIKit (Pure UI Library)                    │
│  - Tokens & Theme:                                                     │
│    • `CraftColorTokens`: `streakFreeze`, `streakPendingRing`, v.v.     │
│    • `CraftGradientTokens`: `streakStarter`, `streakBlaze`, v.v.       │
│  - Components:                                                         │
│    • `CraftStreakBadge` (Compact Header Pill - .sm / .md)              │
│    • `CraftStreakCard` (7-Day Bento Dashboard Widget)                  │
│    • `CraftStreakCelebrationSheet` (Milestone & Streak Extension Modal)│
│  - Interactive Catalog:                                                │
│    • Interactive demo in `CraftCatalogView`                            │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Tokens & Data Models in `CraftUIKit`

### 3.1. Design Tokens Extension

#### `CraftColorTokens` additions:
- `streakFreeze`: `Color` (Ice Cyan `0x38BDF8` / Frost Blue)
- `streakPending`: `Color` (Muted border/ring color)
- `streakGlow`: `Color` (Subtle amber glow `0xF59E0B.opacity(0.3)`)

#### `CraftGradientTokens` additions:
- `streakStarter`: `LinearGradient` (Warm Coral: `0xE06D3B` -> `0xEA580C`)
- `streakBlaze`: `LinearGradient` (Blazing Gold & Orange: `0xF59E0B` -> `0xEA580C`)
- `streakLegendary`: `LinearGradient` (Deep Aurora & Radiant Cyan / Violet: `0x8B5CF6` -> `0x06B6D4`)

---

### 3.2. View State Models (`CraftStreakModels.swift`)

```swift
import SwiftUI

/// Cấp độ trực quan của ngọn lửa Streak.
public enum CraftStreakTier: String, Sendable, CaseIterable {
    case starter   // 1 - 6 ngày (Cam ấm)
    case blaze     // 7 - 29 ngày (Lửa rực sáng)
    case legendary // 30+ ngày (Huyền thoại / Aura đa sắc)

    public static func tier(for days: Int) -> CraftStreakTier {
        switch days {
        case 0...6: return .starter
        case 7...29: return .blaze
        default: return .legendary
        }
    }
}

/// Trạng thái của từng ngày trong tuần.
public enum CraftStreakDayStatus: String, Sendable, CaseIterable {
    case completed // Đã hoàn thành mục tiêu học
    case pending   // Ngày hôm nay đang chờ học
    case frozen    // Đã sử dụng khiên bảo vệ (Freeze Shield)
    case missed    // Ngày đã qua nhưng không học
    case upcoming  // Ngày tương lai trong tuần
}

/// DTO mô tả 1 ngày trong tuần.
public struct CraftStreakDay: Identifiable, Sendable, Equatable {
    public let id: String
    public let weekdaySymbol: String // "T2", "T3" hoặc "M", "T"
    public let status: CraftStreakDayStatus
    public let isToday: Bool

    public init(id: String, weekdaySymbol: String, status: CraftStreakDayStatus, isToday: Bool = false) {
        self.id = id
        self.weekdaySymbol = weekdaySymbol
        self.status = status
        self.isToday = isToday
    }
}

/// DTO tổng hợp trạng thái Streak để truyền vào UI.
public struct CraftStreakData: Sendable, Equatable {
    public let currentStreak: Int
    public let bestStreak: Int
    public let freezeTokens: Int
    public let maxFreezeTokens: Int
    public let nextMilestoneDays: Int
    public let isCompletedToday: Bool
    public let weekDays: [CraftStreakDay]
    public let subtitle: String?

    public var tier: CraftStreakTier {
        CraftStreakTier.tier(for: currentStreak)
    }

    public var milestoneProgress: Double {
        guard nextMilestoneDays > 0 else { return 1.0 }
        let progress = Double(currentStreak) / Double(nextMilestoneDays)
        return min(max(progress, 0.0), 1.0)
    }

    public init(
        currentStreak: Int,
        bestStreak: Int,
        freezeTokens: Int = 2,
        maxFreezeTokens: Int = 3,
        nextMilestoneDays: Int = 21,
        isCompletedToday: Bool = false,
        weekDays: [CraftStreakDay] = [],
        subtitle: String? = nil
    ) {
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.freezeTokens = freezeTokens
        self.maxFreezeTokens = maxFreezeTokens
        self.nextMilestoneDays = nextMilestoneDays
        self.isCompletedToday = isCompletedToday
        self.weekDays = weekDays
        self.subtitle = subtitle
    }
}
```

---

## 4. Component Specifications

### 4.1. `CraftStreakBadge` (Compact Pill)
- **Mục đích**: Hiển thị số ngày streak trên Navigation Bar / Header.
- **Kích thước**:
  - `.sm`: Chiều cao 32pt, font `.caption.bold()`, icon flame 13pt.
  - `.md`: Chiều cao 40pt, font `.callout.bold()`, icon flame 16pt.
- **Visuals & HIG**:
  - Hiển thị icon `flame.fill` tô màu theo `tier`.
  - Nếu `!isCompletedToday`: Có hiệu ứng breathing pulse hoặc viền nét đứt tinh tế.
  - Số ngày dùng `.monospacedDigit()` tránh giật layout.
  - Tap target mở rộng đảm bảo tối thiểu 44×44pt.
- **Callbacks**: `onTap: (() -> Void)?`.

---

### 4.2. `CraftStreakCard` (7-Day Bento Dashboard Widget)
- **Mục đích**: Widget trung tâm trên màn hình chính/profile để theo dõi tuần học.
- **Cấu trúc layout (8pt Grid)**:
  1. **Header Row**:
     - Cụm bên trái: Icon ngọn lửa lớn với gradient theo tier + Số ngày streak lớn (`.title2.bold()`) + Nhãn cấp độ (ví dụ: *"Blaze Streak"*).
     - Cụm bên phải: Badge kỷ lục tốt nhất (`"Kỷ lục: 30 ngày"`).
  2. **Week Track Row (`HStack(spacing: 8)`)**:
     - 7 cột tương ứng 7 ngày trong tuần (T2 đến CN).
     - Mỗi ngày gồm: Label thứ (`.caption2`), vòng tròn trạng thái (36×36pt).
     - Render icon tương ứng:
       - `completed`: Ngọn lửa nhỏ / Checkmark trên nền gradient lửa.
       - `pending`: Viền nét đứt nhấp nháy trên nền trong suốt.
       - `frozen`: Icon bông tuyết `snowflake` trên nền xanh băng (`streakFreeze`).
       - `missed`: Chấm xám mờ trung tính.
       - `upcoming`: Vòng tròn xám nhạt tối giản.
  3. **Footer Row**:
     - Khiên bảo vệ: `CraftBadge` với icon `snowflake` hiển thị `2/3 Khiên bảo vệ` (hỗ trợ callback `onFreezeTap`).
     - Thanh tiến độ mốc: `CraftProgressBar` kèm text chú thích (*"Còn 7 ngày nữa để đạt mốc 21 ngày"*).

---

### 4.3. `CraftStreakCelebrationSheet` (Milestone & Extension Modal)
- **Mục đích**: Trình bày sheet/dialog ăn mừng khi hoàn thành bài học kéo dài chuỗi ngày hoặc đạt mốc kỷ lục.
- **Visual & Motion**:
  - Hero Flame lớn (64×64pt) với hiệu ứng Spring Pop-in và gradient tier rực rỡ.
  - Hạt ăn mừng `CraftSparkleView` (bắn pháo hoa / tia sáng vàng & cam).
  - Hiệu ứng nhảy số (Animated Roll Counter) từ chuỗi ngày cũ sang mới (ví dụ `13` ➔ `14`).
  - Mini 7-day bar cập nhật trạng thái ngày hôm nay sang `completed` ngay trước mắt người dùng.
  - Haptic feedback chuẩn Apple (`UIImpactFeedbackGenerator(style: .medium)` hoặc `UINotificationFeedbackGenerator(.success)`).
  - Nút chính `CraftButton("Tiếp tục học", variant: .solid, tone: .primary)` kích hoạt callback `onDismiss`.

---

## 5. Accessibility & Motion Guidelines

1. **Reduce Motion**:
   - Tự động kiểm tra `@Environment(\.accessibilityReduceMotion)`.
   - Nếu `true`: Tắt toàn bộ chuyển động lặp vô tận (breathing pulse), tắt hiệu ứng hạt `CraftSparkleView`, và hiển thị số trực tiếp không qua animation counter.
2. **VoiceOver**:
   - Gộp các phần tử con thành single element logic:
     ```swift
     .accessibilityElement(children: .combine)
     .accessibilityLabel("Chuỗi \(data.currentStreak) ngày học liên tiếp, Cấp độ \(data.tier.rawValue). \(data.isCompletedToday ? "Hôm nay đã hoàn thành" : "Hôm nay chưa hoàn thành").")
     .accessibilityHint("Chạm hai lần để xem chi tiết chuỗi ngày.")
     ```
3. **Dynamic Type**:
   - Sử dụng `.font(.system(.body, design: .rounded))` hoặc các font style ngữ nghĩa để layout thích ứng mượt mà khi người dùng tăng kích thước chữ hệ thống.

---

## 6. Testing Strategy

1. **`CraftUIKitTests`**:
   - `CraftStreakModelTests`: Test khởi tạo `CraftStreakData`, test logic ánh xạ `CraftStreakTier.tier(for:)`, test `milestoneProgress`.
   - `CraftStreakComponentTests`: Test khởi tạo `CraftStreakBadge`, `CraftStreakCard`, `CraftStreakCelebrationSheet` với các mock state khác nhau (`completed`, `pending`, `frozen`, `legendary tier`).
2. **`CraftCatalogView` Demo**:
   - Tạo mục **"Streak Components"** cho phép chuyển đổi tương tác:
     - Đổi chuỗi ngày (3 ngày, 14 ngày, 45 ngày).
     - Toggle trạng thái `isCompletedToday`.
     - Nút thử nghiệm mở `CraftStreakCelebrationSheet`.
     - Kiểm tra trực quan trên các theme `Default Slate`, `Emerald Teal`, `Light` và `Dark Mode`.
3. **App Verification (`VocabCraftApp`)**:
   - Thay thế badge cũ trong `HeaderView.swift` bằng `CraftStreakBadge`.
   - Tích hợp `CraftStreakCard` vào Homepage view.
