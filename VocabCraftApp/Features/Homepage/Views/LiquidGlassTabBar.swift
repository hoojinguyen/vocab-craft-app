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
        HStack(spacing: 10) {
            // Main Tab Bar Capsule (Trang chủ, Từ vựng, Phản xạ, Cài đặt)
            Group {
                if #available(iOS 26, macOS 26, *) {
                    GlassEffectContainer(spacing: 4) {
                        mainTabsContent
                            .glassEffect(.regular, in: Capsule())
                    }
                } else {
                    mainTabsContent
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.45),
                                                    Color.white.opacity(0.12),
                                                    Color.black.opacity(0.06)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
                }
            }

            // Standalone Search Circle Button (Apple Music Search Button Style)
            let isSearchSelected = selectedTab == .search
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                    selectedTab = .search
                }
            }) {
                ZStack {
                    if isSearchSelected {
                        Circle()
                            .fill(Color.vocabMint.opacity(0.16))
                            .overlay(
                                Circle()
                                    .stroke(Color.vocabMint.opacity(0.4), lineWidth: 1)
                            )
                    }

                    Image(systemName: TabItem.search.symbol)
                        .font(.system(size: 20, weight: isSearchSelected ? .bold : .medium))
                        .foregroundColor(isSearchSelected ? Color.vocabMint : Color.vocabInk)
                        .scaleEffect(isSearchSelected ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSearchSelected)
                }
                .frame(width: 52, height: 52)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .background(
                Group {
                    if #available(iOS 26, macOS 26, *) {
                        Circle().glassEffect(.regular.interactive(), in: Circle())
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.45),
                                                Color.white.opacity(0.12),
                                                Color.black.opacity(0.06)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
                    }
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private var mainTabsContent: some View {
        HStack(spacing: 2) {
            let mainTabs: [TabItem] = [.home, .vocabulary, .reflex, .settings]
            ForEach(mainTabs) { tab in
                let isSelected = selectedTab == tab
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                    }
                    .foregroundColor(isSelected ? Color.vocabMint : Color.vocabMuted)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .contentShape(Rectangle()) // CRITICAL: Makes the entire tab area 100% tappable on real device!
                    .background {
                        if isSelected {
                            if #available(iOS 26, macOS 26, *) {
                                Capsule()
                                    .fill(Color.vocabMint.opacity(0.14))
                                    .glassEffect(.regular.tint(Color.vocabMint.opacity(0.2)).interactive(), in: Capsule())
                                    .glassEffectID("activeTabPill", in: animationNamespace)
                                    .glassEffectTransition(.matchedGeometry)
                            } else {
                                Capsule()
                                    .fill(Color.vocabMint.opacity(0.14))
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.vocabMint.opacity(0.35),
                                                        Color.vocabMint.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 0.8
                                            )
                                    )
                                    .matchedGeometryEffect(id: "activeTabIndicator", in: animationNamespace)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
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



