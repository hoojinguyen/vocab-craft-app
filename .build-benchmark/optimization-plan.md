# Xcode Build Optimization Plan


## Project Context

- **Project:** `VocabCraftApp.xcodeproj`
- **Scheme:** `VocabCraftApp`
- **Configuration:** `Debug`
- **Destination:** `platform=iOS Simulator,name=iPhone 17`
- **Xcode:** Xcode 26.6 Build version 17F113
- **macOS:** macOS-26.6.1-arm64-arm-64bit-Mach-O
- **Date:** 2026-08-23T16:31:11.276080+00:00
- **Benchmark artifact:** `.build-benchmark/20260823T162900Z-vocabcraftapp.json`

## Baseline Benchmarks

| Metric | Clean | Incremental |
|--------|-------|-------------|
| Median | 24.799s | 1.117s |
| Min | 24.659s | 1.066s |
| Max | 26.272s | 1.504s |
| Runs | 3 | 3 |

### Clean Build Timing Summary

> **Note:** These are aggregated task times across all CPU cores. Because Xcode runs many tasks in parallel, these totals typically exceed the actual build wait time shown above. A large number here does not mean it is blocking your build.

| Category | Tasks | Seconds |
|----------|------:|--------:|
| SwiftCompile | 30 | 119.088s |
| SwiftEmitModule | 3 | 6.090s |
| SwiftDriver | 3 | 1.273s |
| Ld | 3 | 0.884s |
| GenerateDSYMFile | 2 | 0.503s |
| ValidateEmbeddedBinary | 1 | 0.466s |
| ExtractAppIntentsMetadata | 3 | 0.124s |
| CodeSign | 2 | 0.072s |
| AppIntentsSSUTraining | 2 | 0.053s |
| CompileXCStrings | 1 | 0.043s |
| RegisterExecutionPolicyException | 3 | 0.040s |
| Copy | 14 | 0.034s |
| CopySwiftLibs | 1 | 0.026s |
| ProcessProductPackagingDER | 4 | 0.021s |
| CopyStringsFile | 2 | 0.009s |
| ProcessInfoPlistFile | 2 | 0.008s |
| Touch | 2 | 0.006s |
| WriteAuxiliaryFile | 36 | 0.006s |
| SwiftDriver Compilation Requirements | 3 | 0.004s |
| SwiftDriver Compilation | 3 | 0.003s |
| ProcessProductPackaging | 4 | 0.002s |
| SwiftMergeGeneratedHeaders | 3 | 0.001s |
| Validate | 1 | 0.000s |

### Incremental Build Timing Summary

> **Note:** These are aggregated task times across all CPU cores. Because Xcode runs many tasks in parallel, these totals typically exceed the actual build wait time shown above. A large number here does not mean it is blocking your build.

| Category | Tasks | Seconds |
|----------|------:|--------:|
| ValidateEmbeddedBinary | 0 | 0.116s |
| CodeSign | 0 | 0.009s |
| CopySwiftLibs | 0 | 0.005s |
| Copy | 0 | 0.002s |
| ProcessInfoPlistFile | 0 | 0.001s |
| Validate | 0 | 0.000s |

## Build Settings Audit

### Debug Configuration

- [x] `SWIFT_COMPILATION_MODE`: `(unset)` (recommended: `singlefile`)
- [ ] `SWIFT_OPTIMIZATION_LEVEL`: `(unset)` (recommended: `-Onone`)
- [ ] `GCC_OPTIMIZATION_LEVEL`: `(unset)` (recommended: `0`)
- [x] `ONLY_ACTIVE_ARCH`: `YES` (recommended: `YES`)
- [ ] `DEBUG_INFORMATION_FORMAT`: `(unset)` (recommended: `dwarf`)
- [ ] `ENABLE_TESTABILITY`: `(unset)` (recommended: `YES`)
- [ ] `EAGER_LINKING`: `(unset)` (recommended: `YES`)

### General (All Configurations)

- [ ] `COMPILATION_CACHE_ENABLE_CACHING`: `(unset)` (recommended: `YES`)

### Release Configuration

- [ ] `SWIFT_COMPILATION_MODE`: `(unset)` (recommended: `wholemodule`)
- [ ] `SWIFT_OPTIMIZATION_LEVEL`: `(unset)` (recommended: `-O`)
- [ ] `GCC_OPTIMIZATION_LEVEL`: `(unset)` (recommended: `s`)
- [x] `ONLY_ACTIVE_ARCH`: `NO` (recommended: `NO`)
- [ ] `DEBUG_INFORMATION_FORMAT`: `(unset)` (recommended: `dwarf-with-dsym`)
- [ ] `ENABLE_TESTABILITY`: `(unset)` (recommended: `NO`)

