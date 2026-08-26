import SwiftUI

// MARK: - CraftToggleStyle

/// A custom `ToggleStyle` rendering a smooth, theme-colored toggle switch.
public struct CraftToggleStyle: ToggleStyle {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public let showsLabel: Bool
    public let activeTint: Color?
    public let inactiveTint: Color?
    public let style: CraftSurfaceStyle

    public init(
        showsLabel: Bool = true,
        activeTint: Color? = nil,
        inactiveTint: Color? = nil,
        style: CraftSurfaceStyle = .flat
    ) {
        self.showsLabel = showsLabel
        self.activeTint = activeTint
        self.inactiveTint = inactiveTint
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            guard isEnabled else { return }
            withAnimation(theme.animations.springSnappy) {
                configuration.isOn.toggle()
            }
        }) {
            if showsLabel {
                HStack {
                    configuration.label
                        .font(theme.typography.bodyLarge)
                        .foregroundStyle(theme.colors.textPrimary)

                    Spacer()

                    switchControl(isOn: configuration.isOn)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            } else {
                switchControl(isOn: configuration.isOn)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.5)
        .sensoryFeedback(.selection, trigger: configuration.isOn)
    }

    @ViewBuilder
    private func switchControl(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            // Track
            if style == .glass && !isOn && inactiveTint == nil {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 28)
                    .overlay(
                        Capsule()
                            .fill(theme.colors.surfaceSubtle.opacity(theme.glass.tintOpacity))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                    )
            } else {
                Capsule()
                    .fill(trackFill(isOn: isOn))
                    .frame(width: 48, height: 28)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                trackBorder(isOn: isOn),
                                lineWidth: 1
                            )
                    )
            }

            // Thumb
            Circle()
                .fill(Color.white)
                .frame(width: 22, height: 22)
                .padding(3)
                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
        }
        .frame(width: 48, height: 28)
    }

    private func trackFill(isOn: Bool) -> Color {
        if isOn {
            return activeTint ?? theme.colors.brandPrimary
        } else {
            return inactiveTint ?? theme.colors.surfaceSubtle
        }
    }

    private func trackBorder(isOn: Bool) -> Color {
        if isOn {
            return Color.clear
        } else {
            return theme.colors.borderDefault
        }
    }
}

// MARK: - ToggleStyle Extension

public extension ToggleStyle where Self == CraftToggleStyle {
    /// Applies the standard theme-colored Craft toggle style with full row label and switch.
    static var craft: CraftToggleStyle {
        CraftToggleStyle(showsLabel: true)
    }

    /// Applies a customizable theme-colored Craft toggle style with full row label and switch.
    static func craft(
        activeTint: Color? = nil,
        inactiveTint: Color? = nil,
        style: CraftSurfaceStyle = .flat
    ) -> CraftToggleStyle {
        CraftToggleStyle(showsLabel: true, activeTint: activeTint, inactiveTint: inactiveTint, style: style)
    }

    /// Applies a standalone switch-only Craft toggle style without label or row spacer.
    static var craftSwitch: CraftToggleStyle {
        CraftToggleStyle(showsLabel: false)
    }

    /// Applies a customizable standalone switch-only Craft toggle style.
    static func craftSwitch(
        activeTint: Color? = nil,
        inactiveTint: Color? = nil,
        style: CraftSurfaceStyle = .flat
    ) -> CraftToggleStyle {
        CraftToggleStyle(showsLabel: false, activeTint: activeTint, inactiveTint: inactiveTint, style: style)
    }
}

// MARK: - Standalone CraftSwitch Component

/// A standalone theme-colored switch control without row label.
public struct CraftSwitch: View {
    @Binding public var isOn: Bool
    public let activeTint: Color?
    public let inactiveTint: Color?
    public let style: CraftSurfaceStyle

    public init(
        isOn: Binding<Bool>,
        activeTint: Color? = nil,
        inactiveTint: Color? = nil,
        style: CraftSurfaceStyle = .flat
    ) {
        self._isOn = isOn
        self.activeTint = activeTint
        self.inactiveTint = inactiveTint
        self.style = style
    }

    public var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .toggleStyle(.craftSwitch(activeTint: activeTint, inactiveTint: inactiveTint, style: style))
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
    public let activeTint: Color?
    public let inactiveTint: Color?
    public let style: CraftSurfaceStyle

    public var title: String? { rawTitle }
    public var subtitle: String? { rawSubtitle }

    public init(
        isOn: Binding<Bool>,
        title: String,
        subtitle: String? = nil,
        iconName: String? = nil,
        activeTint: Color? = nil,
        inactiveTint: Color? = nil,
        style: CraftSurfaceStyle = .flat
    ) {
        self.isOn = isOn
        self.titleKey = nil
        self.rawTitle = title
        self.subtitleKey = nil
        self.rawSubtitle = subtitle
        self.iconName = iconName
        self.activeTint = activeTint
        self.inactiveTint = inactiveTint
        self.style = style
    }

    public init(
        isOn: Binding<Bool>,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        iconName: String? = nil,
        activeTint: Color? = nil,
        inactiveTint: Color? = nil,
        style: CraftSurfaceStyle = .flat
    ) {
        self.isOn = isOn
        self.titleKey = title
        self.rawTitle = nil
        self.subtitleKey = subtitle
        self.rawSubtitle = nil
        self.iconName = iconName
        self.activeTint = activeTint
        self.inactiveTint = inactiveTint
        self.style = style
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
                        color: isOn.wrappedValue ? (activeTint ?? theme.colors.brandPrimary) : theme.colors.textMuted
                    )
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
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
                    if style == .glass && !isOn.wrappedValue && inactiveTint == nil {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .frame(width: 48, height: 28)
                            .overlay(
                                Capsule()
                                    .fill(theme.colors.surfaceSubtle.opacity(theme.glass.tintOpacity))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                            )
                    } else {
                        Capsule()
                            .fill(isOn.wrappedValue ? (activeTint ?? theme.colors.brandPrimary) : (inactiveTint ?? theme.colors.surfaceSubtle))
                            .frame(width: 48, height: 28)
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        isOn.wrappedValue ? Color.clear : theme.colors.borderDefault,
                                        lineWidth: 1
                                    )
                            )
                    }

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .padding(3)
                        .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                }
                .frame(width: 48, height: 28)
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
        .accessibilityValue(isOn.wrappedValue ? CraftLocalized.string("craft.common.state.on") : CraftLocalized.string("craft.common.state.off"))
    }
}

#Preview("CraftToggle") {
    @Previewable @State var isOn1 = false
    @Previewable @State var isOn2 = true
    @Previewable @State var isOn3 = true
    
    return ScrollView {
        VStack(spacing: 24) {
            CraftToggle(
                isOn: $isOn1,
                title: "Basic Toggle Off"
            )
            
            CraftToggle(
                isOn: $isOn2,
                title: "Basic Toggle On"
            )
            
            CraftToggle(
                isOn: $isOn3,
                title: "Notifications",
                subtitle: "Receive daily practice reminders",
                iconName: "bell"
            )
            
            CraftToggle(
                isOn: .constant(true),
                title: "Disabled State",
                subtitle: "This toggle cannot be changed"
            )
            .disabled(true)
        }
        .padding()
    }
}
