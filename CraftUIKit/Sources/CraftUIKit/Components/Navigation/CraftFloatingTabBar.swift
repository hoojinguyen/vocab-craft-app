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
}

// MARK: - CraftFloatingTabBar Component

/// A floating liquid-glass navigation bar featuring animated sliding tab indicators,
/// spring transitions, safe area handling, minimum 44pt touch targets, and an optional elevated FAB slot.
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

                centerFAB(action: centerAction)

                ForEach(trailingItems) { item in
                    tabButton(for: item)
                }
            } else {
                ForEach(items) { item in
                    tabButton(for: item)
                }
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.hairline, lineWidth: 1)
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
                Image(systemName: item.symbol)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)

                Text(item.title)
                    .font(theme.typography.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? theme.colors.brandPrimary : theme.colors.textMuted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.vertical, theme.spacing.xs)
            .padding(.horizontal, theme.spacing.xs)
            .background {
                if isSelected {
                    Capsule()
                        .fill(theme.colors.brandPrimary.opacity(0.12))
                        .matchedGeometryEffect(id: "activeTabIndicator", in: tabNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .craftPressEffect(scale: 0.95)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    // MARK: - Center Elevated FAB

    @ViewBuilder
    private func centerFAB(action: @escaping () -> Void) -> some View {
        Button {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            #endif
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(theme.gradients.brandHero)
                    .frame(width: 48, height: 48)
                    .craftShadow(theme.shadows.md)

                VStack(spacing: 2) {
                    Image(systemName: centerSymbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    if let centerTitle, !centerTitle.isEmpty {
                        Text(centerTitle)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .craftPressEffect(scale: 0.90)
        .accessibilityLabel(centerTitle ?? "Action")
        .accessibilityAddTraits(.isButton)
    }
}
