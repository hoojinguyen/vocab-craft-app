---
name: babysit
description: Use when reviewing and resolving AI reviewer bot comments on a pull request, requiring deep technical root-cause analysis, human approval gate, automated fixes, thread replies, and continuous PR watch loop until approval.
---

# Babysit: AI PR Review Resolver & Watch Loop

## Overview

**Babysit** automates the end-to-end resolution of AI reviewer feedback on GitHub Pull Requests. It runs an intelligent, iterative loop that ingests comments from AI agents (CodeRabbit, Gemini Code Assist, Copilot, Greptile, etc.), performs deep technical root-cause triage, pauses at a **Mandatory Human Approval Gate**, applies approved fixes under strict project quality gates, replies directly to comment threads, and watches the PR until all reviewer agents approve.

**Core Principle:** *Verify before fixing. Explain the bot's rationale. Require human approval before mutating. Reply with technical evidence, never flattery. Loop until clean approval.*

```
PR Raised / Bot Comments
          │
          ▼
┌─────────────────────────────────┐
│ 1. Ingest Feedback & Threads    │ ◄───┐
└────────────────┬────────────────┘     │
                 │                      │
                 ▼                      │
┌─────────────────────────────────┐     │
│ 2. Deep Root-Cause Analysis     │     │
│    (Why bot commented + Verdict)│     │
└────────────────┬────────────────┘     │
                 │                      │
                 ▼                      │
┌─────────────────────────────────┐     │
│ 3. MANDATORY Human Approval     │     │ (Babysit Loop)
│    (Stop & Present Matrix)      │     │
└────────────────┬────────────────┘     │
                 │ [Approved]           │
                 ▼                      │
┌─────────────────────────────────┐     │
│ 4. TDD Fix, Verify, Commit,     │     │
│    Push, Reply & Re-trigger     │     │
└────────────────┬────────────────┘     │
                 │                      │
                 ▼                      │
┌─────────────────────────────────┐     │
│ 5. Watch & Check Bot Status     │─────┘ [New comments / Changes Requested]
└────────────────┬────────────────┘
                 │ [All Bots Approved / 0 Open Comments]
                 ▼
          🎉 PR Ready to Merge
```

---

## When to Use

### Trigger Conditions:
- Immediately after raising a PR following the Superpowers workflow (`brainstorm` $\rightarrow$ `spec` $\rightarrow$ `plan` $\rightarrow$ `implement` $\rightarrow$ `raise PR`).
- Whenever AI reviewer bots have posted comments, change requests, or inline diff notes on a PR.
- When user runs `/babysit` or asks to resolve AI bot reviews on the current branch or PR.

### Do NOT Use When:
- Implementation is still in progress before a PR exists (use `executing-plans` / `test-driven-development` instead).
- Receiving verbal feedback directly from your human partner (use `receiving-code-review` instead).

---

## The 5-Stage Lifecycle

### Stage 1: Context & Feedback Ingestion

1. **Determine Target PR**:
   - Detect from the current Git branch or user input:
     ```bash
     python3 .agents/skills/babysit/scripts/fetch_pr_reviews.py
     ```
   - *Alternative*: Use GitHub MCP tools `get_pull_request`, `get_pull_request_reviews`, `get_pull_request_comments`.
2. **Filter AI Reviewer Bots**:
   - Identify bot authors (e.g. `coderabbitai[bot]`, `gemini-code-assist[bot]`, `github-copilot[bot]`, `greptile-ai[bot]`, etc. See [bot-triggers-and-detection.md](./references/bot-triggers-and-detection.md)).
3. **Group by Discussion Thread**:
   - Group inline review comments by `root_id` / `in_reply_to_id`.
   - Retain only threads where the latest comment is an unreplied/unresolved bot comment.

---

### Stage 2: Technical Triage & Deep Root-Cause Analysis

For each pending bot comment, perform a 5-step technical evaluation:

1. **Extract the Core Claim**:
   - What specific issue, bug, omission, or pattern does the bot allege?
