import SwiftUI

public enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case vocabulary = 1
    case reflex = 2
    case settings = 3

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .home: return "Trang chủ"
        case .vocabulary: return "Từ vựng"
        case .reflex: return "Phản xạ"
        case .settings: return "Cài đặt"
        }
    }

    public var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .vocabulary: return "book.fill"
        case .reflex: return "bolt.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct LiquidGlassTabBar: View {
    @Binding public var selectedTab: TabItem

    public init(selectedTab: Binding<TabItem>) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        HStack {
            ForEach(TabItem.allCases) { tab in
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18))
                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .bold : .medium))
                    }
                    .foregroundColor(selectedTab == tab ? Color.vocabInk : Color.vocabMuted)
                    .padding(.vertical, 6)
                    .padding(.horizontal, selectedTab == tab ? 14 : 6)
                    .frame(minWidth: 48, minHeight: 48)
                    .background(selectedTab == tab ? Color.vocabInk.opacity(0.08) : Color.clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

