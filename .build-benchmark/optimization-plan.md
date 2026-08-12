# Xcode Build Optimization Plan


## Project Context

- **Project:** `VocabCraftApp.xcodeproj`
- **Scheme:** `VocabCraftApp`
- **Configuration:** `Debug`
- **Destination:** `platform=iOS Simulator,name=iPhone 17`
- **Xcode:** Xcode 26.6 Build version 17F113
- **macOS:** macOS-26.6.1-arm64-arm-64bit-Mach-O
- **Date:** 2026-08-12T17:25:21.640045+00:00
- **Benchmark artifact:** `.build-benchmark/20260812T172428Z-vocabcraftapp.json`

## Baseline Benchmarks

| Metric | Clean | Incremental |
|--------|-------|-------------|
| Median | 10.211s | 1.883s |
| Min | 10.130s | 1.783s |
| Max | 10.557s | 2.555s |
| Runs | 3 | 3 |

### Clean Build Timing Summary

> **Note:** These are aggregated task times across all CPU cores. Because Xcode runs many tasks in parallel, these totals typically exceed the actual build wait time shown above. A large number here does not mean it is blocking your build.

| Category | Tasks | Seconds |
|----------|------:|--------:|
| SwiftCompile | 40 | 58.759s |
| SwiftEmitModule | 4 | 3.112s |
| SwiftDriver | 4 | 1.501s |
| Ld | 4 | 0.999s |
| ValidateEmbeddedBinary | 1 | 0.346s |
| GenerateDSYMFile | 2 | 0.224s |
| ExtractAppIntentsMetadata | 2 | 0.044s |
| Copy | 17 | 0.037s |
| CodeSign | 2 | 0.037s |
| AppIntentsSSUTraining | 2 | 0.036s |
| CompileXCStrings | 1 | 0.032s |
| CopySwiftLibs | 1 | 0.020s |
| ProcessProductPackagingDER | 4 | 0.019s |
| RegisterExecutionPolicyException | 2 | 0.013s |
| CreateUniversalBinary | 2 | 0.008s |
| ProcessInfoPlistFile | 2 | 0.008s |
| CopyStringsFile | 2 | 0.007s |
| WriteAuxiliaryFile | 38 | 0.006s |
| Touch | 2 | 0.005s |
| SwiftDriver Compilation Requirements | 4 | 0.005s |
| SwiftDriver Compilation | 4 | 0.004s |
| ProcessProductPackaging | 4 | 0.002s |
| SwiftMergeGeneratedHeaders | 2 | 0.001s |
| Validate | 1 | 0.000s |

### Incremental Build Timing Summary

> **Note:** These are aggregated task times across all CPU cores. Because Xcode runs many tasks in parallel, these totals typically exceed the actual build wait time shown above. A large number here does not mean it is blocking your build.

| Category | Tasks | Seconds |
|----------|------:|--------:|
| SwiftEmitModule | 2 | 1.334s |
| SwiftDriver | 2 | 0.877s |
| SwiftCompile | 2 | 0.510s |
| ValidateEmbeddedBinary | 0 | 0.117s |
| SwiftDriver Compilation | 2 | 0.027s |
| CodeSign | 1 | 0.018s |
| ExtractAppIntentsMetadata | 1 | 0.011s |
| Copy | 4 | 0.006s |
| CopySwiftLibs | 0 | 0.003s |
| ProcessInfoPlistFile | 0 | 0.001s |
| SwiftDriver Compilation Requirements | 2 | 0.001s |
| Validate | 1 | 0.000s |

## Build Settings Audit

### Debug Configuration

- [x] `SWIFT_COMPILATION_MODE`: `(unset)` (recommended: `singlefile`)
- [ ] `SWIFT_OPTIMIZATION_LEVEL`: `(unset)` (recommended: `-Onone`)
- [ ] `GCC_OPTIMIZATION_LEVEL`: `(unset)` (recommended: `0`)
- [ ] `ONLY_ACTIVE_ARCH`: `(unset)` (recommended: `YES`)
- [ ] `DEBUG_INFORMATION_FORMAT`: `(unset)` (recommended: `dwarf`)
- [ ] `ENABLE_TESTABILITY`: `(unset)` (recommended: `YES`)
- [ ] `EAGER_LINKING`: `(unset)` (recommended: `YES`)

### General (All Configurations)

- [ ] `COMPILATION_CACHE_ENABLE_CACHING`: `(unset)` (recommended: `YES`)

### Release Configuration

- [ ] `SWIFT_COMPILATION_MODE`: `(unset)` (recommended: `wholemodule`)
- [ ] `SWIFT_OPTIMIZATION_LEVEL`: `(unset)` (recommended: `-O`)
- [ ] `GCC_OPTIMIZATION_LEVEL`: `(unset)` (recommended: `s`)
- [ ] `ONLY_ACTIVE_ARCH`: `(unset)` (recommended: `NO`)
- [ ] `DEBUG_INFORMATION_FORMAT`: `(unset)` (recommended: `dwarf-with-dsym`)
- [ ] `ENABLE_TESTABILITY`: `(unset)` (recommended: `NO`)

### Cross-Target Consistency

- [x] `SWIFT_COMPILATION_MODE` is consistent across all targets
- [x] `SWIFT_OPTIMIZATION_LEVEL` is consistent across all targets
- [x] `ONLY_ACTIVE_ARCH` is consistent across all targets
- [x] `DEBUG_INFORMATION_FORMAT` is consistent across all targets

## Compilation Diagnostics

Threshold: 100ms | Total warnings: 1 | Function bodies: 1 | Expressions: 0

| Duration | Kind | File | Line | Name |
|---------:|------|------|-----:|------|
| 118ms | function-body | SuggestedWordsCardView.swift | 67 | suggestedCard(for:) |

