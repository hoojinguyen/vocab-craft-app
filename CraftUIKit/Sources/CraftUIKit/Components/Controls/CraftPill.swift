import SwiftUI

// MARK: - CraftPill / CraftFilterChip Component

/// A selectable filter chip / pill tag with active/inactive fill, stroke, and optional leading icon or counter.
public struct CraftPill: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    public let iconName: String?
    public let count: Int?
    public let isSelected: Bool
    public let action: () -> Void

    public var title: String? {
        rawTitle
    }

    public init(
        _ title: String,
        iconName: String? = nil,
        count: Int? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.iconName = iconName
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    public init(
        _ titleKey: LocalizedStringKey,
        iconName: String? = nil,
        count: Int? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.rawTitle = nil
        self.iconName = iconName
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.xs) {
                // Leading Icon Slot
                if let iconName {
                    CraftIcon(iconName, size: .sm, color: foregroundColor)
                }

                // Label Text
                if let titleKey {
                    Text(titleKey)
                        .font(theme.typography.label)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(foregroundColor)
                } else if let rawTitle {
                    Text(rawTitle)
                        .font(theme.typography.label)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(foregroundColor)
                }

                // Optional Count Badge
                if let count {
                    Text("\(count)")
                        .font(theme.typography.caption)
                        .fontWeight(.bold)
                        .contentTransition(.numericText())
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, theme.spacing.xs)
                        .background(countBadgeBackground)
                        .foregroundStyle(countBadgeForeground)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(backgroundFill)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: isSelected ? 1.5 : 1.0)
            )
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: 0.95))
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityElement(children: .combine)
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

#Preview("CraftPill") {
    @Previewable @State var isSelected1 = false
    @Previewable @State var isSelected2 = true
    
    return ScrollView {
        VStack(spacing: 24) {
            HStack {
                CraftPill("Unselected", isSelected: isSelected1) { isSelected1.toggle() }
                CraftPill("Selected", isSelected: isSelected2) { isSelected2.toggle() }
            }
            
            HStack {
                CraftPill("With Icon", iconName: "star", isSelected: false) {}
                CraftPill("Selected Icon", iconName: "heart.fill", isSelected: true) {}
            }
            
            HStack {
                CraftPill("Categories", count: 12) {}
                CraftPill("Filters", iconName: "line.3.horizontal.decrease", count: 3, isSelected: true) {}
            }
        }
        .padding()
    }
}
