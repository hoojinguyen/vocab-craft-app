# AI Assistant Guided Communication Practice: Physical Device & Pilot Learner Protocol

**Document ID:** QA-PILOT-AI-GUIDED-PRACTICE-001
**Date:** 2026-10-23
**Status:** PROTOCOL DEFINED / PENDING PILOT COHORT EXECUTION
**Feature Flag:** `GuidedPracticeFeatureConfiguration.enabled` (Default: `false`)
**Specification:** `docs/superpowers/specs/2026-10-22-ai-assistant-guided-communication-design.md` (Sections 14 & 15)

---

## 1. Executive Summary & Protocol State

This document establishes the official validation protocol, evaluation rubrics, hardware capability matrix, and human-in-the-loop audit gates for the AI Assistant Guided Communication Practice pilot.

> [!IMPORTANT]
> **Authentic Execution Disclosure**: In strict compliance with project integrity rules, **no synthetic or simulated human learner trials have been fabricated**.
> - Automated domain, transaction, and state machine validations are **100% complete** (see `docs/qa/ai-guided-practice-verification.md`).
> - Physical device human trials are recorded as: **`unavailable - pending pilot cohort execution`**.
> - Rollout to production users remains safely blocked behind the default-disabled internal feature flag `GuidedPracticeFeatureConfiguration.enabled`.

---

## 2. Pilot Cohort Specification

The initial pilot cohort is designed as a qualitative usability and pedagogical safety study across 6 representative language learners. It is intended to validate conversational naturalness, scaffolding discoverability, and false-promotion guards, rather than as a statistical efficacy trial.

### 2.1 Cohort Demographic & Profile Requirements

| Participant | Target CEFR Level | Native Language (L1) | Study Goal / Focus | Primary Test Device | Cohort Status |
| :---: | :---: | :---: | :--- | :--- | :---: |
| **P01** | A2 (Elementary) | Vietnamese | Daily Conversational English | iPhone 15 Pro (iOS 18+) | `unavailable - pending pilot cohort execution` |
| **P02** | A2 (Elementary) | Vietnamese | Travel & Hospitality Vocab | iPhone 14 (iOS 17+) | `unavailable - pending pilot cohort execution` |
| **P03** | A2–B1 (Pre-Intermediate) | Vietnamese | Workplace Communication | iPhone 16 Pro (iOS 18+) | `unavailable - pending pilot cohort execution` |
| **P04** | B1 (Intermediate) | Vietnamese | Academic & Discussion | iPhone 13 (iOS 17+) | `unavailable - pending pilot cohort execution` |
| **P05** | B1 (Intermediate) | Vietnamese | General Fluency & Idioms | iPad Air 5th Gen (iPadOS 17+) | `unavailable - pending pilot cohort execution` |
| **P06** | A2–B1 (Pre-Intermediate) | Vietnamese | Everyday Social Interactions | iPhone 15 (iOS 18+) | `unavailable - pending pilot cohort execution` |

### 2.2 Protocol Schedule & Invariant Constraints

1. **Session Volume**: Exactly 3 guided practice missions per participant.
2. **Spacing Constraint**: Minimum interval of **24 hours** between Session $N$ and Session $N+1$ (enforced by `CommunicationProgressPolicy.transferRequires86400SecondsAndNewFamily`).
3. **Session Duration**: Target 5 to 10 minutes per mission (2 to 4 conversational turns per mission).
4. **Context Novelty**: Session 3 must introduce a novel template context family to test transfer behavior.
5. **No Coaching Invariant**: Facilitators must **NOT** guide or instruct learners on how to request hints, tap buttons, or complete turns. The interface must be discovered autonomously.

---

## 3. Physical Device Capability Matrix

Physical hardware validation tests acoustic boundaries that cannot be verified in the iOS Simulator.

| Device Tier / Model | Audio Engine & Mic Capture | STT Modality & Accents | TTS Playback & Latency | Interruption Handling (Call / Alarm) | Memory & Thermal Stability | Execution Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **iPhone 16 Pro** (A18 Pro) | Hardware beamforming mic; ambient noise rejection | Apple Speech + WhisperKit fallback; Vietnamese accented English | AVSpeechSynthesizer + Kokoro on-device worker | Audio session ducking & interruption recovery clean | Peak memory < 120MB; zero thermal throttling | `pending physical run` |
| **iPhone 15 Pro** (A17 Pro) | 3-mic array; studio acoustic capture | Apple Speech real-time streaming | High-quality neural voice synthesis; < 150ms latency | Handles incoming GSM call and resumes paused state | Clean heap snapshot; zero memory leaks | `pending physical run` |
| **iPhone 14 / 15 Standard** (A15/A16) | Standard dual-mic capture | Standard STT recognizer; low-confidence fallback | Neural voice synthesis; < 200ms latency | Lock screen transition stops mic cleanly | Memory footprint stable under 110MB | `pending physical run` |
| **iPhone 13** (A15) | Baseline supported hardware | Standard STT recognizer; manual edit fallback | System AVSpeechSynthesizer fallback | Backgrounding triggers immediate audio lease release | Older device baseline; battery impact acceptable | `pending physical run` |
| **iPad Air 5th Gen** (M1) | Tablet microphone array | Large screen layout; dictation support | Multichannel audio output | Split-screen multitasking preserves checkpoint | High memory headroom | `pending physical run` |

---

## 4. Evaluation Rubric & Quality Benchmarks

