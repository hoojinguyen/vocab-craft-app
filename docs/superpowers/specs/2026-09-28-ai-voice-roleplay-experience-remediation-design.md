# Design Specification: AI Voice Roleplay Experience Remediation & Conversational Scaffolding

- **Date**: 2026-09-28
- **Topic**: Speaking AI Voice Call Experience Remediation, Real-Time Audio Metering & Dynamic Turn Scaffolding
- **Status**: Draft (Awaiting User Review)
- **Target Repository**: VocabCraft (`VocabCraftApp`, `Packages/SpeechKit`, `Packages/CraftUIKit`)

---

## 1. Context & Problem Statement

The Speaking AI feature provides an interactive, full-screen real-time voice call simulation where users roleplay with AI characters (e.g. Barista Emma, Concierge David, Hiring Manager Ms. Jenkins) to practice conversational English with target vocabulary.

During device testing, three critical issues were identified:
1. **Navigation Freeze on End Call**:
   - Tapping the end call or close button fails to dismiss back to the main hub screen (`AIAssistantHubView`).
   - Root cause: `RoleplayVoiceCallView` is presented as a `.fullScreenCover` on `AIAssistantHubView`. Upon call completion, `RoleplayVoiceCallView` attempts to present another nested modal `.fullScreenCover(item: $viewModel.sessionSummary)` on top of itself. In SwiftUI on iOS, dismissing a parent presentation from within a child modal often corrupts the UIViewController hierarchy, leaving the user stuck on screen. Furthermore, the top-left Close (`X`) button also triggers `endCall()` rather than an immediate exit/discard flow.
2. **Speech Recognition Failure & Zero Audio Feedback**:
   - The user speaks into the microphone, but the app does not receive the speech, produces no response, and gives no visual indication that it is listening.
   - Root cause: In `SpeechRecognitionService.swift`, audio session lease acquisition (`audioSessionCoordinator.acquire(.speechCapture)`) is triggered inside a detached asynchronous `Task` without being awaited. Immediately following this, `audioEngine.start()` is called synchronously on the main actor while the `AVAudioSession` category is still `.playback` from the AI's prior TTS greeting. Consequently, `audioEngine.inputNode` fails or returns zero-format audio, triggering `onError`, cancelling the `SilenceDetector`, and leaving the speech engine dead. Additionally, `CraftVoiceOrbView` only runs a static 1.2s repeating breathing animation, providing zero live decibel/metering feedback from the microphone.
3. **Absence of Conversational Hints / Scaffolding**:
   - English learners frequently experience anxiety or freeze when asked to speak, not knowing how to formulate an authentic response or use the scenario's target vocabulary.
   - Root cause: `RoleplayTurnOutput` only returns `characterReply`, `targetWordsUsed`, `refinementSuggestion`, and `pedagogicalNote`. There is no `suggestedResponses` field in the domain schema or LLM prompts, and no UI container to display or preview pronunciation of sample answers.

---

## 2. Goals & Success Criteria

1. **Deterministic Navigation Dismissal (100% Reliable)**:
   - Eliminate nested `.fullScreenCover` modals by switching view state inline (`if let summary = viewModel.sessionSummary { RoleplaySummaryView(...) } else { callContent }`).
   - Distinguish Top Close (`X`) button (quick discard with confirmation alert) from Bottom Red Hang-Up button (session completion with inline summary).
   - Dismissing from `RoleplaySummaryView` via "Xong" cleanly and immediately returns to `AIAssistantHubView`.
2. **Robust Speech-to-Text Pipeline with Live Decibel Metering**:
   - Sequence audio session transitions: wait for `.playback` lease release and ensure `.speechCapture` lease is fully acquired and active before configuring `audioEngine.inputNode` and calling `audioEngine.start()`.
   - Calculate real-time RMS power (decibel metering normalized from `0.0` to `1.0`) on the audio tap buffer.
   - Update `CraftVoiceOrbView` to dynamically scale its outer glow and soundwave rings in real-time in response to the user's voice volume.
   - Prevent `SilenceDetector` from permanently cancelling if the initial 10s elapses without speech.
3. **Dynamic Conversational Scaffolding (Speaking Hints)**:
   - Add `suggestedResponses: [String]` to `RoleplayTurnOutput` and provide turn 0 starter suggestions in `RoleplayScenarioCatalog`.
   - Update Gemini 1.5 Flash system prompts and `IntelligentMockLLMProvider` to generate 2-3 natural speaking suggestions containing target words.
   - Add an expandable/collapsible hint container in `RoleplayVoiceCallView` with TTS pronunciation preview on each suggested phrase.
