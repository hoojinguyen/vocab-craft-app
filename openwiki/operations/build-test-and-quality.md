---
type: operations
title: Build, Test, and Quality Gate
description: SPM and Xcode build, SwiftLint, swift test, and zero-warnings enforcement.
tags: ["build", "xcode", "spm", "quality-gate"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-01545979d25a6b33e8e2f3c3
    resource: repo://.swiftlint.yml
  - id: openwiki-source-6c43740804a3acf640865200
    resource: repo://docs/build-optimization.md
  - id: openwiki-source-16a6a536c0a5303df5e05c6c
    resource: repo://Package.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Ensures deterministic builds, lint compliance, and 100% test pass before any task is considered complete per AGENTS.md strict gate.

## Entrypoints

- **SPM**: `Package.swift` (5.10, iOS17/macOS14) declares `VocabCraftApp` library target, `VocabCraftWidgetExtension`, and local `CraftUIKit`, `SpeechKit` packages; resources via `.process("Resources")`; excludes entitlements/plist.
- **Xcode**: `VocabCraft.xcworkspace` + `VocabCraftApp.xcodeproj` (generatable via `scripts/generate_workspace.py` and `generate_xcodeproj.py`).
- **Lint**: `.swiftlint.yml` (shared + `VocabCraftAppTests/.swiftlint.yml`) enforces CraftUIKit-first, no hardcoded colors, localization rules.
- **Docs**: `docs/build-optimization.md` records benchmark baselines (clean ~24.8s, incremental ~1.1s) and settings audit.

## Mechanisms

1. **Clean build**: `swift build` / Xcode Build (SwiftCompile 30 tasks, SwiftEmitModule 3, etc.). Compilation cache flag recommended.
2. **Tests**: `swift test` and `swift test --filter LocalizationTests`; XCTest shim under `VocabCraftAppTests/Support/XCTestShim.swift` bridges modern `@Test` to legacy runner. Over 50 suites cover domain, UI, audio, persistence.
3. **SwiftLint**: `swiftlint lint` or plugin `SimplyDanny/SwiftLintPlugins`; CI fails on warnings. Custom rules enforce zero raw styling and zero hardcoded strings.
4. **Quality gate** (AGENTS.md §5): localization verification → full test suite → swiftlint → compile with 0 warnings/errors. Violations must be fixed before completion.

## Relationships

- **Upstream**: SPM resolves local packages before build.
- **Downstream**: CI (GitHub Actions, see OpenWiki workflow) runs same gate; build optimization benchmarks under `.build-benchmark/`.

## State and Lifecycle

Build artifacts under `.build`; Xcode DerivedData separately. Incremental builds benefit from `SWIFT_COMPILATION_MODE=singlefile` and `ONLY_ACTIVE_ARCH=YES` in Debug per optimization plan.

## Invariants

- Task is never complete with warnings. AGENTS.md mandates verification-before-completion skill.
- No hardcoded colors/strings pass lint; must use `CraftColor`/`AppStrings` + xcstrings.

## Failure

- Build errors surface as Xcode diagnostics; lint warnings block merge.
- Missing workspace triggers `generate_workspace.py`; command failure instructs fix before commit.

## Configuration

`SWIFT_OPTIMIZATION_LEVEL`, `DEBUG_INFORMATION_FORMAT`, `ENABLE_TESTABILITY` tuned per configuration in optimization doc. `skills-lock.json` pins skill versions.

## Extension

Add package by editing `Package.swift` dependencies/targets; add script under `scripts/`.

## Tests

All tests are verification: `swiftlint`, `swift test`, and Xcode no-warning build constitute the gate itself.
