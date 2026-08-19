# Reflex Blitz Audio, Pacing, and UX Enhancements Design

## Overview
This document specifies the technical design to refine and resolve critical user experience, audio routing, concurrency, and performance issues in the **Reflex Blitz** drill mode of VocabCraftApp.

## Problems Identified
1. **Rushed Word Transition on Success:** When the user speaks the correct word, the app advances in 400ms, which is too brief for the user to visually observe and digest the completed phrase and pronunciation before the card disappears.
2. **TTS Bleed / Self-Echo on Timeout:** When a timeout occurs, TTS speaks the word asynchronously while the timer hard-sleeps for 1200ms and advances. If TTS takes longer or speech recognition is still listening, the microphone captures the phone's own speaker audio and misrecognizes it on the subsequent card.
3. **Audio Speaker Crackling / Buzzing ("Loa rè"):** AVAudioSession configuration conflict between `ContinuousReflexSpeechService` (`.measurement` mode) and `TextToSpeechService` (`.spokenAudio` mode with `.allowBluetoothHFP`). Dynamic reconfiguration during an active `AVAudioEngine` tap causes buffer underruns, sample-rate switches (48kHz <-> 8/16kHz), and audio distortion.
4. **Severe Frame Drops & Lag on Mode Switching:**
   - The stopwatch loop updates `elapsedTimeMs` 20 times per second (50ms interval) on the `@Observable` ViewModel, triggering high-frequency MainActor view body invalidations.
   - When switching to Keyboard Fallback mode, `ContinuousReflexSpeechService` continues processing audio input in the background, contending with the system `UIKeyboard` animation and text input engine.
5. **Missing Reward Audio Cue:** Lack of an immediate, crisp success sound cue to validate correct speech recognition.

---

## Architectural & UX Solutions

### 1. UX Pacing, Visual Scaffolding, and Timing Integrity
- **Success Dwell Time:** Extended from 400ms to **1000ms** (1.0s).
- **Cloze Slot Reveal:** On correct match, the cloze blank `[ ••• ]` replaces smoothly with the target word/collocation highlighted in `.vocabMint` and displays the IPA badge.
- **Timing Integrity Guarantee:**
  - `responseTimeMs` measures strictly from card appearance (`wordStartTime`) until the exact timestamp the match is detected.
  - The 1000ms success dwell time, timeout TTS playback time, transition animations, and countdown are **explicitly excluded** from the user's reflex response time and session average calculations.

### 2. Multisensory Success Feedback
- **Sound Effect:** Immediate playback of a system success chime via `AudioServicesPlaySystemSound` or `SoundEffectService` on successful match.
- **Haptic Feedback:** Trigger `.sensoryFeedback(.success)`.

### 3. Anti-Self-Echo & Async TTS Synchronization
- **Async TTS Completion:** Extend `TextToSpeechProtocol` to support `speakAsync(text: String, rate: Float, locale: String) async`.
- **Speech Recognition Mute / Pause:** While TTS is speaking in `handleTimeout`:
  - `ContinuousReflexSpeechService.pauseListening()` (or `isRecognitionMuted = true`) ignores incoming microphone buffers.
  - `await ttsService.speakAsync(...)` guarantees the full utterance is finished.
  - An additional 300ms silence buffer elapses before advancing to `loadWord(at: currentWordIndex + 1)` and unmuting the speech recognizer.

### 4. Audio Session Unification (Zero Distortion / Crackling)
- Both `ContinuousReflexSpeechService` and `TextToSpeechService` share a consistent, high-fidelity `AVAudioSession` configuration:
  - Category: `.playAndRecord`
  - Mode: `.default` or `.spokenAudio`
  - Options: `[.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]`
  - Explicitly eliminate `.allowBluetoothHFP` to prevent Bluetooth and speaker routing from downsampling to low-quality mono 8kHz/16kHz SCO.
- Guard against redundant `AVAudioSession.setCategory` calls while `AVAudioEngine` is actively running.

### 5. Performance Optimization & Keyboard Mode Lifecycle
- **Microphone Lifecycle on Mode Switch:**
  - Switching to **Keyboard Fallback** (`isKeyboardFallbackActive = true`): Immediately suspends audio engine tap / speech recognition task to free up CPU and eliminate contention with UIKit `UIKeyboard`.
  - Switching to **Voice Mode** (`isKeyboardFallbackActive = false`): Resumes microphone stream and recognition task.
- **Timer Optimization:** Reduce stopwatch tick frequency from 50ms to 100ms (10 ticks/sec instead of 20 ticks/sec), reducing MainActor re-renders by 50% without any perceived loss of timer smoothness.

---

## File Changes Overview
- **`VocabCraftApp/Domain/Protocols/AudioServiceProtocols.swift`**: Add `speakAsync` signature to `TextToSpeechProtocol`.
- **`VocabCraftApp/Core/Audio/TextToSpeechService.swift`**: Implement `speakAsync`, fix `AVAudioSession` category options.
- **`VocabCraftApp/Core/Audio/SoundEffectService.swift`**: New service for playing zero-latency success audio feedback.
- **`VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift`**: Add `pauseListening()` / `resumeListening()`, unify `AVAudioSession` options.
- **`VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`**: Adopt 1000ms dwell time, async TTS timeout handling, mic pausing during keyboard mode & TTS, success sound trigger, and 100ms timer ticks.
- **`VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`**: Refine sentence display for correct word reveal.
- **`VocabCraftAppTests/...`**: Update and add unit tests covering async TTS, speech muting, and timing behavior.
