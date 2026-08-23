import SwiftUI

// MARK: - Depth Token Protocol

/// Tactile depth and top-edge bevel highlight tokens for layered physical UI components.
public protocol CraftDepthTokens: Sendable {
    /// Small 3D depth offset (2pt default)
    var depthSm: CGFloat { get }
    /// Medium 3D depth offset (4pt default)
    var depthMd: CGFloat { get }
    /// Large 3D depth offset (6pt default)
    var depthLg: CGFloat { get }
    /// Bevel / top-edge inner highlight gradient
    var topHighlight: LinearGradient { get }
}

public extension CraftDepthTokens {
    var depthSm: CGFloat { 2 }
    var depthMd: CGFloat { 4 }
    var depthLg: CGFloat { 6 }
    var topHighlight: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.35), Color.white.opacity(0.08), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Default Implementation

/// Default tactile depth tokens.
public struct CraftDefaultDepthTokens: CraftDepthTokens {
    public var depthSm: CGFloat
    public var depthMd: CGFloat
    public var depthLg: CGFloat
    public var topHighlight: LinearGradient

    public init(
        depthSm: CGFloat = 2,
        depthMd: CGFloat = 4,
        depthLg: CGFloat = 6,
        topHighlight: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.35), Color.white.opacity(0.08), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
    ) {
        self.depthSm = depthSm
        self.depthMd = depthMd
        self.depthLg = depthLg
        self.topHighlight = topHighlight
    }
}
