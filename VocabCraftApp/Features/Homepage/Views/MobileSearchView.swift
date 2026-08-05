import SwiftUI

public struct MobileSearchView: View {
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
                .foregroundColor(.vocabHeroTeal)
            
            TextField("Tra cứu từ vựng hoặc thẻ bài...", text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.vocabInk)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.vocabMuted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            
            Button(action: onVoiceSearchTapped) {
                ZStack {
                    Circle()
                        .fill(Color.vocabHeroTeal.opacity(0.08))
                        .frame(width: 32, height: 32)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.vocabHeroTeal)
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
                .fill(Color.vocabSurfaceCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.vocabHeroTeal.opacity(0.05), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}