2. **Verify Against Codebase & Project Guidelines**:
   - Read the referenced file and surrounding context.
   - Cross-check with project rules in `AGENTS.md`:
     - *UI & Tokens*: Does the suggestion violate CraftUIKit tokens (e.g. proposing raw `Color.red` instead of `CraftColorTokens`)?
     - *Localization*: Does it adhere to 100% EN/VI bilingual parity in `Localizable.xcstrings`?
     - *Concurrency & Safety*: Does it comply with Swift Concurrency and memory lifecycle rules?
     - *YAGNI & Spec*: Was this intentionally omitted or out-of-scope for the PR?
3. **Explain "Why did the agent comment this way?"**:
   - Diagnose the bot's heuristic, blind spot, or valid discovery:
     - *Example (False Positive)*: "Bot saw a closure without `[weak self]`, missing the fact that `@Observable` view models in SwiftUI lifecycle don't create reference cycles here."
     - *Example (Valid Catch)*: "Bot identified that `Localizable.xcstrings` had an English key with no corresponding Vietnamese entry, violating `AGENTS.md` §4."
4. **Classify the Verdict**:
   - `[VALID - CODE FIX]`: Genuine defect, bug, or rule violation needing code change.
   - `[VALID - TEST ONLY]`: Code is sound, but needs an explicit test to guarantee invariants.
   - `[INVALID - SPEC MISUNDERSTANDING]`: Bot suggested out-of-scope feature (YAGNI) or misread requirements.
   - `[INVALID - ARCHITECTURAL CONFLICT]`: Bot suggested raw styling or anti-pattern forbidden by project rules.
   - `[CLARIFICATION / QUESTION]`: Bot requested explanation.
5. **Formulate Proposed Action & Reply**:
   - For `VALID`: Precise file, line, and implementation diff.
   - For `INVALID`: Strict, non-performative technical rebuttal citing specs, rules, or test evidence (see [reply-guidelines-and-templates.md](./references/reply-guidelines-and-templates.md)).

---

### Stage 3: MANDATORY Human Approval Gate

> [!IMPORTANT]
> **STOP EXECUTION**: You MUST present the **Review Analysis Matrix** to the human developer and wait for explicit approval before modifying any code, committing, pushing, or replying on GitHub.

1. **Render the Review Analysis Matrix**:
   Use the standard format from [review-analysis-matrix-template.md](./references/review-analysis-matrix-template.md):

```markdown
### 📋 PR #<PR_NUMBER> AI Review Analysis Matrix (Cycle #<N>)

| # | Bot | File & Location | Summary of Claim | Why Bot Commented | Verdict | Proposed Action / Fix / Rebuttal |
|---|-----|-----------------|------------------|-------------------|---------|-----------------------------------|
| 1 | `coderabbitai` | `ReflexBlitzView.swift:45` | Missing error state handling | Bot checked local catch block without seeing coordinator handler. | `[INVALID - SPEC MISUNDERSTANDING]` | **Pushback**: Point out coordinator error delegation in `ReflexCoordinator`. |
| 2 | `gemini-code-assist` | `Localizable.xcstrings` | Missing Vietnamese translation | Bot parsed key `app.reflex.streak` with only English entry. | `[VALID - CODE FIX]` | **Fix**: Add `"vi"` entry with `extractionState: "manual"` per `AGENTS.md`. |

---

### 🛡️ Summary of Proposed Actions:
- **Valid Fixes to Implement**: Item #2
- **Pushbacks to Explain**: Item #1

**Awaiting your approval:** Reply `proceed` to apply these actions, or specify adjustments to any item.
```

2. **Wait for User Response**:
   - If user says `proceed` / `approve`: Proceed to Stage 4.
   - If user requests changes (e.g. *"Fix item 1 instead"*): Update proposals and re-confirm.

---

### Stage 4: Post-Approval Execution, Verification & GitHub Sync

Once human approval is granted:

1. **Implement Code Fixes with TDD & Quality Gate**:
   - For all `VALID` items, make changes adhering to `AGENTS.md`:
     - Strict `CraftUIKit` token usage (no hardcoded styles).
     - Strict 100% bilingual parity in `Localizable.xcstrings`.
     - Zero compiler warnings, zero lint errors (`swiftlint`).
     - Run full test suite: `swift test`.
2. **Commit and Push**:
   - Create a clean conventional commit:
     ```bash
     git add <modified-files>
     git commit -m "fix(reflex): resolve AI review comments on translations and edge cases"
     git push origin <branch-name>
     ```
