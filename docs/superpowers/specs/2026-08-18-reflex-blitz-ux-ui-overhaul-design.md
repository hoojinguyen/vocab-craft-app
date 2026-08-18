# Design Document: Reflex Blitz UX/UI & Learning Experience Overhaul

- **Date:** 2026-08-18
- **Author:** Antigravity & Pair Programming Partner
- **Status:** Approved
- **Target Platform:** iOS 17.0+ (SwiftUI, Observation, Apple HIG)

---

## 1. Executive Summary & Goals

The Spoken Reflex Blitz drill is designed to build subconscious vocal recall speed for English vocabulary through high-tempo timed challenges. 

A thorough simulator audit identified several critical UX/UI flaws:
1. **Severe Visual Dead Space & Dual Focus Disconnect**: The question card was centered while the live speech wave and transcript were placed 400pt below at the bottom edge.
2. **Invisible Time Pressure**: No per-word countdown timer existed (6.0s timeout and 3.5s hint were invisible).
3. **No Target Word Injection in Cloze Blank**: Answering correctly left `[ ________ ]` in place rather than filling the word into context.
4. **Missing Phonetic / Pronunciation Anchors**: No IPA phonetics or speaker audio during drilling or on the summary screen.
5. **Shallow Summary Screen**: Weak words showed only names and timeout tags without Vietnamese definitions or pronunciation replay buttons.

This design document outlines the comprehensive UX/UI restructuring to solve these issues, creating an intense, focused, and frictionless learning experience.

---

## 2. Architectural & Component Changes

```
┌─────────────────────────────────────────────────────────┐
│ [X] Đóng          [ 🔥 x3 COMBO ]             [⏭] Bỏ qua│
│ ━━━━━━━ (Tiến độ phiên: Từ 3/10) ━━━━━━━━━━━━━━━━━━━━━━ │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ ─── [ Viền đếm lùi 6.0s bo quanh viền thẻ ] ─────── │ │
│ │                                                     │ │
│ │   "Finding this was pure [ serendipity ]."          │ │
│ │                                                     │ │
│ │   Nghĩa: Sự may mắn bất ngờ                          │ │
│ │   IPA: /ˌser.ənˈdɪp.ə.ti/                           │ │
│ │                                                     │ │
│ │   💡 Gợi ý: s... • noun                             │ │
│ │                                                     │ │
│ │ ─────────────────────────────────────────────────── │ │
│ │   🎙️ [||| |||| |||||] Đang lắng nghe...             │ │
│ │   "pure serendipity..."                             │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│               [ ⌨️ Chuyển sang gõ phím ]                │
└─────────────────────────────────────────────────────────┘
```

### 2.1. File Modifications & Responsibilities

| File Path | Responsibilities |
|---|---|
| `VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift` | Add IPA phonetics field `ipa: String` to `ReflexBlitzWordItem`, helper for cloze sentence completion, and enriched `ReflexBlitzAttempt` / `ReflexBlitzWeakWordAttempt`. |
| `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift` | Compute `fractionRemaining: Double` (0.0 to 1.0) and `timerColorStage`, provide speak lemma helper via `TextToSpeechProtocol`, and format completed sentences. |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift` | Embed perimeter border stroke countdown timer, text morphing from `[ ______ ]` to highlighted target word, IPA phonetics badge, and integrated voice visualizer dock. |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift` | Clean vertical layout containing `ReflexBlitzHeaderView`, consolidated `ReflexBlitzCardView`, and keyboard toggle button. |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift` | Enriched weak words rows with Vietnamese definitions, IPA phonetics, and instant tap-to-speak mini speaker buttons. |

---

## 3. Detailed Interaction & Animation Specifications

### 3.1. Perimeter Countdown Timer
- **Duration**: 6,000ms per word challenge.
- **Formula**: `fractionRemaining = max(0.0, min(1.0, 1.0 - Double(elapsedTimeMs) / 6000.0))`.
- **Stroke Path**: `RoundedRectangle(cornerRadius: 28, style: .continuous).trim(from: 0, to: fractionRemaining)`.
- **Color Progression**:
  - `0ms <= elapsed < 3500ms`: `Color.vocabMint` / `Color.vocabHeroAccent` (steady state).
  - `3500ms <= elapsed < 5000ms`: `Color.vocabPeach` (hint active warning).
  - `5000ms <= elapsed <= 6000ms`: `Color.vocabCoral` with pulse animation (urgent timeout warning).

### 3.2. Cloze Blank Text Morphing
- **In Drilling (Normal)**: Shows `word.clozeSentenceEn` with `[ ________ ]`.
- **On Correct Match**:
  - Replaces `[ ________ ]` with `[ \(word.lemma) ]` in `Color.vocabMint` with bold font weight.
  - Displays IPA pronunciation badge `/...\/` below the definition.
  - Triggers `.sensoryFeedback(.success)` and 400ms pause before advancing.
- **On Timeout / Skip**:
  - Replaces text with `word.exampleSentenceEn` in `Color.vocabCoral`.
  - Triggers `.sensoryFeedback(.impact(weight: .heavy))` and speaks pronunciation via TTS.
  - 1200ms pause before advancing.

### 3.3. Summary Screen Learning Actions
- Each item in `summary.weakWordAttempts` contains:
  - Lemma (e.g. `resilient`)
  - Part of Speech & IPA (e.g. `adj. • /rɪˈzɪl.jənt/`)
  - Vietnamese definition (e.g. `Kiên cường, mau hồi phục`)
  - Mini speaker button triggering `ttsService.speak(text: weak.lemma, rate: 0.5, locale: "en-US")`
  - Response time badge (`Hết giờ` or `5.2s`)
- Primary action: "🔄 Củng cố ngay X từ yếu" restarts session with filtered weak words.
- Secondary action: "Hoàn thành & Lưu tiến độ" saves SRS metrics and returns to Home.

---

## 4. Testing & Verification Strategy

1. **Unit Tests**:
   - `ReflexBlitzModelsTests.swift`: Verify IPA property, default starter words with IPA, and completed sentence builders.
   - `ReflexBlitzViewModelTests.swift`: Verify `fractionRemaining` calculation, timer color stages, and weak words re-drilling filter.
   - `ReflexBlitzComponentsTests.swift`: Verify `ReflexBlitzCardView` rendering with perimeter stroke and IPA badge.
   - `ReflexBlitzSummaryViewTests.swift`: Verify summary content with mini speaker button tap triggers TTS.
2. **Simulator Snapshot Verification**:
   - `ReflexBlitzViewIntegrationTests.swift`: Run `testCaptureAllReflexBlitzScreenshots()` on iPhone 17 Simulator to capture and inspect all 8 upgraded screens.
