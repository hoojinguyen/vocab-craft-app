import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Tab Item Protocol

/// Contract for navigation tab items used in `CraftFloatingTabBar`.
public protocol CraftTabItemProtocol: Identifiable, Equatable, Sendable where ID: Sendable & Hashable {
    var id: ID { get }
    var title: String { get }
    var symbol: String { get }
    var badgeCount: Int? { get }
}

public extension CraftTabItemProtocol {
    var badgeCount: Int? {
        nil
    }
}

// MARK: - Tactile FAB Button Style

/// Tactile 3D button style for floating action button in `CraftFloatingTabBar`.
public struct CraftTactileFABButtonStyle: ButtonStyle {
    public let depth: CGFloat
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(depth: CGFloat = 4) {
        self.depth = depth
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let depressOffset = isPressed ? depth : 0

        ZStack {
            // Bottom 3D Bevel / Extrusion Lip
            Circle()
                .fill(theme.colors.brandSecondary)
                .offset(y: depth)

            // Top Tactile Face
            configuration.label
                .offset(y: depressOffset)
        }
        .padding(.bottom, depth)
        .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1.0)
        .animation(theme.animations.springSnappy, value: isPressed)
    }
}

// MARK: - CraftFloatingTabBar Component

/// A floating liquid-glass navigation bar featuring animated sliding tab indicators,
/// spring transitions, safe area handling, minimum 44pt touch targets, and an integrated tactile action button.
public struct CraftFloatingTabBar<Item: CraftTabItemProtocol>: View {
    @Environment(\.craftTheme) private var theme
    @Namespace private var tabNamespace

    @Binding public var selectedItem: Item
    public let items: [Item]
    public let centerAction: (() -> Void)?
    public let centerSymbol: String
    public let centerTitle: String?

    public init(
        selectedItem: Binding<Item>,
        items: [Item],
        centerAction: (() -> Void)? = nil,
        centerSymbol: String = "plus",
        centerTitle: String? = nil
    ) {
        self._selectedItem = selectedItem
        self.items = items
        self.centerAction = centerAction
        self.centerSymbol = centerSymbol
        self.centerTitle = centerTitle
    }

    private var leadingItems: [Item] {
        let mid = items.count / 2
        return Array(items.prefix(mid))
    }

    private var trailingItems: [Item] {
        let mid = items.count / 2
        return Array(items.suffix(from: mid))
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xs) {
            if let centerAction {
                ForEach(leadingItems) { item in
                    tabButton(for: item)
                }

                centerActionButton(action: centerAction)

                ForEach(trailingItems) { item in
                    tabButton(for: item)
                }
            } else {
                ForEach(items) { item in
                    tabButton(for: item)
                }
            }
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.xs)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
        }
        .craftShadow(theme.shadows.lg)
        .padding(.horizontal, theme.spacing.base)
        .padding(.bottom, theme.spacing.sm)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Tab Item Button

    @ViewBuilder
    private func tabButton(for item: Item) -> some View {
        let isSelected = selectedItem.id == item.id

        Button {
            #if os(iOS)
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
            #endif
            withAnimation(theme.animations.springSnappy) {
                selectedItem = item
            }
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    CraftIcon(
                        item.symbol,
                        size: .md,
                        color: isSelected ? theme.colors.brandPrimary : theme.colors.textMuted,
                        renderingMode: isSelected ? .hierarchical : .monochrome,
                        weight: isSelected ? .bold : .medium
                    )

                    if let badgeCount = item.badgeCount, badgeCount > 0 {
                        Text("\(min(badgeCount, 99))")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(theme.colors.statusDanger)
                            .clipShape(Capsule())
                            .offset(x: 8, y: -4)
                    }
                }

                Text(item.title)
                    .font(theme.typography.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? theme.colors.textPrimary : theme.colors.textMuted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 46)
            .padding(.vertical, 6)
            .padding(.horizontal, theme.spacing.xs)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(theme.colors.surfaceElevated.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(theme.colors.hairline, lineWidth: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                        )
                        .matchedGeometryEffect(id: "activeTabIndicator", in: tabNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: 0.95))
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    // MARK: - Center Action Button

    @ViewBuilder
    private func centerActionButton(action: @escaping () -> Void) -> some View {
        Button {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            #endif
            action()
        } label: {
            ZStack {
                // Top Surface Disc with Brand Hero Gradient & Top Highlight Stroke
                Circle()
                    .fill(theme.gradients.brandHero)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
                    )
                    .craftShadow(theme.shadows.sm)

                VStack(spacing: 2) {
                    CraftIcon(
                        centerSymbol,
                        size: .md,
                        color: theme.colors.textInverse,
                        renderingMode: .monochrome,
                        weight: .bold
                    )

                    if let centerTitle, !centerTitle.isEmpty {
                        Text(centerTitle)
                            .font(theme.typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textInverse)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: 48, height: 48)
            .contentShape(Circle())
        }
        .buttonStyle(CraftTactileFABButtonStyle(depth: theme.depths.depthMd))
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(centerTitle ?? "Action")
        .accessibilityAddTraits(.isButton)
    }
}

private struct _PreviewTab: CraftTabItemProtocol {
    let id: String
    let title: String
    let symbol: String
}

#Preview("CraftFloatingTabBar") {
    @Previewable @State var selected = _PreviewTab(id: "home", title: "Home", symbol: "house")
    
    let tabs = [
        _PreviewTab(id: "home", title: "Home", symbol: "house"),
        _PreviewTab(id: "search", title: "Search", symbol: "magnifyingglass"),
        _PreviewTab(id: "library", title: "Library", symbol: "books.vertical"),
        _PreviewTab(id: "profile", title: "Profile", symbol: "person")
    ]
    
    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        CraftFloatingTabBar(
            selectedItem: $selected,
            items: tabs,
            centerAction: { },
            centerSymbol: "plus"
        )
    }
}