## Prioritized Recommendations

### 1. Set `SWIFT_OPTIMIZATION_LEVEL` to `-Onone` for Debug

**Category:** build-settings
**Evidence:** Current value: `(unset)`. Optimization passes add compile time without debug benefit.
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 2. Set `GCC_OPTIMIZATION_LEVEL` to `0` for Debug

**Category:** build-settings
**Evidence:** Current value: `(unset)`. C/ObjC optimization adds compile time without debug benefit.
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 3. Set `ONLY_ACTIVE_ARCH` to `YES` for Debug

**Category:** build-settings
**Evidence:** Current value: `(unset)`. Building all architectures multiplies compile and link time.
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 4. Set `DEBUG_INFORMATION_FORMAT` to `dwarf` for Debug

**Category:** build-settings
**Evidence:** Current value: `(unset)`. dwarf-with-dsym generates a separate dSYM, adding overhead.
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 5. Set `ENABLE_TESTABILITY` to `YES` for Debug

**Category:** build-settings
**Evidence:** Current value: `(unset)`. Required for @testable import during development.
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 6. Set `EAGER_LINKING` to `YES` for Debug

**Category:** build-settings
**Evidence:** Current value: `(unset)`. Allows linker to start before all compilation finishes, reducing wall-clock time.
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 7. Enable `COMPILATION_CACHE_ENABLE_CACHING = YES`

**Category:** build-settings
**Evidence:** Current value: `(unset)`. Caches compilation results so repeat builds of unchanged inputs are served from cache. Measured 5-14% faster clean builds across tested projects; benefit compounds during branch switching and pulling changes.
**Impact:** High
**Confidence:** High
**Risk:** Low

### 8. Set `SWIFT_COMPILATION_MODE` to `wholemodule` for Release

**Category:** build-settings
**Evidence:** Current value: `(unset)`. Whole-module optimization produces faster runtime code.
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 9. Set `SWIFT_OPTIMIZATION_LEVEL` to `-O` for Release

**Category:** build-settings
**Evidence:** Current value: `(unset)`. Optimized binaries for production (-Osize also acceptable).
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 10. Set `GCC_OPTIMIZATION_LEVEL` to `s` for Release

**Category:** build-settings
**Evidence:** Current value: `(unset)`. Optimizes C/ObjC for size in release.
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 11. Set `ONLY_ACTIVE_ARCH` to `NO` for Release

**Category:** build-settings
**Evidence:** Current value: `(unset)`. Release builds must include all architectures for distribution.
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 12. Set `DEBUG_INFORMATION_FORMAT` to `dwarf-with-dsym` for Release

**Category:** build-settings
**Evidence:** Current value: `(unset)`. dSYM bundles are needed for crash symbolication.
**Impact:** Medium
**Confidence:** High
**Risk:** Low

### 13. Set `ENABLE_TESTABILITY` to `NO` for Release

**Category:** build-settings
**Evidence:** Current value: `(unset)`. Removes internal-symbol export overhead from release builds.
**Impact:** Medium
**Confidence:** High
**Risk:** Low


## Approval Checklist

- [x] **1. Set `SWIFT_OPTIMIZATION_LEVEL` to `-Onone` for Debug** -- Impact: Medium | Risk: Low
- [x] **2. Set `GCC_OPTIMIZATION_LEVEL` to `0` for Debug** -- Impact: Medium | Risk: Low
- [x] **3. Set `ONLY_ACTIVE_ARCH` to `YES` for Debug** -- Impact: Medium | Risk: Low
- [x] **4. Set `DEBUG_INFORMATION_FORMAT` to `dwarf` for Debug** -- Impact: Medium | Risk: Low
- [x] **5. Set `ENABLE_TESTABILITY` to `YES` for Debug** -- Impact: Medium | Risk: Low
- [x] **6. Set `EAGER_LINKING` to `YES` for Debug** -- Impact: Medium | Risk: Low
- [x] **7. Enable `COMPILATION_CACHE_ENABLE_CACHING = YES`** -- Impact: High | Risk: Low
- [x] **8. Set `SWIFT_COMPILATION_MODE` to `wholemodule` for Release** -- Impact: Medium | Risk: Low
- [x] **9. Set `SWIFT_OPTIMIZATION_LEVEL` to `-O` for Release** -- Impact: Medium | Risk: Low
- [x] **10. Set `GCC_OPTIMIZATION_LEVEL` to `s` for Release** -- Impact: Medium | Risk: Low
- [x] **11. Set `ONLY_ACTIVE_ARCH` to `NO` for Release** -- Impact: Medium | Risk: Low
- [x] **12. Set `DEBUG_INFORMATION_FORMAT` to `dwarf-with-dsym` for Release** -- Impact: Medium | Risk: Low
- [x] **13. Set `ENABLE_TESTABILITY` to `NO` for Release** -- Impact: Medium | Risk: Low
- [x] **14. Refactor Type-Checking Hotspot in `SuggestedWordsCardView.swift`** -- Impact: Low | Risk: Low

## Verification Results

- **Post-Change Clean Build Median:** **2.439s** (was 10.211s) -- **7.772s faster (76.1% reduction)**
- **Post-Change Incremental Build Median:** **1.654s** (was 1.883s) -- **0.229s faster (12.2% reduction)**
- **Post-Change Cached Clean Median:** **8.642s** (compilation cache active)
- **Benchmark Artifact:** `.build-benchmark/20260812T172635Z-vocabcraftapp.json`

### Summary
Your clean build now takes **2.439s** (was 10.211s) -- **7.772s faster**.
Your incremental build now takes **1.654s** (was 1.883s) -- **0.229s faster**.