4. **Quality Gates**:
   - 0 compiler warnings, 0 SwiftLint warnings.
   - 100% test pass rate for all unit and integration test suites.
   - 100% localization parity (EN/VI) in `Localizable.xcstrings` under `app.ai_assistant.*`.
   - Strict CraftUIKit design token conformance.

---

## 3. Detailed Architecture & Design

### 3.1 In-View Navigation & Dismissal Architecture

#### View Hierarchy Elimination of Nested Modal Presentation
Instead of stacking modals, `RoleplayVoiceCallView` manages its full-screen presentation through an inline state transition:

```swift
@MainActor
public struct RoleplayVoiceCallView: View {
    @Bindable public var viewModel: RoleplayVoiceCallViewModel
    private let onDismiss: () -> Void
    @Environment(\.craftTheme) private var theme

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            if let summary = viewModel.sessionSummary {
                RoleplaySummaryView(summary: summary) {
                    onDismiss()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                activeCallStage
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.sessionSummary != nil)
        .alert(
            AppStrings.AIAssistant.discardConfirmTitle,
            isPresented: $viewModel.showDiscardAlert
        ) {
            Button(AppStrings.Common.cancel, role: .cancel) {}
            Button(AppStrings.Common.confirm, role: .destructive) {
                viewModel.cancelCall()
                onDismiss()
            }
        } message: {
            Text(AppStrings.AIAssistant.discardConfirmMessage)
        }
    }
}
```

#### Dual Exit Behavior:
- **Top Header Close Button (`X`)**:
  - Triggers `viewModel.handleCloseButton()`.
  - If the call is within initial seconds with 0 turns, immediately cancels and calls `onDismiss()`.
  - If active conversation has occurred, presents `showDiscardAlert`. Confirming calls `viewModel.cancelCall()` and `onDismiss()`.
- **Bottom Red Hang-Up Button (`phoneDown`)**:
  - Triggers `Task { await viewModel.endCall() }`.
  - Engine completes session, sets `sessionSummary`, smoothly transitioning the screen to `RoleplaySummaryView`. Tapping "Xong" calls `onDismiss()`.

---

### 3.2 Audio Session & Speech Recognition Pipeline

#### Sequential Lease Acquisition in `SpeechRecognitionService`
`startListening` is updated to guarantee that the audio session is in `.playAndRecord` before initializing `AVAudioEngine`:

```swift
public func startListening(
    onResult: @escaping (String) -> Void,
    onAudioLevelUpdate: ((Float) -> Void)? = nil,
    onError: @escaping (Error) -> Void
)
```

1. **Authorization & Pre-flight**: Verify microphone and speech recognition authorizations.
2. **Audio Session Lease Acquisition**:
   - `let lease = try await self.audioSessionCoordinator.acquire(.speechCapture)`
   - Set `activeLease = lease`.
3. **Hardware Configuration**:
   - Configure `inputNode` using `inputNode.outputFormat(forBus: 0)`.
   - Validate `sampleRate > 0 && channelCount > 0`.
4. **Buffer Tap & RMS Decibel Metering**:
   ```swift
   inputNode.installTap(onBus: 0, bufferSize: 1024, format: hardwareFormat) { [weak self] buffer, _ in
       guard buffer.frameLength > 0 else { return }
       request.append(buffer)
       
       guard let channelData = buffer.floatChannelData?[0] else { return }
       var sumSquares: Float = 0
       let frameCount = Int(buffer.frameLength)
       for i in 0..<frameCount {
           let sample = channelData[i]
           sumSquares += sample * sample
       }
       let rms = sqrt(sumSquares / Float(frameCount))
       let db = 20 * log10(max(rms, 0.0001))
       let normalized = min(1.0, max(0.0, (db + 50.0) / 50.0))
       
       self?.dispatchAudioLevel(normalized)
   }
   ```
5. **Engine Start**: `audioEngine.prepare(); try audioEngine.start(); isRecording = true`.

#### Standby-Resilient `SilenceDetector`
In `TurnBasedVoiceConversationEngine`:
- If 10 seconds of initial silence elapses without user speech, `SilenceDetector` maintains standby mode rather than permanently cancelling.
- When live speech is detected (`audioLevel > 0.05` or partial transcript arrives), trailing silence (1.5s) countdown begins. Once silence is sustained for 1.5s after speech, the turn automatically finalizes.

---

### 3.3 Dynamic Conversational Scaffolding & Suggested Responses

