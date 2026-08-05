# Ultra-Clean Header Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `HeaderView.swift` to implement the Ultra-Clean layout — removing the avatar & duplicate progress ring, expanding the greeting title font, and simplifying the streak capsule badge to icon + number (`🔥 14`).

**Architecture:** Update `VocabCraftApp/Features/Homepage/Views/HeaderView.swift` and `VocabCraftAppTests/Features/Homepage/HeaderViewTests.swift`.

**Tech Stack:** Swift, SwiftUI, XCTest

## Global Constraints

- Touch target: Notification bell button minimum 44x44 pt
- Streak badge text: Icon `flame.fill` + Number `\(streakDays)` (13pt Bold)
- Greeting title: `"Chào \(userName) 👋"` (20pt Bold, `vocabInk`)
- Subtitle: `"Mục tiêu hôm nay: \(Int(dailyGoalProgress * 100))%"` (13pt Medium, `vocabMuted`)

---

### Task 1: Refactor HeaderView to Ultra-Clean Layout

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HeaderView.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/HeaderViewTests.swift`

**Interfaces:**
- Consumes: `HeaderView(userName:streakDays:dailyGoalProgress:unreadNotifications:)`
- Produces: Ultra-clean header without avatar, with simplified `🔥 14` streak badge.

- [ ] **Step 1: Update unit tests for Ultra-Clean HeaderView**

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

- [ ] **Step 2: Run test baseline**

Run: `swift test --filter HeaderViewTests`  
Expected: PASS

- [ ] **Step 3: Update `HeaderView.swift` implementation**

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
            // Greeting & Goal Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text("Chào \(userName) 👋")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                
                Text("Mục tiêu hôm nay: \(Int(dailyGoalProgress * 100))%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }

            Spacer()

            // Minimalist Streak Badge (Icon + Number)
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.vocabCoral)
                Text("\(streakDays)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.vocabCoral)
            }
            .padding(.horizontal, 12)
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

- [ ] **Step 4: Run test suite to verify full pass**

Run: `swift test`  
Expected: PASS (0 failures)

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HeaderView.swift VocabCraftAppTests/Features/Homepage/HeaderViewTests.swift
git commit -m "refactor(homepage): update HeaderView to Ultra-Clean layout (remove avatar, simplify streak to 🔥 14)"
```
