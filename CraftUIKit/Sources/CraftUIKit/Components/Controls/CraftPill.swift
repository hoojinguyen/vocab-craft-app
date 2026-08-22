import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftPill / CraftFilterChip Component

/// A selectable filter chip / pill tag with active/inactive fill, stroke, and optional leading icon or counter.
public struct CraftPill: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public let title: String
    public let iconName: String?
    public let count: Int?
    public let isSelected: Bool
    public let action: () -> Void

    public init(
        _ title: String,
        iconName: String? = nil,
        count: Int? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            #endif
            action()
        }) {
            HStack(spacing: theme.spacing.xs) {
                // Leading Icon Slot
                if let iconName {
                    CraftIcon(iconName, size: .sm, color: foregroundColor)
                }

                // Label Text
                Text(title)
                    .font(theme.typography.label)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(foregroundColor)

                // Optional Count Badge
                if let count {
                    Text("\(count)")
                        .font(theme.typography.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(countBadgeBackground)
                        .foregroundColor(countBadgeForeground)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, 6)
            .background(backgroundFill)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: isSelected ? 1.5 : 1.0)
            )
            .contentShape(Rectangle())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .craftPressEffect(scale: 0.95)
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }

    private var foregroundColor: Color {
        if isSelected {
            return theme.colors.brandPrimary
        }
        return theme.colors.textSecondary
    }

    private var backgroundFill: Color {
        if isSelected {
            return theme.colors.brandPrimary.opacity(0.12)
        }
        return theme.colors.surfaceSubtle
    }

    private var borderColor: Color {
        if isSelected {
            return theme.colors.brandPrimary
        }
        return theme.colors.borderDefault
    }

    private var countBadgeBackground: Color {
        if isSelected {
            return theme.colors.brandPrimary
        }
        return theme.colors.borderDefault
    }

    private var countBadgeForeground: Color {
        if isSelected {
            return .white
        }
        return theme.colors.textSecondary
    }
}

// MARK: - Typealias

/// Semantic alias for filter chip use cases.
public typealias CraftFilterChip = CraftPill
