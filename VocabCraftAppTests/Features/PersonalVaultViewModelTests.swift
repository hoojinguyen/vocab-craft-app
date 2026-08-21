import Testing
import Foundation
@testable import VocabCraftApp

@Suite("PersonalVaultViewModel Tests")
struct PersonalVaultViewModelTests {
    
    @Test("Toggle chọn từng từ và Chọn tất cả, Bỏ chọn tất cả")
    @MainActor
    func testSelectionManagement() async {
        let mockWords = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung")
        ]
        
        let vm = PersonalVaultViewModel(mockWords: mockWords)
        #expect(vm.selectedWordIds.isEmpty)
        #expect(vm.selectedWords.isEmpty)
        
        // Toggle chọn từ 1
        vm.toggleWordSelection(id: 1)
        #expect(vm.selectedWordIds.contains(1))
        #expect(vm.selectedWords.count == 1)
        #expect(vm.selectedWords.first?.id == 1)
        
        // Toggle bỏ chọn từ 1
        vm.toggleWordSelection(id: 1)
        #expect(vm.selectedWordIds.isEmpty)
        #expect(vm.selectedWords.isEmpty)
        
        // Chọn tất cả
        vm.selectAll()
        #expect(vm.selectedWordIds.count == 2)
        #expect(vm.selectedWordIds.contains(1))
        #expect(vm.selectedWordIds.contains(2))
        #expect(vm.selectedWords.count == 2)
        
        // Bỏ chọn tất cả
        vm.deselectAll()
        #expect(vm.selectedWordIds.isEmpty)
        #expect(vm.selectedWords.isEmpty)
    }

    @Test("Chuyển đổi bộ lọc 3 tabs VaultTabFilter")
    @MainActor
    func testVaultTabFilterChanges() async {
        let vm = PersonalVaultViewModel()
        #expect(vm.vaultTabFilter == .notMastered)
        
        vm.setVaultFilter(.mastered)
        #expect(vm.vaultTabFilter == .mastered)
        
        vm.setVaultFilter(.bookmarked)
        #expect(vm.vaultTabFilter == .bookmarked)
        
        vm.setVaultFilter(.notMastered)
        #expect(vm.vaultTabFilter == .notMastered)
    }

    @Test("Tải dữ liệu vaultWords từ FetchPersonalVaultUseCase theo bộ lọc")
    @MainActor
    func testLoadVaultWordsFromUseCase() async {
        let mockWords = [
            VaultWordItem(id: 10, lemma: "resilience", pos: "n.", definitionVi: "Khả năng phục hồi", isMastered: false),
            VaultWordItem(id: 20, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện", isMastered: true)
        ]
        let mockUseCase = MockFetchPersonalVaultUseCase(vaultWords: mockWords)
        let vm = PersonalVaultViewModel(fetchVaultUseCase: mockUseCase)
        
        #expect(vm.vaultWords.isEmpty)
        
        // Mặc định .notMastered -> chỉ trả về resilience
        await vm.loadData()
        #expect(vm.vaultWords.count == 1)
        #expect(vm.vaultWords.first?.id == 10)
        #expect(vm.vaultWords.first?.lemma == "resilience")
        
        // Chuyển sang .mastered -> chỉ trả về eloquent
        vm.setVaultFilter(.mastered)
        await vm.loadData()
        #expect(vm.vaultWords.count == 1)
        #expect(vm.vaultWords.first?.id == 20)
        #expect(vm.vaultWords.first?.lemma == "eloquent")
    }

    @Test("Tìm kiếm và lọc vaultWords qua query")
    @MainActor
    func testSearchQueryWithVaultWords() async {
        let mockWords = [
            VaultWordItem(id: 1, lemma: "adaptable", pos: "adj.", definitionVi: "Thích nghi", isMastered: false),
            VaultWordItem(id: 2, lemma: "diligent", pos: "adj.", definitionVi: "Chăm chỉ", isMastered: false)
        ]
        let mockUseCase = MockFetchPersonalVaultUseCase(vaultWords: mockWords)
        let vm = PersonalVaultViewModel(fetchVaultUseCase: mockUseCase)
        
        vm.setSearchQuery("adapt")
        #expect(vm.searchQuery == "adapt")
        
        await vm.loadData()
        #expect(vm.vaultWords.count == 1)
        #expect(vm.vaultWords.first?.lemma == "adaptable")
    }

    @Test("Phát âm từ vựng VaultWordItem qua TextToSpeech")
    @MainActor
    func testPlayAudioForVaultWord() async {
        let mockTTS = MockTTS()
        let vm = PersonalVaultViewModel(ttsService: mockTTS)
        let word = VaultWordItem(id: 1, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện")
        
        vm.playAudio(for: word)
        #expect(mockTTS.lastSpokenText == "eloquent")
    }
}

// MARK: - Test Helpers

@MainActor
private final class MockTTS: TextToSpeechProtocol {
    var lastSpokenText: String?
    var isSpeaking: Bool = false
    
    func speak(text: String, rate: Float, locale: String) {
        lastSpokenText = text
    }
    
    func stop() {}
}

private final class MockFetchPersonalVaultUseCase: FetchPersonalVaultUseCaseProtocol, @unchecked Sendable {
    private let vaultWords: [VaultWordItem]
    
    init(vaultWords: [VaultWordItem] = []) {
        self.vaultWords = vaultWords
    }
    
    func execute(filter: PersonalVaultFilter, searchQuery: String?) async throws -> PersonalVaultResult {
        return PersonalVaultResult(words: [], metrics: PersonalVaultMetrics())
    }
    
    func fetchVaultWords(filter: VaultTabFilter, searchQuery: String?) async throws -> [VaultWordItem] {
        var filtered = vaultWords
        switch filter {
        case .notMastered:
            filtered = vaultWords.filter { !$0.isMastered }
        case .mastered:
            filtered = vaultWords.filter(\.isMastered)
        case .bookmarked:
            filtered = vaultWords.filter(\.isBookmarked)
        }
        
        if let query = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            let lower = query.lowercased()
            filtered = filtered.filter { $0.lemma.lowercased().contains(lower) || $0.definitionVi.lowercased().contains(lower) }
        }
        
        return filtered
    }
}
