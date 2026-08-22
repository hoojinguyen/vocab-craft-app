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
/// and smooth presentation transitions.
public struct CraftBottomSheet<Content: View>: View {
    @Environment(\.craftTheme) private var theme
    @Binding public var isPresented: Bool

    public let title: String?
    public let detents: [CraftSheetDetent]
    public let onDismiss: (() -> Void)?
    public let content: Content

    @GestureState private var dragTranslation: CGFloat = 0

    public init(
        isPresented: Binding<Bool>,
        title: String? = nil,
        detents: [CraftSheetDetent] = [.medium, .large],
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.detents = detents
        self.onDismiss = onDismiss
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            Capsule()
                .fill(theme.colors.borderDefault)
                .frame(width: 36, height: 4)
                .padding(.top, theme.spacing.sm)
                .padding(.bottom, theme.spacing.xs)

            // Header (if title exists)
            if let title, !title.isEmpty {
                HStack {
                    CraftText(title, style: .headline, color: theme.colors.textPrimary)
                    Spacer()
                    Button(action: dismissSheet) {
                        CraftIcon(.wrongCircle, size: .md, color: theme.colors.textMuted)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Dismiss")
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
        .background(theme.colors.surfaceCard)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: theme.radii.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: theme.radii.xl
            )
        )
        .craftShadow(theme.shadows.xl)
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

    private func dismissSheet() {
        withAnimation(theme.animations.springSmooth) {
            isPresented = false
        }
        onDismiss?()
    }
}

// MARK: - Bottom Sheet View Modifier

public struct CraftBottomSheetModifier<SheetContent: View>: ViewModifier {
    @Environment(\.craftTheme) private var theme
    @Binding public var isPresented: Bool
    public let title: String?
    public let detents: [CraftSheetDetent]
    public let onDismiss: (() -> Void)?
    public let sheetContent: SheetContent

    public init(
        isPresented: Binding<Bool>,
        title: String? = nil,
        detents: [CraftSheetDetent] = [.medium, .large],
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder sheetContent: () -> SheetContent
    ) {
        self._isPresented = isPresented
        self.title = title
        self.detents = detents
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
                    CraftBottomSheet(
                        isPresented: $isPresented,
                        title: title,
                        detents: detents,
                        onDismiss: onDismiss
                    ) {
                        sheetContent
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
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        modifier(
            CraftBottomSheetModifier(
                isPresented: isPresented,
                title: title,
                detents: detents,
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
        detents: [.medium, .large]
    ) {
        VStack(spacing: 16) {
            Text("Sheet Content Goes Here")
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
    }
}
