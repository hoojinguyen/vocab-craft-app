import Foundation
import Observation

@MainActor
@Observable
public final class SpeakingResultViewModel {
    private let sessionId: UUID
    private let repository: any SpeakingRepositoryProtocol
    private let analyze: AnalyzeSpeakingSessionUseCase
    private let storage: SpeakingAudioStorage
    private var savingSuggestions: Set<String> = []

    public private(set) var session: SpeakingSessionSnapshot?
    public private(set) var isAnalyzing = false
    public private(set) var savedSuggestions: Set<String> = []
    public private(set) var didFailToLoad = false
    public private(set) var didFailToSavePhrase = false

    public var canRetry: Bool {
        guard session?.status == .analysisFailed, let audioFileName = session?.audioFileName else { return false }
        let audioURL = storage.url(for: audioFileName)
        guard audioURL.lastPathComponent == audioFileName else { return false }
        var isDirectory = ObjCBool(false)
        return FileManager.default.fileExists(atPath: audioURL.path, isDirectory: &isDirectory) && !isDirectory.boolValue
    }

    public init(
        sessionId: UUID,
        repository: any SpeakingRepositoryProtocol,
        analyze: AnalyzeSpeakingSessionUseCase,
        storage: SpeakingAudioStorage
    ) {
        self.sessionId = sessionId
        self.repository = repository
        self.analyze = analyze
        self.storage = storage
    }

    public func load() async {
        await refresh()
        guard session?.status == .pendingAnalysis else { return }
        await runAnalysis()
    }

    public func retry() async {
        guard !isAnalyzing, canRetry else { return }
        await runAnalysis()
    }

    public func save(correction: SpeakingAnalysis.Correction) async {
        await save(
            original: correction.original,
            suggestion: correction.corrected,
            note: correction.explanation,
            source: .correction
        )
    }

    public func save(phrasing: SpeakingAnalysis.NaturalPhrasing) async {
        await save(
            original: phrasing.original,
            suggestion: phrasing.natural,
            note: phrasing.note,
            source: .naturalPhrasing
        )
    }

    private func runAnalysis() async {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }
        _ = await analyze.execute(sessionId: sessionId)
        await refresh()
    }

    private func refresh() async {
        do {
            session = try await repository.session(id: sessionId)
            didFailToLoad = session == nil
        } catch {
            didFailToLoad = true
            return
        }
        do {
            let phrases = try await repository.phrases()
            savedSuggestions = Set(phrases.map { QuoteNormalizer.normalize($0.suggestion) })
        } catch {
            savedSuggestions = []
        }
    }

    private func save(
        original: String,
        suggestion: String,
        note: String,
        source: SavedPhraseSource
    ) async {
        let key = QuoteNormalizer.normalize(suggestion)
        guard !key.isEmpty, !savedSuggestions.contains(key), !savingSuggestions.contains(key),
              let session else { return }
        savingSuggestions.insert(key)
        didFailToSavePhrase = false
        defer { savingSuggestions.remove(key) }

        let phrase = SavedPhrase(
            id: UUID(), original: original, suggestion: suggestion, note: note,
            sessionId: session.id, source: source, createdAt: Date()
        )
        do {
            _ = try await repository.savePhrase(phrase)
            savedSuggestions.insert(key)
        } catch {
            didFailToSavePhrase = true
        }
    }
}
