# CraftUIKit Folder Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure CraftUIKit's Components/ directory from flat files to domain-cohesive sub-folders, co-locating models with their component clusters.

**Architecture:** Pure file moves using `git mv` — no source code changes. SPM auto-discovers all `.swift` files under `Sources/` regardless of folder depth, so moves are transparent to the build system.

**Tech Stack:** Swift Package Manager, Git

**Spec:** `docs/superpowers/specs/2026-08-26-craftui-folder-restructure-design.md`

## Global Constraints

- All moves MUST use `git mv` to preserve file history.
- No source code modifications — only file relocations.
- `Models/` must retain `CraftActivityModels.swift` (shared across clusters).
- Build and tests must pass after every task.

---

### Task 1: Create sub-folder structure

**Files:**
- Create directories: `Containers/LearningPath/`, `Containers/Cards/`, `Containers/Progress/`, `Containers/Streak/`, `Containers/Activity/`, `Containers/VoiceMatch/`, `Feedback/Countdown/`

- [ ] **Step 1: Create all target sub-folders**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components
mkdir -p Containers/LearningPath
mkdir -p Containers/Cards
mkdir -p Containers/Progress
mkdir -p Containers/Streak
mkdir -p Containers/Activity
mkdir -p Containers/VoiceMatch
mkdir -p Feedback/Countdown
```

---

### Task 2: Move LearningPath cluster (13 files)

**Files:**
- Move: 11 files from `Containers/` → `Containers/LearningPath/`
- Move: 2 files from `Models/` → `Containers/LearningPath/`

- [ ] **Step 1: Move 11 Containers files into LearningPath/**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit
git mv Components/Containers/CraftLearningPath.swift Components/Containers/LearningPath/
git mv Components/Containers/CraftLearningPathAnimations.swift Components/Containers/LearningPath/
git mv Components/Containers/CraftLessonSectionView.swift Components/Containers/LearningPath/
git mv Components/Containers/CraftLessonRow.swift Components/Containers/LearningPath/
git mv Components/Containers/CraftLessonNode.swift Components/Containers/LearningPath/
git mv Components/Containers/CraftLessonDetailSheet.swift Components/Containers/LearningPath/
git mv Components/Containers/CraftPathNode.swift Components/Containers/LearningPath/
git mv Components/Containers/CraftNodeConnector.swift Components/Containers/LearningPath/
git mv Components/Containers/CraftSnakePathGeometry.swift Components/Containers/LearningPath/
git mv Components/Containers/CraftPathUnlockSurge.swift Components/Containers/LearningPath/
git mv Components/Containers/CraftJourneySection.swift Components/Containers/LearningPath/
```

- [ ] **Step 2: Co-locate domain-specific models**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit
git mv Models/CraftLearningPathModels.swift Components/Containers/LearningPath/
git mv Models/CraftJourneyModels.swift Components/Containers/LearningPath/
```

- [ ] **Step 3: Verify build**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
swift build --package-path CraftUIKit 2>&1 | tail -5
```
Expected: Build succeeded

- [ ] **Step 4: Commit**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
git add -A
git commit -m "refactor(CraftUIKit): group LearningPath cluster into sub-folder

Move 11 view files + 2 model files into Containers/LearningPath/.
Co-locate CraftLearningPathModels and CraftJourneyModels with their views."
```

---

### Task 3: Move Cards cluster (5 files)

**Files:**
- Move: 5 files from `Containers/` → `Containers/Cards/`

- [ ] **Step 1: Move card files**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit
git mv Components/Containers/CraftCard.swift Components/Containers/Cards/
git mv Components/Containers/CraftActionCard.swift Components/Containers/Cards/
git mv Components/Containers/CraftFlipCard.swift Components/Containers/Cards/
git mv Components/Containers/CraftListRow.swift Components/Containers/Cards/
git mv Components/Containers/CraftEmptyState.swift Components/Containers/Cards/
```

- [ ] **Step 2: Verify build**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
swift build --package-path CraftUIKit 2>&1 | tail -5
```
Expected: Build succeeded

- [ ] **Step 3: Commit**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
git add -A
git commit -m "refactor(CraftUIKit): group Cards cluster into sub-folder

Move CraftCard, CraftActionCard, CraftFlipCard, CraftListRow,
CraftEmptyState into Containers/Cards/."
```

---

### Task 4: Move Progress cluster (5 files)

**Files:**
- Move: 5 files from `Containers/` → `Containers/Progress/`

