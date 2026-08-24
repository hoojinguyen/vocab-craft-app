import SwiftUI

// MARK: - Sheet Detents

/// Supported detent sizes for custom bottom sheets.
public enum CraftSheetDetent: Sendable, Equatable {
    case medium
    case large
    case fraction(CGFloat)
    case height(CGFloat)
}

// MARK: - CraftBottomSheet Container

/// A customizable bottom sheet container featuring a drag handle, rounded top corners,
/// theme-driven surface styles (.elevated, .glass, .outlined, .flat), localized headers,
/// and smooth presentation transitions.
public struct CraftBottomSheet<Content: View>: View {
    @Environment(\.craftTheme) private var theme
    @Binding public var isPresented: Bool

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?

    public var title: String? { rawTitle }
    public let detents: [CraftSheetDetent]
    public let style: CraftSurfaceStyle
    public let onDismiss: (() -> Void)?
    public let content: Content

    @GestureState private var dragTranslation: CGFloat = 0

    public init(
        isPresented: Binding<Bool>,
        title: String? = nil,
        detents: [CraftSheetDetent] = [.medium, .large],
        style: CraftSurfaceStyle = .elevated,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.titleKey = nil
        self.rawTitle = title
        self.detents = detents
        self.style = style
        self.onDismiss = onDismiss
        self.content = content()
    }

    public init(
        isPresented: Binding<Bool>,
        titleKey: LocalizedStringKey,
        detents: [CraftSheetDetent] = [.medium, .large],
        style: CraftSurfaceStyle = .elevated,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.titleKey = titleKey
        self.rawTitle = nil
        self.detents = detents
        self.style = style
        self.onDismiss = onDismiss
        self.content = content()
    }

    public var body: some View {
        let sheetShape = UnevenRoundedRectangle(
            topLeadingRadius: theme.radii.xl,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: theme.radii.xl
        )

        VStack(spacing: 0) {
            // Drag Indicator
            Capsule()
                .fill(theme.colors.borderDefault)
                .frame(width: 36, height: 4)
                .padding(.top, theme.spacing.sm)
                .padding(.bottom, theme.spacing.xs)

            // Header (if title exists)
            if let titleKey {
                HStack {
                    CraftText(titleKey, style: .headline, color: theme.colors.textPrimary)
                    Spacer()
                    Button(action: dismissSheet) {
                        CraftIcon(.wrongCircle, size: .md, color: theme.colors.textMuted)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(CraftLocalized.string("craft.action.dismiss"))
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xs)
            } else if let rawTitle, !rawTitle.isEmpty {
                HStack {
                    CraftText(rawTitle, style: .headline, color: theme.colors.textPrimary)
                    Spacer()
                    Button(action: dismissSheet) {
                        CraftIcon(.wrongCircle, size: .md, color: theme.colors.textMuted)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(CraftLocalized.string("craft.action.dismiss"))
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xs)
            }

            // Sheet Body
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
        }
        .background(sheetBackground(shape: sheetShape))
        .clipShape(sheetShape)
        .overlay(sheetBorder(shape: sheetShape))
        .modifier(SheetShadowModifier(style: style, theme: theme))
        .offset(y: max(0, dragTranslation))
        .gesture(
            DragGesture()
                .updating($dragTranslation) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismissSheet()
                    }
                }
        )
    }

    @ViewBuilder
    private func sheetBackground(shape: UnevenRoundedRectangle) -> some View {
        switch style {
        case .glass:
            ZStack {
                shape.fill(.ultraThinMaterial)
                shape.fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
            }
        case .outlined, .elevated, .tactile3D:
            shape.fill(theme.colors.surfaceCard)
        case .flat:
            shape.fill(theme.colors.surfaceSubtle)
        }
    }

