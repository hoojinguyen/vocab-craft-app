import CraftUIKit
import SwiftUI

struct SpeakingPhrasebookView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let repository: any SpeakingRepositoryProtocol
    let ttsService: TextToSpeechProtocol

    @State private var phrases: [SavedPhrase] = []
    @State private var isLoading = true
    @State private var isShowingDeleteError = false

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            HStack {
                CraftText(AppStrings.Speaking.phrasebookTitle, style: .titleLarge)
                Spacer()
                CraftIconButton(iconName: "xmark", accessibilityLabelKey: AppStrings.Common.close) {
                    dismiss()
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.base)

            if isLoading {
                CraftSpinner(size: .lg, color: theme.colors.brandPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if phrases.isEmpty {
                CraftText(AppStrings.Speaking.phrasebookEmpty, style: .bodyMedium, color: theme.colors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(theme.spacing.base)
            } else {
                List {
                    ForEach(phrases) { phrase in
                        CraftCard {
                            CraftListRow(
                                title: phrase.suggestion,
                                subtitle: phrase.original,
                                iconName: "quote.opening",
                                showChevron: false
                            ) {
                                CraftSpeakerButton(action: { play(phrase) })
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(theme.colors.canvasBackground)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await delete(phrase) }
                            } label: {
                                Label(AppStrings.Speaking.phrasebookDelete, systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.canvasBackground)
        .task { await loadPhrases() }
        .alert(AppStrings.Common.error, isPresented: $isShowingDeleteError) {
            Button(AppStrings.Common.ok, role: .cancel) { }
        } message: {
            Text(AppStrings.Speaking.errorUnknown)
        }
    }

    private func play(_ phrase: SavedPhrase) {
        ttsService.speak(text: phrase.suggestion, context: .pronunciation(locale: "en-US"), rate: 1)
    }

    private func delete(_ phrase: SavedPhrase) async {
        do {
            try await repository.deletePhrase(id: phrase.id)
            await loadPhrases()
        } catch {
            isShowingDeleteError = true
        }
    }

    private func loadPhrases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            phrases = try await repository.phrases()
        } catch {
            isShowingDeleteError = true
        }
    }
}
