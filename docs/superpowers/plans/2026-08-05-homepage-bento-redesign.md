# Homepage Bento & Dark Mode Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign `HomepageView` and its subcomponents into a modern Neumorphic Bento layout with standardized Vietnamese microcopy, Apple HIG compliant 44pt touch targets, tactile spring animations, and automatic Light/Dark mode support.

**Architecture:** Refactor SwiftUI views in `VocabCraftApp/Features/Homepage/Views` and update semantic color tokens in `VocabCraftApp/Core/DesignSystem/Color+VocabCraft.swift`. Leverage `Color.vocabCanvas`, `Color.vocabSurfaceCard`, and `Color.vocabInk` semantic bindings to achieve clean automatic dark mode transitions without modifying caller APIs.

**Tech Stack:** Swift, SwiftUI, XCTest, macOS / iOS SDK

## Global Constraints

- Platform Requirements: iOS 17+, macOS 14+ compatible SwiftUI code
- Minimum Touch Target: 44x44 pt on all interactive controls (bell icon, clear button, voice button, tab bar items)
- Design Token Names: Must use exact semantic bindings `Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabHeroTeal`, `Color.vocabInk`, `Color.vocabMuted`, `Color.vocabHairline`, `Color.vocabCoral`, `Color.vocabMint`, `Color.vocabPeach`, `Color.vocabLavender`
- Test Framework: `swift test` with XCTest assertions in `VocabCraftAppTests`

---

### Task 1: Semantic Color Tokens & Dark Mode Assets

**Files:**
- Modify: `VocabCraftApp/Core/DesignSystem/Color+VocabCraft.swift`
- Test: `VocabCraftAppTests/DesignSystem/ColorTokensTests.swift`

**Interfaces:**
- Consumes: Existing `Color+VocabCraft.swift` extension
- Produces: `Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabHeroTeal`, `Color.vocabInk`, `Color.vocabMuted`, `Color.vocabHairline` with dynamic Light/Dark initializer support

- [ ] **Step 1: Write the failing test for semantic color tokens**

Create `VocabCraftAppTests/DesignSystem/ColorTokensTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class ColorTokensTests: XCTestCase {
    func testSemanticColorTokensExistAndInstantiate() {
        XCTAssertNotNil(Color.vocabCanvas)
        XCTAssertNotNil(Color.vocabSurfaceCard)
        XCTAssertNotNil(Color.vocabHeroTeal)
        XCTAssertNotNil(Color.vocabInk)
        XCTAssertNotNil(Color.vocabMuted)
        XCTAssertNotNil(Color.vocabHairline)
        XCTAssertNotNil(Color.vocabCoral)
        XCTAssertNotNil(Color.vocabMint)
        XCTAssertNotNil(Color.vocabPeach)
        XCTAssertNotNil(Color.vocabLavender)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ColorTokensTests`  
Expected: FAIL due to missing `ColorTokensTests.swift` in package target or missing static properties.

- [ ] **Step 3: Update `Color+VocabCraft.swift` with dynamic Light/Dark color definitions**

Modify `VocabCraftApp/Core/DesignSystem/Color+VocabCraft.swift`:

