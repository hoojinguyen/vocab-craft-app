# Gemini API Key Configuration & Character Voice Playback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide in-app Gemini API Key storage in Settings and AI Hub, dynamic provider switching, and interactive/auto-play Text-To-Speech character dialogue in the Roleplay Room.

**Architecture:** Extend `UserSettingsStore` with `geminiApiKey` persisted in `UserDefaults`. Make `AppContainer.llmProvider` a dynamic computed property resolving `GeminiLLMProvider` when a key exists, else `MockLLMProvider`. Inject `TextToSpeechProtocol` into `RoleplayRoomViewModel` for auto-vocalizing character replies and replaying via a speaker icon button on `RoleplayRoomView`. Provide UI configuration via `SettingsAICard` in `SettingsView` and `AIConfigSheet` in `AIAssistantHubView`.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, AVFoundation (AVSpeechSynthesizer via `TextToSpeechService`), CraftUIKit design system tokens, Swift Testing (`@Suite`, `@Test`).

**Spec:** [docs/superpowers/specs/2026-09-22-gemini-api-key-and-tts-playback.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-09-22-gemini-api-key-and-tts-playback.md)

## Global Constraints

- Swift 6 strict concurrency (`Sendable` conformance, `@MainActor` on UI/ViewModels).
- CraftUIKit-First: Use `CraftCard`, `CraftIconButton`, `CraftBadge`, `CraftButton`, `theme.colors.*`, `theme.spacing.*`, `theme.typography.*`. Zero raw hardcoded colors or padding.
- Zero Hardcoded Strings: 100% bilingual parity (English and Vietnamese) in `Localizable.xcstrings`.
- Quality Gate: 0 SwiftLint warnings, 0 compiler warnings, 100% test pass rate.
- Physical device deployment target: iPhone 16 Pro ("Hooji", UDID: `00008140-0009646C0AC0801C`).

---

### Task 1: UserSettingsStore & Dynamic LLMProvider in AppContainer

