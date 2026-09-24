# AI Voice Roleplay: Immersive Hands-Free Conversational Call Design Specification

- **Date**: 2026-09-25
- **Topic**: AI Voice Roleplay Mode with Full-Screen Call UI & Intelligent Offline Simulation
- **Status**: Approved by User, Ready for Implementation Planning
- **Classification**: Architectural

---

## 1. Executive Summary & Problem Statement

### 1.1 Context
In the previous iterations, VocabCraft introduced the AI Assistant Scenario Roleplay subsystem (`AIAssistantHubView`, `RoleplayRoomView`, `ExecuteRoleplayTurnUseCase`, `GeminiLLMProvider`, and `MockLLMProvider`), supported by in-app API key configuration and character text-to-speech audio playback. 

### 1.2 The Problem
1. **Passive vs. Active Production Gap**: Text chatting on a keyboard does not adequately activate real-time spoken fluency or reflex. Language learners need to listen to natural pacing, produce spoken sentences, and overcome hesitation in a realistic conversational environment.
2. **API Key Dependency Blocker**: Users frequently do not have a Gemini API key ready during development, initial download, or offline usage. The previous `MockLLMProvider` returned a single static sentence ("That sounds wonderful! Let me assist you with that."), preventing meaningful physical device testing or offline practice.

### 1.3 The Solution
Implement **AI Voice Roleplay Call Mode (`RoleplayVoiceCallView`)**:
- An immersive, full-screen audio call interface featuring an animated **Voice Orb (`CraftVoiceOrbView`)** that transforms across Speaking, Listening, and Thinking states.
- **Hands-Free Turn-Taking**: Seamless audio pipeline coordinating Apple Text-to-Speech playback, microphone capture via `SpeechRecognitionService`, and silence detection (`SilenceDetector`) with a ~1.5-second pause threshold.
- **Real-Time Pedagogical HUD**: Live target word chips pinned at the top that animate and trigger tactile haptics (`CraftHapticFeedback.success()`) when pronounced correctly in speech, paired with toggleable live subtitles.
- **Intelligent Offline Scenario Simulation Engine (`IntelligentMockLLMProvider`)**: A multi-turn, contextual branching offline dialogue engine for catalog scenarios (e.g. Cafe, Job Interview, Hotel Check-in). It matches target words and produces dynamic, context-aware responses with refinements, enabling 100% full testing and practice on physical devices without an API key.
- **Seamless Provider Switching**: When a Gemini API key is configured, the system automatically transitions to Google Gemini 1.5 Flash for unconstrained generative conversations.

---

## 2. Goals & Non-Goals

### 2.1 Goals
- **Full-Screen Voice Call Mode**: Build `RoleplayVoiceCallView` adhering to `CraftUIKit` design tokens, featuring dark canvas depth, animated Voice Orb, and tactile controls.
- **Robust Audio Session Coordination**: Safely orchestrate playback (TTS) and recording (STT) without hardware audio session collisions using `AudioSessionCoordinator`.
- **Hands-Free & Tap-to-Finish Turn-Taking**: Automatic turn-taking via `SilenceDetector` plus an explicit manual tap action for noisy environments.
- **Intelligent Offline Simulation**: Rich multi-turn conversational simulation capable of target-word extraction, contextual replies, and sentence refinements when no API key is set.
- **Live Guidance & Subtitles**: Interactive target word chips with tactile spring animations and optional live subtitle display.
- **SRS & Progress Integration**: Automatically update word mastery levels in `UserProgressRepository` and grant XP upon call completion.
- **Zero Hardcoded Strings & Quality Gates**: 100% bilingual parity (EN/VI) in `Localizable.xcstrings`, zero SwiftLint warnings, zero compiler warnings.

### 2.2 Non-Goals
- Real-time bidirectional WebSocket streaming via Gemini Live (deferred to a future phase; clean seam protocol is established).
- Video calling or video avatar rendering.
- User-generated scenario scripting in the UI (prioritizing catalog scenarios + dynamic SRS generation).

---

## 3. Architecture & Audio State Machine