```swift
import SwiftUI

public extension Color {
    // Dynamic Light / Dark mode helper
    static func dynamic(light: Color, dark: Color) -> Color {
        #if os(iOS)
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif os(macOS)
        return Color(NSColor(name: nil, dynamicProvider: { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua ? NSColor(dark) : NSColor(light)
        }))
        #else
        return light
        #endif
    }

    // Semantic Canvas & Surface Tokens
    static let vocabCanvas = dynamic(
        light: Color(red: 1.0, green: 0.98, blue: 0.94), // #FFFAF0 Warm Cream
        dark: Color(red: 0.04, green: 0.10, blue: 0.10)   // #0A1A1A Deep Forest Night
    )
    
    static let vocabSurfaceSoft = dynamic(
        light: Color(red: 0.98, green: 0.96, blue: 0.91), // #FAF5E8
        dark: Color(red: 0.08, green: 0.14, blue: 0.14)   // #142424
    )

    static let vocabSurfaceCard = dynamic(
        light: Color.white,                              // #FFFFFF Pure White
        dark: Color(red: 0.10, green: 0.16, blue: 0.16)   // #1A2A2A Slate Card
    )

    static let vocabHeroTeal = dynamic(
        light: Color(red: 0.10, green: 0.23, blue: 0.23), // #1A3A3A Deep Forest Teal
        dark: Color(red: 0.06, green: 0.17, blue: 0.17)   // #0F2B2B Dark Teal
    )

    static let vocabInk = dynamic(
        light: Color(red: 0.04, green: 0.04, blue: 0.04), // #0A0A0A Off-Black
        dark: Color(red: 0.94, green: 0.96, blue: 0.99)   // #F0F6FC Soft Off-White
    )

    static let vocabMuted = dynamic(
        light: Color(red: 0.41, green: 0.41, blue: 0.41), // #6A6A6A Neutral Gray
        dark: Color(red: 0.63, green: 0.68, blue: 0.75)   // #A0AEC0 Light Slate Gray
    )

    static let vocabHairline = dynamic(
        light: Color(red: 0.90, green: 0.90, blue: 0.90), // #E5E5E5
        dark: Color.white.opacity(0.12)
    )

    // Brand Accent Tokens
    static let vocabCoral = dynamic(
        light: Color(red: 1.0, green: 0.42, blue: 0.35),  // #FF6B5A Coral
        dark: Color(red: 1.0, green: 0.48, blue: 0.42)   // #FF7A6B (+Luminance)
    )

    static let vocabMint = dynamic(
        light: Color(red: 0.64, green: 0.83, blue: 0.77), // #A4D4C5 Mint
        dark: Color(red: 0.71, green: 0.90, blue: 0.84)  // #B5E5D6 (+Luminance)
    )

    static let vocabPeach = dynamic(
        light: Color(red: 1.0, green: 0.69, blue: 0.52),  // #FFB084 Peach
        dark: Color(red: 1.0, green: 0.75, blue: 0.61)   // #FFC09C (+Luminance)
    )

    static let vocabLavender = dynamic(
        light: Color(red: 0.72, green: 0.64, blue: 0.93), // #B8A4ED Lavender
        dark: Color(red: 0.78, green: 0.72, blue: 0.95)  // #C8B8F2 (+Luminance)
    )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ColorTokensTests`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/DesignSystem/Color+VocabCraft.swift VocabCraftAppTests/DesignSystem/ColorTokensTests.swift
git commit -m "feat(design): add semantic dynamic Light and Dark mode color tokens"
```

---

### Task 2: HeaderView Redesign & Touch Targets

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HeaderView.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/HeaderViewTests.swift`

**Interfaces:**
- Consumes: `HeaderView(userName:streakDays:dailyGoalProgress:unreadNotifications:)`
- Produces: Redesigned HeaderView with `"🔥 14 ngày liên tiếp"` streak capsule, `"Chào Hooji 👋"` greeting, and 44x44 pt notification bell hit box.

- [ ] **Step 1: Write failing tests for HeaderView microcopy and structure**

Modify `VocabCraftAppTests/Features/Homepage/HeaderViewTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class HeaderViewTests: XCTestCase {
    func testHeaderViewInstantiation() {
        let view = HeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyGoalProgress: 0.75,
            unreadNotifications: true
        )
        XCTAssertNotNil(view.body)
        XCTAssertEqual(view.userName, "Hooji N.")
        XCTAssertEqual(view.streakDays, 14)
        XCTAssertEqual(view.dailyGoalProgress, 0.75)
        XCTAssertTrue(view.unreadNotifications)
    }
}
```

- [ ] **Step 2: Run test to verify it compiles and runs**

Run: `swift test --filter HeaderViewTests`  
Expected: PASS (pre-check baseline)