#### Domain Model Extension
```swift
public struct RoleplayTurnOutput: Codable, Sendable, Equatable {
    public let characterReply: String
    public let targetWordsUsed: [String]
    public let refinementSuggestion: String?
    public let pedagogicalNote: String?
    public let suggestedResponses: [String]

    public init(
        characterReply: String,
        targetWordsUsed: [String],
        refinementSuggestion: String? = nil,
        pedagogicalNote: String? = nil,
        suggestedResponses: [String] = []
    ) { ... }
}
```

#### Starter Suggestions Catalog
`RoleplayScenario` is augmented with `starterSuggestions: [String]` so that the user receives immediate suggestions in response to the character's initial greeting.

#### LLM Provider Updates
- **GeminiLLMProvider**: System prompt directs Gemini to return JSON with `suggestedResponses` containing 2-3 spoken replies tailored to the scenario and target vocabulary.
- **IntelligentMockLLMProvider**: Generates 2-3 dynamic candidate sentences for every turn using the scenario's topic and unmastered target words.

#### UI Scaffolding Component in `RoleplayVoiceCallView`
- Positioned above the bottom action bar.
- Collapsed: A tactile button `[ 💡 Gợi ý câu trả lời ]`.
- Expanded: Displays cards with the suggested sentences.
- Each suggestion features a TTS audio button (`CraftIconButton(symbol: .speakerWave2)`) allowing the learner to listen to standard pronunciation before speaking.
- Automatically collapses when the user begins speaking.

---

### 3.4 Live Reactive Audio Feedback (`CraftVoiceOrbView`)

- `CraftVoiceOrbView` accepts `audioLevel: Float` (normalized `0.0 ... 1.0`).
- When `state == .listening`:
  - Outer Glow: `scaleEffect(1.0 + CGFloat(audioLevel) * 0.35)` with animated opacity boost.
  - Soundwave Ring: `scaleEffect(1.0 + CGFloat(audioLevel) * 0.20)`.
  - Icon: Switches to `.waveform` when `audioLevel > 0.08` (active speaking) vs `.mic` (listening standby).
- Provides immediate, fluid visual proof that the app is capturing audio.

---

## 4. Error Handling & Edge Cases

| Scenario | System Response |
| :--- | :--- |
| **Microphone permission denied** | Display pre-flight settings alert, prevent voice call launch. |
| **Incoming phone call / Audio interruption** | Audio session coordinator broadcasts `.interruptionBegan`; engine pauses capture; resumes on `.interruptionEnded`. |
| **Network timeout on Gemini call** | Engine retains user's spoken transcript; displays retry banner without resetting state. |
| **User freezes / remains silent** | Silence detector stays in standby; suggested responses remain visible to guide the user. |
| **Accidental quick exit** | If call duration < 3s and turns == 0, dismisses immediately without showing summary. |

---

## 5. Localization Requirements (`Localizable.xcstrings`)

All user-facing strings must adhere to `app.ai_assistant.*` taxonomy with 100% EN & VI parity:
- `app.ai_assistant.speaking_hints_button`: "💡 Gợi ý câu trả lời" / "💡 Suggested responses"
- `app.ai_assistant.speaking_hints_title`: "Gợi ý câu nói" / "Suggested responses"
- `app.ai_assistant.listen_sample`: "Nghe mẫu" / "Listen to sample"
- `app.ai_assistant.discard_confirm_title`: "Kết thúc cuộc hội thoại?" / "End conversation?"
- `app.ai_assistant.discard_confirm_message`: "Bạn có chắc muốn thoát? Tiến độ cuộc gọi hiện tại sẽ không được lưu." / "Are you sure you want to exit? Current call progress will not be saved."

---

## 6. Testing & Quality Gate

1. **TurnBasedVoiceConversationEngineTests**:
   - Verify speech capture lease acquisition before listening starts.
   - Verify audio level propagation to observers.
   - Verify standby silence detector behavior.
   - Verify suggested responses storage and propagation.
2. **SpeechRecognitionServiceTests**:
   - Verify sequential lease acquisition and error handling on hardware setup.
3. **RoleplayVoiceCallViewModelTests**:
   - Verify close button discard alert logic.
   - Verify hang-up button inline summary assignment.
   - Verify suggestion toggle and TTS preview invocation.
4. **IntelligentMockLLMProviderTests**:
   - Verify structured output schema includes non-empty `suggestedResponses`.
5. **LocalizationTests**:
   - Verify 100% key parity across `en` and `vi`.