```
┌─────────────────────────────────────────────────────────────┐
│                 AIAssistant Feature Layer                   │
│   AIAssistantHubView ──► RoleplayVoiceCallView (Full-Screen)│
│                 RoleplayVoiceCallViewModel                  │
└──────────────────────────────┬──────────────────────────────┘
                               │ uses
┌──────────────────────────────▼──────────────────────────────┐
│           VoiceConversationEngineProtocol (Domain)          │
│               TurnBasedVoiceConversationEngine              │
└──────────────┬───────────────────────────────┬──────────────┘
               │                               │
       Audio Coordination              LLM Provider
               │                               │
┌──────────────▼──────────────┐ ┌──────────────▼──────────────┐
│   AudioSessionCoordinator   │ │     LLMProviderProtocol     │
│  ├── TextToSpeechService    │ │  ├── GeminiLLMProvider      │
│  └── SpeechRecognition      │ │  └── IntelligentMockLLM     │
│      Service + SilenceDetector│                               │
└─────────────────────────────┘ └─────────────────────────────┘
```

### 3.1 Finite State Machine

```
           ┌───────────────────────────────────────────────┐
           │                     IDLE                      │
           │           (Scenario loaded, ready)            │
           └───────────────────────┬───────────────────────┘
                                   │ startCall()
                                   ▼
          ┌─────────────────────────────────────────────────┐
          │                    SPEAKING                     │
     ┌───►│  • AI speaks via TextToSpeechService            │◄────┐
     │    │  • Voice Orb pulses with wave oscillation       │     │
     │    └────────────────────────┬────────────────────────┘     │
     │                             │ didFinishSpeaking
     │                             ▼                              │
     │    ┌─────────────────────────────────────────────────┐     │
     │    │                   LISTENING                     │     │
     │    │  • Mic active via SpeechRecognitionService      │     │
     │    │  • Voice Orb reacts to mic metering amplitude   │     │
     │    │  • SilenceDetector monitors 1.5s pause          │     │
     │    └────────────────────────┬────────────────────────┘     │
     │                             │ Silence >= 1.5s OR Tap Finish│
     │                             ▼                              │
     │    ┌─────────────────────────────────────────────────┐     │
     │    │                   THINKING                      │     │
     │    │  • Mic closed, input dispatched to LLM          │     │
     │    │  • Voice Orb performs breathing rotation        │     │
     │    │  • Target words matched & haptic triggered      │     │
     │    └────────────────────────┬────────────────────────┘     │
     │                             │ LLM output received          │
     └─────────────────────────────┴──────────────────────────────┘
                                   │
                              User taps End Call
                                   ▼
          ┌─────────────────────────────────────────────────┐
          │                     ENDED                       │
          │  • Release Audio Session Leases                 │
          │  • Dispatch CompleteRoleplaySessionUseCase      │
          │  • Transition to RoleplaySummaryView            │
          └─────────────────────────────────────────────────┘
```

### 3.2 State Definition

```swift
public enum VoiceCallState: Equatable, Sendable {
    case idle
    case speaking(characterText: String)
    case listening(liveTranscript: String)
    case thinking
    case ended
}
```

---

## 4. Component Design & Protocols

### 4.1 Voice Conversation Engine Protocol
Located in `VocabCraftApp/Domain/Protocols/VoiceConversationEngineProtocol.swift`:

```swift
@MainActor
public protocol VoiceConversationEngineProtocol: AnyObject {
    var state: VoiceCallState { get }
    var isMuted: Bool { get }
    var isSubtitlesVisible: Bool { get }
    var masteredTargetWords: Set<String> { get }
    var messages: [RoleplayMessage] { get }
    
    func startCall() async
    func finishUserTurnManually()
    func toggleMute()
    func toggleSubtitles()
    func endCall() async -> RoleplaySessionSummary
}
```

### 4.2 Voice Orb Component (`CraftVoiceOrbView`)
Located in `VocabCraftApp/Features/AIAssistant/Views/Components/CraftVoiceOrbView.swift`:
- Multi-layer circular visualizer with layered radial gradients, outer glow, and blur effects.
- Dynamic spring animation reacting to `VoiceCallState`:
  - **Speaking**: Harmonic radial pulsing scaling between 1.0 and 1.2 at 2Hz.
  - **Listening**: Real-time soundwave ripple reacting to audio input levels with dynamic ring expansions.
  - **Thinking**: Continuous breathing luminescence with subtle rotation.