3. **Reply to GitHub Comment Threads**:
   - Reply directly to each comment thread using `reply_pr_thread.py` or GitHub MCP:
     ```bash
     # For valid fixes:
     python3 .agents/skills/babysit/scripts/reply_pr_thread.py \
       --pr <PR_NUMBER> \
       --comment-id <COMMENT_ID> \
       --body "Fixed in commit <COMMIT_SHA>. Added missing translations with 100% parity."

     # For pushbacks:
     python3 .agents/skills/babysit/scripts/reply_pr_thread.py \
       --pr <PR_NUMBER> \
       --comment-id <COMMENT_ID> \
       --body "Keeping current implementation. Per AGENTS.md §3, all styling must use CraftColorTokens rather than raw Color initializers."
     ```
4. **Trigger AI Reviewer Re-Check**:
   - Post trigger command or re-request review via `trigger_bot_rereview.py`:
     ```bash
     python3 .agents/skills/babysit/scripts/trigger_bot_rereview.py --pr <PR_NUMBER> --bot coderabbitai
     python3 .agents/skills/babysit/scripts/trigger_bot_rereview.py --pr <PR_NUMBER> --bot gemini
     ```

---

### Stage 5: Watch & Babysit Loop

1. **Schedule / Wait for Bot Reviews**:
   - Inform user: *"Fixes pushed and replies sent. Entering watch mode for bot re-reviews..."*
   - Set a timer/check using the Antigravity `schedule` tool (e.g. DurationSeconds=120 or recurring check) to poll PR status:
     ```bash
     python3 .agents/skills/babysit/scripts/fetch_pr_reviews.py --pr <PR_NUMBER>
     ```
2. **Evaluate Loop Exit Conditions**:
   - ✅ **DONE (Success)**:
     - All AI reviewer bots have review state `APPROVED`, OR
     - All bot comment threads are resolved and no pending bot comments / `CHANGES_REQUESTED` remain.
     - **Action**: Report success to human developer: *"🎉 All AI reviewer agents have approved or completed reviews with 0 remaining issues. PR is ready to merge!"*
   - 🔄 **CONTINUE LOOP**:
     - New comments posted by AI reviewer bots, or review state is `CHANGES_REQUESTED`.
     - **Action**: Re-enter **Stage 1** for the new cycle (Ingest $\rightarrow$ Deep Analysis $\rightarrow$ Human Approval Gate $\rightarrow$ Fix/Reply $\rightarrow$ Watch).

---

## Anti-Rationalizations & Red Flags

| Rationalization (Excuse) | Reality |
|:---|:---|
| *"The bot is probably right, I'll just change the code without checking"* | Blind implementation causes regressions. Check codebase and `AGENTS.md` first. |
| *"This fix is tiny, I can skip the Human Approval Gate"* | **Never skip the Human Approval Gate.** The human owns the PR and architectural choices. |
| *"I'll reply with 'Thank you, great point!' to be polite"* | Violates non-performative communication rule. State technical facts only. |
| *"I'll post one big top-level PR comment instead of replying to threads"* | Pollutes PR history and doesn't resolve inline discussions. Reply to each thread directly. |
| *"The bot wants raw Color.blue, so I'll add Color.blue to satisfy it"* | Violates `AGENTS.md` §3. Push back with design system token rationale. |

---

## Quick Reference Commands

```bash
# 1. Fetch AI bot comments
python3 .agents/skills/babysit/scripts/fetch_pr_reviews.py --pr <PR_NUMBER>

# 2. Reply to inline thread
python3 .agents/skills/babysit/scripts/reply_pr_thread.py --pr <PR_NUMBER> --comment-id <ID> --body "<MESSAGE>"

# 3. Trigger bot re-review
python3 .agents/skills/babysit/scripts/trigger_bot_rereview.py --pr <PR_NUMBER> --bot coderabbitai
```

---

## References

- [Review Analysis Matrix Template](./references/review-analysis-matrix-template.md)
- [AI Reviewer Bots Detection & Triggers](./references/bot-triggers-and-detection.md)
- [Technical Reply Guidelines & Templates](./references/reply-guidelines-and-templates.md)
