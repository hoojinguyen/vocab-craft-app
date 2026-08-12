import SwiftUI

public enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case vocabulary = 1
    case reflex = 2
    case settings = 3
    case search = 4

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .home: return "Trang chủ"
        case .vocabulary: return "Từ vựng"
        case .reflex: return "Phản xạ"
        case .settings: return "Cài đặt"
        case .search: return "Tra từ"
        }
    }

    public var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .vocabulary: return "book.fill"
        case .reflex: return "bolt.fill"
        case .settings: return "gearshape.fill"
        case .search: return "magnifyingglass"
        }
    }
}

public struct LiquidGlassTabBar: View {
    @Binding public var selectedTab: TabItem
    @Namespace private var animationNamespace

    public init(selectedTab: Binding<TabItem>) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        Group {
            if #available(iOS 26, macOS 26, *) {
                GlassEffectContainer(spacing: 8) {
                    tabContent
                        .glassEffect(.regular, in: Capsule())
                }
            } else {
                tabContent
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.35),
                                                Color.white.opacity(0.1),
                                                Color.black.opacity(0.08)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private var tabContent: some View {
        HStack(spacing: 4) {
            ForEach(TabItem.allCases) { tab in
                let isSelected = selectedTab == tab
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 17, weight: isSelected ? .bold : .medium))
                            .scaleEffect(isSelected ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .semibold, design: .rounded))
                    }
                    .foregroundColor(isSelected ? Color.vocabInk : Color.vocabMuted)
                    .padding(.vertical, 8)
                    .padding(.horizontal, isSelected ? 12 : 6)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background {
                        if isSelected {
                            if #available(iOS 26, macOS 26, *) {
                                Capsule()
                                    .fill(Color.vocabInk.opacity(0.12))
                                    .glassEffect(.regular.interactive(), in: Capsule())
                                    .glassEffectID("activeTabPill", in: animationNamespace)
                                    .glassEffectTransition(.matchedGeometry)
                            } else {
                                Capsule()
                                    .fill(Color.vocabInk.opacity(0.12))
                                    .matchedGeometryEffect(id: "activeTabIndicator", in: animationNamespace)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }
}

#Preview("Liquid Glass TabBar - Light") {
    ZStack(alignment: .bottom) {
        Color.vocabCanvas.ignoresSafeArea()
        LiquidGlassTabBar(selectedTab: .constant(.home))
    }
}

#Preview("Liquid Glass TabBar - Dark") {
    ZStack(alignment: .bottom) {
        Color.vocabCanvas.ignoresSafeArea()
        LiquidGlassTabBar(selectedTab: .constant(.vocabulary))
    }
    .preferredColorScheme(.dark)
}