### 4.3 Intelligent Scenario Simulation Engine (`IntelligentMockLLMProvider`)
Located in `VocabCraftApp/Data/AI/IntelligentMockLLMProvider.swift`:
- Conforms to `LLMProviderProtocol`.
- Inspects `messages.last?.content` and compares against scenario keywords and target words.
- Maintains dialogue turn counts and context branching:
  - **Cafe Order Scenario**: Greeting ➔ Size/Drink preference ➔ Pastry accompaniment ➔ Bill calculation & farewell.
  - **Job Interview Scenario**: Welcome ➔ Background & role fit ➔ Teamwork / challenge handling ➔ Wrap-up & next steps.
  - **Hotel Check-in Scenario**: Greeting ➔ Reservation lookup ➔ Room preferences & key handover ➔ Amenities & checkout info.
- Extracts any target words used by the user, returns structured `RoleplayTurnOutput` with realistic sentence refinements and pedagogical tips.
- Falls back to generic adaptive English conversational responses if free-form speech occurs outside scenario branches.

### 4.4 Voice Call View (`RoleplayVoiceCallView`)
Located in `VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift`:
- **Top HUD**:
  - Close / End call button (`CraftIconButton(symbol: .close)`).
  - Scenario title & character title.
  - Horizontal `ScrollView` of target words using `CraftBadge`. When a target word is mastered, transitions to `.success` tone with spring animation and tactile haptic feedback.
- **Center Stage**:
  - Large character avatar badge and `CraftVoiceOrbView`.
  - State indicator caption ("Listening...", "Speaking...", "Thinking...").
- **Bottom Stage**:
  - Live subtitles card: semi-transparent glass container showing character speech or user transcript.
  - Control bar:
    - Subtitle toggle button.
    - Large circular End Call button (`variant: .danger` / red circle).
    - Mic mute toggle button.
    - Tap-to-finish button when speaking.

---

## 5. Bilingual Localization Taxonomy

Declared in `VocabCraftApp/Resources/Localizable.xcstrings`:

| Key | English (`en`) | Vietnamese (`vi`) |
| :--- | :--- | :--- |
| `app.ai.call.start` | Start Voice Call | Bắt đầu gọi thoại |
| `app.ai.call.end` | End Call | Kết thúc cuộc gọi |
| `app.ai.call.state.speaking` | Character is speaking... | Nhân vật đang nói... |
| `app.ai.call.state.listening` | Listening to you... | Đang lắng nghe bạn... |
| `app.ai.call.state.thinking` | Thinking... | Đang suy nghĩ... |
| `app.ai.call.action.finish_turn` | Tap when finished speaking | Chạm khi nói xong |
| `app.ai.call.action.mute` | Mute microphone | Tắt tiếng micro |
| `app.ai.call.action.unmute` | Unmute microphone | Bật micro |
| `app.ai.call.action.toggle_captions` | Toggle subtitles | Bật/tắt phụ đề |
| `app.ai.call.target_words` | Target Words | Từ vựng mục tiêu |
| `app.ai.call.mic_permission_title` | Microphone Access Required | Cần quyền truy cập Micro |
| `app.ai.call.mic_permission_message` | Please allow microphone access in iOS Settings to practice speaking with AI. | Vui lòng cho phép quyền Micro trong Cài đặt iOS để luyện nói cùng AI. |

---

## 6. Verification Plan

### 6.1 Automated Unit Tests
Run the automated test suite targeting AI roleplay and audio coordination:
```bash
xcodebuild test -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" -only-testing:VocabCraftAppTests/VoiceRoleplayEngineTests -only-testing:VocabCraftAppTests/IntelligentMockLLMProviderTests
```

### 6.2 SwiftLint & Build Gate
Verify zero errors and zero warnings:
```bash
swiftlint --strict
xcodebuild clean build -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

### 6.3 Physical Device Manual Verification Steps
1. Launch VocabCraftApp on physical iPhone.
2. Navigate to **Tab 3: AI Assistant**.
3. Select Daily Mission ("Ordering Coffee at a Cafe") and tap **"Start Voice Call"**.
4. Observe the AI character greeting via speaker.
5. Watch the Voice Orb transition to **"Listening to you..."**.
6. Speak clearly: *"I would like an espresso and a warm croissant, please."*
7. Observe:
   - Target words `espresso` and `croissant` light up with checkmarks and trigger tactile haptic vibration.
   - Live subtitles transcribe the sentence.
   - After 1.5s pause, Voice Orb enters "Thinking..." state.
   - Barista replies in character via speaker.
8. Tap **End Call** and verify that `RoleplaySummaryView` displays turn statistics, mastered words, and XP earned.
