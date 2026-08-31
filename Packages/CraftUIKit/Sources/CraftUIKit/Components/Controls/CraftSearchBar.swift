import SwiftUI

// MARK: - SearchBar Enums

/// Visual style variants for CraftSearchBar supporting CraftUIKit's full surface spectrum.
public enum CraftSearchBarStyle: String, Sendable, CaseIterable {
    case standard
    case flat
    case elevated
    case outlined
    case recessed
    case tactile3D
    case glass

    public var surfaceStyle: CraftSurfaceStyle {
        switch self {
        case .standard, .flat: return .flat
        case .elevated: return .elevated
        case .outlined: return .outlined
        case .recessed: return .flat
        case .tactile3D: return .tactile3D
        case .glass: return .glass
        }
    }
}

/// Sizing tiers for CraftSearchBar.
public enum CraftSearchBarSize: String, Sendable, CaseIterable {
    case sm
    case md
    case lg

    public var height: CGFloat {
        switch self {
        case .sm: return 36
        case .md: return 44
        case .lg: return 52
        }
    }

    public var iconSize: CraftIconSize {
        switch self {
        case .sm: return .sm
        case .md: return .md
        case .lg: return .md
        }
    }

    public var horizontalPadding: CGFloat {
        switch self {
        case .sm: return 10
        case .md: return 12
        case .lg: return 16
        }
    }
}

/// Border geometry shape for CraftSearchBar.
public enum CraftSearchBarShape: Sendable, Equatable {
    case capsule
    case roundedRectangle(radius: CGFloat)
}

// MARK: - Backing Shape

private struct CraftSearchBarBackingShape: Shape {
    let shape: CraftSearchBarShape

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .capsule:
            return Capsule().path(in: rect)
        case .roundedRectangle(let radius):
            return RoundedRectangle(cornerRadius: radius).path(in: rect)
        }
    }
}

// MARK: - CraftSearchBar Component

