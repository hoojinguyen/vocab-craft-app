# Technical Reply Guidelines and Templates for AI Review Comments

This reference outlines the technical, evidence-based standards for replying to AI reviewer bot comments on PR threads.

---

## 1. Zero Performative Communication Policy

Strictly adhere to the `receiving-code-review` core principles:

### ❌ FORBIDDEN RESPONSES:
- "You're absolutely right!"
- "Great point!" / "Excellent feedback!" / "Thanks for catching that!"
- "Good suggestion, letting me fix it right now!"
- Any polite filler or emotional performance.

### ✅ MANDATORY RESPONSES:
- State the technical fact or fix location.
- Cite the commit SHA or specific test name.
- Provide objective, evidence-backed pushback citing codebase architecture, `AGENTS.md` standards, or test invariants.

---

## 2. Standard Reply Templates

### Template A: Fix Applied (`[VALID - CODE FIX]` / `[VALID - TEST ONLY]`)
```text
Fixed in commit [COMMIT_SHA].
- [Brief description of change, e.g.: Added missing Vietnamese key in Localizable.xcstrings with manual extractionState.]
- [Brief description of test added, e.g.: Added @Test suite 'MixedReflexDrillViewsTests' validating zero-item array guard.]
```
*For CodeRabbit threads, you may prefix with `@coderabbitai resolve`.*

---

### Template B: Technical Pushback - Architectural Standards / Tokens (`[INVALID - ARCHITECTURAL CONFLICT]`)
```text
Keeping current implementation as designed.
In this codebase, raw colors/typography (e.g. Color.red or ad-hoc system fonts) are strictly prohibited by our design system architecture (see AGENTS.md §3). All styling must use CraftUIKit semantic design tokens (`CraftColorTokens.statusError`, `CraftFont.captionMedium`). The current usage strictly conforms to these tokens.
```

---

### Template C: Technical Pushback - YAGNI & Spec Boundaries (`[INVALID - SPEC MISUNDERSTANDING]`)
```text
Keeping current implementation.
The suggested parameter/method is not part of this feature's specification or current consumer surface. Per YAGNI and Swift API Design Guidelines, we intentionally omit unused configuration parameters until a concrete use case requires them.
```

---

### Template D: Technical Pushback - Concurrency / Lifecycle Safety
```text
Verified safe as implemented.
The view model is annotated with `@MainActor` and observed via SwiftUI `@Observable` environment injection. Task cancellation and lifecycle teardown are managed in `.task(id:)`, preventing detached async background execution or memory leaks. Verified with zero leaks under memory graph debugging.
```

---

### Template E: Clarification / Question Answer
```text
Clarification: The function `[FunctionName]` intentionally returns early when `[Condition]` because `[Reason, e.g. the drill mode switches to interstitial summary state]`.
```
