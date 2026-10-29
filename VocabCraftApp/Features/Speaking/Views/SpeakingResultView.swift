import CraftUIKit
import SwiftUI

struct SpeakingResultView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SpeakingResultViewModel
    @State private var isShowingSaveError = false

    init(viewModel: SpeakingResultViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            HStack {
                CraftText(
                    resultTitle,
                    style: .titleLarge
                )
                Spacer()
                CraftIconButton(iconName: "xmark", accessibilityLabelKey: AppStrings.Common.close) {
                    dismiss()
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.base)

            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    resultContent
                }
                .padding(theme.spacing.base)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.canvasBackground)
        .task { await viewModel.load() }
        .onChange(of: viewModel.didFailToSavePhrase) { _, failed in
            isShowingSaveError = failed
        }
        .alert(AppStrings.Common.error, isPresented: $isShowingSaveError) {
            Button(AppStrings.Common.ok, role: .cancel) { }
        } message: {
            Text(AppStrings.Speaking.errorUnknown)
        }
    }

    private var resultTitle: LocalizedStringKey {
        guard let titleKey = viewModel.session?.plan.blueprint.titleKey else {
            return AppStrings.Speaking.resultScores
        }
        return LocalizedStringKey(titleKey)
    }

    @ViewBuilder
    private var resultContent: some View {
        if viewModel.isAnalyzing {
            loadingState
        } else if viewModel.didFailToLoad || viewModel.session == nil {
            CraftText(AppStrings.Speaking.resultFailed, style: .bodyMedium, color: theme.colors.statusWarning)
        } else if viewModel.didFailToPersistAnalysis {
            analysisFailedState
        } else if viewModel.session?.status == .pendingAnalysis {
            loadingState
        } else if let session = viewModel.session {
            switch session.status {
            case .pendingAnalysis:
                loadingState
            case .analysisFailed:
                analysisFailedState
            case .tooShort:
                CraftCard {
                    CraftText(AppStrings.Speaking.resultTooShort, style: .bodyMedium)
                }
            case .analyzed:
                if let analysis = session.analysis {
                    analysisContent(analysis)
                } else {
                    CraftText(AppStrings.Speaking.resultFailed, style: .bodyMedium)
                }
            }
        }
    }

    private var loadingState: some View {
        CraftCard {
            VStack(spacing: theme.spacing.md) {
                CraftSpinner(size: .lg, color: theme.colors.brandPrimary)
                CraftText(AppStrings.Speaking.resultAnalyzing, style: .bodyMedium)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var analysisFailedState: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                CraftText(AppStrings.Speaking.resultFailed, style: .headline)
                if viewModel.canRetry {
                    CraftButton(AppStrings.Speaking.resultRetry, isLoading: viewModel.isAnalyzing) {
                        Task { await viewModel.retry() }
                    }
                    .disabled(viewModel.isAnalyzing)
                } else {
                    CraftText(AppStrings.Speaking.resultAudioMissing, style: .bodyMedium, color: theme.colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func analysisContent(_ analysis: SpeakingAnalysis) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            scoreSection(analysis.scores)
            if let objective = analysis.objective {
                objectiveSection(objective)
            }
            summarySection(analysis.summary)
            correctionsSection(analysis.corrections)
            naturalPhrasingSection(analysis.naturalPhrasings)
            pronunciationSection(analysis.pronunciation)
            targetWordsSection(analysis.targetWords)
        }
    }

    private func scoreSection(_ scores: SpeakingAnalysis.Scores) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                CraftText(AppStrings.Speaking.resultScores, style: .headline)
                scoreRow(AppStrings.Speaking.resultFluency, score: scores.fluency)
                scoreRow(AppStrings.Speaking.resultGrammar, score: scores.grammar)
                scoreRow(AppStrings.Speaking.resultVocabulary, score: scores.vocabulary)
                scoreRow(AppStrings.Speaking.resultPronunciation, score: scores.pronunciation)
            }
        }
    }

    private func scoreRow(_ title: LocalizedStringKey, score: SpeakingAnalysis.Score) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.sm) {
                CraftText(title, style: .bodyMedium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                CraftText(AppStrings.Speaking.resultScoreValueText(value: score.value), style: .caption,
                          color: theme.colors.textSecondary)
            }
            CraftProgressBar(progress: Double(score.value) / 5)
            CraftText(score.reason, style: .caption, color: theme.colors.textSecondary)
        }
    }

    private func objectiveSection(_ objective: SpeakingAnalysis.Objective) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                CraftText(objective.met ? AppStrings.Speaking.resultObjectiveMet : AppStrings.Speaking.resultObjectiveNotMet,
                          style: .headline, color: objective.met ? theme.colors.statusSuccess : theme.colors.statusWarning)
                CraftText(objective.note, style: .bodyMedium, color: theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func summarySection(_ summary: SpeakingAnalysis.Summary) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            phraseList(title: AppStrings.Speaking.resultStrengths, values: summary.strengths)
            phraseList(title: AppStrings.Speaking.resultFocusNext, values: summary.focusNext)
        }
    }

    @ViewBuilder
    private func phraseList(title: LocalizedStringKey, values: [String]) -> some View {
        if !values.isEmpty {
            CraftCard {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    CraftText(title, style: .headline)
                    ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                        CraftText(value, style: .bodyMedium, color: theme.colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func correctionsSection(_ corrections: [SpeakingAnalysis.Correction]) -> some View {
        if !corrections.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                CraftText(AppStrings.Speaking.resultCorrections, style: .headline)
                ForEach(Array(corrections.enumerated()), id: \.offset) { _, correction in
                    CraftCard {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            CraftText(correction.original, style: .bodyMedium, color: theme.colors.textMuted)
                                .strikethrough(true, color: theme.colors.textMuted)
                            CraftText(correction.corrected, style: .bodyMedium, color: theme.colors.statusSuccess)
                            CraftText(correction.explanation, style: .caption, color: theme.colors.textSecondary)
                            saveButton(isSaved: isSaved(correction.corrected)) {
                                Task { await viewModel.save(correction: correction) }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func naturalPhrasingSection(_ phrases: [SpeakingAnalysis.NaturalPhrasing]) -> some View {
        if !phrases.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                CraftText(AppStrings.Speaking.resultNatural, style: .headline)
                ForEach(Array(phrases.enumerated()), id: \.offset) { _, phrase in
                    CraftCard {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            CraftText(phrase.original, style: .caption, color: theme.colors.textSecondary)
                            CraftText(phrase.natural, style: .bodyMedium, color: theme.colors.brandPrimary)
                            CraftText(phrase.note, style: .caption, color: theme.colors.textSecondary)
                            saveButton(isSaved: isSaved(phrase.natural)) {
                                Task { await viewModel.save(phrasing: phrase) }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pronunciationSection(_ notes: [SpeakingAnalysis.PronunciationNote]) -> some View {
        if !notes.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                CraftText(AppStrings.Speaking.resultPronunciationNotes, style: .headline)
                ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                    CraftCard {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            CraftText(note.word, style: .bodyMedium)
                            CraftText(note.issue, style: .bodyMedium)
                            CraftText(note.tip, style: .caption, color: theme.colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func targetWordsSection(_ words: [SpeakingAnalysis.TargetWordUse]) -> some View {
        if !words.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                CraftText(AppStrings.Speaking.resultTargetWords, style: .headline)
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                        HStack(spacing: theme.spacing.sm) {
                            CraftBadge(word.lemma, tone: word.used && word.usedCorrectly ? .success : .warning, size: .sm)
                            CraftBadge(targetWordStatus(word), tone: word.used && word.usedCorrectly ? .success : .warning, size: .sm)
                        }
                    }
                }
            }
        }
    }

    private func saveButton(isSaved: Bool, action: @escaping () -> Void) -> some View {
        CraftButton(
            isSaved ? AppStrings.Speaking.resultSaved : AppStrings.Speaking.resultSavePhrase,
            variant: .secondary,
            size: .sm,
            action: action
        )
        .disabled(isSaved)
    }

    private func isSaved(_ suggestion: String) -> Bool {
        viewModel.savedSuggestions.contains(QuoteNormalizer.normalize(suggestion))
    }

    private func targetWordStatus(_ word: SpeakingAnalysis.TargetWordUse) -> LocalizedStringKey {
        if !word.used { return AppStrings.Speaking.resultTargetUnused }
        return word.usedCorrectly ? AppStrings.Speaking.resultTargetUsedCorrectly : AppStrings.Speaking.resultTargetUsedIncorrectly
    }
}