    @ViewBuilder
    private func sheetBorder(shape: UnevenRoundedRectangle) -> some View {
        switch style {
        case .glass:
            ZStack {
                shape.strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                shape.strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
            }
        case .outlined:
            shape.strokeBorder(theme.colors.borderDefault, lineWidth: 1)
        case .elevated:
            shape.strokeBorder(
                LinearGradient(
                    stops: [
                        .init(color: .craftDynamic(light: Color.white.opacity(0.8), dark: Color.white.opacity(0.18)), location: 0.0),
                        .init(color: theme.colors.borderDefault.opacity(0.4), location: 0.5),
                        .init(color: theme.colors.hairline, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
        case .flat, .tactile3D:
            EmptyView()
        }
    }

    private func dismissSheet() {
        withAnimation(theme.animations.springSmooth) {
            isPresented = false
        }
        onDismiss?()
    }
}

private struct SheetShadowModifier: ViewModifier {
    let style: CraftSurfaceStyle
    let theme: CraftTheme

    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            content.craftShadow(theme.shadows.xl)
        case .glass:
            content.craftShadow(theme.shadows.lg)
        case .flat, .outlined, .tactile3D:
            content
        }
    }
}

// MARK: - Bottom Sheet View Modifier

public struct CraftBottomSheetModifier<SheetContent: View>: ViewModifier {
    @Environment(\.craftTheme) private var theme
    @Binding public var isPresented: Bool
    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    public let detents: [CraftSheetDetent]
    public let style: CraftSurfaceStyle
    public let onDismiss: (() -> Void)?
    public let sheetContent: SheetContent

    public var title: String? { rawTitle }

    public init(
        isPresented: Binding<Bool>,
        title: String? = nil,
        detents: [CraftSheetDetent] = [.medium, .large],
        style: CraftSurfaceStyle = .elevated,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder sheetContent: () -> SheetContent
    ) {
        self._isPresented = isPresented
        self.titleKey = nil
        self.rawTitle = title
        self.detents = detents
        self.style = style
        self.onDismiss = onDismiss
        self.sheetContent = sheetContent()
    }

    public init(
        isPresented: Binding<Bool>,
        titleKey: LocalizedStringKey,
        detents: [CraftSheetDetent] = [.medium, .large],
        style: CraftSurfaceStyle = .elevated,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder sheetContent: () -> SheetContent
    ) {
        self._isPresented = isPresented
        self.titleKey = titleKey
        self.rawTitle = nil
        self.detents = detents
        self.style = style
        self.onDismiss = onDismiss
        self.sheetContent = sheetContent()
    }

    public func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                // Dimmed Scrim Backdrop
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(theme.animations.springSmooth) {
                            isPresented = false
                        }
                        onDismiss?()
                    }
                    .zIndex(999)

                // Slide-up Sheet
                VStack {
                    Spacer()
                    if let titleKey {
                        CraftBottomSheet(
                            isPresented: $isPresented,
                            titleKey: titleKey,
                            detents: detents,
                            style: style,
                            onDismiss: onDismiss
                        ) {
                            sheetContent
                        }
                    } else {
                        CraftBottomSheet(
                            isPresented: $isPresented,
                            title: rawTitle,
                            detents: detents,
                            style: style,
                            onDismiss: onDismiss
                        ) {
                            sheetContent
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(theme.animations.springSmooth, value: isPresented)
    }
}

// MARK: - View Extension

public extension View {
    /// Presents a custom modal bottom sheet with rounded top corners and drag dismiss gesture.
    func craftBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        detents: [CraftSheetDetent] = [.medium, .large],
        style: CraftSurfaceStyle = .elevated,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        modifier(
            CraftBottomSheetModifier(
                isPresented: isPresented,
                title: title,
                detents: detents,
                style: style,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
    }

    /// Presents a custom localized modal bottom sheet with rounded top corners and drag dismiss gesture.
    func craftBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        titleKey: LocalizedStringKey,
        detents: [CraftSheetDetent] = [.medium, .large],
        style: CraftSurfaceStyle = .elevated,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        modifier(
            CraftBottomSheetModifier(
                isPresented: isPresented,
                titleKey: titleKey,
                detents: detents,
                style: style,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
    }
}

#Preview("CraftBottomSheet") {
    @Previewable @State var isPresented = true

    return VStack {
        Button("Show Sheet") {
            isPresented = true
        }
    }
    .craftBottomSheet(
        isPresented: $isPresented,
        title: "Preview Sheet",
        detents: [.medium, .large],
        style: .glass
    ) {
        VStack(spacing: 16) {
            Text("Sheet Content Goes Here")
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
    }
}
