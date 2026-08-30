import SwiftUI

/// Layout alignment variant for `CraftPageHeader`.
public enum CraftHeaderAlignment: Sendable, Equatable {
    /// Large Title style (Leading-aligned title with `displayLarge` typography, Apple Books style).
    case leading
    /// Inline Title style (Centered title with `headline`/`titleLarge` typography).
    case center
}

/// A unified, slot-based navigation and page header organism in CraftUIKit with Apple Books scroll transition.
public struct CraftPageHeader<Leading: View, Trailing: View>: View {
    public let title: LocalizedStringKey
    public let subtitle: LocalizedStringKey?
    public let alignment: CraftHeaderAlignment
    public let enableScrollFade: Bool

    private let leadingContent: Leading
    private let trailingContent: Trailing

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.alignment = alignment
        self.enableScrollFade = enableScrollFade
        self.leadingContent = leading()
        self.trailingContent = trailing()
    }

    public init(
        verbatim titleText: String,
        subtitleVerbatim: String? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = LocalizedStringKey(titleText)
        self.subtitle = subtitleVerbatim.map { LocalizedStringKey($0) }
        self.alignment = alignment
        self.enableScrollFade = enableScrollFade
        self.leadingContent = leading()
        self.trailingContent = trailing()
    }

    public var body: some View {
        applyScrollTransition(
            headerLayout
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.xs)
                .accessibilityElement(children: .contain)
                .accessibilityAddTraits(.isHeader)
        )
    }

    @ViewBuilder
    private var headerLayout: some View {
        switch alignment {
        case .leading:
            leadingLayout
        case .center:
            centerLayout
        }
    }

    private var leadingLayout: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            leadingContent

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title, bundle: .module)
                    .font(theme.typography.displayLarge)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let subtitle {
                    Text(subtitle, bundle: .module)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: theme.spacing.xs)

            trailingContent
        }
    }

    private var centerLayout: some View {
        ZStack(alignment: .center) {
            HStack {
                leadingContent
                Spacer()
                trailingContent
            }

            VStack(alignment: .center, spacing: theme.spacing.xxs) {
                Text(title, bundle: .module)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let subtitle {
                    Text(subtitle, bundle: .module)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 48)
        }
    }

    @ViewBuilder
    private func applyScrollTransition<Content: View>(_ content: Content) -> some View {
        if enableScrollFade {
            let isReduceMotion = reduceMotion
            content.scrollTransition(.animated) { view, phase in
                view
                    .opacity(isReduceMotion ? (phase.isIdentity ? 1.0 : 0.0) : max(0.0, 1.0 - abs(phase.value) * 1.25))
                    .scaleEffect(isReduceMotion ? 1.0 : (1.0 - abs(phase.value) * 0.04))
                    .offset(y: isReduceMotion ? 0 : phase.value * -8)
            }
        } else {
            content
        }
    }
}

public extension CraftPageHeader where Leading == EmptyView, Trailing == EmptyView {
    init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true
    ) {
        self.init(
            title,
            subtitle: subtitle,
            alignment: alignment,
            enableScrollFade: enableScrollFade,
            leading: { EmptyView() },
            trailing: { EmptyView() }
        )
    }

    init(
        verbatim titleText: String,
        subtitleVerbatim: String? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true
    ) {
        self.init(
            verbatim: titleText,
            subtitleVerbatim: subtitleVerbatim,
            alignment: alignment,
            enableScrollFade: enableScrollFade,
            leading: { EmptyView() },
            trailing: { EmptyView() }
        )
    }
}

public extension CraftPageHeader where Trailing == EmptyView {
    init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true,
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(
            title,
            subtitle: subtitle,
            alignment: alignment,
            enableScrollFade: enableScrollFade,
            leading: leading,
            trailing: { EmptyView() }
        )
    }

    init(
        verbatim titleText: String,
        subtitleVerbatim: String? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true,
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(
            verbatim: titleText,
            subtitleVerbatim: subtitleVerbatim,
            alignment: alignment,
            enableScrollFade: enableScrollFade,
            leading: leading,
            trailing: { EmptyView() }
        )
    }
}

public extension CraftPageHeader where Leading == EmptyView {
    init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            title,
            subtitle: subtitle,
            alignment: alignment,
            enableScrollFade: enableScrollFade,
            leading: { EmptyView() },
            trailing: trailing
        )
    }

    init(
        verbatim titleText: String,
        subtitleVerbatim: String? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            verbatim: titleText,
            subtitleVerbatim: subtitleVerbatim,
            alignment: alignment,
            enableScrollFade: enableScrollFade,
            leading: { EmptyView() },
            trailing: trailing
        )
    }
}

#if canImport(PreviewsMacros)
#Preview("CraftPageHeader - Leading") {
    CraftPageHeader(
        "Home",
        subtitle: "Daily Learning Path",
        alignment: .leading
    ) {
        CraftBadge("🔥 14", tone: .success, size: .sm)
    }
    .background(CraftDefaultColorTokens().canvasBackground)
}

#Preview("CraftPageHeader - Center") {
    CraftPageHeader(
        "AI Tutor",
        subtitle: "Active Conversation",
        alignment: .center
    )
    .background(CraftDefaultColorTokens().canvasBackground)
}
#endif
