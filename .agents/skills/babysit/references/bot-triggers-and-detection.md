# AI Reviewer Bots Detection and Re-Review Triggers

This reference details the detection patterns, review behavior, and command triggers for popular AI Code Reviewers on GitHub.

---

## 1. Known AI Bot Registry

| Bot Name | GitHub Username Pattern | Trigger / Re-Review Command | Behavior / Capabilities |
|:---|:---|:---|:---|
| **CodeRabbit** | `coderabbitai`, `coderabbitai[bot]` | `@coderabbitai review`<br>`@coderabbitai full review`<br>`@coderabbitai resolve` | Posts comprehensive review summaries, walkthroughs, and inline line-by-line diff comments. |
| **Gemini Code Assist** | `gemini-code-assist[bot]`, `google-gemini[bot]` | `@gemini-code-assist review` | Inspects code changes, flags Swift concurrency issues, security, and missing error paths. |
| **GitHub Copilot** | `copilot[bot]`, `github-copilot[bot]` | `@github-copilot review` | Reviews inline code changes, recommends idiomatic patterns and edge cases. |
| **Greptile** | `greptile-ai[bot]`, `greptile` | `@greptile review` | Uses full codebase context to find architectural mismatch and breaking callers. |
| **Qodo (Codium)** | `qodo-cover-agent[bot]`, `qodo[bot]` | `@qodo-cover-agent review` | Focuses heavily on edge case test coverage and behavior invariants. |
| **Sourcery** | `sourcery-ai[bot]` | `@sourcery-ai review` | Suggests refactorings, duplication elimination, and complexity reduction. |
| **Generic Bot Pattern** | `.*\[bot\]$`, `.*-bot$` | `@<bot-name> review` | Falls back to pinging the bot or re-requesting review via GitHub API. |

---

## 2. Re-Review Trigger Methods

### Method A: PR Top-Level Comment (Slash / Mention Command)
Most bots listen to webhook events on new issue comments containing their specific trigger command.
Example:
```bash
python3 .agents/skills/babysit/scripts/trigger_bot_rereview.py --pr 42 --bot coderabbitai --command "@coderabbitai full review"
```

### Method B: GitHub Re-Request Review API
For bots configured as official GitHub Reviewers:
```bash
python3 .agents/skills/babysit/scripts/trigger_bot_rereview.py --pr 42 --bot coderabbitai --request-review
```
Endpoint: `POST /repos/{owner}/{repo}/pulls/{pr}/requested_reviewers`

### Method C: Push Commit Trigger
Almost all AI bots automatically re-trigger on new commit pushes (`git push origin <branch>`). 
However, mentioning the bot with a trigger command ensures immediate re-evaluation of specific threads.

---

## 3. Resolving Comment Threads on GitHub

1. **Inline Reply**: Always reply inside the specific review comment thread:
   ```bash
   python3 .agents/skills/babysit/scripts/reply_pr_thread.py --pr 42 --comment-id 123456789 --body "Fixed in commit 8a3f91b. Added Swift Testing invariant."
   ```
2. **CodeRabbit Resolve Command**:
   If CodeRabbit posted an inline comment, you can reply directly in the thread:
   ```text
   @coderabbitai resolve
   Fixed in commit 8a3f91b.
   ```
   This signals CodeRabbit to automatically collapse or resolve the discussion thread.
