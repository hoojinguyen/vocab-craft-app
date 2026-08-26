# CraftSearchBar UI/UX, Performance Optimization & Full-Spectrum Styles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elevate `CraftSearchBar` into a high-performance, lag-free, tactile, and full-spectrum styled search component across CraftUIKit with support for 7 style variants, 3 ergonomic sizes (`sm`, `md`, `lg`), haptic sensory feedback, loading states, and SF Symbol micro-interactions.

**Architecture:** Refactor `CraftSearchBar` to eliminate nested animation conflicts, bind full hit-testing to the outer pill container, integrate with `CraftSurfaceStyle` (`flat`, `elevated`, `outlined`, `recessed`, `tactile3D`, `glass`) via `CraftSurfaceModifier`, and deliver 44pt minimum touch targets for Clear/Cancel buttons.

**Tech Stack:** Swift 6, SwiftUI, iOS 17+, Swift Testing / XCTest, CraftUIKit theming & token system.

**Spec:** `docs/superpowers/specs/2026-08-26-craftsearchbar-redesign-spec.md`

## Global Constraints
- Target iOS 17.0+, macOS 14.0+
- Pure SwiftUI native without UIKit workarounds
- Dynamic Type and dark mode compliance with zero hardcoded colors
- Maintain 100% backward compatibility for existing initializers and test cases (`.standard`, `.recessed`, `.glass`)
- Apple HIG minimum 44x44pt touch targets on interactive buttons

---

### Task 1: Refactor CraftSearchBar with Full-Spectrum Styles, Sizes, Performance & Micro-Interactions

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

**Interfaces:**
- Produces:
  - `public enum CraftSearchBarStyle: String, Sendable, CaseIterable { case standard, flat, elevated, outlined, recessed, tactile3D, glass }`
  - `public enum CraftSearchBarSize: String, Sendable, CaseIterable { case sm, md, lg }`
  - `public struct CraftSearchBar: View` supporting `size`, `style`, `shape`, `customTint`, `customGradient`, `isLoading`, and localized/verbatim initializers.

- [ ] **Step 1: Write comprehensive unit tests for all styles, sizes, loading state, and localization**
- [ ] **Step 2: Run tests to verify failure on new styles/sizes**
- [ ] **Step 3: Implement CraftSearchBar refactoring with single-transaction spring animation, container tap interception, full surface styles, and haptics**
- [ ] **Step 4: Run tests to verify all pass**

---

### Task 2: Update Interactive Gallery Showcase in CraftCatalogView

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

- [ ] **Step 1: Add interactive style selector, size selector, and loading toggle in CraftCatalogView for CraftSearchBar**
- [ ] **Step 2: Run catalog test suite (`swift test --filter CatalogViewTests`) to verify 100% pass**

---

### Task 3: Build & Verification

**Files:**
- Test: `CraftUIKit/Tests/CraftUIKitTests/`

- [ ] **Step 1: Run full test suite (`swift test`)**
- [ ] **Step 2: Commit changes to git**
