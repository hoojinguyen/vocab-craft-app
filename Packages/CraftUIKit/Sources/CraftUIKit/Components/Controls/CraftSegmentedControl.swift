import SwiftUI

// MARK: - CraftSegmentOption

/// Option model for individual segments in a `CraftSegmentedControl`.
public struct CraftSegmentOption<Value: Hashable & Sendable>: Identifiable, Sendable, Equatable {
    public let id: Value
    public let title: String
    public let count: Int?
    public let symbol: CraftSymbol?

    public init(
        _ id: Value,
        title: String,
        count: Int? = nil,
        symbol: CraftSymbol? = nil
    ) {
        self.id = id
        self.title = title
        self.count = count
        self.symbol = symbol
    }

    public static func == (lhs: CraftSegmentOption<Value>, rhs: CraftSegmentOption<Value>) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.count == rhs.count && lhs.symbol == rhs.symbol
    }
}

// MARK: - CraftSegmentedControl Component

/// A flexible, token-compliant segmented control for switching between categories or view modes.
/// Supports standard and liquid glass styles, count badges, optional leading icons, and spring animations.
public struct CraftSegmentedControl<Value: Hashable & Sendable>: View {
    @Environment(\.craftTheme) private var theme
    @Binding public var selection: Value
    public let options: [CraftSegmentOption<Value>]
    public let style: CraftSurfaceStyle
    public var onSelect: ((Value) -> Void)?

    @Namespace private var segmentNamespace

    public init(
        selection: Binding<Value>,
        options: [CraftSegmentOption<Value>],
        style: CraftSurfaceStyle = .glass,
        onSelect: ((Value) -> Void)? = nil
    ) {
        self._selection = selection
        self.options = options
        self.style = style
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(options) { option in
                let isSelected = selection == option.id

                Button(action: {
                    withAnimation(theme.animations.springSnappy) {
                        selection = option.id
                        onSelect?(option.id)
                    }
                }) {
                    HStack(spacing: theme.spacing.xs) {
                        if let symbol = option.symbol {
                            CraftIcon(symbol, size: .sm)
                                .foregroundStyle(isSelected ? theme.colors.textPrimary : theme.colors.textSecondary)
                        }

                        Text(verbatim: segmentLabel(for: option))
                            .font(theme.typography.label)
                            .fontWeight(isSelected ? .bold : .medium)
                            .foregroundStyle(isSelected ? theme.colors.textPrimary : theme.colors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .padding(.vertical, theme.spacing.sm)
                    .padding(.horizontal, theme.spacing.xs)
                    .frame(maxWidth: .infinity)
                    .background {
                        if isSelected {
                            segmentActiveBackground
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(theme.spacing.xs)
        .background(containerBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.md)
                .strokeBorder(containerBorder, lineWidth: 1)
        )
        .sensoryFeedback(.selection, trigger: selection)
    }

    // MARK: - Private Helpers & View Builders

    private func segmentLabel(for option: CraftSegmentOption<Value>) -> String {
        if let count = option.count {
            return "\(option.title) (\(count))"
        }
        return option.title
    }

    @ViewBuilder
    private var segmentActiveBackground: some View {
        if style == .glass {
            RoundedRectangle(cornerRadius: theme.radii.sm)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.sm)
                        .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                )
                .craftShadow(theme.shadows.sm)
        } else {
            RoundedRectangle(cornerRadius: theme.radii.sm)
                .fill(theme.colors.surfaceCard)
                .craftShadow(theme.shadows.sm)
        }
    }

    @ViewBuilder
    private var containerBackground: some View {
        if style == .glass {
            ZStack {
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
            }
        } else {
            theme.colors.surfaceSubtle
        }
    }

    private var containerBorder: some ShapeStyle {
        if style == .glass {
            return AnyShapeStyle(theme.glass.borderGradient)
        } else {
            return AnyShapeStyle(theme.colors.borderDefault)
        }
    }
}

// MARK: - Previews

#Preview("CraftSegmentedControl - Glass & Flat") {
    @Previewable @State var selectedFilter = "notMastered"
    let options = [
        CraftSegmentOption("notMastered", title: "Learning", count: 13),
        CraftSegmentOption("mastered", title: "Mastered", count: 13),
        CraftSegmentOption("saved", title: "Saved", count: 12)
    ]

    VStack(spacing: 24) {
        CraftSegmentedControl(
            selection: $selectedFilter,
            options: options,
            style: .glass
        )

        CraftSegmentedControl(
            selection: $selectedFilter,
            options: options,
            style: .flat
        )
    }
    .padding()
}
