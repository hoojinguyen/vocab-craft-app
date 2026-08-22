import SwiftUI

/// Root protocol defining a theme in CraftUIKit.
///
/// All design tokens (colors, typography, spacing, corner radii, drop shadows,
/// gradients, and animations) are accessed through this contract.
public protocol CraftTheme: Sendable {
    var colors: CraftColorTokens { get }
    var typography: CraftTypographyTokens { get }
    var spacing: CraftSpacingTokens { get }
    var radii: CraftRadiusTokens { get }
    var shadows: CraftShadowTokens { get }
    var gradients: CraftGradientTokens { get }
    var animations: CraftAnimationTokens { get }
    var opacities: CraftOpacityTokens { get }
}