### Cross-Target Consistency

- [x] `SWIFT_COMPILATION_MODE` is consistent across all targets
- [x] `SWIFT_OPTIMIZATION_LEVEL` is consistent across all targets
- [x] `ONLY_ACTIVE_ARCH` is consistent across all targets
- [x] `DEBUG_INFORMATION_FORMAT` is consistent across all targets

## Compilation Diagnostics

Threshold: 100ms | Total warnings: 8 | Function bodies: 1 | Expressions: 7

| Duration | Kind | File | Line | Name |
|---------:|------|------|-----:|------|
| 2255ms | expression | ReflexBlitzCardView.swift | 588 | (expression) |
| 2237ms | expression | MixedDrillSectionViews.swift | 109 | (expression) |
| 2005ms | expression | ReflexBlitzCardView.swift | 274 | (expression) |
| 1443ms | expression | MixedDrillSectionViews.swift | 255 | (expression) |
| 146ms | function-body | CompleteStageChallengeUseCase.swift | 21 | execute(stageId:deckId:results:) |
| 123ms | expression | CompleteStageChallengeUseCase.swift | 26 | (expression) |
| 108ms | expression | ReflexBlitzCardView.swift | 432 | (expression) |
| 101ms | expression | ReflexBlitzCardView.swift | 417 | (expression) |

## Prioritized Recommendations

### 1. Enable Compilation Caching (COMPILATION_CACHE_ENABLE_CACHING = YES)

**Wait-Time Impact:** Measured 5-14% faster clean builds across tested projects. The benefit compounds in real workflows where the cache persists between builds -- branch switching, pulling changes, and CI with persistent DerivedData.
**Actionability:** repo-available
**Category:** build-settings
**Evidence:** COMPILATION_CACHE_ENABLE_CACHING is currently unset in VocabCraftApp.xcodeproj.
**Impact:** High
**Confidence:** High
**Risk:** Low
**Scope:** VocabCraftApp.xcodeproj (All Configurations)

### 2. Set DEBUG_INFORMATION_FORMAT to "dwarf" for Debug

**Wait-Time Impact:** Expected to reduce your Debug clean build by approximately 0.5 seconds by eliminating dSYM generation overhead.
**Actionability:** repo-available
**Category:** build-settings
**Evidence:** DEBUG_INFORMATION_FORMAT is unset for Debug, causing Xcode to run GenerateDSYMFile tasks (taking ~0.50s per build in timing summaries).
**Impact:** Medium
**Confidence:** High
**Risk:** Low
**Scope:** VocabCraftApp.xcodeproj (Debug Configuration)

### 3. Set EAGER_LINKING to "YES" for Debug

**Wait-Time Impact:** Impact on wait time is uncertain -- re-benchmark after applying to confirm.
**Actionability:** repo-available
**Category:** build-settings
**Evidence:** EAGER_LINKING is unset. Eager linking allows the linker to begin emitting Mach-O output as soon as dependent TBDs are available rather than waiting for all object files.
**Impact:** Medium
**Confidence:** High
**Risk:** Low
**Scope:** VocabCraftApp.xcodeproj (Debug Configuration)

### 4. Align Standard Debug & Release Compiler Settings in Project

**Wait-Time Impact:** No wait-time improvement expected. The benefit is deterministic builds, explicit compiler intent, and preventing module variant drift.
**Actionability:** repo-available
**Category:** build-settings
**Evidence:** SWIFT_OPTIMIZATION_LEVEL, GCC_OPTIMIZATION_LEVEL, ENABLE_TESTABILITY, and SWIFT_COMPILATION_MODE are unset at the project level, relying on implicit Xcode defaults.
**Impact:** Medium
**Confidence:** High
**Risk:** Low
**Scope:** VocabCraftApp.xcodeproj (Debug and Release Configurations)

### 5. Refactor Severe Type-Checking Hotspots in ReflexBlitzCardView.swift (>4.4s compile work)

**Wait-Time Impact:** Reduces parallel compile work by ~4.5s and expected to reduce wait time if ReflexBlitzCardView is on the compile critical path.
**Actionability:** repo-available
**Category:** compilation
**Evidence:** diagnose_compilation identified 4 expressions in ReflexBlitzCardView.swift taking over 4,469ms combined (line 588 took 2255ms, line 274 took 2005ms, line 432 took 108ms, line 417 took 101ms) due to un-typed integer modulo arithmetic within Capsule.frame modifiers, complex nested ternaries in .fill(), and Text concatenation chains.
**Impact:** High
**Confidence:** High
**Risk:** Low
**Scope:** VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift

