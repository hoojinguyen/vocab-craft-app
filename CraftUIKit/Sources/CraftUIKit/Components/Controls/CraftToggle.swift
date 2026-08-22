import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftToggleStyle

/// A custom `ToggleStyle` rendering a smooth, theme-colored toggle switch.
public struct CraftToggleStyle: ToggleStyle {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)

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
            .contentShape(Rectangle())
            .frame(minWidth: 44, minHeight: 44)
            .opacity(isEnabled ? 1.0 : 0.5)
            .onTapGesture {
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                #endif
                withAnimation(theme.animations.springSnappy) {
                    configuration.isOn.toggle()
                }
            }
        }
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

    public var isOn: Binding<Bool>
    public let title: String
    public let subtitle: String?
    public let iconName: String?

    public init(
        isOn: Binding<Bool>,
        title: String,
        subtitle: String? = nil,
        iconName: String? = nil
    ) {
        self.isOn = isOn
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
    }

    public var body: some View {
        HStack(spacing: theme.spacing.md) {
            if let iconName {
                CraftIcon(
                    iconName,
                    size: .lg,
                    color: isOn.wrappedValue ? theme.colors.brandPrimary : theme.colors.textMuted
                )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.craft)
        }
        .padding(.vertical, theme.spacing.xs)
        .frame(minHeight: 44)
    }
}