/// A high-performance, tactile, and full-spectrum styled search input bar with focus glow, clear action, sensory haptics, and optional trailing actions.
public struct CraftSearchBar: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @FocusState private var isFocused: Bool
    @State private var clearHapticTrigger: Bool = false
    @State private var cancelHapticTrigger: Bool = false

    public var text: Binding<String>
    private let placeholderKey: LocalizedStringKey?
    private let rawPlaceholder: String?
    public let size: CraftSearchBarSize
    public let style: CraftSearchBarStyle
    public let shape: CraftSearchBarShape
    public let customTint: Color?
    public let customGradient: LinearGradient?
    public let trailingIcon: String?
    public let trailingAction: (() -> Void)?
    public let isLoading: Bool
    public let onCancel: (() -> Void)?
    public let onSubmit: (() -> Void)?

    public var placeholder: String {
        rawPlaceholder ?? CraftLocalized.string("craft.search.placeholder")
    }

    public init(
        text: Binding<String>,
        placeholder: String = CraftLocalized.string("craft.search.placeholder"),
        size: CraftSearchBarSize = .md,
        style: CraftSearchBarStyle = .standard,
        shape: CraftSearchBarShape = .capsule,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        isLoading: Bool = false,
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.text = text
        self.placeholderKey = nil
        self.rawPlaceholder = placeholder
        self.size = size
        self.style = style
        self.shape = shape
        self.customTint = customTint
        self.customGradient = customGradient
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
        self.isLoading = isLoading
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    public init(
        text: Binding<String>,
        placeholder: LocalizedStringKey,
        size: CraftSearchBarSize = .md,
        style: CraftSearchBarStyle = .standard,
        shape: CraftSearchBarShape = .capsule,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        isLoading: Bool = false,
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.text = text
        self.placeholderKey = placeholder
        self.rawPlaceholder = nil
        self.size = size
        self.style = style
        self.shape = shape
        self.customTint = customTint
        self.customGradient = customGradient
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
        self.isLoading = isLoading
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Search Input Field Container
            HStack(spacing: size == .sm ? theme.spacing.xs : theme.spacing.sm) {
                // Leading Icon or Loading Spinner
                if isLoading {
                    CraftSpinner(size: size.iconSize, color: customTint ?? theme.colors.brandPrimary)
                } else {
                    CraftIcon(
                        .search,
                        size: size.iconSize,
                        color: isFocused ? (customTint ?? theme.colors.borderFocus) : theme.colors.textMuted
                    )
                }

                // Text Input
                Group {
                    if let placeholderKey {
                        TextField(placeholderKey, text: text)
                    } else {
                        TextField(placeholder, text: text)
                    }
                }
                .font(textFieldFont)
                .foregroundStyle(theme.colors.textPrimary)
                .focused($isFocused)
                .autocorrectionDisabled()
                #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
                .textInputAutocapitalization(.never)
                #endif
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }

                // Clear Action Button
                if !text.wrappedValue.isEmpty && !isLoading {
                    Button(action: {
                        text.wrappedValue = ""
                        clearHapticTrigger.toggle()
                    }) {
                        CraftIcon(.wrongCircle, size: .sm, color: theme.colors.textMuted)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 32, minHeight: 32)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .sensoryFeedback(.impact(weight: .light), trigger: clearHapticTrigger)
                    .accessibilityLabel(CraftLocalized.string("craft.search.clear_a11y"))
                }

                // Optional Trailing Action Icon Button
                if let trailingIcon, let trailingAction {
                    Button(action: trailingAction) {
                        CraftIcon(
                            trailingIcon,
                            size: .sm,
                            color: isFocused ? (customTint ?? theme.colors.brandPrimary) : theme.colors.textMuted
                        )
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 32, minHeight: 32)
                    .accessibilityLabel(CraftLocalized.string("craft.search.trailing_action_a11y"))
                }
            }
            .padding(.horizontal, size.horizontalPadding)
            .frame(height: size.height)
            .background(backgroundView)
            .clipShape(searchShape)
            .overlay(borderOverlay)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isFocused {
                    isFocused = true
                }
            }

            // Cancel Button — scoped animation to avoid animating entire HStack
            Group {
                if isFocused && onCancel != nil {
                    Button(action: {
                        isFocused = false
                        cancelHapticTrigger.toggle()
                        onCancel?()
                    }) {
                        Text(CraftLocalized.string("craft.common.action.cancel"))
                            .font(cancelButtonFont)
                            .foregroundStyle(customTint ?? theme.colors.brandPrimary)
                            .padding(.horizontal, 4)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .sensoryFeedback(.selection, trigger: cancelHapticTrigger)
                }
            }
            .animation(theme.animations.springSnappy, value: isFocused)
        }
    }

    private var textFieldFont: Font {
        switch size {
        case .sm: return theme.typography.caption
        case .md: return theme.typography.bodyMedium
        case .lg: return theme.typography.bodyLarge
        }
    }

    private var cancelButtonFont: Font {
        switch size {
        case .sm: return theme.typography.label
        case .md: return theme.typography.bodyMedium
        case .lg: return theme.typography.bodyLarge
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if let customGradient {
            searchShape.fill(customGradient)
        } else if let customTint {
            switch style {
            case .glass:
                ZStack {
                    searchShape.fill(.ultraThinMaterial)
                    searchShape.fill(customTint.opacity(theme.glass.tintOpacity))
                }
            case .tactile3D, .elevated, .outlined:
                searchShape.fill(theme.colors.surfaceCard)
            case .standard, .flat:
                searchShape.fill(customTint.opacity(0.12))
            case .recessed:
                ZStack {
                    customTint.opacity(0.15)
                    LinearGradient(
                        colors: [Color.black.opacity(0.15), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        } else {
            switch style {
            case .standard, .flat:
                theme.colors.surfaceSubtle
            case .elevated:
                theme.colors.surfaceElevated
            case .outlined:
                theme.colors.surfaceCard
            case .recessed:
                ZStack {
                    theme.colors.surfaceSubtle.opacity(0.6)
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            case .tactile3D:
                theme.colors.surfaceCard
            case .glass:
                ZStack {
                    searchShape.fill(.ultraThinMaterial)
                    searchShape.fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
                }
            }
        }
    }

    private var searchShape: CraftSearchBarBackingShape {
        CraftSearchBarBackingShape(shape: shape)
    }

    @ViewBuilder
    private var borderOverlay: some View {
        let strokeWidth: CGFloat = isFocused ? 1.5 : 1.0

        if isFocused {
            shapeStroke(color: customTint ?? theme.colors.borderFocus, width: strokeWidth)
        } else {
            switch style {
            case .standard, .flat:
                shapeStroke(color: theme.colors.borderDefault, width: strokeWidth)
            case .elevated:
                shapeStroke(
                    gradient: LinearGradient(
                        stops: [
                            .init(color: .craftDynamic(light: Color.white.opacity(0.7), dark: Color.white.opacity(0.16)), location: 0.0),
                            .init(color: .craftDynamic(light: theme.colors.hairline.opacity(0.4), dark: Color.white.opacity(0.04)), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    width: strokeWidth
                )
            case .outlined:
                shapeStroke(color: theme.colors.borderDefault, width: strokeWidth)
            case .recessed:
                shapeStroke(color: theme.colors.hairline, width: strokeWidth)
            case .tactile3D:
                shapeStroke(
                    gradient: LinearGradient(
                        stops: [
                            .init(color: .craftDynamic(light: Color.white.opacity(0.75), dark: Color.white.opacity(0.20)), location: 0.0),
                            .init(color: theme.colors.borderDefault.opacity(0.6), location: 0.4),
                            .init(color: theme.colors.borderDefault, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    width: strokeWidth
                )
            case .glass:
                shapeStroke(gradient: theme.glass.borderGradient, width: strokeWidth)
            }
        }
    }

    @ViewBuilder
    private func shapeStroke(color: Color, width: CGFloat) -> some View {
        switch shape {
        case .capsule:
            Capsule().strokeBorder(color, lineWidth: width)
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius).strokeBorder(color, lineWidth: width)
        }
    }

    @ViewBuilder
    private func shapeStroke(gradient: LinearGradient, width: CGFloat) -> some View {
        switch shape {
        case .capsule:
            Capsule().strokeBorder(gradient, lineWidth: width)
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius).strokeBorder(gradient, lineWidth: width)
        }
    }
}

#if canImport(PreviewsMacros)
#Preview("CraftSearchBar") {
    @Previewable @State var emptyText = ""
    @Previewable @State var filledText = "SwiftUI"

    return ScrollView {
        VStack(spacing: 24) {
            ForEach(CraftSearchBarSize.allCases, id: \.self) { size in
                CraftSearchBar(
                    text: $emptyText,
                    placeholder: "Search size \(size.rawValue)...",
                    size: size
                )
            }

            ForEach(CraftSearchBarStyle.allCases, id: \.self) { style in
                CraftSearchBar(
                    text: $filledText,
                    placeholder: "Search \(style.rawValue)...",
                    style: style,
                    onCancel: { filledText = "" }
                )
            }

            CraftSearchBar(
                text: $filledText,
                placeholder: "Loading spinner...",
                isLoading: true
            )
        }
        .padding()
    }
}
#endif
