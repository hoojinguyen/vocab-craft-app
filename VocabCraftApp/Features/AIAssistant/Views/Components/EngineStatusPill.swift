import CraftUIKit
import SwiftUI

/// Compact pill badge presenting active AI engine status (On-Device Local vs Cloud Active).
/// Conforms to HIG Rule 1.1 with minimum 44x44pt touch target.
public struct EngineStatusPill: View {
    @Environment(\.craftTheme) private var theme

    private let minimumTouchTarget: CGFloat = 44

    public let isCloudConfigured: Bool
    public let onTap: () -> Void

    public init(isCloudConfigured: Bool, onTap: @escaping () -> Void) {
        self.isCloudConfigured = isCloudConfigured
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            CraftBadge(
                isCloudConfigured ? AppStrings.AIAssistant.engineCloud : AppStrings.AIAssistant.engineOnDevice,
                symbol: isCloudConfigured ? .checkmarkCircle : .sparkles,
                variant: .subtle,
                tone: isCloudConfigured ? .success : .neutral,
                size: .sm
            )
        }
        .buttonStyle(.plain)
        .frame(minWidth: minimumTouchTarget, minHeight: minimumTouchTarget)
        .contentShape(Rectangle())
        .accessibilityAddTraits(.isButton)
    }
}

#if DEBUG
#Preview("EngineStatusPill") {
    VStack(spacing: 16) {
        EngineStatusPill(isCloudConfigured: false, onTap: {})
        EngineStatusPill(isCloudConfigured: true, onTap: {})
    }
    .padding()
}
#endif
