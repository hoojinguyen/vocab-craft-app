import CraftUIKit
import SwiftUI

/// Dedicated Search New Word view serving as the entry point for looking up new vocabulary.
public struct SearchNewWordView: View {
    @Environment(\.craftTheme) private var theme
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private let recentSearches = ["resilient", "ubiquitous", "ephemeral", "pragmatic", "meticulous"]

    private var suggestedTopics: [(String, String, Color)] {
        [
            ("IELTS Band 7.0+", "sparkles", theme.colors.accent),
            ("Business & Tech", "briefcase.fill", theme.colors.statusInfo),
            ("Academic Research", "book.closed.fill", theme.colors.statusDanger),
            ("Daily Expressions", "bubble.left.and.bubble.right.fill", theme.colors.statusSuccess)
        ]
    }

    public init() {}

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Title
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            (Text(AppStrings.Tabs.search) + Text(" 🔍"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(theme.colors.textPrimary)
                            Text(AppStrings.Homepage.searchPlaceholder)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.colors.textSecondary)

                        TextField(AppStrings.Homepage.searchPlaceholder, text: $searchText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.colors.textPrimary)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled(true)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 15))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(theme.colors.surfaceCard)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isSearchFocused ? theme.colors.textPrimary.opacity(0.3) : theme.colors.hairline, lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)

                    // Future Feature Roadmap Banner
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(theme.colors.accent)
                            Text(AppStrings.Search.upcomingFeatureTitle)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.colors.accent)
                            Spacer()
                        }

                        Text(AppStrings.Search.smartLookupTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.colors.textPrimary)

                        Text(AppStrings.Search.smartLookupDescription)
                            .font(.system(size: 13))
                            .foregroundColor(theme.colors.textSecondary)
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [theme.colors.accent.opacity(0.08), theme.colors.surfaceCard],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(theme.colors.accent.opacity(0.2), lineWidth: 1.5)
                    )
                    .padding(.horizontal)

                    // Recent Searches
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppStrings.Search.recentSearchesTitle)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(theme.colors.textPrimary)
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
                                        .foregroundColor(theme.colors.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(theme.colors.surfaceCard)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(theme.colors.hairline, lineWidth: 1.5)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Suggested Topics Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppStrings.Search.suggestedTopicsTitle)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(theme.colors.textPrimary)
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

                                    Text(LocalizedStringKey(topic.0))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(theme.colors.textPrimary)
                                        .lineLimit(1)

                                    Spacer(minLength: 0)
                                }
                                .padding(12)
                                .background(theme.colors.surfaceCard)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(theme.colors.hairline, lineWidth: 1.5)
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
