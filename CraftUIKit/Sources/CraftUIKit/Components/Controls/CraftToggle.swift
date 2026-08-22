import SwiftUI

// MARK: - CraftToggleStyle

/// A custom `ToggleStyle` rendering a smooth, theme-colored toggle switch.
public struct CraftToggleStyle: ToggleStyle {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            guard isEnabled else { return }
            withAnimation(theme.animations.springSnappy) {
                configuration.isOn.toggle()
            }
        }) {
            HStack {
                configuration.label
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(theme.colors.textPrimary)

                Spacer()

                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    // Track
                    Capsule()
                        .fill(configuration.isOn ? theme.colors.brandPrimary : theme.colors.surfaceSubtle)
                        .frame(width: 50, height: 30)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    configuration.isOn ? Color.clear : theme.colors.borderDefault,
                                    lineWidth: 1
                                )
                        )

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .padding(3)
                        .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                }
                .frame(width: 50, height: 30)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.5)
        .sensoryFeedback(.selection, trigger: configuration.isOn)
    }
}

// MARK: - ToggleStyle Extension

public extension ToggleStyle where Self == CraftToggleStyle {
    /// Applies the standard theme-colored Craft toggle style.
    static var craft: CraftToggleStyle {
        CraftToggleStyle()
    }
}

// MARK: - CraftToggle View

/// A full-row toggle control with title, optional subtitle, and optional leading icon.
public struct CraftToggle: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public var isOn: Binding<Bool>
    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let subtitleKey: LocalizedStringKey?
    private let rawSubtitle: String?
    public let iconName: String?

    public var title: String? { rawTitle }
    public var subtitle: String? { rawSubtitle }

    public init(
        isOn: Binding<Bool>,
        title: String,
        subtitle: String? = nil,
        iconName: String? = nil
    ) {
        self.isOn = isOn
        self.titleKey = nil
        self.rawTitle = title
        self.subtitleKey = nil
        self.rawSubtitle = subtitle
        self.iconName = iconName
    }

    public init(
        isOn: Binding<Bool>,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        iconName: String? = nil
    ) {
        self.isOn = isOn
        self.titleKey = title
        self.rawTitle = nil
        self.subtitleKey = subtitle
        self.rawSubtitle = nil
        self.iconName = iconName
    }

    public var body: some View {
        Button(action: {
            guard isEnabled else { return }
            withAnimation(theme.animations.springSnappy) {
                isOn.wrappedValue.toggle()
            }
        }) {
            HStack(spacing: theme.spacing.md) {
                if let iconName {
                    CraftIcon(
                        iconName,
                        size: .lg,
                        color: isOn.wrappedValue ? theme.colors.brandPrimary : theme.colors.textMuted
                    )
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let titleKey {
                        Text(titleKey)
                            .font(theme.typography.bodyLarge)
                            .foregroundStyle(theme.colors.textPrimary)
                    } else if let rawTitle {
                        Text(rawTitle)
                            .font(theme.typography.bodyLarge)
                            .foregroundStyle(theme.colors.textPrimary)
                    }

                    if let subtitleKey {
                        Text(subtitleKey)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    } else if let rawSubtitle, !rawSubtitle.isEmpty {
                        Text(rawSubtitle)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }

                Spacer()

                // Switch Visual Indicator
                ZStack(alignment: isOn.wrappedValue ? .trailing : .leading) {
                    // Track
                    Capsule()
                        .fill(isOn.wrappedValue ? theme.colors.brandPrimary : theme.colors.surfaceSubtle)
                        .frame(width: 50, height: 30)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isOn.wrappedValue ? Color.clear : theme.colors.borderDefault,
                                    lineWidth: 1
                                )
                        )

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .padding(3)
                        .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                }
                .frame(width: 50, height: 30)
            }
            .padding(.vertical, theme.spacing.xs)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.5)
        .sensoryFeedback(.selection, trigger: isOn.wrappedValue)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn.wrappedValue ? [.isButton, .isSelected] : [.isButton])
        .accessibilityValue(isOn.wrappedValue ? "On" : "Off")
    }
}
