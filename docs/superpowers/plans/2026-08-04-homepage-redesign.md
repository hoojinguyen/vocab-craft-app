# VocabCraft Homepage Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the redesigned VocabCraft iOS Homepage Screen and native Design System tokens adapted from `DESIGN.md` with full Light/Dark mode support, Bento Grid SRS analytics, and an iOS Liquid Glass Floating Tab Bar.

**Architecture:** Build SwiftUI design system color and typography tokens matching `DESIGN.md`, construct modular Bento Grid dashboard components (SRS Hero Card, Reflex Card, SRS Queue Card, CEFR breakdown), and assemble the main `HomepageView` wrapped in a floating Liquid Glass tab bar.

**Tech Stack:** Swift 5.9+, SwiftUI (iOS 17+), SF Symbols Framework, `SRSEngine` (SQLite).

## Global Constraints

- **Color Tokens:** Light Canvas `#FFFAF0`, Dark Canvas `#0A1A1A`, Surface Soft `#FAF5E8`, Surface Dark Elevated `#1A2A2A`, Hero Teal `#1A3A3A`, Mint `#A4D4C5`, Peach `#FFB084`, Lavender `#B8A4ED`, Coral `#FF6B5A`, Ink `#0A0A0A`, Dark Text `#FFFFFF`.
- **Iconography:** All icons MUST use Apple's native **SF Symbols Framework** (`Image(systemName: "...")`). Strictly no text emojis or custom SVGs in production code.
- **Liquid Glass Tab Bar:** Floating navigation bar with `backdrop-filter` translucency effect and 28pt corner radius.

---

### Task 1: Color Tokens & Design System Layer

**Files:**
- Create: `VocabCraftApp/Core/DesignSystem/ColorTokens.swift`
- Test: `VocabCraftAppTests/DesignSystem/ColorTokensTests.swift`

**Interfaces:**
- Produces: `Color.vocabCanvas`, `Color.vocabSurfaceSoft`, `Color.vocabHeroTeal`, `Color.vocabMint`, `Color.vocabPeach`, `Color.vocabLavender`, `Color.vocabCoral`, `Color.vocabInk`

