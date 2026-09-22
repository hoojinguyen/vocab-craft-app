# AI Assistant: Gemini API Key Configuration & Character Voice Playback (TTS) Spec

- **Date**: 2026-09-22
- **Topic**: Direct Gemini API Key Storage & Character Audio Playback
- **Status**: Approved Direction, Ready for Implementation Planning
- **Classification**: Feature Enhancement

---

## 1. Executive Summary & Problem Statement

### 1.1 Context
In the previous phase, the AI Assistant Scenario Roleplay subsystem was successfully implemented and deployed to the user's physical iPhone ("Hooji"). The roleplay engine communicates via `LLMProviderProtocol` (`MockLLMProvider` and `GeminiLLMProvider`).

### 1.2 Identified Needs
During physical device verification, two core gaps were identified:
1. **Gemini API Key Access on Physical Device**: `AppContainer.llmProvider` previously only resolved keys from `ProcessInfo.processInfo.environment["GEMINI_API_KEY"]`. On a physical iPhone running directly outside an attached Xcode scheme, environment variables are empty, causing the app to fall back to `MockLLMProvider`. The user has their own Google Gemini API Key and needs an in-app entry point to enter and persist it.
2. **Dialogue Voice & Audio Playback**: The user reported only seeing text responses. Character speech immersion requires vocalization through Apple Text-To-Speech (`TextToSpeechService` / `AVSpeechSynthesizer`), with auto-play on new character messages and interactive speaker replay buttons.

---

## 2. Goals & Non-Goals

### 2.1 Goals
- **In-App API Key Persistence**: Securely store `geminiApiKey` in `UserSettingsStore` (backed by `UserDefaults`).
- **Dynamic Provider Switching**: `AppContainer.llmProvider` dynamically uses `GeminiLLMProvider(apiKey:)` whenever `userSettingsStore.geminiApiKey` (or env var) is present, seamlessly switching from `MockLLMProvider` without app restart.
- **Dual UI Access**:
  - Main Settings tab: Dedicated "AI Configuration" card with secure entry, visibility toggle, and connection status badge.
  - AI Assistant Hub: Quick configuration sheet (`AIConfigSheet`) accessible via header button / status banner.
- **Character Audio Playback (TTS)**:
  - Inject `TextToSpeechProtocol` into `RoleplayRoomViewModel`.
  - Auto-play character dialogue when AI replies.
  - Interactive speaker icon button on all character messages to allow instant replay anytime.
- **Zero Hardcoded Strings & 100% Bilingual Parity**: All new user-facing strings declared in `VocabCraftApp/Resources/Localizable.xcstrings` for both English (`en`) and Vietnamese (`vi`).
- **Zero Warnings & Quality Gates**: 100% test pass rate, 0 SwiftLint violations, 0 Xcode build warnings.

### 2.2 Non-Goals
- Cloud secret sync across devices (local device storage is sufficient and privacy-safe).
- Real-time speech streaming / WebSocket audio (turn-based TTS is responsive and already supported).

---

## 3. Architecture & Data Flow

```
[User Input: Settings or AI Hub]
            │
            ▼
   [UserSettingsStore]
   (geminiApiKey persisted in UserDefaults)
            │
            ▼
    [AppContainer.llmProvider]
    (Evaluates key -> returns GeminiLLMProvider or MockLLMProvider)
            │
            ▼
[ExecuteRoleplayTurnUseCase] ────► [Google Gemini 1.5 Flash API]
            │
            ▼
  [RoleplayRoomViewModel] ───────► [TextToSpeechService / AVSpeechSynthesizer]
            │                                    │
            ▼                                    ▼
   [RoleplayRoomView] ───────────────► Audio Output (iPhone Speaker)
   (Dialogue bubble + Speaker button)
```

---

## 4. UI/UX Specifications

### 4.1 Settings: AI Configuration Section
- Section Header: `AppStrings.Settings.sectionAI` ("AI Configuration" / "Cấu hình AI")
- Card with:
  - Connection status row: Shows "Active (Gemini 1.5 Flash)" or "Mock Mode (Demo)" with color-coded `CraftBadge`.
  - Secure input row: Secure/regular `TextField` with `CraftSymbol.eye` / `CraftSymbol.eyeSlash` toggle.
  - Clear button if key is populated.
  - Subtle help text with guidance on acquiring a Gemini API key.

### 4.2 AI Assistant Hub: Quick Key Banner / Header Access
- When API Key is not yet entered, show a subtle banner or header gear button prompting setup.
- Tapping presents `AIConfigSheet` enabling quick key paste, verification, and save without leaving the AI Hub.

### 4.3 Roleplay Room: Audio Playback
- AI message bubbles include a `CraftIconButton(symbol: .audio, size: .sm, variant: .subtle)` icon button.
- Tapping triggers `viewModel.playSpeech(for: message.text)`.
- When an AI message arrives, the character's line is automatically spoken via `ttsService.speak(text: reply)`.
