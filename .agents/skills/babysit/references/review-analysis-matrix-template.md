# Review Analysis Matrix Template

This template defines the mandatory structure of the Review Analysis Matrix presented to the human developer during **Stage 3 (Human Approval Gate)** of the `babysit` workflow.

---

## 1. Markdown Matrix Format

When presenting comments for human review, render this exact table structure in chat / artifact:

```markdown
### 📋 PR #[PR_NUMBER] AI Review Analysis Matrix (Cycle #[CYCLE_INDEX])

| # | Bot | File & Location | Summary of Claim | Root-Cause Rationale (Why Bot Commented) | Verdict | Proposed Action / Fix / Rebuttal |
|---|-----|-----------------|------------------|------------------------------------------|---------|-----------------------------------|
| 1 | `coderabbitai` | `ReflexBlitzView.swift:45` | Claims `audioPlayer` might leak memory | Bot detected closure capturing `self` without seeing `@Observable` lifecycle isolation in container. | `[INVALID - ARCHITECTURAL CONFLICT]` | **Pushback**: Point out that `@Observable` view models retain state via SwiftUI environment, lifecycle is scoped, and memory is verified green with Leaks Instrument. |
| 2 | `gemini-code-assist` | `Localizable.xcstrings` | Missing Vietnamese key for `app.reflex.timeout` | Bot parsed view string `app.reflex.timeout` and noticed key was only defined in English branch. | `[VALID - CODE FIX]` | **Fix**: Add `"vi"` translation with `extractionState: "manual"` and state `"translated"` to maintain 100% bilingual parity per `AGENTS.md`. |
| 3 | `copilot` | `MixedReflexDrillView.swift:102` | Asks to add edge case test for empty array | Array check currently returns early, but there is no dedicated unit test guarding this condition. | `[VALID - TEST ONLY]` | **Test**: Add Swift Testing `@Test func testEmptyDeckReflex()` in `MixedReflexDrillViewsTests.swift`. |

---

### 🛡️ Summary of Proposed Actions:
- **Valid Fixes (To Implement)**: Items #2, #3
- **Pushbacks (To Explain & Dismiss)**: Item #1
- **Estimated Code Files Modified**: 1 (`Localizable.xcstrings`)
- **Estimated Test Files Modified**: 1 (`MixedReflexDrillViewsTests.swift`)

> [!IMPORTANT]
> **Human Approval Required**:
> - Type **`proceed`** / **`approve all`** to execute the proposed fixes and send replies.
> - Or adjust any item (e.g. *"Change item #1 to fix instead of pushback"*, *"Edit reply for #1"*).
```

---

## 2. Verdict Standards

| Verdict | Meaning | Action Requirement |
|:---|:---|:---|
| `[VALID - CODE FIX]` | Bot identified a real bug, regression, race condition, or violated project rule (`AGENTS.md`). | Implement code fix with TDD + quality gate. Reply with commit SHA. |
| `[VALID - TEST ONLY]` | Implementation is sound, but missing an invariant test guarding against regressions. | Add unit test using Swift Testing (`@Test`, `#expect`). |
| `[INVALID - SPEC MISUNDERSTANDING]` | Bot suggested out-of-scope features (violating YAGNI) or misunderstood user flow/requirements. | Technical pushback citing spec/PR description and tests. |
| `[INVALID - ARCHITECTURAL CONFLICT]` | Bot suggested raw colors/fonts, anti-patterns, or patterns forbidden in `AGENTS.md` (e.g. avoiding CraftUIKit). | Technical pushback citing project design system rules. |
| `[CLARIFICATION / QUESTION]` | Bot asked a question or needs clarification on intent. | Concise technical answer. |

---

## 3. Human Approval Gate Rules
1. **Never skip approval**: No automated commit or GitHub reply may be dispatched before explicit human response.
2. **Support overrides**: If the developer instructs to handle an item differently (e.g., dismiss a valid item or fix an invalid one), strictly follow the developer's directive.