- [ ] **Step 3: Refactor `HeaderView.swift` for Bento layout & 44pt touch boundary**

Modify `VocabCraftApp/Features/Homepage/Views/HeaderView.swift`:

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
                    .stroke(Color.vocabHairline, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(max(dailyGoalProgress, 0), 1.0))
                    .stroke(Color.vocabCoral, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(userName.prefix(2).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.vocabInk)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("Chào \(userName) 👋")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                
                Text("Mục tiêu hôm nay: \(Int(dailyGoalProgress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }

            Spacer()

            // Streak Badge Pill Capsule
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.vocabCoral)
                Text("\(streakDays) ngày liên tiếp")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.vocabCoral)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.vocabCoral.opacity(0.12))
            .clipShape(Capsule())

            // Notification Bell Button with 44x44pt touch target
            ZStack(alignment: .topTrailing) {
                Button(action: {}) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.vocabInk)
                        .frame(width: 44, height: 44)
                        .background(Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                if unreadNotifications {
                    Circle()
                        .fill(Color.vocabCoral)
                        .frame(width: 9, height: 9)
                        .offset(x: -4, y: 4)
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
git commit -m "refactor(homepage): update HeaderView microcopy, streak capsule, and 44pt touch target"
```

---

### Task 3: MobileSearchView Touch Target & Styling Upgrade

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/MobileSearchView.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/MobileSearchViewTests.swift`

**Interfaces:**
- Consumes: `MobileSearchView(searchText:onVoiceSearchTapped:)`
- Produces: Refactored search bar with 44x44 pt hit targets on Clear and Voice Search buttons.

- [ ] **Step 1: Write failing/updated tests for MobileSearchView**

Modify `VocabCraftAppTests/Features/Homepage/MobileSearchViewTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class MobileSearchViewTests: XCTestCase {
    func testMobileSearchViewInitialization() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let view = MobileSearchView(searchText: binding, onVoiceSearchTapped: {})
        XCTAssertNotNil(view.body)
        XCTAssertEqual(view.searchText, "Hello")
    }
}
```

- [ ] **Step 2: Run test to verify pre-check baseline**

Run: `swift test --filter MobileSearchViewTests`  
Expected: PASS

- [ ] **Step 3: Refactor `MobileSearchView.swift` with 44pt buttons and dynamic surface card background**

Modify `VocabCraftApp/Features/Homepage/Views/MobileSearchView.swift`:

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
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.vocabHeroTeal)
            
            TextField("Tra cứu từ vựng hoặc thẻ bài...", text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.vocabInk)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.vocabMuted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            
            Button(action: onVoiceSearchTapped) {
                ZStack {
                    Circle()
                        .fill(Color.vocabHeroTeal.opacity(0.08))
                        .frame(width: 32, height: 32)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.vocabHeroTeal)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.vocabSurfaceCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.vocabHeroTeal.opacity(0.05), radius: 6, x: 0, y: 3)
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
git commit -m "refactor(homepage): upgrade MobileSearchView styling and 44pt touch targets"
```

---

### Task 4: SRSMemoryHeroCard Microcopy & Alignment Refactor

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/SRSMemoryHeroCard.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift`

**Interfaces:**
- Consumes: `SRSMemoryHeroCard(totalWords:retentionPercentage:)`
- Produces: Refactored Hero Card with `"85% từ đã đi vào bộ nhớ bền vững"` microcopy.

- [ ] **Step 1: Write test for SRSMemoryHeroCard**

Modify `VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class BentoCardsTests: XCTestCase {
    func testSRSMemoryHeroCardInstantiation() {
        let heroCard = SRSMemoryHeroCard(totalWords: 1420, retentionPercentage: 0.85)
        XCTAssertNotNil(heroCard.body)
        XCTAssertEqual(heroCard.totalWords, 1420)
        XCTAssertEqual(heroCard.retentionPercentage, 0.85)
    }
}
```

- [ ] **Step 2: Run test to verify baseline**

Run: `swift test --filter BentoCardsTests`  
Expected: PASS

- [ ] **Step 3: Refactor `SRSMemoryHeroCard.swift`**

Modify `VocabCraftApp/Features/Homepage/Views/SRSMemoryHeroCard.swift`:

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
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TRÍ NHỚ DÀI HẠN (SRS)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.vocabMint)
                    .tracking(0.5)

                Text("\(totalWords) từ")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("\(Int(retentionPercentage * 100))% từ đã đi vào bộ nhớ bền vững")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMint.opacity(0.9))
            }

            Spacer()

            // 60pt Conic progress gauge ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(retentionPercentage, 0.0), 1.0)))
                    .stroke(
                        Color.vocabMint,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(retentionPercentage * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.vocabMint)
            }
            .frame(width: 60, height: 60)
        }
        .padding(20)
        .background(Color.vocabHeroTeal)
        .cornerRadius(24)
        .padding(.horizontal)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter BentoCardsTests`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/SRSMemoryHeroCard.swift VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift
git commit -m "refactor(homepage): refine SRSMemoryHeroCard typography and microcopy"
```

