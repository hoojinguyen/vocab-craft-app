# Phase 3A — Offline Learning Verification Report

**Date**: 2026-09-06  
**Repositories**: `vocab-craft-api` (`feat/phase-3a`), `vocab-craft-app` (`feat/phase-3a`)  
**Target Simulator**: iPhone 17 (iOS 18.0+)  

---

## 1. Executive Summary

Phase 3A (Offline Learning) is complete and verified across both the authoring/publishing backend (`vocab-craft-api`) and the client application (`vocab-craft-app`).

1. **Stage A (Authoring & Publishing Engine)**: Complete in `vocab-craft-api`. All authoring data models, editorial review workflows, SQLite publishing pipeline, and bundle verification tooling implemented and tested.
2. **Stage B (iOS Offline Storage & Journal Engine)**: Complete in `vocab-craft-app` (PR #20). SQLite content repository, guest journal engine, learning path adapter, and app container wiring implemented with 0 SwiftLint violations.
3. **Stage C (Real Content & Cross-Repo Acceptance)**:
   - First release candidate generated with 60 high-frequency words, 67 senses across 5 lessons and 1 deck ("Core 60 Vocabulary").
   - 100% approved through review decisions, published to production SQLite bundle (`vocab_content.sqlite`) and `manifest.json`.
   - Production bundle and attribution (`NOTICE.txt`) integrated into `VocabCraftApp` bundle.
   - Comprehensive offline acceptance tests written and verified passing on iPhone 17 Simulator.

---

## 2. Release Artifact Verification

### Production Content Bundle

- **Bundle Artifacts**:
  - `VocabCraftApp/Resources/Content/vocab_content.sqlite`:
    - Size: 303,104 bytes
    - SHA-256: `6c3402b5efdb29998f2769e812cd7df482abb777a7caf4ae807a413093bd2713`
    - PRAGMA integrity_check: `ok`
    - PRAGMA foreign_key_check: clean (0 violations)
  - `VocabCraftApp/Resources/Content/manifest.json`:
    - Release version: 1
    - Schema version: 1
    - Entities: 1 deck, 5 lessons, 60 entries, 67 senses
  - `VocabCraftApp/Resources/Content/NOTICE.txt`:
    - License attribution for Wiktionary content under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0) with VocabCraft project attribution.

### Invariant & Content Quality Checks
- All 67 senses have complete bilingual definitions (`definition_en` and `definition_vi`).
- All 67 senses have complete bilingual contextual examples (`example_en` and `example_vi`).
- CEFR level coverage: A1 (44 senses), A2 (18 senses), B1 (5 senses).
- Parts of speech: Noun (37), Verb (18), Adjective (10), Adverb (2).
- Zero orphan senses, zero broken references across decks, lessons, and entries.

---

## 3. Test & Verification Results

### Backend (`vocab-craft-api`)
```
.venv/bin/pytest -q
........................................................................ [ 44%]
........................................................................ [ 88%]
..................                                                       [100%]
162 passed, 2 warnings in 4.90s
```
- Verified test suites:
  - `tests/content/test_first_release.py`:
    - `test_first_release_sqlite_and_manifest_exist_and_match`
    - `test_first_release_content_domain_invariants`
    - `test_first_release_editorial_approvals`
  - All publisher, authoring, review, and migration tests pass.

### Client (`vocab-craft-app`)

#### SwiftLint Strict Linting
```bash
swiftlint --strict
Done linting! Found 0 violations, 0 serious in 251 files.
```

#### Acceptance Test Suite (`OfflineLearningAcceptanceTests`)
- Destination: `platform=iOS Simulator,name=iPhone 17,OS=latest`
- Test cases:
  1. `testProductionBundleLoadsOfflineWithoutNetwork`:
     - Reads directly from production bundle embedded in app resources.
     - Confirms 1 deck ("Core 60 Vocabulary"), 5 lessons, 67 senses loaded without network.
     - Confirms bilingual integrity on every loaded sense.
  2. `testOfflineSenseProgressionAndJournalPersistenceAcrossRelaunch`:
     - Completes sense exercises offline.
     - Records journal events and verifies mastery/progression calculation.
     - Simulates app relaunch by recreating container and repository with the exact same journal URL.
     - Verifies 100% state persistence across app relaunch.
- Result: `** TEST SUCCEEDED **` (2 tests, 0 failures, 0.166s).

#### Full Regression Suite
- Total tests executed across Swift Testing and XCTest: **322 tests**.
- Result: **322/322 tests passed (0 failures, 0 unexpected)**.
- Build status: **0 errors, 0 warnings**.

---

## 4. Conclusion & Sign-Off

Phase 3A has met all completion criteria:
- [x] Schema & publishing engine functional and verified.
- [x] Content review and approval complete for first production dataset.
- [x] Production bundle embedded into iOS app target resources.
- [x] Full offline learning path adapter and guest learning journal functioning.
- [x] All automated tests and offline acceptance tests passing on iOS 17 simulator.
- [x] Zero SwiftLint warnings, zero compiler warnings.