### 6. Refactor Severe Type-Checking Hotspots in MixedDrillSectionViews.swift (>3.6s compile work)

**Wait-Time Impact:** Reduces parallel compile work by ~3.7s and expected to reduce wait time if MixedDrillSectionViews is on the compile critical path.
**Actionability:** repo-available
**Category:** compilation
**Evidence:** diagnose_compilation identified 2 expressions in MixedDrillSectionViews.swift taking 3,680ms combined (line 109 took 2237ms, line 255 took 1443ms) due to inline dynamic waveform height modulo arithmetic inside SwiftUI view builder ForEach hierarchies.
**Impact:** High
**Confidence:** High
**Risk:** Low
**Scope:** VocabCraftApp/Features/Vocabulary/Views/Components/MixedDrillSectionViews.swift

### 7. Refactor Arithmetic Type-Checking Hotspot in CompleteStageChallengeUseCase.swift

**Wait-Time Impact:** Reduces parallel compile work by ~0.27s (unlikely to noticeably reduce wall-clock wait time on its own, but cleans up type inference).
**Actionability:** repo-available
**Category:** compilation
**Evidence:** diagnose_compilation identified function body execute(stageId:deckId:results:) (146ms) and line 26 (123ms) due to complex inline ternary with multiple Double conversions for score calculation.
**Impact:** Low
**Confidence:** High
**Risk:** Low
**Scope:** VocabCraftApp/Domain/UseCases/CompleteStageChallengeUseCase.swift


## Approval Checklist

- [x] **1. Enable Compilation Caching (COMPILATION_CACHE_ENABLE_CACHING = YES)** -- Impact: Measured 5-14% faster clean builds across tested projects. The benefit compounds in real workflows where the cache persists between builds -- branch switching, pulling changes, and CI with persistent DerivedData. | Actionability: repo-available | Risk: Low
- [x] **2. Set DEBUG_INFORMATION_FORMAT to "dwarf" for Debug** -- Impact: Expected to reduce your Debug clean build by approximately 0.5 seconds by eliminating dSYM generation overhead. | Actionability: repo-available | Risk: Low
- [x] **3. Set EAGER_LINKING to "YES" for Debug** -- Impact: Impact on wait time is uncertain -- re-benchmark after applying to confirm. | Actionability: repo-available | Risk: Low
- [x] **4. Align Standard Debug & Release Compiler Settings in Project** -- Impact: No wait-time improvement expected. The benefit is deterministic builds, explicit compiler intent, and preventing module variant drift. | Actionability: repo-available | Risk: Low
- [x] **5. Refactor Severe Type-Checking Hotspots in ReflexBlitzCardView.swift (>4.4s compile work)** -- Impact: Reduces parallel compile work by ~4.5s and expected to reduce wait time if ReflexBlitzCardView is on the compile critical path. | Actionability: repo-available | Risk: Low
- [x] **6. Refactor Severe Type-Checking Hotspots in MixedDrillSectionViews.swift (>3.6s compile work)** -- Impact: Reduces parallel compile work by ~3.7s and expected to reduce wait time if MixedDrillSectionViews is on the compile critical path. | Actionability: repo-available | Risk: Low
- [x] **7. Refactor Arithmetic Type-Checking Hotspot in CompleteStageChallengeUseCase.swift** -- Impact: Reduces parallel compile work by ~0.27s (unlikely to noticeably reduce wall-clock wait time on its own, but cleans up type inference). | Actionability: repo-available | Risk: Low

## Verification Results

- **Baseline Clean Build Median:** **24.799s**
- **Post-Change Clean Build Median:** **3.722s** -- **21.077s faster (85.0% reduction)**
- **Baseline Incremental (Zero-Change) Median:** **1.117s**
- **Post-Change Incremental (Zero-Change) Median:** **1.041s** -- **0.076s faster (6.8% reduction)**
- **Post-Change Cached Clean Median:** **18.111s** (compilation cache active across cold DerivedData rebuilds)
- **Compilation Diagnostics:** **0 warnings** above 100ms threshold (was 8 warnings taking >8.2s of type checking)
- **Unit Test Suite:** **46/46 tests passed** across 11 test suites
- **Post-Change Benchmark Artifact:** `.build-benchmark/20260823T163731Z-vocabcraftapp.json`

### Summary
Your clean build now takes **3.722s** (was 24.799s) -- **21.077s faster (85.0% faster)**.
Your zero-change build now takes **1.041s** (was 1.117s) -- **0.076s faster**.