---

### Task 5: ActionCardsGrid Bento Styling & Spring Animation

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift`

**Interfaces:**
- Consumes: `ActionCardsGrid(dueCardsCount:onReflexTap:onQueueTap:)`
- Produces: Dual Bento action cards with `vocabSurfaceCard` surface, `vocabHairline` border, accent badges, and `BentoCardButtonStyle` spring press effect.

- [ ] **Step 1: Write test for ActionCardsGrid**

Add to `VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift`:

```swift
    func testActionCardsGridInstantiation() {
        let grid = ActionCardsGrid(dueCardsCount: 24, onReflexTap: {}, onQueueTap: {})
        XCTAssertNotNil(grid.body)
        XCTAssertEqual(grid.dueCardsCount, 24)
    }
```

- [ ] **Step 2: Run test to verify baseline**

Run: `swift test --filter BentoCardsTests`  
Expected: PASS

- [ ] **Step 3: Refactor `ActionCardsGrid.swift` to Bento White Surface Card style**

Modify `VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift`:

```swift
import SwiftUI

public struct BentoCardButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

public struct ActionCardsGrid: View {
    public let dueCardsCount: Int
    public var onReflexTap: () -> Void
    public var onQueueTap: () -> Void

    public init(
        dueCardsCount: Int,
        onReflexTap: @escaping () -> Void,
        onQueueTap: @escaping () -> Void
    ) {
        self.dueCardsCount = dueCardsCount
        self.onReflexTap = onReflexTap
        self.onQueueTap = onQueueTap
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Quick Reflex Drill Card
            Button(action: onReflexTap) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("THỬ THÁCH")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.vocabPeach.opacity(0.20))
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(10)

