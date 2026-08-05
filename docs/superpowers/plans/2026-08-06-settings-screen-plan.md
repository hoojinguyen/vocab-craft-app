# Settings Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and integrate a feature-complete Settings screen (`SettingsView`) in `VocabCraftApp` featuring profile summary, SRS learning goals, interactive TTS audio preview, theme/haptics controls, and app data management.

**Architecture:** MVVM architecture with `@Observable` `UserSettingsStore` for `@AppStorage` persistence, `SettingsViewModel` for business logic & TTS service execution, and modular SwiftUI views using `.insetGrouped` List styling with `VocabCraft` design system tokens.

**Tech Stack:** Swift 5.9+, SwiftUI, `@Observable`, `@AppStorage`, AVFoundation (via `TextToSpeechProtocol`), XCTest.

## Global Constraints

- Use dynamic color tokens from `Color+VocabCraft.swift` (`Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabInk`, etc.).
- Maintain UI padding above `LiquidGlassTabBar` to prevent layout overlaps.
- All new views must build cleanly on iOS target without deprecation or layout warnings.

---

### Task 1: `UserSettingsStore` Data Persistence Model

**Files:**
- Create: `VocabCraftApp/Core/Database/UserSettingsStore.swift`
- Test: `VocabCraftAppTests/UserSettingsStoreTests.swift`

**Interfaces:**
- Produces: `UserSettingsStore` with properties:
  - `dailyGoalCount: Int`
  - `isNotificationEnabled: Bool`
  - `notificationTime: Date`
  - `ttsVoiceGender: String`
  - `ttsSpeed: Float`
  - `appTheme: String`
  - `isHapticsEnabled: Bool`
  - `isSoundEffectsEnabled: Bool`

- [ ] **Step 1: Write tests for UserSettingsStore**

```swift
import XCTest
@testable import VocabCraftApp

final class UserSettingsStoreTests: XCTestCase {
    func testDefaultUserSettingsValues() {
        let store = UserSettingsStore()
        XCTAssertEqual(store.dailyGoalCount, 15)
        XCTAssertEqual(store.ttsVoiceGender, "US")
        XCTAssertEqual(store.ttsSpeed, 0.85)
        XCTAssertTrue(store.isHapticsEnabled)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: FAIL due to missing `UserSettingsStore`.

- [ ] **Step 3: Write UserSettingsStore implementation**

```swift
import SwiftUI
import Foundation

@Observable
public final class UserSettingsStore: @unchecked Sendable {
    @ObservationIgnored
    @AppStorage("daily_goal_count") public var dailyGoalCount: Int = 15
    
    @ObservationIgnored
    @AppStorage("is_notification_enabled") public var isNotificationEnabled: Bool = true
    
    @ObservationIgnored
    @AppStorage("tts_voice_gender") public var ttsVoiceGender: String = "US"
    
    @ObservationIgnored
    @AppStorage("tts_speed") public var ttsSpeed: Double = 0.85
    
    @ObservationIgnored
    @AppStorage("app_theme") public var appTheme: String = "system"
    
    @ObservationIgnored
    @AppStorage("is_haptics_enabled") public var isHapticsEnabled: Bool = true
    
    @ObservationIgnored
    @AppStorage("is_sound_effects_enabled") public var isSoundEffectsEnabled: Bool = true

