import SwiftUI

/// Dedicated Search New Word view serving as the entry point for looking up new vocabulary.
public struct SearchNewWordView: View {
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private let recentSearches = ["resilient", "ubiquitous", "ephemeral", "pragmatic", "meticulous"]
    private let suggestedTopics = [
        ("IELTS Band 7.0+", "sparkles", Color.orange),
        ("Business & Tech", "briefcase.fill", Color.blue),
        ("Academic Research", "book.closed.fill", Color.purple),
        ("Daily Expressions", "bubble.left.and.bubble.right.fill", Color.green)
    ]

    public init() {}

    public var body: some View {
        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Title
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            (Text(AppStrings.Tabs.search) + Text(" 🔍"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color.vocabInk)
                            Text(AppStrings.Homepage.searchPlaceholder)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.vocabMuted)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.vocabMuted)

                        TextField(AppStrings.Homepage.searchPlaceholder, text: $searchText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.vocabInk)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled(true)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.vocabMuted)
                            }
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 15))
                                .foregroundColor(Color.vocabMuted)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isSearchFocused ? Color.vocabInk.opacity(0.3) : Color.vocabHairline, lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)

                    // Future Feature Roadmap Banner
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.orange)
                            Text("TÍNH NĂNG SẮP RA MẮT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.orange)
                            Spacer()
                        }

                        Text("Tra cứu thông minh bằng AI Context")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.vocabInk)

                        Text("Hệ thống từ điển thông minh với AI giải thích ngữ cảnh tự nhiên, phát âm bản ngữ và tự động tạo thẻ nhớ SRS chuẩn bị được ra mắt.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.vocabMuted)
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.08), Color.vocabSurfaceCard],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1.5)
                    )
                    .padding(.horizontal)

                    // Recent Searches
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Từ vừa tìm kiếm")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentSearches, id: \.self) { word in
                                    Button(action: { searchText = word }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 11))
                                            Text(word)
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundColor(Color.vocabInk)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.vocabSurfaceCard)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.vocabHairline, lineWidth: 1.5)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Suggested Topics Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chủ đề từ vựng gợi ý")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.vocabInk)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(suggestedTopics, id: \.0) { topic in
                                HStack(spacing: 12) {
                                    Image(systemName: topic.1)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(topic.2)
                                        .frame(width: 36, height: 36)
                                        .background(topic.2.opacity(0.12))
                                        .cornerRadius(10)

                                    Text(topic.0)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color.vocabInk)
                                        .lineLimit(1)

                                    Spacer(minLength: 0)
                                }
                                .padding(12)
                                .background(Color.vocabSurfaceCard)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
    }
}
