import SwiftUI

// MARK: - CraftListRow Component

/// A standardized, theme-driven list row with an icon container, title, subtitle,
/// trailing slot, and optional chevron with tactile press interaction.
public struct CraftListRow<TrailingContent: View>: View {
    @Environment(\.craftTheme) private var theme

    public let title: String
    public let subtitle: String?
    public let iconName: String?
    public let iconColor: Color?
    public let iconBackgroundColor: Color?
    public let showChevron: Bool
    public let action: (() -> Void)?
    public let trailingContent: TrailingContent

    public init(
        title: String,
        subtitle: String? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        iconBackgroundColor: Color? = nil,
        showChevron: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> TrailingContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.iconColor = iconColor
        self.iconBackgroundColor = iconBackgroundColor
        self.showChevron = showChevron
        self.action = action
        self.trailingContent = trailing()
    }

    public var body: some View {
        let rowContent = HStack(spacing: theme.spacing.md) {
            // Leading Icon Squircle
            if let iconName {
                let bg = iconBackgroundColor ?? theme.colors.surfaceSubtle
                let fg = iconColor ?? theme.colors.brandPrimary

                ZStack {
                    RoundedRectangle(cornerRadius: theme.radii.sm)
                        .fill(bg)
                        .frame(width: 36, height: 36)

                    CraftIcon(iconName, size: .md, color: fg)
                }
            }

            // Title and Subtitle
            VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
                CraftText(title, style: .headline, color: theme.colors.textPrimary)

                if let subtitle, !subtitle.isEmpty {
                    CraftText(subtitle, style: .caption, color: theme.colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Trailing Slot
            trailingContent

            // Optional Chevron
            if showChevron {
                CraftIcon("chevron.right", size: .sm, color: theme.colors.textMuted)
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.sm)
        .frame(minHeight: 52)
        .contentShape(Rectangle())

        if let action {
            Button(action: action) {
                rowContent
            }
            .buttonStyle(PlainButtonStyle())
            .craftPressEffect()
        } else {
            rowContent
        }
    }
}

// MARK: - Convenience Initializer without Trailing Slot

public extension CraftListRow where TrailingContent == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        iconName: String? = nil,
        iconColor: Color? = nil,
        iconBackgroundColor: Color? = nil,
        showChevron: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            iconName: iconName,
            iconColor: iconColor,
            iconBackgroundColor: iconBackgroundColor,
            showChevron: showChevron,
            action: action
        ) {
            EmptyView()
        }
    }
}
