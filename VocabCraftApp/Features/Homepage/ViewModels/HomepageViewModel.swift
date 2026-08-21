import Foundation
import Observation

/// State model for HomepageView
public struct HomepageState: Equatable {
    public var userName: String
    public var streakDays: Int
    public var dailyGoalProgress: Double
    public var dueCardsCount: Int
    public var totalWords: Int
    public var retentionPercentage: Double
    public var unreadNotifications: Bool
    public var searchText: String
    public var suggestedWords: [SuggestedWord]
    public var currentSuggestedWordIndex: Int

    public init(
        userName: String = "Hooji N.",
        streakDays: Int = 14,
        dailyGoalProgress: Double = 0.75,
        dueCardsCount: Int = 24,
        totalWords: Int = 1420,
        retentionPercentage: Double = 0.85,
        unreadNotifications: Bool = true,
        searchText: String = "",
        suggestedWords: [SuggestedWord] = [],
        currentSuggestedWordIndex: Int? = nil
    ) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyGoalProgress = dailyGoalProgress
        self.dueCardsCount = dueCardsCount
        self.totalWords = totalWords
        self.retentionPercentage = retentionPercentage
        self.unreadNotifications = unreadNotifications
        self.searchText = searchText
        self.suggestedWords = suggestedWords

        // Randomize initial suggested word index on each app launch if not explicitly set
        if let explicitIndex = currentSuggestedWordIndex, suggestedWords.indices.contains(explicitIndex) {
            self.currentSuggestedWordIndex = explicitIndex
        } else if !suggestedWords.isEmpty {
            self.currentSuggestedWordIndex = Int.random(in: 0..<suggestedWords.count)
        } else {
            self.currentSuggestedWordIndex = 0
        }
    }
}

@MainActor
@Observable
public final class HomepageViewModel {
    public private(set) var state: HomepageState

    public var searchText: String {
        get { state.searchText }
        set { state.searchText = newValue }
    }

    public var currentSuggestedWordIndex: Int {
        get { state.currentSuggestedWordIndex }
        set { state.currentSuggestedWordIndex = newValue }
    }

    public var suggestedWords: [SuggestedWord] {
        get { state.suggestedWords }
        set { state.suggestedWords = newValue }
    }

    public let fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol?
    public let ttsService: TextToSpeechProtocol

    public init(
        initialState: HomepageState = HomepageState(),
        fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil
    ) {
        self.state = initialState
        self.fetchVocabularyUseCase = fetchVocabularyUseCase
        self.ttsService = ttsService ?? TextToSpeechService()
    }

    public func loadData() async {
        guard state.suggestedWords.isEmpty else { return }
        guard let useCase = fetchVocabularyUseCase else { return }
        do {
            let fetchedWords = try await useCase.executeFetchWords(limit: 10)
            if !fetchedWords.isEmpty {
                self.state.suggestedWords = fetchedWords.map { word in
                    SuggestedWord(
                        id: String(word.id),
                        lemma: word.lemma,
                        pos: word.pos ?? "noun",
                        ipaUs: word.ipaUs ?? "",
                        cefrLevel: word.cefrLevel ?? "A1",
                        definitionVi: word.definitionVi ?? word.definitionEn ?? "",
                        definitionEn: word.definitionEn ?? "",
                        example: word.example ?? "",
                        isBookmarked: false,
                        topicTag: "Từ vựng nổi bật"
                    )
                }
                if self.state.currentSuggestedWordIndex >= self.state.suggestedWords.count {
                    self.state.currentSuggestedWordIndex = 0
                }
            }
        } catch {
            print("[HomepageViewModel] Failed to load data: \(error)")
        }
    }

    public func speakSuggestedWord(_ word: SuggestedWord) {
        ttsService.speak(text: word.lemma)
    }

    public func updateSearchText(_ text: String) {
        state.searchText = text
    }

    public func toggleBookmarkSuggestedWord(id: String) {
        if let index = state.suggestedWords.firstIndex(where: { $0.id == id }) {
            state.suggestedWords[index].isBookmarked.toggle()
        }
    }

    public func performVoiceSearch() {
        // Trigger voice search intent
    }
}