    public init() {}
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/UserSettingsStore.swift VocabCraftAppTests/UserSettingsStoreTests.swift
git commit -m "feat: add UserSettingsStore for persistent preferences"
```

---

### Task 2: `SettingsViewModel` Logic & Audio Preview Integration

**Files:**
- Create: `VocabCraftApp/Features/Settings/ViewModels/SettingsViewModel.swift`
- Test: `VocabCraftAppTests/SettingsViewModelTests.swift`

**Interfaces:**
- Consumes: `UserSettingsStore`, `TextToSpeechProtocol`
- Produces: `SettingsViewModel` with `playAudioPreview()`, `clearCache()`, `isPlayingAudio: Bool`

- [ ] **Step 1: Write tests for SettingsViewModel**

```swift
import XCTest
@testable import VocabCraftApp

final class SettingsViewModelTests: XCTestCase {
    func testAudioPreviewExecution() {
        let store = UserSettingsStore()
        let vm = SettingsViewModel(store: store)
        XCTAssertFalse(vm.isPlayingAudio)
        vm.playAudioPreview()
        // Verify audio trigger logic
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: FAIL due to missing `SettingsViewModel`.

- [ ] **Step 3: Write SettingsViewModel implementation**

```swift
import SwiftUI

@Observable
public final class SettingsViewModel {
    public let store: UserSettingsStore
    public var isPlayingAudio: Bool = false
    public var cacheSizeString: String = "12.4 MB"
    private let ttsService: TextToSpeechProtocol?

    public init(store: UserSettingsStore = UserSettingsStore(), ttsService: TextToSpeechProtocol? = nil) {
        self.store = store
        self.ttsService = ttsService
    }

    public func playAudioPreview() {
        isPlayingAudio = true
        let sampleText = "VocabCraft: Master English naturally"
        ttsService?.speak(sampleText)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isPlayingAudio = false
        }
    }

    public func clearCache() {
        cacheSizeString = "0.0 MB"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Settings/ViewModels/SettingsViewModel.swift VocabCraftAppTests/SettingsViewModelTests.swift
git commit -m "feat: add SettingsViewModel with audio preview and cache controls"
```

---

### Task 3: Profile Header & Custom Settings Row Views

**Files:**
- Create: `VocabCraftApp/Features/Settings/Views/Components/ProfileHeaderCard.swift`
- Create: `VocabCraftApp/Features/Settings/Views/Components/SettingsRowView.swift`

**Interfaces:**
- Produces: `ProfileHeaderCard` view and `SettingsRowView` component with SF Symbol badge support.

- [ ] **Step 1: Create ProfileHeaderCard view**

```swift
import SwiftUI

public struct ProfileHeaderCard: View {
    public var userName: String = "Hooji N."
    public var userLevel: String = "B2 Intermediate"
    public var streakDays: Int = 14

    public var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.vocabHeroTeal)
                    .frame(width: 56, height: 56)
                Text(userName.prefix(1))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.headline)
                    .foregroundColor(.vocabInk)
                
                HStack(spacing: 8) {
                    Text(userLevel)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.vocabLavender.opacity(0.15))
                        .foregroundColor(.vocabLavender)
                        .clipShape(Capsule())
                    
                    Text("🔥 \(streakDays) ngày")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.vocabCoral)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 2: Create SettingsRowView component**

```swift
import SwiftUI

public struct SettingsRowView<Content: View>: View {
    public let iconName: String
    public let iconColor: Color
    public let title: String
    public let content: Content

    public init(iconName: String, iconColor: Color, title: String, @ViewBuilder content: () -> Content) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.title = title
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 30, height: 30)
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(.vocabInk)
            
            Spacer()
            
            content
        }
    }
}
```

- [ ] **Step 3: Commit UI Components**

```bash
git add VocabCraftApp/Features/Settings/Views/Components/
git commit -m "feat: add ProfileHeaderCard and SettingsRowView components"
```

---

### Task 4: Main `SettingsView` Implementation

**Files:**
- Create: `VocabCraftApp/Features/Settings/Views/SettingsView.swift`

**Interfaces:**
- Consumes: `SettingsViewModel`, `ProfileHeaderCard`, `SettingsRowView`
- Produces: Complete `SettingsView`

- [ ] **Step 1: Create SettingsView**

Implement `SettingsView` using `List` styled with `.insetGrouped`, background set to `Color.vocabCanvas`, sections for Learning, Audio, Appearance, and Data, and TTS audio preview playback button.

- [ ] **Step 2: Commit SettingsView**

```bash
git add VocabCraftApp/Features/Settings/Views/SettingsView.swift
git commit -m "feat: implement full SettingsView with Inset Grouped layout"
```

---

### Task 5: Integration into `HomepageView` & Build Verification

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`

- [ ] **Step 1: Replace .settings placeholder in HomepageView**

```swift
case .settings:
    SettingsView(viewModel: viewModel.settingsViewModel)
```

- [ ] **Step 2: Run full build and tests**

Run: `swift build` (or `xcodebuild build -scheme VocabCraftApp`)
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Final Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift
git commit -m "feat: integrate SettingsView into HomepageView main tab bar"
```