- [ ] **Step 1: Write the failing color token test**

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class ColorTokensTests: XCTestCase {
    func testColorTokensExist() {
        XCTAssertNotNil(Color.vocabCanvas)
        XCTAssertNotNil(Color.vocabHeroTeal)
        XCTAssertNotNil(Color.vocabPeach)
        XCTAssertNotNil(Color.vocabLavender)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ColorTokensTests`
Expected: FAIL with "vocabCanvas is not a member of Color"

- [ ] **Step 3: Write minimal ColorTokens implementation**

```swift
import SwiftUI

public extension Color {
    static let vocabCanvas = Color("CanvasColor", bundle: nil)
    static let vocabSurfaceSoft = Color(hex: "#FAF5E8")
    static let vocabHeroTeal = Color(hex: "#1A3A3A")
    static let vocabMint = Color(hex: "#A4D4C5")
    static let vocabPeach = Color(hex: "#FFB084")
    static let vocabLavender = Color(hex: "#B8A4ED")
    static let vocabCoral = Color(hex: "#FF6B5A")
    static let vocabInk = Color(hex: "#0A0A0A")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ColorTokensTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/DesignSystem/ColorTokens.swift VocabCraftAppTests/DesignSystem/ColorTokensTests.swift
git commit -m "feat: add VocabCraft design system color tokens from DESIGN.md"
```

---

### Task 2: Header View Component (SF Symbols & Goal Progress Ring)

**Files:**
- Create: `VocabCraftApp/Features/Homepage/Views/HeaderView.swift`
- Test: `VocabCraftAppTests/Features/Homepage/HeaderViewTests.swift`

**Interfaces:**
- Consumes: `Color.vocabCoral`, `Color.vocabInk`
- Produces: `HeaderView(userName:streakDays:dailyGoalProgress:unreadNotifications:)`

- [ ] **Step 1: Write the failing header view test**

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class HeaderViewTests: XCTestCase {
    func testHeaderViewInitialization() {
        let view = HeaderView(userName: "Hooji N.", streakDays: 14, dailyGoalProgress: 0.75, unreadNotifications: true)
        XCTAssertNotNil(view)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter HeaderViewTests`
Expected: FAIL with "cannot find HeaderView in scope"

- [ ] **Step 3: Write HeaderView implementation with native SF Symbols**

```swift
import SwiftUI

public struct HeaderView: View {
    public let userName: String
    public let streakDays: Int
    public let dailyGoalProgress: Double
    public let unreadNotifications: Bool

    public init(userName: String, streakDays: Int, dailyGoalProgress: Double, unreadNotifications: Bool) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyGoalProgress = dailyGoalProgress
        self.unreadNotifications = unreadNotifications
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Avatar inside Daily Goal Conic Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: dailyGoalProgress)
                    .stroke(Color.vocabCoral, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(userName.prefix(2).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.vocabCoral)
                    Text("\(streakDays) NGÀY CONTINUOUS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.vocabCoral)
                }
                
                Text("Mục tiêu hôm nay: \(Int(dailyGoalProgress * 100))%")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }

            Spacer()

            // Notification Bell (SF Symbol)
            ZStack(alignment: .topTrailing) {
                Button(action: {}) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(width: 38, height: 38)
                        .background(Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                }
                
                if unreadNotifications {
                    Circle()
                        .fill(Color.vocabCoral)
                        .frame(width: 8, height: 8)
                        .offset(x: -2, y: 2)
                }
            }
        }
        .padding(.horizontal)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter HeaderViewTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HeaderView.swift VocabCraftAppTests/Features/Homepage/HeaderViewTests.swift
git commit -m "feat: add native HeaderView component with SF Symbols and Goal Progress Ring"
```

---

### Task 3: Mobile Quick Search Bar (Voice Input)

**Files:**
- Create: `VocabCraftApp/Features/Homepage/Views/MobileSearchView.swift`
- Test: `VocabCraftAppTests/Features/Homepage/MobileSearchViewTests.swift`

**Interfaces:**
- Consumes: SF Symbols `magnifyingglass`, `mic.fill`
- Produces: `MobileSearchView(searchText:onVoiceSearchTapped:)`

- [ ] **Step 1: Write the failing search view test**

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class MobileSearchViewTests: XCTestCase {
    func testMobileSearchViewInit() {
        let binding = Binding.constant("")
        let view = MobileSearchView(searchText: binding, onVoiceSearchTapped: {})
        XCTAssertNotNil(view)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter MobileSearchViewTests`
Expected: FAIL with "MobileSearchView not found"

- [ ] **Step 3: Write MobileSearchView implementation**

```swift
import SwiftUI

public struct MobileSearchView: View {
    @Binding public var searchText: String
    public var onVoiceSearchTapped: () -> Void

    public init(searchText: Binding<String>, onVoiceSearchTapped: @escaping () -> Void) {
        self._searchText = searchText
        self.onVoiceSearchTapped = onVoiceSearchTapped
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Tra cứu từ vựng hoặc thẻ bài...", text: $searchText)
                .font(.system(size: 13))
            
            Button(action: onVoiceSearchTapped) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.vocabSurfaceSoft)
        .cornerRadius(14)
        .padding(.horizontal)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter MobileSearchViewTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/MobileSearchView.swift VocabCraftAppTests/Features/Homepage/MobileSearchViewTests.swift
git commit -m "feat: add MobileSearchView component with SF Symbols search and microphone icons"
```

---

### Task 4: SRS Memory Hero Card & Action Bento Cards

**Files:**
- Create: `VocabCraftApp/Features/Homepage/Views/SRSMemoryHeroCard.swift`
- Create: `VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift`
- Test: `VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift`

**Interfaces:**
- Consumes: `Color.vocabHeroTeal`, `Color.vocabMint`, `Color.vocabPeach`, `Color.vocabLavender`
- SF Symbols: `bolt.fill`, `timer`, `calendar`, `rectangle.stack.fill`
- Produces: `SRSMemoryHeroCard(totalWords:retentionPercentage:)`, `ActionCardsGrid(dueCardsCount:onReflexTap:onQueueTap:)`

- [ ] **Step 1: Write failing bento cards test**

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class BentoCardsTests: XCTestCase {
    func testSRSMemoryHeroCard() {
        let hero = SRSMemoryHeroCard(totalWords: 1420, retentionPercentage: 0.85)
        XCTAssertNotNil(hero)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter BentoCardsTests`
Expected: FAIL with "SRSMemoryHeroCard not found"

- [ ] **Step 3: Write SRSMemoryHeroCard and ActionCardsGrid**

```swift
import SwiftUI

public struct SRSMemoryHeroCard: View {
    public let totalWords: Int
    public let retentionPercentage: Double

    public init(totalWords: Int, retentionPercentage: Double) {
        self.totalWords = totalWords
        self.retentionPercentage = retentionPercentage
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TRÍ NHỚ DÀI HẠN (SRS)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.vocabMint)

                Text("\(totalWords) từ")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("\(Int(retentionPercentage * 100))% từ đã vào trí nhớ bền vững")
                    .font(.system(size: 11))
                    .foregroundColor(Color.vocabMint)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: retentionPercentage)
                    .stroke(Color.vocabMint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(retentionPercentage * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.vocabMint)
            }
            .frame(width: 54, height: 54)
        }
        .padding(18)
        .background(Color.vocabHeroTeal)
        .cornerRadius(24)
        .padding(.horizontal)
    }
}

public struct ActionCardsGrid: View {
    public let dueCardsCount: Int
    public var onReflexTap: () -> Void
    public var onQueueTap: () -> Void

    public var body: some View {
        HStack(spacing: 10) {
            // Quick Reflex Card
            Button(action: onReflexTap) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("⚡ QUICK DRILL")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.12))
                            .cornerRadius(10)
                        Spacer()
                        Image(systemName: "timer")
                    }
                    Text("Luyện Phản Xạ")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color.vocabPeach)
                .cornerRadius(24)
            }

            // SRS Queue Card
            Button(action: onQueueTap) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("📅 SRS QUEUE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.12))
                            .cornerRadius(10)
                        Spacer()
                        Image(systemName: "rectangle.stack.fill")
                    }
                    Text("\(dueCardsCount) Thẻ Bài")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color.vocabLavender)
                .cornerRadius(24)
            }
        }
        .padding(.horizontal)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter BentoCardsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/SRSMemoryHeroCard.swift VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift
git commit -m "feat: add SRS Memory Hero Card and Bento Action Cards components"
```

---

### Task 5: iOS Liquid Glass Floating Tab Bar & Main Homepage Assembly

**Files:**
- Create: `VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift`
- Modify: `VocabCraftApp/App/VocabCraftApp.swift`
- Test: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- SF Symbols: `house.fill`, `book.fill`, `bolt.fill`, `gearshape.fill`
- Produces: `LiquidGlassTabBar(selectedTab:)`, `HomepageView`

- [ ] **Step 1: Write failing homepage view assembly test**

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class HomepageViewTests: XCTestCase {
    func testHomepageViewCreation() {
        let view = HomepageView()
        XCTAssertNotNil(view)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter HomepageViewTests`
Expected: FAIL with "HomepageView not found"

- [ ] **Step 3: Write LiquidGlassTabBar and HomepageView**

```swift
import SwiftUI

public enum TabItem: Int, CaseIterable {
    case home = 0
    case vocabulary = 1
    case reflex = 2
    case settings = 3

    var title: String {
        switch self {
        case .home: return "Trang chủ"
        case .vocabulary: return "Từ vựng"
        case .reflex: return "Phản xạ"
        case .settings: return "Cài đặt"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .vocabulary: return "book.fill"
        case .reflex: return "bolt.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct LiquidGlassTabBar: View {
    @Binding public var selectedTab: TabItem

    public var body: some View {
        HStack {
            ForEach(TabItem.allCases, id: \.rawValue) { tab in
                Spacer()
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18))
                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .bold : .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .primary : .secondary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, selectedTab == tab ? 12 : 4)
                    .background(selectedTab == tab ? Color.primary.opacity(0.08) : Color.clear)
                    .clipShape(Capsule())
                }
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

public struct HomepageView: View {
    @State private var searchText: String = ""
    @State private var selectedTab: TabItem = .home

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.vocabCanvas
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HeaderView(userName: "Hooji N.", streakDays: 14, dailyGoalProgress: 0.75, unreadNotifications: true)
                    
                    MobileSearchView(searchText: $searchText, onVoiceSearchTapped: {})
                    
                    SRSMemoryHeroCard(totalWords: 1420, retentionPercentage: 0.85)
                    
                    ActionCardsGrid(dueCardsCount: 24, onReflexTap: {}, onQueueTap: {})
                    
                    Spacer(minLength: 100)
                }
                .padding(.top)
            }

            LiquidGlassTabBar(selectedTab: $selectedTab)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter HomepageViewTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift VocabCraftApp/App/VocabCraftApp.swift VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift
git commit -m "feat: assemble redesigned HomepageView with Liquid Glass Tab Bar and native SF Symbols"
```

---

## Plan Handoff Announcement

Plan complete and saved to `docs/superpowers/plans/2026-08-04-homepage-redesign.md`. Two execution options:

1. **Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
