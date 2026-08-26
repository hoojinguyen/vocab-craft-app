import SwiftUI

// MARK: - CraftPill / CraftFilterChip Component

/// A selectable filter chip / pill tag with active/inactive fill, stroke, and optional leading icon or counter.
public struct CraftPill: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.craftSurfaceStyle) private var envStyle

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    public let iconName: String?
    public let count: Int?
    public let isSelected: Bool
    public let style: CraftSurfaceStyle?
    public let customTint: Color?
    public let action: () -> Void

    public var title: String? {
        rawTitle
    }

    public var resolvedStyle: CraftSurfaceStyle {
        style ?? envStyle
    }

    public init(
        _ title: String,
        iconName: String? = nil,
        count: Int? = nil,
        isSelected: Bool = false,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.iconName = iconName
        self.count = count
        self.isSelected = isSelected
        self.style = style
        self.customTint = customTint
        self.action = action
    }

    public init(
        _ titleKey: LocalizedStringKey,
        iconName: String? = nil,
        count: Int? = nil,
        isSelected: Bool = false,
        style: CraftSurfaceStyle? = nil,
        customTint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.rawTitle = nil
        self.iconName = iconName
        self.count = count
        self.isSelected = isSelected
        self.style = style
        self.customTint = customTint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            applyShadow(
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
                        Text(verbatim: "\(count)")
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
                .overlay(borderOverlay)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            )
        }
        .buttonStyle(.craftPress(scale: 0.95))
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }

    private var foregroundColor: Color {
        if isSelected {
            return customTint ?? theme.colors.brandPrimary
        }
        return theme.colors.textSecondary
    }

    @ViewBuilder
    private var backgroundFill: some View {
        let activeColor = customTint ?? theme.colors.brandPrimary
        if isSelected {
            if resolvedStyle == .glass {
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(activeColor.opacity(0.18))
                }
            } else {
                activeColor.opacity(0.12)
            }
        } else {
            switch resolvedStyle {
            case .glass:
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
                }
            case .flat:
                theme.colors.surfaceSubtle
            case .elevated:
                theme.colors.surfaceElevated
            case .outlined, .tactile3D:
                theme.colors.surfaceCard
            }
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        let activeColor = customTint ?? theme.colors.brandPrimary
        if isSelected {
            if resolvedStyle == .glass {
                ZStack {
                    Capsule().strokeBorder(theme.glass.borderGradient, lineWidth: 1.5)
                    Capsule().strokeBorder(activeColor.opacity(0.4), lineWidth: 1.5)
                }
            } else {
                Capsule().strokeBorder(activeColor, lineWidth: 1.5)
            }
        } else {
            switch resolvedStyle {
            case .flat:
                Capsule().strokeBorder(theme.colors.borderDefault, lineWidth: 1.0)
            case .elevated:
                Capsule().strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .craftDynamic(light: Color.white.opacity(0.7), dark: Color.white.opacity(0.16)), location: 0.0),
                            .init(color: .craftDynamic(light: theme.colors.hairline.opacity(0.4), dark: Color.white.opacity(0.04)), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
            case .outlined:
                Capsule().strokeBorder(theme.colors.borderDefault, lineWidth: 1.0)
            case .tactile3D:
                ZStack {
                    Capsule().strokeBorder(theme.colors.borderDefault, lineWidth: 1.0)
                    Capsule().strokeBorder(theme.depths.topHighlight, lineWidth: 1.0)
                }
            case .glass:
                Capsule().strokeBorder(theme.glass.borderGradient, lineWidth: 1.0)
            }
        }
    }

    @ViewBuilder
    private func applyShadow<V: View>(_ view: V) -> some View {
        switch resolvedStyle {
        case .elevated:
            view.craftShadow(theme.shadows.sm)
        case .glass:
            view.craftShadow(theme.shadows.sm)
        case .flat, .outlined, .tactile3D:
            view
        }
    }

    private var countBadgeBackground: Color {
        if isSelected {
            return customTint ?? theme.colors.brandPrimary
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
