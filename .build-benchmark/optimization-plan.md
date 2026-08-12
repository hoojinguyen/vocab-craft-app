# Xcode Build Optimization Plan


## Project Context

- **Project:** `VocabCraftApp.xcodeproj`
- **Scheme:** `VocabCraftApp`
- **Configuration:** `Debug`
- **Destination:** `platform=iOS Simulator,name=iPhone 17`
- **Xcode:** Xcode 26.4.1 Build version 17E202
- **macOS:** macOS-26.5-arm64-arm-64bit-Mach-O
- **Date:** 2026-08-12T06:28:54.977625+00:00
- **Benchmark artifact:** `.build-benchmark/20260812T062754Z-vocabcraftapp.json`

## Baseline Benchmarks

| Metric | Clean | Cached Clean | Incremental |
|--------|-------|-------------|-------------|
| Median | 2.815s | 9.023s | 1.030s |
| Min | 2.787s | 8.973s | 1.009s |
| Max | 2.844s | 9.197s | 1.488s |
| Runs | 3 | 3 | 3 |

> **Cached Clean** = clean build with a warm compilation cache. This is the realistic scenario for branch switching, pulling changes, or Clean Build Folder. The compilation cache lives outside DerivedData and survives product deletion.


### Clean Build Timing Summary

> **Note:** These are aggregated task times across all CPU cores. Because Xcode runs many tasks in parallel, these totals typically exceed the actual build wait time shown above. A large number here does not mean it is blocking your build.

| Category | Tasks | Seconds |
|----------|------:|--------:|
| SwiftDriver | 2 | 0.825s |
| SwiftCompile | 20 | 0.657s |
| Ld | 6 | 0.567s |
| ValidateEmbeddedBinary | 1 | 0.366s |
| CodeSign | 6 | 0.065s |
| SwiftEmitModule | 2 | 0.054s |
| ExtractAppIntentsMetadata | 2 | 0.038s |
| AppIntentsSSUTraining | 2 | 0.033s |
| RegisterExecutionPolicyException | 2 | 0.020s |
| Copy | 9 | 0.016s |
| ProcessProductPackagingDER | 4 | 0.011s |
| CopySwiftLibs | 1 | 0.008s |
| ProcessInfoPlistFile | 2 | 0.008s |
| WriteAuxiliaryFile | 33 | 0.006s |
| ConstructStubExecutorLinkFileList | 2 | 0.003s |
| Touch | 2 | 0.003s |
| SwiftDriver Compilation Requirements | 2 | 0.002s |
| ProcessProductPackaging | 4 | 0.001s |
| SwiftDriver Compilation | 2 | 0.001s |
| SwiftMergeGeneratedHeaders | 2 | 0.000s |
| Validate | 1 | 0.000s |

### Cached Clean Build Timing Summary

> **Note:** These are aggregated task times across all CPU cores. Because Xcode runs many tasks in parallel, these totals typically exceed the actual build wait time shown above. A large number here does not mean it is blocking your build.

| Category | Tasks | Seconds |
|----------|------:|--------:|
| SwiftCompile | 20 | 17.768s |
| SwiftEmitModule | 2 | 1.723s |
| SwiftDriver | 2 | 1.155s |
| Ld | 6 | 0.567s |
| ValidateEmbeddedBinary | 1 | 0.402s |
| CodeSign | 6 | 0.066s |
| ExtractAppIntentsMetadata | 2 | 0.039s |
| AppIntentsSSUTraining | 2 | 0.033s |
| Copy | 9 | 0.019s |
| RegisterExecutionPolicyException | 2 | 0.019s |
| ProcessProductPackagingDER | 4 | 0.014s |
| CopySwiftLibs | 1 | 0.010s |
| ProcessInfoPlistFile | 2 | 0.008s |
| WriteAuxiliaryFile | 33 | 0.007s |
| ConstructStubExecutorLinkFileList | 2 | 0.003s |
| Touch | 2 | 0.003s |
| SwiftDriver Compilation Requirements | 2 | 0.002s |
| ProcessProductPackaging | 4 | 0.002s |
| SwiftDriver Compilation | 2 | 0.002s |
| SwiftMergeGeneratedHeaders | 2 | 0.001s |
| Validate | 1 | 0.000s |

### Incremental Build Timing Summary

> **Note:** These are aggregated task times across all CPU cores. Because Xcode runs many tasks in parallel, these totals typically exceed the actual build wait time shown above. A large number here does not mean it is blocking your build.

| Category | Tasks | Seconds |
|----------|------:|--------:|
| ValidateEmbeddedBinary | 0 | 0.117s |
| CodeSign | 1 | 0.012s |
| CopySwiftLibs | 1 | 0.009s |
| ProcessInfoPlistFile | 2 | 0.006s |
| Copy | 0 | 0.003s |
| Validate | 0 | 0.000s |

## Build Settings Audit

### Debug Configuration

- [x] `SWIFT_COMPILATION_MODE`: `singlefile` (recommended: `singlefile`)
- [x] `SWIFT_OPTIMIZATION_LEVEL`: `-Onone` (recommended: `-Onone`)
- [x] `GCC_OPTIMIZATION_LEVEL`: `0` (recommended: `0`)
- [x] `ONLY_ACTIVE_ARCH`: `YES` (recommended: `YES`)
- [x] `DEBUG_INFORMATION_FORMAT`: `dwarf` (recommended: `dwarf`)
- [x] `ENABLE_TESTABILITY`: `YES` (recommended: `YES`)
- [x] `EAGER_LINKING`: `YES` (recommended: `YES`)

### General (All Configurations)

- [x] `COMPILATION_CACHE_ENABLE_CACHING`: `YES` (recommended: `YES`)

### Release Configuration

- [x] `SWIFT_COMPILATION_MODE`: `wholemodule` (recommended: `wholemodule`)
- [x] `SWIFT_OPTIMIZATION_LEVEL`: `-O` (recommended: `-O`)
- [x] `GCC_OPTIMIZATION_LEVEL`: `s` (recommended: `s`)
- [x] `ONLY_ACTIVE_ARCH`: `NO` (recommended: `NO`)
- [x] `DEBUG_INFORMATION_FORMAT`: `dwarf-with-dsym` (recommended: `dwarf-with-dsym`)
- [x] `ENABLE_TESTABILITY`: `NO` (recommended: `NO`)

### Cross-Target Consistency

- [x] `SWIFT_COMPILATION_MODE` is consistent across all targets
- [x] `SWIFT_OPTIMIZATION_LEVEL` is consistent across all targets
- [x] `ONLY_ACTIVE_ARCH` is consistent across all targets
- [x] `DEBUG_INFORMATION_FORMAT` is consistent across all targets

## Compilation Diagnostics

Threshold: 100ms | Total warnings: 0 | Function bodies: 0 | Expressions: 0

No type-checking hotspots found above threshold.

## Prioritized Recommendations

No recommendations artifact provided.

## Approval Checklist

No recommendations to approve.

## Next Steps

After implementing approved changes, re-benchmark with the same inputs:

```bash
python3 scripts/benchmark_builds.py \
  --project VocabCraftApp.xcodeproj \
  --scheme VocabCraftApp \
  --configuration Debug \
  --destination "platform=iOS Simulator,name=iPhone 17" \
  --output-dir .build-benchmark
```

Compare the new wall-clock medians against the baseline. Report results as:
"Your [clean/incremental] build now takes X.Xs (was Y.Ys) -- Z.Zs faster/slower."
