# CraftUIKit Folder Restructure — Cluster Sub-folders Design

## Problem Statement

CraftUIKit's `Components/` directory has grown to 56 files with large component clusters scattered across multiple categories. Related files are split across 3–4 different directories, making the codebase hard to review, maintain, and explore.

**Worst offenders:**
- **Containers/** is a flat dump of 24 files — LearningPath (6 files), Lesson (4 files), Progress (5 files), and miscellaneous cards all live side-by-side with no grouping.
- **Streak** cluster is split across 4 directories: `Atoms/CraftStreakBadge`, `Containers/CraftStreakCard`, `Feedback/CraftStreakCelebrationSheet`, `Models/CraftStreakModels`.
- **Models/** is fully separated from the components they serve, despite most models being domain-specific to a single component cluster.

The only example of correct sub-grouping is `Feedback/Speech/` (5 co-located files), which proves the pattern works.

## Approved Approach: Cluster Sub-folders (Domain Cohesion)

**Principle:** Prioritize domain cohesion over strict type classification. Each complex component cluster gets its own sub-folder containing ALL related files — views, models, animations, sub-components — regardless of their "atomic level". Simple standalone components remain flat within their category.

**Key decisions:**
1. **Hybrid strategy** — Keep Atoms/Controls/Containers/Feedback/Navigation/Overlays hierarchy, but add sub-folders for clusters.
2. **Domain-specific models co-locate** with their component cluster. Only truly shared models stay in `Models/`.
3. **Cross-category moves allowed** when domain cohesion demands it (e.g., `CraftStreakBadge` moves from Atoms → `Containers/Streak/`).

---

## Target Folder Structure

```
CraftUIKit/Sources/CraftUIKit/
├── Components/
│   ├── Atoms/
│   │   ├── CraftBadge.swift
│   │   ├── CraftDivider.swift
│   │   ├── CraftIcon.swift
│   │   ├── CraftIconButton.swift
│   │   ├── CraftPulsingAuraRing.swift
│   │   ├── CraftSpinner.swift
│   │   └── CraftText.swift
│   │
│   ├── Containers/
│   │   ├── Cards/
│   │   │   ├── CraftCard.swift
│   │   │   ├── CraftActionCard.swift
│   │   │   ├── CraftFlipCard.swift
│   │   │   ├── CraftListRow.swift
│   │   │   └── CraftEmptyState.swift
│   │   ├── LearningPath/
│   │   │   ├── CraftLearningPath.swift
│   │   │   ├── CraftLearningPathAnimations.swift
│   │   │   ├── CraftLearningPathModels.swift
│   │   │   ├── CraftJourneyModels.swift
│   │   │   ├── CraftJourneySection.swift
│   │   │   ├── CraftLessonSectionView.swift
│   │   │   ├── CraftLessonRow.swift
│   │   │   ├── CraftLessonNode.swift
│   │   │   ├── CraftLessonDetailSheet.swift
│   │   │   ├── CraftPathNode.swift
│   │   │   ├── CraftNodeConnector.swift
│   │   │   ├── CraftSnakePathGeometry.swift
│   │   │   └── CraftPathUnlockSurge.swift
│   │   ├── Progress/
│   │   │   ├── CraftProgressBar.swift
│   │   │   ├── CraftProgressRing.swift
│   │   │   ├── CraftSegmentedBar.swift
│   │   │   ├── CraftStepNode.swift
│   │   │   └── CraftStepProgressIndicator.swift
│   │   ├── Streak/
│   │   │   ├── CraftStreakCard.swift
│   │   │   ├── CraftStreakBadge.swift
│   │   │   ├── CraftStreakCelebrationSheet.swift
│   │   │   └── CraftStreakModels.swift
│   │   ├── Activity/
│   │   │   └── CraftActivityTrackerCard.swift
│   │   └── VoiceMatch/
│   │       └── CraftVoiceMatchCard.swift
│   │
│   ├── Controls/
│   │   ├── CraftButton.swift
│   │   ├── CraftChoiceCard.swift
│   │   ├── CraftPill.swift
│   │   ├── CraftSearchBar.swift
│   │   ├── CraftStepper.swift
│   │   ├── CraftTextField.swift
│   │   └── CraftToggle.swift
│   │
│   ├── Feedback/
│   │   ├── CraftCelebrationSheet.swift
│   │   ├── CraftFeedbackSheet.swift
│   │   ├── CraftSparkleView.swift
│   │   ├── CraftSymbolEffects.swift
│   │   ├── CraftWaveformView.swift
│   │   ├── Countdown/
│   │   │   ├── CraftCountdownOverlay.swift
│   │   │   └── CraftCountdownTimerBar.swift
│   │   └── Speech/
│   │       ├── CraftSpeechModels.swift
│   │       ├── CraftSpeechWordFlowLayout.swift
│   │       ├── CraftSpeechWordTokenView.swift
│   │       ├── CraftTactileMicHubView.swift
│   │       └── CraftTextMatchEngine.swift
│   │
│   ├── Navigation/
│   │   └── CraftFloatingTabBar.swift
│   │
│   └── Overlays/
│       ├── CraftBottomSheet.swift
│       ├── CraftDialog.swift
│       └── CraftToast.swift
│
├── Environment/
│   ├── CraftLocalized.swift
│   └── CraftThemeEnvironment.swift
│
├── Models/
│   └── CraftActivityModels.swift
│
├── Modifiers/
│   ├── CraftMotionGuardModifier.swift
│   ├── CraftSquashAndStretchModifier.swift
│   ├── CraftSurfaceModifier.swift
│   ├── PressEffectModifier.swift
│   ├── ShimmerModifier.swift
│   └── TypographyModifier.swift
│
├── Previews/
│   └── CraftCatalogView.swift
│
├── Resources/
│   └── Localizable.xcstrings
│
└── Tokens/
    ├── CraftAnimationTokens.swift
    ├── CraftColorTokens.swift
    ├── CraftDepthTokens.swift
    ├── CraftGlassTokens.swift
    ├── CraftGradientTokens.swift
    ├── CraftOpacityTokens.swift
    ├── CraftRadiusTokens.swift
    ├── CraftShadowTokens.swift
    ├── CraftSpacingTokens.swift
    ├── CraftSurfaceStyle.swift
    ├── CraftSymbol.swift
    ├── CraftTheme.swift
    ├── CraftTypographyTokens.swift
    └── Themes/
        └── CraftDefaultTheme.swift
```

---

## Detailed File Movement Manifest

### Moves INTO `Containers/LearningPath/`
Files already in `Containers/` — just move into sub-folder:
| File | Current Location | New Location |
|:---|:---|:---|
| `CraftLearningPath.swift` | `Containers/` | `Containers/LearningPath/` |
| `CraftLearningPathAnimations.swift` | `Containers/` | `Containers/LearningPath/` |
| `CraftLessonSectionView.swift` | `Containers/` | `Containers/LearningPath/` |
| `CraftLessonRow.swift` | `Containers/` | `Containers/LearningPath/` |
| `CraftLessonNode.swift` | `Containers/` | `Containers/LearningPath/` |
| `CraftLessonDetailSheet.swift` | `Containers/` | `Containers/LearningPath/` |
| `CraftPathNode.swift` | `Containers/` | `Containers/LearningPath/` |
| `CraftNodeConnector.swift` | `Containers/` | `Containers/LearningPath/` |
| `CraftSnakePathGeometry.swift` | `Containers/` | `Containers/LearningPath/` |
| `CraftPathUnlockSurge.swift` | `Containers/` | `Containers/LearningPath/` |
| `CraftJourneySection.swift` | `Containers/` | `Containers/LearningPath/` |

Co-located models from `Models/`:
| File | Current Location | New Location |
|:---|:---|:---|
| `CraftLearningPathModels.swift` | `Models/` | `Containers/LearningPath/` |
| `CraftJourneyModels.swift` | `Models/` | `Containers/LearningPath/` |

### Moves INTO `Containers/Cards/`
| File | Current Location | New Location |
|:---|:---|:---|
| `CraftCard.swift` | `Containers/` | `Containers/Cards/` |
| `CraftActionCard.swift` | `Containers/` | `Containers/Cards/` |
| `CraftFlipCard.swift` | `Containers/` | `Containers/Cards/` |
| `CraftListRow.swift` | `Containers/` | `Containers/Cards/` |
| `CraftEmptyState.swift` | `Containers/` | `Containers/Cards/` |

### Moves INTO `Containers/Progress/`
| File | Current Location | New Location |
|:---|:---|:---|
| `CraftProgressBar.swift` | `Containers/` | `Containers/Progress/` |
| `CraftProgressRing.swift` | `Containers/` | `Containers/Progress/` |
| `CraftSegmentedBar.swift` | `Containers/` | `Containers/Progress/` |
| `CraftStepNode.swift` | `Containers/` | `Containers/Progress/` |
| `CraftStepProgressIndicator.swift` | `Containers/` | `Containers/Progress/` |

### Moves INTO `Containers/Streak/` (cross-category)
| File | Current Location | New Location |
|:---|:---|:---|
| `CraftStreakCard.swift` | `Containers/` | `Containers/Streak/` |
| `CraftStreakBadge.swift` | **`Atoms/`** | `Containers/Streak/` |
| `CraftStreakCelebrationSheet.swift` | **`Feedback/`** | `Containers/Streak/` |
| `CraftStreakModels.swift` | **`Models/`** | `Containers/Streak/` |

### Moves INTO `Containers/Activity/`
| File | Current Location | New Location |
|:---|:---|:---|
| `CraftActivityTrackerCard.swift` | `Containers/` | `Containers/Activity/` |

### Moves INTO `Containers/VoiceMatch/`
| File | Current Location | New Location |
|:---|:---|:---|
| `CraftVoiceMatchCard.swift` | `Containers/` | `Containers/VoiceMatch/` |

### Moves INTO `Feedback/Countdown/`
| File | Current Location | New Location |
|:---|:---|:---|
| `CraftCountdownOverlay.swift` | `Feedback/` | `Feedback/Countdown/` |
| `CraftCountdownTimerBar.swift` | `Feedback/` | `Feedback/Countdown/` |

### Deletions from `Models/`
After co-locating domain-specific models, `Models/` retains only:
- `CraftActivityModels.swift` — shared across Streak, Activity, and Celebration components.

**Removed from `Models/`:**
- `CraftLearningPathModels.swift` → `Containers/LearningPath/`
- `CraftJourneyModels.swift` → `Containers/LearningPath/`
- `CraftStreakModels.swift` → `Containers/Streak/`

---

## Dependency Analysis Summary

### Why co-location is safe
All files are within the same SPM module (`CraftUIKit`). Swift Package Manager compiles all `.swift` files under `Sources/` regardless of folder depth. **No imports, access levels, or build settings need to change.**

### Cross-cluster dependencies
| Dependency | Impact |
|:---|:---|
| `CraftStreakModels` depends on `CraftActivityModels` | Safe — `CraftActivityModels` stays in shared `Models/` |
| `CraftStreakCard` uses `CraftActivityDay` from `CraftActivityModels` | Safe — same module, no import needed |
| `CraftLearningPath` uses `.craftConfetti` from `CraftSparkleView` (Feedback) | Safe — same module cross-reference |
| `CraftLessonDetailSheet` uses `CraftBadge` (Atoms), `CraftButton` (Controls), `CraftCard` (Cards) | Safe — same module cross-reference |
| `NodeAnchorPreferenceKey` defined in `CraftLessonSectionView`, used by `CraftNodeConnector`, `CraftJourneySection` | Safe — all three co-locate in `LearningPath/` |

### No code changes required
This refactor is **purely structural** — only file moves, no source code modifications. All `public` types, extensions, and protocols remain accessible within the module.

---

## Risk Assessment

| Risk | Mitigation |
|:---|:---|
| Xcode project references break | SPM-based — folder structure auto-discovered. No `.pbxproj` file references to update. |
| Git history fragmentation | Use `git mv` for all moves to preserve file history. |
| `CraftCatalogView.swift` (143KB preview file) breaks | No changes needed — it references types by name, not by file path. |
| Future confusion about where to put new components | Document the grouping convention in AGENTS.md or a README. |

---

## Verification Plan

### Build Verification
```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app
swift build --package-path CraftUIKit
```

### Test Verification
```bash
swift test --package-path CraftUIKit
```

### Structural Verification
```bash
# Verify no files left in flat Containers/
ls CraftUIKit/Sources/CraftUIKit/Components/Containers/*.swift
# Should return: no files (all moved to sub-folders)

# Verify Models/ only has shared models
ls CraftUIKit/Sources/CraftUIKit/Models/
# Should return: CraftActivityModels.swift only
```
