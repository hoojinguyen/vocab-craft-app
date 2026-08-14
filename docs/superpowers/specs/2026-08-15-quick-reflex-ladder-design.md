# Design Specification: Quick Reflex Ladder

Date: 2026-08-15  
Status: Approved for implementation planning

## 1. Purpose and Scope

Redesign **“Luyện phản xạ từ này”** into a single-word, voice-first micro-practice that trains productive recall: a learner sees an idea or situation, says the target English word or expression, and immediately uses it in one short sentence.

The feature is launched from a word in the personal vocabulary store and completes in roughly 45 seconds. It is not a general grammar evaluator, chatbot, or multi-word study session.

### Decisions already made

- Primary learning outcome: **idea/situation → spoken English word or expression**.
- Default input: speech; the learner can switch to typing without losing the attempt.
- Practice depth: retrieve the target, then use it in a self-produced short sentence.
- Timing: soft timing with progressively revealed hints; expiry never marks an answer wrong.
- Product approach: **Reflex Ladder** is the core flow. Micro Roleplay may later supply alternate second-step situations; Contrast Sprint is explicitly out of scope.

## 2. Learner Experience

1. The learner expands `WordAccordionCard` and taps **Luyện phản xạ từ này**.
2. `QuickReflexDrillSheetView` opens with a compact target-word badge and a two-stage progress indicator. The target word stays hidden during retrieval.
3. **Stage 1 — Retrieve**: a Vietnamese definition or concise situation appears. The learner says the matching English word/expression or types it.
   - At 4 seconds, reveal the part of speech.
   - At 7 seconds, reveal the first letter or a concise phrase frame.
   - The learner may use a microphone, change to typing, retry once after unclear recognition, reveal the answer, skip, or close the sheet.
4. **Stage 2 — Use**: a different, short situation derived from the word’s existing example translation appears. The learner gives one short English sentence containing the target.
   - The target word is visible at this stage.
   - At 5 seconds, offer an optional sentence frame.
   - Speech is the default; typing remains available.
5. **Result**: a compact card shows Retrieve and Use as separate outcomes, the time saved versus the most recent comparable attempt when available, and the learner’s self-report: **Quen** or **Còn lúng túng**.
6. The sheet dismisses to the vocabulary list. Mastery stars update only if retrieval succeeded.

The first release uses only current word data: Vietnamese definition, part of speech, English example, and Vietnamese example. It does not call a generative model or network service to create prompts.

## 3. Learning and Feedback Rules

### Retrieval

- A correct response is an exact normalized match for the target lemma/expression, accepting case and surrounding punctuation differences.
- Speech recognition may display the transcript and word-level feedback already available through SpeechKit.
- When the target is unclear or absent, offer one retry, then an immediate typing fallback.
- The first successful retrieval determines the SRS result.

### Use in a sentence

- A successful usage response contains the normalized target expression in the learner’s transcript or typed sentence.
- This release deliberately does **not** claim to grade grammar, fluency, or semantic appropriateness. The prompt encourages natural usage; the result confirms observable target use only.
- The learner can hear the existing example sentence as an optional model, without replacing their own response requirement.

### Hints, skipping, and SRS

- Hints are progressive aids, not timer penalties. Store the highest hint shown.
- Reveal-answer and skip create a **deferred attempt** log only. They do not call SRS and do not reduce mastery.
- A successful retrieval calls the existing SRS recording use case once. The Stage 2 outcome, hints, and confidence inform analytics/progress messaging only; they cannot block or increase SRS mastery.
- Closing the sheet or cancelling before results persists nothing and always stops active recording and timers.

## 4. Architecture and Boundaries

### `QuickReflexDrillSheetView`

Owns presentation: header, progress indicator, mic/typing controls, adaptive hint display, result card, dismissal, accessibility labels, and routing the completion callback to `VocabularyView`. It contains no scoring or prompt-generation decisions.

### `QuickReflexDrillViewModel`

Owns the session state machine:

`retrieve → useInSentence → result`

It tracks stage start times, input mode, hint level, retry count, transcript/typed answer, stage outcomes, and self-report. It owns timer cancellation and recording lifecycle on transition, cancellation, and deinitialization.

### `QuickReflexPromptFactory`

Produces deterministic stage prompts from `WordItem`.

- Retrieve: Vietnamese definition plus part-of-speech and first-letter hint material.
- Use: a communication instruction based on the Vietnamese example sentence, with an optional template selected by part of speech.

The factory must handle missing or unusable example text by supplying a neutral, short prompt requesting any sentence with the target expression. It has no UI, persistence, or speech dependency.

### `TargetExpressionMatcher`

Normalizes typed text and speech transcripts, then identifies the target lemma or multi-word expression as a standalone expression rather than a substring. It builds on the app’s existing string-normalization facilities. Speech assessment of complete example sentences is not reused as the correctness gate for free production.

### Persistence and SRS

- Continue to use `EvaluateSRSUseCase.recordReview` for a successful Retrieve stage, exactly once per completed drill.
- Persist a dedicated quick-reflex attempt record (or extend the existing reflex session record) containing: word ID, retrieve/use time, retrieve/use outcome, max hint level, input mode, retry count, self-report, and timestamp.
- The log supports progress messages and future adaptation. It must not change the SRS schedule outside the successful Retrieve rule.

## 5. Data Flow and Failure Handling

1. `VocabularyView` presents the sheet with a snapshot of the selected `WordItem`.
2. The view model asks `QuickReflexPromptFactory` for the two-stage prompt.
3. For each stage, the view model accepts speech or typed input and asks `TargetExpressionMatcher` to evaluate it.
4. It records the completed attempt. If retrieval was successful, it calls the SRS use case and forwards the resulting mastery to `VocabularyView`.
5. The result UI reads the session outcome and latest comparable log; it never waits for remote processing.

Failure and safety rules:

- Missing microphone permission, unavailable speech recognition, SpeechKit error, or offline recognition failure immediately expose typing; the drill remains completable.
- Empty or unclear speech results offer retry then typing; no error can leave the mic in a listening state.
- A soft timer only reveals hints. It never auto-submits an answer or marks a stage incorrect.
- Result logging or SRS persistence errors show a recoverable message and retain the completed result in memory; the sheet can still be dismissed safely.

## 6. Testing and Acceptance Criteria

### Unit tests

- `QuickReflexPromptFactory` makes valid retrieve/use prompts and fallbacks for noun, verb, adjective, and multi-word expressions.
- `TargetExpressionMatcher` accepts capitalization/punctuation variations, rejects substrings, and handles multi-word targets.
- View-model state tests cover hints, voice-to-typing switch, retry, skip/reveal, cancellation, and one-way stage progression.
- SRS tests prove successful Retrieve calls record once; skip, reveal, speech errors, and cancellation do not call it.
- Persistence tests verify all attempt fields and do not mutate `UserWordProgress` for deferred attempts.

### UI and regression tests

- Existing sheet presentation and vocabulary-star update remain functional.
- Voice and type controls expose clear VoiceOver labels and meet 44 pt touch targets.
- SpeechKit integration tests verify active recognition stops on completion, error, and dismissal.

### Acceptance criteria

- From a word card, a learner can complete both stages using speech, typing, or a mix, without a network request.
- A learner who takes longer is guided by hints rather than failed by a timer.
- The results distinguish retrieval from sentence use, and never claim to grade grammar.
- Only a successful retrieval changes SRS mastery; no skipped, revealed, failed-recognition, or cancelled drill changes it.
