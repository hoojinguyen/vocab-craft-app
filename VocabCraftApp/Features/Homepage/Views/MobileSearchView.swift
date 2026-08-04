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
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            TextField("Tra cứu từ vựng hoặc thẻ bài...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Button(action: onVoiceSearchTapped) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.vocabSurfaceSoft)
        .cornerRadius(14)
        .padding(.horizontal)
    }
}