- [ ] **Step 1: Move progress files**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit
git mv Components/Containers/CraftProgressBar.swift Components/Containers/Progress/
git mv Components/Containers/CraftProgressRing.swift Components/Containers/Progress/
git mv Components/Containers/CraftSegmentedBar.swift Components/Containers/Progress/
git mv Components/Containers/CraftStepNode.swift Components/Containers/Progress/
git mv Components/Containers/CraftStepProgressIndicator.swift Components/Containers/Progress/
```

- [ ] **Step 2: Verify build**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
swift build --package-path CraftUIKit 2>&1 | tail -5
```
Expected: Build succeeded

- [ ] **Step 3: Commit**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
git add -A
git commit -m "refactor(CraftUIKit): group Progress cluster into sub-folder

Move CraftProgressBar, CraftProgressRing, CraftSegmentedBar,
CraftStepNode, CraftStepProgressIndicator into Containers/Progress/."
```

---

### Task 5: Move Streak cluster (4 files, cross-category)

**Files:**
- Move: `CraftStreakCard.swift` from `Containers/` → `Containers/Streak/`
- Move: `CraftStreakBadge.swift` from `Atoms/` → `Containers/Streak/`
- Move: `CraftStreakCelebrationSheet.swift` from `Feedback/` → `Containers/Streak/`
- Move: `CraftStreakModels.swift` from `Models/` → `Containers/Streak/`

- [ ] **Step 1: Move streak files from 4 different locations**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit
git mv Components/Containers/CraftStreakCard.swift Components/Containers/Streak/
git mv Components/Atoms/CraftStreakBadge.swift Components/Containers/Streak/
git mv Components/Feedback/CraftStreakCelebrationSheet.swift Components/Containers/Streak/
git mv Models/CraftStreakModels.swift Components/Containers/Streak/
```

- [ ] **Step 2: Verify build**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
swift build --package-path CraftUIKit 2>&1 | tail -5
```
Expected: Build succeeded

- [ ] **Step 3: Commit**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
git add -A
git commit -m "refactor(CraftUIKit): group Streak cluster into sub-folder

Consolidate streak-related files from 4 directories (Atoms, Containers,
Feedback, Models) into Containers/Streak/ for domain cohesion."
```

---

### Task 6: Move Activity, VoiceMatch, and Countdown clusters (4 files)

**Files:**
- Move: `CraftActivityTrackerCard.swift` → `Containers/Activity/`
- Move: `CraftVoiceMatchCard.swift` → `Containers/VoiceMatch/`
- Move: `CraftCountdownOverlay.swift` → `Feedback/Countdown/`
- Move: `CraftCountdownTimerBar.swift` → `Feedback/Countdown/`

- [ ] **Step 1: Move remaining files**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit
git mv Components/Containers/CraftActivityTrackerCard.swift Components/Containers/Activity/
git mv Components/Containers/CraftVoiceMatchCard.swift Components/Containers/VoiceMatch/
git mv Components/Feedback/CraftCountdownOverlay.swift Components/Feedback/Countdown/
git mv Components/Feedback/CraftCountdownTimerBar.swift Components/Feedback/Countdown/
```

- [ ] **Step 2: Verify build**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
swift build --package-path CraftUIKit 2>&1 | tail -5
```
Expected: Build succeeded

- [ ] **Step 3: Commit**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
git add -A
git commit -m "refactor(CraftUIKit): group Activity, VoiceMatch, Countdown clusters

Move CraftActivityTrackerCard into Containers/Activity/,
CraftVoiceMatchCard into Containers/VoiceMatch/,
CraftCountdownOverlay and CraftCountdownTimerBar into Feedback/Countdown/."
```

---

### Task 7: Final verification and structural audit

- [ ] **Step 1: Verify Containers/ has no loose .swift files**

```bash
ls /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Containers/*.swift 2>&1
```
Expected: `No such file or directory` (all files moved to sub-folders)

- [ ] **Step 2: Verify Models/ only has shared model**

```bash
ls /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Models/
```
Expected: Only `CraftActivityModels.swift`

- [ ] **Step 3: Print final directory tree**

```bash
find /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit -type f -name "*.swift" | sort | sed 's|.*/CraftUIKit/Sources/CraftUIKit/||'
```

- [ ] **Step 4: Run full test suite**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
swift test --package-path CraftUIKit 2>&1 | tail -20
```
Expected: All tests pass

- [ ] **Step 5: Build main app to verify no downstream breakage**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
xcodebuild -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -10
```
Expected: Build succeeded

- [ ] **Step 6: Final commit**

```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
git add -A
git commit -m "refactor(CraftUIKit): complete folder restructure

CraftUIKit Components/ reorganized from flat files to domain-cohesive
sub-folders. 33 files moved across 7 sub-folders. Zero code changes.
All builds and tests pass."
```
