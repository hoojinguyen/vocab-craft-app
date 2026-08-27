# CraftUIKit & Design System Rules

## 1. CraftUIKit-First Component Reuse Policy
- **Primary Component Source**: Before building any UI view or control, check `CraftUIKit` (`Packages/CraftUIKit/Sources/CraftUIKit/Components/`) for existing atoms, molecules, and containers (`CraftBadge`, `CraftIcon`, `CraftIconButton`, `CraftCard`, `CraftFlipCard`, `CraftProgressBar`, `CraftProgressRing`, `CraftStreakCard`, `CraftLearningPath`, etc.).
- **Zero Redundant Components**: Never recreate or duplicate components in the main application target when `CraftUIKit` already provides them.
- **Mandatory Human Consultation**: If no component in `CraftUIKit` satisfies the requirements, you must discuss with the human developer first before creating a new component or deciding to expand `CraftUIKit`.

## 2. Strict Design Tokens & Theme Conformance
- **Zero Raw Values**: Never hardcode hex codes, RGB values, raw colors (`Color.red`, `Color(hex: ...)`), ad-hoc fonts, hardcoded padding, or corner radii.
- **100% Token Adherence**: Strictly use `CraftUIKit` tokens:
  - Colors: `CraftColor` / `CraftColorTokens`
  - Typography: `CraftFont` / `CraftTypographyTokens`
  - Spacing & Radius: `CraftSpacingTokens`, `CraftRadiusTokens`
  - Shadow & Glass: `CraftShadowTokens`, `CraftGlassTokens`, `CraftDepthTokens`, `CraftGradientTokens`
- **Zero Unauthorized Styling**: Do not add new colors, fonts, or styling paradigms without explicit user approval.