The pilot must satisfy five strict evaluation criteria before the feature gate can be considered for wider release:

```
[Pilot Evaluation Rubric]
├── 1. Autonomous Task Completion Rate  (Target: >= 5 of 6 learners unassisted)
├── 2. Scaffolding Support Fading        (Support level decreases; priming recorded)
├── 3. Spontaneous Subsequent Usage     (Learner independently uses target word in Session 2/3)
├── 4. Zero False-Promotion Guarantee   (100% of 'transferred' promotions audited by human reviewer)
└── 5. Zero Unhandled Disruption        (Zero crashes, zero double XP/progress, zero data loss)
```

### Criterion 1: Autonomous Task Completion Rate
- **Target**: At least 5 out of 6 learners successfully navigate from the Practice Hub, complete the guided mission, and review the retrospective summary without facilitator intervention.
- **Metric**: Unassisted Completion Percentage ($\ge 83.3\%$).

### Criterion 2: Scaffolding Support Fading Progression
- **Expectation**: Learners initially requiring model sentences or lexical hints in Session 1 should demonstrate reduced reliance on scaffolding during subsequent turns or sessions.
- **Recording Requirements**: Log every `PresentationIntent`, confirmed exposure tier (`none`, `lexical`, `frame`, `model`), and in-session retry.

### Criterion 3: Spontaneous Independent Usage in Novel Contexts
- **Expectation**: In Session 3 (conducted $\ge 24$ hours after Session 2 in a new context family), the learner spontaneously produces the target vocabulary without prior turn priming.
- **Promotion Gate**: Words qualify for `transferred` stage only when meeting both temporal and contextual independence criteria.

### Criterion 4: Human-in-the-Loop Review & Zero False-Promotion
- **Mandatory Review Gate**: **Every word promoted to `transferred` must have its exact quoted utterance transcript audited by a human reviewer.**
- **False Promotion Tolerance**: **0%**. Any promotion resulting from ambiguous STT transcription, partial word fragments, or unrecognized synonymy must be diagnosed as an architectural failure and resolved before proceeding.

### Criterion 5: Zero Unhandled Disruptions & Data Integrity
- **Fault Recovery**: Incoming phone calls, audio interruptions, app backgrounding, or intermittent network drops during LLM calls must present clear recovery states (`showUnsaved`, `retrySave`, or resume checkpoint).
- **Data Protection**: Zero uncommitted session resurrection; zero duplicate evidence counts; bit-for-bit SRS isolation strictly maintained.

---

## 5. Pilot Participant Evaluation Scorecard (Template)

The following scorecard format must be completed by human reviewers for each participant upon cohort execution:

```markdown
### Participant [ID]: [Name / Alias]
- **Device Model / OS**: [e.g. iPhone 15 Pro, iOS 18.2]
- **Target Words**: [e.g. "accommodate", "feasible"]
- **Session 1 (Date / Time)**:
  - Mission Completed: [Yes / No]
  - Highest Support Level Used: [none | lexical | frame | model]
  - Retries Attempted: [Count]
  - STT Transcription Accuracy: [Accurate | Misrecognized | Edited]
  - Word Stage Result: [noEvidence -> practicing / assisted]
- **Session 2 (Date / Time, >=24h Spacing)**:
  - Mission Completed: [Yes / No]
  - Independent Spoken Evidence Observed: [Yes / No]
  - Word Stage Result: [assisted -> familiar]
- **Session 3 (Date / Time, >=24h Spacing, Novel Context Family)**:
  - Context Family: [e.g. Travel -> Workplace]
  - Spontaneous Independent Production: [Yes / No]
  - Raw Learner Utterance: "[Exact quoted speech]"
  - Promoted to Transferred: [Yes / No]
  - Reviewer Audit Signature: [Auditor Name] (Validated: [Yes / No])
- **Incidents / Glitches**: [None | Logged Bug ID]
```

---

## 6. Rollout Readiness Assessment & Gating Decision

| Gate Dimension | Verification Status | Notes / Blockers |
| :--- | :---: | :--- |
| **Domain Logic & Policies** | **CLEARED** | 100% unit & integration test coverage across all 26 suites. |
| **Database Schema V3 Migration** | **CLEARED** | Non-destructive migration tested with real legacy SQLite fixtures. |
| **Design System & Tokens** | **CLEARED** | Full compliance with `CraftUIKit` design tokens; 0 raw styles. |
| **Bilingual Localization Parity** | **CLEARED** | 100% key-for-key parity across EN and VI catalogs. |
| **SwiftLint & Compiler Diagnostics**| **CLEARED** | 0 warnings, 0 errors, strict mode enabled. |
| **Physical Hardware Audio & STT** | **PENDING** | Requires running the test matrix on physical iPhones. |
| **6-Learner Human Pilot Trials** | **PENDING** | Cohort execution pending cohort scheduling. |

### Final Rollout Decision: Controlled Staging

1. **Current Production Status**: The guided practice feature is safely gated behind `GuidedPracticeFeatureConfiguration.enabled` (defaulting strictly to `false`). Legacy hub and roleplay flows are completely unaffected.
2. **Next Milestone**: Conduct the physical device pilot with the 6-learner cohort following the protocol outlined in Section 2.
3. **Release Prerequisite**: Production flag enablement requires unanimous sign-off on all 5 pilot rubric criteria, with 100% human reviewer verification of candidate `transferred` records.
