import CraftUIKit
import SwiftUI

public struct MobileSearchView: View {
    @Environment(\.craftTheme) private var theme
    @Binding public var searchText: String
    public var onVoiceSearchTapped: () -> Void

    public init(searchText: Binding<String>, onVoiceSearchTapped: @escaping () -> Void) {
        self._searchText = searchText
        self.onVoiceSearchTapped = onVoiceSearchTapped
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.colors.accent)

            TextField(AppStrings.Search.placeholder, text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }

            Button(action: onVoiceSearchTapped) {
                ZStack {
                    Circle()
                        .fill(theme.colors.accent.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.colors.accent)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.colors.surfaceCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.colors.hairline, lineWidth: 1.5)
        )
        .shadow(color: theme.colors.brandPrimary.opacity(0.05), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}