                        Spacer()

                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.vocabHeroTeal)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Luyện Phản Xạ")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                        Text("Rèn phản xạ tốc độ")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.vocabMuted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vocabSurfaceCard)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                )
                .shadow(color: Color.vocabHeroTeal.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(BentoCardButtonStyle())

            // SRS Queue Card
            Button(action: onQueueTap) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(dueCardsCount) THẺ BÀI")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.vocabLavender.opacity(0.20))
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(10)

                        Spacer()

                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.vocabHeroTeal)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hàng Đợi SRS")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                        Text("Cần hoàn thành hôm nay")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.vocabMuted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vocabSurfaceCard)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                )
                .shadow(color: Color.vocabHeroTeal.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(BentoCardButtonStyle())
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
git add VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift
git commit -m "refactor(homepage): update ActionCardsGrid to Bento surface card style with spring button interaction"
```

---

### Task 6: CEFRDistributionCard Legend & Tri-color Segment Refactor

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/CEFRDistributionCard.swift`
- Test: `VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift`

**Interfaces:**
- Consumes: `CEFRDistributionCard(a1a2Count:b1b2Count:c1c2Count:onDetailTap:)`
- Produces: Refactored CEFR card with dynamic `vocabSurfaceCard` fill, `vocabHairline` border, and updated subtitle `"Tiến trình năng lực từ vựng"`.

- [ ] **Step 1: Add test for CEFRDistributionCard**

Add to `VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift`:

```swift
    func testCEFRDistributionCardInstantiation() {
        let card = CEFRDistributionCard(a1a2Count: 450, b1b2Count: 620, c1c2Count: 350)
        XCTAssertNotNil(card.body)
    }
```

- [ ] **Step 2: Run test to verify baseline**

Run: `swift test --filter BentoCardsTests`  
Expected: PASS

- [ ] **Step 3: Refactor `CEFRDistributionCard.swift`**

Modify `VocabCraftApp/Features/Homepage/Views/CEFRDistributionCard.swift`:

```swift
import SwiftUI

public struct CEFRDistributionCard: View {
    public let a1a2Count: Int
    public let b1b2Count: Int
    public let c1c2Count: Int
    public var onDetailTap: (() -> Void)?

    public init(
        a1a2Count: Int = 450,
        b1b2Count: Int = 620,
        c1c2Count: Int = 350,
        onDetailTap: (() -> Void)? = nil
    ) {
        self.a1a2Count = a1a2Count
        self.b1b2Count = b1b2Count
        self.c1c2Count = c1c2Count
        self.onDetailTap = onDetailTap
    }

    private var totalCount: Int {
        max(a1a2Count + b1b2Count + c1c2Count, 1)
    }

    private var a1a2Ratio: CGFloat {
        CGFloat(a1a2Count) / CGFloat(totalCount)
    }

    private var b1b2Ratio: CGFloat {
        CGFloat(b1b2Count) / CGFloat(totalCount)
    }

    private var c1c2Ratio: CGFloat {
        CGFloat(c1c2Count) / CGFloat(totalCount)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with Detail link
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PHÂN BỔ TRÌNH ĐỘ CEFR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.vocabMuted)
                        .tracking(0.5)

                    Text("Tiến trình năng lực từ vựng")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                }

                Spacer()

                if let onDetailTap = onDetailTap {
                    Button(action: onDetailTap) {
                        HStack(spacing: 2) {
                            Text("Chi tiết")
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color.vocabCoral)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.vocabMuted)
                }
            }

            // Tri-color Segmented Progress Bar
            GeometryReader { geometry in
                let width = geometry.size.width
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.vocabMint)
                        .frame(width: max(width * a1a2Ratio - 2, 4))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.vocabPeach)
                        .frame(width: max(width * b1b2Ratio - 2, 4))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.vocabLavender)
                        .frame(width: max(width * c1c2Ratio - 2, 4))
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())

            // Legend / breakdown
            HStack(spacing: 12) {
                CEFRLegendItem(
                    title: "A1-A2",
                    count: a1a2Count,
                    color: Color.vocabMint
                )

                Spacer()

                CEFRLegendItem(
                    title: "B1-B2",
                    count: b1b2Count,
                    color: Color.vocabPeach
                )

                Spacer()

                CEFRLegendItem(
                    title: "C1-C2",
                    count: c1c2Count,
                    color: Color.vocabLavender
                )
            }
            .font(.system(size: 12))
        }
        .padding(18)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.vocabHeroTeal.opacity(0.04), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}

private struct CEFRLegendItem: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.vocabMuted)

            Text("\(count) từ")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.vocabInk)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter BentoCardsTests`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/CEFRDistributionCard.swift VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift
git commit -m "refactor(homepage): update CEFRDistributionCard styling and word count legend"
```

---

### Task 7: LiquidGlassTabBar Touch Target & Dark Mode Glass Overlay

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- Consumes: `LiquidGlassTabBar(selectedTab:)`
- Produces: Floating glass tab bar with min 48x48 pt hit targets per tab.

- [ ] **Step 1: Write test for LiquidGlassTabBar**

Modify `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class HomepageViewTests: XCTestCase {
    func testTabItemProperties() {
        XCTAssertEqual(TabItem.allCases.count, 4)
        XCTAssertEqual(TabItem.home.title, "Trang chủ")
        XCTAssertEqual(TabItem.vocabulary.title, "Từ vựng")
        XCTAssertEqual(TabItem.reflex.title, "Phản xạ")
        XCTAssertEqual(TabItem.settings.title, "Cài đặt")
    }
}
```

- [ ] **Step 2: Run test to verify baseline**

Run: `swift test --filter HomepageViewTests`  
Expected: PASS

- [ ] **Step 3: Refactor `LiquidGlassTabBar.swift`**

Modify `VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift`:

```swift
import SwiftUI

public enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case vocabulary = 1
    case reflex = 2
    case settings = 3

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .home: return "Trang chủ"
        case .vocabulary: return "Từ vựng"
        case .reflex: return "Phản xạ"
        case .settings: return "Cài đặt"
        }
    }

    public var symbol: String {
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

    public init(selectedTab: Binding<TabItem>) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        HStack {
            ForEach(TabItem.allCases) { tab in
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18))
                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .bold : .medium))
                    }
                    .foregroundColor(selectedTab == tab ? Color.vocabInk : Color.vocabMuted)
                    .padding(.vertical, 6)
                    .padding(.horizontal, selectedTab == tab ? 14 : 6)
                    .frame(minWidth: 48, minHeight: 48)
                    .background(selectedTab == tab ? Color.vocabInk.opacity(0.08) : Color.clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter HomepageViewTests`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift
git commit -m "refactor(homepage): update LiquidGlassTabBar touch targets and semantic color bindings"
```

---

### Task 8: HomepageView Integration & Full Suite Verification

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Test: All tests in `VocabCraftAppTests`

**Interfaces:**
- Consumes: All updated subcomponents
- Produces: Integrated HomepageView in Bento layout using `Color.vocabCanvas` background.

- [ ] **Step 1: Verify HomepageView structure and bindings**

Modify `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`:

```swift
import SwiftUI

public struct HomepageView: View {
    public let userName: String
    public let streakDays: Int
    public let dailyGoalProgress: Double
    public let dueCardsCount: Int
    public let totalWords: Int
    public let retentionPercentage: Double
    public let unreadNotifications: Bool

    @State private var searchText: String = ""
    @State private var selectedTab: TabItem = .home

    public init(
        userName: String = "Hooji N.",
        streakDays: Int = 14,
        dailyGoalProgress: Double = 0.75,
        dueCardsCount: Int = 24,
        totalWords: Int = 1420,
        retentionPercentage: Double = 0.85,
        unreadNotifications: Bool = true
    ) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyGoalProgress = dailyGoalProgress
        self.dueCardsCount = dueCardsCount
        self.totalWords = totalWords
        self.retentionPercentage = retentionPercentage
        self.unreadNotifications = unreadNotifications
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.vocabCanvas
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    HeaderView(
                        userName: userName,
                        streakDays: streakDays,
                        dailyGoalProgress: dailyGoalProgress,
                        unreadNotifications: unreadNotifications
                    )

                    MobileSearchView(
                        searchText: $searchText,
                        onVoiceSearchTapped: {}
                    )

                    SRSMemoryHeroCard(
                        totalWords: totalWords,
                        retentionPercentage: retentionPercentage
                    )

                    ActionCardsGrid(
                        dueCardsCount: dueCardsCount,
                        onReflexTap: {},
                        onQueueTap: {}
                    )

                    CEFRDistributionCard()

                    Spacer(minLength: 100)
                }
                .padding(.top)
            }

            LiquidGlassTabBar(selectedTab: $selectedTab)
        }
    }
}
```

- [ ] **Step 2: Run full test suite to verify 100% clean pass**

Run: `swift test`  
Expected: PASS (all tests passing with 0 failures)

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift
git commit -m "feat(homepage): complete Bento layout & Dark mode redesign for HomepageView"
```