**Files:**
- Modify: `VocabCraftApp/Core/Database/UserSettingsStore.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Test: `VocabCraftAppTests/App/AppContainerAITests.swift`

**Interfaces:**
- Consumes: `UserDefaults`, `LLMProviderProtocol`, `GeminiLLMProvider`, `MockLLMProvider`.
- Produces: `UserSettingsStore.geminiApiKey: String`, dynamic `AppContainer.llmProvider: LLMProviderProtocol`.

- [ ] **Step 1: Write failing unit test in AppContainerAITests.swift**
```swift
@Test @MainActor
func testDynamicLLMProviderSwitchingWithApiKey() {
    let defaults = UserDefaults(suiteName: "test_dynamic_llm_\(UUID().uuidString)") ?? .standard
    let store = UserSettingsStore(defaults: defaults)
    let container = AppContainer(userSettingsStore: store)
    
    // Initially empty key -> MockLLMProvider
    #expect(container.llmProvider is MockLLMProvider)
    
    // Set API Key -> GeminiLLMProvider
    store.geminiApiKey = "AIzaSyFakeTestKey12345"
    #expect(container.llmProvider is GeminiLLMProvider)
    
    // Clear API Key -> MockLLMProvider
    store.geminiApiKey = ""
    #expect(container.llmProvider is MockLLMProvider)
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `swift test --filter AppContainerAITests/testDynamicLLMProviderSwitchingWithApiKey`
Expected: FAIL (compilation error: `geminiApiKey` not found on `UserSettingsStore`).

- [ ] **Step 3: Implement minimal code in UserSettingsStore.swift & AppContainer.swift**
In `UserSettingsStore.swift`:
```swift
public var geminiApiKey: String {
    didSet {
        defaults.set(geminiApiKey, forKey: "gemini_api_key")
    }
}
```
Initialize in `init`:
```swift
self.geminiApiKey = defaults.string(forKey: "gemini_api_key") ?? ""
```

In `AppContainer.swift`:
Change `public lazy var llmProvider: LLMProviderProtocol` to:
```swift
public var llmProvider: LLMProviderProtocol {
    let key = userSettingsStore.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    if !key.isEmpty {
        return GeminiLLMProvider(apiKey: key)
    }
    if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
       !envKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return GeminiLLMProvider(apiKey: envKey)
    }
    return MockLLMProvider()
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `swift test --filter AppContainerAITests`
Expected: PASS.

- [ ] **Step 5: Commit changes**
```bash
git add VocabCraftApp/Core/Database/UserSettingsStore.swift VocabCraftApp/App/DI/AppContainer.swift VocabCraftAppTests/App/AppContainerAITests.swift
git commit -m "feat(ai): add in-app gemini api key persistence and dynamic llm provider resolution"
```

---

### Task 2: TTS Integration in RoleplayRoomViewModel & RoleplayRoomView

**Files:**
- Modify: `VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayRoomViewModel.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/RoleplayRoomView.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`

**Interfaces:**
- Consumes: `TextToSpeechProtocol`, `RoleplayScenario`, `DisplayChatMessage`.
- Produces: `RoleplayRoomViewModel.playSpeech(for:)`, auto-play on AI reply, speaker replay button in `RoleplayRoomView`.

- [ ] **Step 1: Write failing test in AIAssistantViewsTests.swift**
```swift
@Test @MainActor
func testRoleplayRoomViewModelSpeechPlayback() async {
    let scenario = makeSampleScenario()
    let mockTTS = MockTextToSpeechService()
    let vm = RoleplayRoomViewModel(
        scenario: scenario,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase(llmProvider: MockLLMProvider()),
        completeSessionUseCase: CompleteRoleplaySessionUseCase(),
        ttsService: mockTTS
    )
    
    vm.playSpeech(for: "Welcome to the coffee shop!")
    #expect(mockTTS.isSpeaking == true)
    
    mockTTS.stop()
    await vm.sendMessage("Hello!")
    // Verify auto-play triggered for character reply
    #expect(mockTTS.isSpeaking == true)
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `swift test --filter AIAssistantViewsTests/testRoleplayRoomViewModelSpeechPlayback`
Expected: FAIL (compilation error or method missing).

- [ ] **Step 3: Implement minimal code**
In `RoleplayRoomViewModel.swift`:
Add `private let ttsService: (any TextToSpeechProtocol)?` to properties and initializer.
Add:
```swift
public func playSpeech(for text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    ttsService?.speak(text: trimmed)
}
```
Inside `sendMessage(_ text: String)`:
After appending `aiMsg`, call:
```swift
playSpeech(for: output.characterReply)
```

In `AppContainer.swift`:
Update `makeRoleplayRoomViewModel`:
```swift
@MainActor
public func makeRoleplayRoomViewModel(for scenario: RoleplayScenario) -> RoleplayRoomViewModel {
    RoleplayRoomViewModel(
        scenario: scenario,
        executeTurnUseCase: makeExecuteRoleplayTurnUseCase(),
        completeSessionUseCase: makeCompleteRoleplaySessionUseCase(),
        ttsService: ttsService
    )
}
```

In `RoleplayRoomView.swift`:
In `messageRow(_ message: DisplayChatMessage)`:
For `!message.isUser`, add a speaker `CraftIconButton`:
```swift
if !message.isUser {
    CraftIconButton(
        symbol: .audio,
        size: .sm,
        variant: .subtle,
        accessibilityLabelKey: AppStrings.AIAssistant.audioPlayButton
    ) {
        viewModel.playSpeech(for: message.text)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `swift test --filter AIAssistantViewsTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**
```bash
git add VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayRoomViewModel.swift VocabCraftApp/Features/AIAssistant/Views/RoleplayRoomView.swift VocabCraftApp/App/DI/AppContainer.swift VocabCraftAppTests/AI/AIAssistantViewsTests.swift
git commit -m "feat(ai): integrate text-to-speech dialogue playback in roleplay room"
```

---

### Task 3: Localization Strings for AI Configuration & Audio Controls

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift`

**Interfaces:**
- Consumes: `Localizable.xcstrings`.
- Produces: `AppStrings.Settings.sectionAI`, `AppStrings.Settings.aiGeminiKeyTitle`, `AppStrings.Settings.aiGeminiStatusConnected`, `AppStrings.AIAssistant.audioPlayButton`, `AppStrings.AIAssistant.apiKeySheetTitle`, etc.

- [ ] **Step 1: Write failing test in AIAssistantLocalizationTests.swift**
```swift
@Test
func testNewAIConfigurationAndAudioStringsExistInCatalog() throws {
    guard let catalogUrl = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings") else {
        Issue.record("Localizable.xcstrings not found in module bundle")
        return
    }
    let data = try Data(contentsOf: catalogUrl)
    let json = try JSONDecoder().decode(StringCatalogDTO.self, from: data)
    
    let requiredKeys = [
        "app.settings.section.ai",
        "app.settings.ai.gemini_key_title",
        "app.settings.ai.gemini_key_placeholder",
        "app.settings.ai.gemini_status_connected",
        "app.settings.ai.gemini_status_mock",
        "app.settings.ai.gemini_active",
        "app.settings.ai.gemini_mock",
        "app.settings.ai.gemini_help_text",
        "app.settings.ai.show_key",
        "app.settings.ai.hide_key",
        "app.settings.ai.clear_key",
        "app.ai_assistant.room.play_audio",
        "app.ai_assistant.hub.configure_api_key",
        "app.ai_assistant.hub.api_key_sheet_title",
        "app.ai_assistant.hub.api_key_banner_desc"
    ]
    
    for key in requiredKeys {
        #expect(json.strings[key] != nil, "Missing key: \(key)")
        #expect(json.strings[key]?.localizations["en"] != nil, "Missing 'en' for \(key)")
        #expect(json.strings[key]?.localizations["vi"] != nil, "Missing 'vi' for \(key)")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `swift test --filter AIAssistantLocalizationTests/testNewAIConfigurationAndAudioStringsExistInCatalog`
Expected: FAIL (keys not found in catalog).

- [ ] **Step 3: Implement minimal code**
Update `Localizable.xcstrings` with both `en` and `vi` translations.
Update `AppStrings.swift` with static accessors.

- [ ] **Step 4: Run test to verify it passes**
Run: `swift test --filter AIAssistantLocalizationTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**
```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift
git commit -m "feat(ai): add bilingual localization for ai configuration and audio controls"
```

---

### Task 4: In-App UI Configuration (Settings Card & AI Hub Sheet)

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/Views/AIConfigSheet.swift`
- Modify: `VocabCraftApp/Features/Settings/Views/SettingsView.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`
- Test: `VocabCraftAppTests/AI/AIAssistantViewsTests.swift`

**Interfaces:**
- Consumes: `UserSettingsStore`, `CraftCard`, `CraftIconButton`, `CraftBadge`, `CraftButton`, `AppStrings`.
- Produces: `AIConfigSheet`, `SettingsAICard`, quick configuration modal in `AIAssistantHubView`.

- [ ] **Step 1: Write failing test in AIAssistantViewsTests.swift**
```swift
@Test @MainActor
func testAIConfigSheetRendersAndSavesKey() {
    let defaults = UserDefaults(suiteName: "test_ai_config_sheet_\(UUID().uuidString)") ?? .standard
    let store = UserSettingsStore(defaults: defaults)
    var dismissed = false
    let sheet = AIConfigSheet(store: store) {
        dismissed = true
    }
    _ = sheet.body
    
    sheet.onDismiss()
    #expect(dismissed)
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `swift test --filter AIAssistantViewsTests/testAIConfigSheetRendersAndSavesKey`
Expected: FAIL (`AIConfigSheet` does not exist).

- [ ] **Step 3: Implement minimal code**
1. Create `VocabCraftApp/Features/AIAssistant/Views/AIConfigSheet.swift`.
2. Add `SettingsAICard` to `SettingsView.swift` inside `aiSection`.
3. Add configuration banner / header button to `AIAssistantHubView.swift` presenting `AIConfigSheet`.
4. Add `AIConfigSheet.swift` to `VocabCraftApp.xcodeproj/project.pbxproj`.

- [ ] **Step 4: Run test to verify it passes**
Run: `swift test --filter AIAssistantViewsTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**
```bash
git add VocabCraftApp/Features/AIAssistant/Views/AIConfigSheet.swift VocabCraftApp/Features/Settings/Views/SettingsView.swift VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift VocabCraftApp.xcodeproj/project.pbxproj VocabCraftAppTests/AI/AIAssistantViewsTests.swift
git commit -m "feat(ai): implement in-app ai configuration sheet and settings card"
```

---

### Task 5: Full Verification, Xcode Device Build & Deployment

**Files:**
- None (Build & Deployment phase).

**Interfaces:**
- Physical device deployment to `00008140-0009646C0AC0801C` ("Hooji").

- [ ] **Step 1: Run full test suite and swiftlint**
Run: `swift test`
Run: `swiftlint`
Expected: All tests pass, 0 lint warnings/errors.

- [ ] **Step 2: Build VocabCraftApp for physical device**
Run: `xcodebuild -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination "id=00008140-0009646C0AC0801C" build`
Expected: BUILD SUCCEEDED with 0 errors and 0 warnings.

- [ ] **Step 3: Install & Launch on physical device**
Run: `xcrun devicectl device install app --device 00008140-0009646C0AC0801C /Users/hoojinguyen/Library/Developer/Xcode/DerivedData/VocabCraft-bsajuyoloryhtkdmtxovtgwjhfeg/Build/Products/Debug-iphoneos/VocabCraftApp.app`
Run: `xcrun devicectl device process launch --device 00008140-0009646C0AC0801C com.hoojinguyen.vocabcraft`
Expected: Process launched successfully on "Hooji".

- [ ] **Step 4: Update walkthrough artifact and notify user**
Document verification results and guide user to test entering their Gemini API key and hearing TTS dialogue.
