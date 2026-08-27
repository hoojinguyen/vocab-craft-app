import SwiftUI


struct LiquidGlassTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct CenterHeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

public struct LiquidGlassTabBar: View {
    @Binding public var selectedTab: TabItem
    @Namespace private var animationNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(selectedTab: Binding<TabItem>) {
        self._selectedTab = selectedTab
    }

    private var leftTabs: [TabItem] { [.home, .vocabulary] }
    private var rightTabs: [TabItem] { [.search, .settings] }

    public var body: some View {
        ZStack(alignment: .center) {
            // Main Dock Capsule Container
            Group {
                if #available(iOS 26, macOS 26, *) {
                    GlassEffectContainer(spacing: 0) {
                        dockContent
                            .glassEffect(.regular, in: Capsule())
                    }
                } else {
                    dockContent
                        .background(
                            Capsule()
                                .fill(.thinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.6),
                                                    Color.white.opacity(0.15)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private var dockContent: some View {
        HStack(spacing: 0) {
            // Left 2 items: Trang chủ, Từ vựng
            ForEach(leftTabs) { tab in
                tabButton(for: tab)
            }

            // Center Hero Search Button
            centerHeroButton

            // Right 2 items: Phản xạ, Cài đặt
            ForEach(rightTabs) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private func tabButton(for tab: TabItem) -> some View {
        let isSelected = selectedTab == tab
        Button(action: {
            let springAnimation = Animation.spring(response: 0.36, dampingFraction: 0.74)
            withAnimation(reduceMotion ? .none : springAnimation) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                    .scaleEffect(isSelected ? (reduceMotion ? 1.0 : 1.12) : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isSelected)

                if let titleKey = tab.titleKey {
                    Text(titleKey)
                        .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                } else if !tab.title.isEmpty {
                    Text(tab.title)
                        .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                }
            }
            .foregroundColor(isSelected ? Color.vocabMint : Color.vocabMuted)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    if #available(iOS 26, macOS 26, *) {
                        Capsule()
                            .fill(Color.dynamic(light: Color.white.opacity(0.85), dark: Color.white.opacity(0.12)))
                            .glassEffect(.regular.interactive(), in: Capsule())
                            .glassEffectID("activeTabPill", in: animationNamespace)
                            .glassEffectTransition(.matchedGeometry)
                    } else {
                        Capsule()
                            .fill(Color.dynamic(light: Color.white.opacity(0.85), dark: Color.white.opacity(0.12)))
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            .matchedGeometryEffect(id: "activeTabIndicator", in: animationNamespace)
                    }
                }
            }
        }
        .buttonStyle(LiquidGlassTabButtonStyle())
    }

    private var centerHeroButton: some View {
        let isSelected = selectedTab == .reflex
        return Button(action: {
            let springAnimation = Animation.spring(response: 0.36, dampingFraction: 0.74)
            withAnimation(reduceMotion ? .none : springAnimation) {
                selectedTab = .reflex
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.vocabMint,
                                Color.vocabMint.opacity(0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: Color.vocabMint.opacity(isSelected ? 0.5 : 0.3),
                        radius: isSelected ? 12 : 8,
                        x: 0,
                        y: isSelected ? 6 : 4
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )

                Image(systemName: "bolt.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(isSelected ? (reduceMotion ? 1.0 : 1.15) : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isSelected)
            }
            .frame(width: 48, height: 48)
            .padding(.horizontal, 6)
            .contentShape(Circle())
        }
        .buttonStyle(CenterHeroButtonStyle())
        .offset(y: -4) // Elevated slightly above dock baseline
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
