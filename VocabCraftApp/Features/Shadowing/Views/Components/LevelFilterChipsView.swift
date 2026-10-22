import CraftUIKit
import SwiftUI

public struct LevelFilterChipsView: View {
    @Environment(\.craftTheme) private var theme

    public let selectedLevel: String?
    public let levels: [String]
    public let onSelectLevel: (String?) -> Void

    public init(
        selectedLevel: String?,
        levels: [String] = ["A1", "A2", "B1", "B2"],
        onSelectLevel: @escaping (String?) -> Void
    ) {
        self.selectedLevel = selectedLevel
        self.levels = levels
        self.onSelectLevel = onSelectLevel
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
                CraftPill(
                    LocalizedStringKey("app.shadowing.hub.filter_all"),
                    isSelected: selectedLevel == nil,
                    action: { onSelectLevel(nil) }
                )

                ForEach(levels, id: \.self) { level in
                    let isSelected = selectedLevel?.localizedCaseInsensitiveCompare(level) == .orderedSame
                    CraftPill(
                        level,
                        isSelected: isSelected,
                        action: { onSelectLevel(level) }
                    )
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.xs)
        }
    }
}
