import CraftUIKit
import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class LearningPathDataMapperTests: XCTestCase {
    private var sampleDecks: [TopicDeckDTO] = []
    private var sampleStages: [SubTopicStageDTO] = []
    private var sampleWords: [TopicWordDTO] = []

    override func setUp() {
        super.setUp()

        sampleDecks = [
            TopicDeckDTO(id: "deck_daily", title: "Daily Life", iconName: "bubble.left", badgeColorHex: "#38B2AC", cefrLevel: "A2 - B1", sortOrder: 1),
            TopicDeckDTO(id: "deck_business", title: "Business", iconName: "briefcase", badgeColorHex: "#ED8936", cefrLevel: "B1 - B2", sortOrder: 2)
        ]

        sampleStages = [
            SubTopicStageDTO(id: "stage_daily_1", deckId: "deck_daily", title: "Habits", iconName: "heart", sortOrder: 1),
            SubTopicStageDTO(id: "stage_daily_2", deckId: "deck_daily", title: "Emotions", iconName: "person.2", sortOrder: 2),
            SubTopicStageDTO(id: "stage_biz_1", deckId: "deck_business", title: "Management", iconName: "checklist", sortOrder: 1),
            SubTopicStageDTO(id: "stage_biz_2", deckId: "deck_business", title: "Negotiation", iconName: "chart.line.uptrend.xyaxis", sortOrder: 2)
        ]

        sampleWords = [
            TopicWordDTO(
                id: 1, stageId: "stage_daily_1", lemma: "Resilience", phonetic: "/rɪˈzɪl.jəns/",
                pos: "noun", cefrLevel: "B2", definitionVi: "Kiên cường", definitionEn: "Resilience",
                exampleEn: "Example", exampleVi: "Ví dụ"
            ),
            TopicWordDTO(
                id: 2, stageId: "stage_daily_1", lemma: "Gratitude", phonetic: "/ˈɡræt̬.ə.tuːd/",
                pos: "noun", cefrLevel: "B1", definitionVi: "Biết ơn", definitionEn: "Gratitude",
                exampleEn: "Example", exampleVi: "Ví dụ"
            ),
            TopicWordDTO(
                id: 3, stageId: "stage_daily_2", lemma: "Empathy", phonetic: "/ˈem.pə.θi/",
                pos: "noun", cefrLevel: "B2", definitionVi: "Đồng cảm", definitionEn: "Empathy",
                exampleEn: "Example", exampleVi: "Ví dụ"
            ),
            TopicWordDTO(
                id: 4, stageId: "stage_biz_1", lemma: "Leadership", phonetic: "/ˈliː.dɚ.ʃɪp/",
                pos: "noun", cefrLevel: "B2", definitionVi: "Lãnh đạo", definitionEn: "Leadership",
                exampleEn: "Example", exampleVi: "Ví dụ"
            ),
            TopicWordDTO(
                id: 5, stageId: "stage_biz_2", lemma: "Contract", phonetic: "/ˈkɑːn.trækt/",
                pos: "noun", cefrLevel: "B1", definitionVi: "Hợp đồng", definitionEn: "Contract",
                exampleEn: "Example", exampleVi: "Ví dụ"
            )
        ]
    }

    func test_new_user_first_node_active_rest_locked() {
        let progressList: [UserStageProgressData] = []

        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: progressList
        )

        XCTAssertEqual(sections.count, 2)

        // Section 1: 2 standard stages + 1 checkpoint + 1 treasure = 4 nodes
        let section1 = sections[0]
        XCTAssertEqual(section1.id, "deck_daily")
        XCTAssertEqual(section1.title, "Daily Life")
        XCTAssertEqual(section1.subtitle, AppStrings.Home.deckSummary(lessons: 3, words: 3))
        XCTAssertEqual(section1.nodes.count, 4)
        XCTAssertEqual(section1.progressText, AppStrings.Home.sectionProgress(completed: 0, total: 3))
        XCTAssertEqual(section1.progressValue ?? 0, 0.5 / 3.0, accuracy: 0.001)

        // Node 1 is active
        let node1 = section1.nodes[0]
        XCTAssertEqual(node1.id, "stage_daily_1")
        XCTAssertEqual(node1.kind, .standard)
        XCTAssertEqual(node1.state, .active)
        XCTAssertNil(node1.stars)

        // Node 2 is upcoming (curiosity preview)
        let node2 = section1.nodes[1]
        XCTAssertEqual(node2.id, "stage_daily_2")
        XCTAssertEqual(node2.kind, .standard)
        XCTAssertEqual(node2.state, .upcoming)

        // Node 3 (Checkpoint) is locked
        let node3 = section1.nodes[2]
        XCTAssertEqual(node3.id, "checkpoint_deck_daily")
        XCTAssertEqual(node3.kind, .checkpoint)
        XCTAssertEqual(node3.state, .locked)

        // Node 4 (Treasure) is locked (bonus)
        let node4 = section1.nodes[3]
        XCTAssertEqual(node4.id, "treasure_deck_daily")
        XCTAssertEqual(node4.kind, .treasureChest)
        XCTAssertEqual(node4.state, .locked)

        // Section 2: All nodes locked
        let section2 = sections[1]
        XCTAssertEqual(section2.id, "deck_business")
        XCTAssertEqual(section2.nodes.count, 4)
        XCTAssertEqual(section2.progressText, AppStrings.Home.sectionProgress(completed: 0, total: 3))
        XCTAssertEqual(section2.progressValue ?? 0, 0.0, accuracy: 0.001)
        XCTAssertTrue(section2.nodes.allSatisfy { $0.state == .locked })
    }

    func test_completed_first_node_unlocks_second_node_with_stars() {
        let progressList = [
            UserStageProgressData(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0)
        ]

        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: progressList
        )

        let section1 = sections[0]
        XCTAssertEqual(section1.progressText, AppStrings.Home.sectionProgress(completed: 1, total: 3))
        XCTAssertEqual(section1.progressValue ?? 0, 1.5 / 3.0, accuracy: 0.001)

        // Node 1 is completed with 3 stars
        let node1 = section1.nodes[0]
        XCTAssertEqual(node1.state, .completed)
        XCTAssertEqual(node1.stars, 3)

        // Node 2 is now active
        let node2 = section1.nodes[1]
        XCTAssertEqual(node2.state, .active)

        // Node 3 (Checkpoint) is preview upcoming
        let node3 = section1.nodes[2]
        XCTAssertEqual(node3.state, .upcoming)

        // Treasure remains locked
        XCTAssertEqual(section1.nodes[3].kind, .treasureChest)
        XCTAssertEqual(section1.nodes[3].state, .locked)

        // Section 2 remains all locked
        let section2 = sections[1]
        XCTAssertTrue(section2.nodes.allSatisfy { $0.state == .locked })
    }

    func test_all_standard_nodes_completed_unlocks_checkpoint_node() {
        let progressList = [
            UserStageProgressData(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0),
            UserStageProgressData(stageId: "stage_daily_2", deckId: "deck_daily", isCompleted: true, score: 2, progressFraction: 1.0)
        ]

        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: progressList
        )

        let section1 = sections[0]
        XCTAssertEqual(section1.progressText, AppStrings.Home.sectionProgress(completed: 2, total: 3))
        XCTAssertEqual(section1.progressValue ?? 0, 2.5 / 3.0, accuracy: 0.001)

        XCTAssertEqual(section1.nodes[0].state, .completed)
        XCTAssertEqual(section1.nodes[0].stars, 3)

        XCTAssertEqual(section1.nodes[1].state, .completed)
        XCTAssertEqual(section1.nodes[1].stars, 2)

        // Checkpoint of Section 1 is now active!
        let checkpointNode = section1.nodes[2]
        XCTAssertEqual(checkpointNode.kind, .checkpoint)
        XCTAssertEqual(checkpointNode.state, .active)

        // Treasure is upcoming preview (next after active checkpoint)
        XCTAssertEqual(section1.nodes[3].kind, .treasureChest)
        XCTAssertEqual(section1.nodes[3].state, .upcoming)

        // Section 2 Node 1 remains locked until checkpoint is completed
        let section2 = sections[1]
        XCTAssertEqual(section2.nodes[0].state, .locked)
    }

    func test_checkpoint_completed_unlocks_next_unit_first_node() {
        let progressList = [
            UserStageProgressData(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0),
            UserStageProgressData(stageId: "stage_daily_2", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0),
            UserStageProgressData(stageId: "checkpoint_deck_daily", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0)
        ]

        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: progressList
        )

        // Section 1 is 100% completed (3/3) — treasure is now bonus
        let section1 = sections[0]
        XCTAssertEqual(section1.progressText, AppStrings.Home.sectionProgress(completed: 3, total: 3))
        XCTAssertEqual(section1.progressValue, 1.0)
        XCTAssertEqual(section1.nodes[2].state, .completed)
        XCTAssertEqual(section1.nodes[2].stars, 3)
        XCTAssertEqual(section1.nodes[3].kind, .treasureChest)
        XCTAssertEqual(section1.nodes[3].state, .bonus)

        // Section 2 Node 1 is now unlocked and active!
        let section2 = sections[1]
        XCTAssertEqual(section2.progressText, AppStrings.Home.sectionProgress(completed: 0, total: 3))
        XCTAssertEqual(section2.nodes[0].id, "stage_biz_1")
        XCTAssertEqual(section2.nodes[0].state, .active)

        // Section 2 Node 2 is upcoming preview, Checkpoint locked
        XCTAssertEqual(section2.nodes[1].state, .upcoming)
        XCTAssertEqual(section2.nodes[2].state, .locked)
    }

    func test_in_progress_node_preserves_progress_fraction() {
        let progressList = [
            UserStageProgressData(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: false, score: 0, progressFraction: 0.5)
        ]

        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: progressList
        )

        let node1 = sections[0].nodes[0]
        XCTAssertEqual(node1.state, .inProgress)
        XCTAssertEqual(node1.progress, 0.5)

        // Next node is preview upcoming
        XCTAssertEqual(sections[0].nodes[1].state, .upcoming)
        XCTAssertEqual(sections[0].nodes[2].state, .locked)
    }

    func test_empty_decks_returns_empty_sections() {
        let sections = LearningPathDataMapper.map(
            decks: [],
            stages: sampleStages,
            words: sampleWords,
            progressList: []
        )

        XCTAssertTrue(sections.isEmpty)
    }

    func test_percentage_scores_converted_to_stars_properly() {
        let progressList = [
            UserStageProgressData(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 98, progressFraction: 1.0),
            UserStageProgressData(stageId: "stage_daily_2", deckId: "deck_daily", isCompleted: true, score: 85, progressFraction: 1.0),
            UserStageProgressData(stageId: "checkpoint_deck_daily", deckId: "deck_daily", isCompleted: true, score: 75, progressFraction: 1.0)
        ]

        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: progressList
        )

        let section1 = sections[0]
        XCTAssertEqual(section1.nodes[0].stars, 3) // >= 95% -> 3 stars
        XCTAssertEqual(section1.nodes[1].stars, 2) // >= 80% -> 2 stars
        XCTAssertEqual(section1.nodes[2].stars, 1) // < 80% -> 1 star
    }

    func test_objectives_and_metadata_configured_correctly() {
        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: []
        )

        let section1 = sections[0]
        XCTAssertEqual(section1.title, "Daily Life")
        XCTAssertFalse(section1.title.contains("Unit"))
        XCTAssertEqual(section1.subtitle, AppStrings.Home.deckSummary(lessons: 3, words: 3))
        XCTAssertEqual(section1.level, "A2 - B1")
        XCTAssertEqual(section1.bannerIcon, "bubble.left")

        // Standard Node 1
        let standardNode = section1.nodes[0]
        XCTAssertEqual(standardNode.xpReward, 25)
        XCTAssertEqual(standardNode.objectives?.count, 3)
        XCTAssertEqual(standardNode.objectives?[0], AppStrings.Home.objective1(words: 2))
        XCTAssertEqual(standardNode.objectives?[1], AppStrings.Home.objective2Text)
        XCTAssertEqual(standardNode.objectives?[2], AppStrings.Home.objective3Text)

        // Checkpoint Node
        let checkpointNode = section1.nodes[2]
        XCTAssertEqual(checkpointNode.xpReward, 80)
        XCTAssertEqual(checkpointNode.title, AppStrings.Home.checkpointTitleText)
        XCTAssertEqual(checkpointNode.subtitle, AppStrings.Home.checkpointSubtitleText)
        XCTAssertEqual(checkpointNode.objectives?.count, 2)
        XCTAssertEqual(checkpointNode.objectives?[0], AppStrings.Home.checkpointObjective1(words: 3)) // 2 in stage 1 + 1 in stage 2 = 3
        XCTAssertEqual(checkpointNode.objectives?[1], AppStrings.Home.checkpointObjective2Text)

        // Treasure Node
        let treasureNode = section1.nodes[3]
        XCTAssertEqual(treasureNode.kind, .treasureChest)
        XCTAssertEqual(treasureNode.xpReward, 150)
        XCTAssertEqual(treasureNode.title, AppStrings.Home.treasureTitleText)
    }

    func test_treasure_completed_branch_showsCompletedWithStars() {
        let progressList = [
            UserStageProgressData(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0),
            UserStageProgressData(stageId: "stage_daily_2", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0),
            UserStageProgressData(stageId: "checkpoint_deck_daily", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0),
            UserStageProgressData(stageId: "treasure_deck_daily", deckId: "deck_daily", isCompleted: true, score: 2, progressFraction: 1.0)
        ]

        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: progressList
        )

        let section1 = sections[0]
        XCTAssertEqual(section1.nodes[3].id, "treasure_deck_daily")
        XCTAssertEqual(section1.nodes[3].kind, .treasureChest)
        XCTAssertEqual(section1.nodes[3].state, .completed)
        XCTAssertEqual(section1.nodes[3].stars, 2)
        XCTAssertEqual(section1.nodes[3].xpReward, 150)
    }

    func test_unsorted_inputs_are_properly_ordered_by_sort_order() {
        let reversedDecks = Array(sampleDecks.reversed())
        let reversedStages = Array(sampleStages.reversed())

        let sections = LearningPathDataMapper.map(
            decks: reversedDecks,
            stages: reversedStages,
            words: sampleWords,
            progressList: []
        )

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].id, "deck_daily")
        XCTAssertEqual(sections[1].id, "deck_business")

        XCTAssertEqual(sections[0].nodes[0].id, "stage_daily_1")
        XCTAssertEqual(sections[0].nodes[1].id, "stage_daily_2")
        XCTAssertEqual(sections[0].nodes[2].id, "checkpoint_deck_daily")
        XCTAssertEqual(sections[0].nodes[3].id, "treasure_deck_daily")
    }

    func testLearningPathDataMapperUsesCleanDeckTitlesWithoutUnitPrefix() {
        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: []
        )
        XCTAssertEqual(sections.first?.title, "Daily Life")
        XCTAssertFalse(sections.first?.title.contains("Unit") ?? true)
        XCTAssertEqual(sections[1].title, "Business")
        XCTAssertFalse(sections[1].title.contains("Unit"))
    }

    func test_map_curriculum_producesExpectedSections() {
        let curriculum = LearningPathCurriculum(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: [
                UserStageProgressData(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0)
            ]
        )

        let sections = LearningPathDataMapper.map(curriculum: curriculum)
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].id, "deck_daily")
        XCTAssertEqual(sections[0].nodes[0].state, .completed)
        XCTAssertEqual(sections[0].nodes[0].stars, 3)
        XCTAssertEqual(sections[0].nodes[1].state, .active)
    }

    // MARK: - Spiral Review Node Tests

    func testSpiralReviewNodeInjectedWhenWordsNeedReview() {
        let deck = TopicDeckDTO(id: "deck_1", titleEn: "Food", titleVi: "Ẩm thực", iconName: "fork.knife", themeKey: "green", cefrLevel: "A1", sortOrder: 0)
        let stage = SubTopicStageDTO(id: "stage_1", deckId: "deck_1", titleEn: "Fruits", titleVi: "Trái cây", iconName: "apple", sortOrder: 0)
        let words = [
            TopicWordDTO(
                id: 1, stageId: "stage_1", lemma: "Apple", phonetic: "/ˈæp.əl/",
                pos: "noun", cefrLevel: "A1", definitionVi: "Quả táo", definitionEn: "A fruit",
                exampleEn: "Eat apple", exampleVi: "Ăn táo"
            )
        ]
        let completedProgress = [UserStageProgressData(stageId: "stage_1", deckId: "deck_1", isCompleted: true, score: 3, progressFraction: 1.0, completedAt: Date())]
        let weakWordProgress = (1...5).map { UserWordProgressData(wordId: Int64($0), masteryLevel: 1, needsReview: true) }

        let sections = LearningPathDataMapper.map(
            decks: [deck],
            stages: [stage],
            words: words,
            progressList: completedProgress,
            weakWords: weakWordProgress
        )

        let nodes = sections.first?.nodes ?? []
        guard let spiralNode = nodes.first(where: { $0.kind == .spiralReview }) else {
            XCTFail("Expected spiralReview node to be injected")
            return
        }
        XCTAssertEqual(spiralNode.title, AppStrings.Home.spiralReviewTitleText)
        let expectedEstimatedMinutes = LessonEconomyPolicy.spiralReviewEstimatedMinutes(wordCount: 5)
        XCTAssertEqual(spiralNode.subtitle, AppStrings.Home.wordsDuration(words: 5, minutes: expectedEstimatedMinutes))
        XCTAssertEqual(spiralNode.xpReward, LessonEconomyPolicy.xpReward(for: .spiralReview))
    }

    func testSpiralReviewNodeOmittedWhenAllWordsAreMastered() {
        let deck = TopicDeckDTO(id: "deck_1", titleEn: "Food", titleVi: "Ẩm thực", iconName: "fork.knife", themeKey: "green", cefrLevel: "A1", sortOrder: 0)
        let stage = SubTopicStageDTO(id: "stage_1", deckId: "deck_1", titleEn: "Fruits", titleVi: "Trái cây", iconName: "apple", sortOrder: 0)
        let words = [
            TopicWordDTO(
                id: 1, stageId: "stage_1", lemma: "Apple", phonetic: "/ˈæp.əl/",
                pos: "noun", cefrLevel: "A1", definitionVi: "Quả táo", definitionEn: "A fruit",
                exampleEn: "Eat apple", exampleVi: "Ăn táo"
            )
        ]
        let completedProgress = [UserStageProgressData(stageId: "stage_1", deckId: "deck_1", isCompleted: true, score: 3, progressFraction: 1.0, completedAt: Date())]
        // 5 words passed, but all are mastered (needsReview == false and masteryLevel >= 3)
        let masteredWordProgress = (1...5).map { UserWordProgressData(wordId: Int64($0), masteryLevel: 4, needsReview: false) }

        let sections = LearningPathDataMapper.map(
            decks: [deck],
            stages: [stage],
            words: words,
            progressList: completedProgress,
            weakWords: masteredWordProgress
        )

        let nodes = sections.first?.nodes ?? []
        XCTAssertFalse(nodes.contains(where: { $0.kind == .spiralReview }))
    }

    func testSpiralReviewNodeOmittedWhenWeakWordsBelowThreshold() {
        let deck = TopicDeckDTO(id: "deck_1", titleEn: "Food", titleVi: "Ẩm thực", iconName: "fork.knife", themeKey: "green", cefrLevel: "A1", sortOrder: 0)
        let stage = SubTopicStageDTO(id: "stage_1", deckId: "deck_1", titleEn: "Fruits", titleVi: "Trái cây", iconName: "apple", sortOrder: 0)
        let words = [
            TopicWordDTO(
                id: 1, stageId: "stage_1", lemma: "Apple", phonetic: "/ˈæp.əl/",
                pos: "noun", cefrLevel: "A1", definitionVi: "Quả táo", definitionEn: "A fruit",
                exampleEn: "Eat apple", exampleVi: "Ăn táo"
            )
        ]
        let completedProgress = [UserStageProgressData(stageId: "stage_1", deckId: "deck_1", isCompleted: true, score: 3, progressFraction: 1.0, completedAt: Date())]
        let weakWordProgress = [UserWordProgressData(wordId: 1, masteryLevel: 1, needsReview: true)]

        let sections = LearningPathDataMapper.map(
            decks: [deck],
            stages: [stage],
            words: words,
            progressList: completedProgress,
            weakWords: weakWordProgress
        )

        let nodes = sections.first?.nodes ?? []
        XCTAssertFalse(nodes.contains(where: { $0.kind == .spiralReview }))
    }

    func testSpiralReviewNodeInjectedWithCustomThreshold() {
        let deck = TopicDeckDTO(id: "deck_1", titleEn: "Food", titleVi: "Ẩm thực", iconName: "fork.knife", themeKey: "green", cefrLevel: "A1", sortOrder: 0)
        let stage = SubTopicStageDTO(id: "stage_1", deckId: "deck_1", titleEn: "Fruits", titleVi: "Trái cây", iconName: "apple", sortOrder: 0)
        let words = [
            TopicWordDTO(
                id: 1, stageId: "stage_1", lemma: "Apple", phonetic: "/ˈæp.əl/",
                pos: "noun", cefrLevel: "A1", definitionVi: "Quả táo", definitionEn: "A fruit",
                exampleEn: "Eat apple", exampleVi: "Ăn táo"
            )
        ]
        let completedProgress = [UserStageProgressData(stageId: "stage_1", deckId: "deck_1", isCompleted: true, score: 3, progressFraction: 1.0, completedAt: Date())]
        let weakWordProgress = [UserWordProgressData(wordId: 1, masteryLevel: 1, needsReview: true)]

        let sections = LearningPathDataMapper.map(
            decks: [deck],
            stages: [stage],
            words: words,
            progressList: completedProgress,
            weakWords: weakWordProgress,
            minWeakWordsThreshold: 1
        )

        let nodes = sections.first?.nodes ?? []
        XCTAssertTrue(nodes.contains(where: { $0.kind == .spiralReview }))
    }

    func testSpiralReviewNodePositionedBeforeCheckpoint() {
        let deck = TopicDeckDTO(id: "deck_1", titleEn: "Food", titleVi: "Ẩm thực", iconName: "fork.knife", themeKey: "green", cefrLevel: "A1", sortOrder: 0)
        let stage = SubTopicStageDTO(id: "stage_1", deckId: "deck_1", titleEn: "Fruits", titleVi: "Trái cây", iconName: "apple", sortOrder: 0)
        let words = [
            TopicWordDTO(
                id: 1, stageId: "stage_1", lemma: "Apple", phonetic: "/ˈæp.əl/",
                pos: "noun", cefrLevel: "A1", definitionVi: "Quả táo", definitionEn: "A fruit",
                exampleEn: "Eat apple", exampleVi: "Ăn táo"
            )
        ]
        let completedProgress = [UserStageProgressData(stageId: "stage_1", deckId: "deck_1", isCompleted: true, score: 3, progressFraction: 1.0, completedAt: Date())]
        let weakWordProgress = (1...5).map { UserWordProgressData(wordId: Int64($0), masteryLevel: 1, needsReview: true) }

        let sections = LearningPathDataMapper.map(
            decks: [deck],
            stages: [stage],
            words: words,
            progressList: completedProgress,
            weakWords: weakWordProgress
        )

        let nodes = sections.first?.nodes ?? []
        guard let spiralIndex = nodes.firstIndex(where: { $0.kind == .spiralReview }),
              let checkpointIndex = nodes.firstIndex(where: { $0.kind == .checkpoint }) else {
            XCTFail("Expected both spiralReview and checkpoint nodes to exist")
            return
        }

        XCTAssertLessThan(spiralIndex, checkpointIndex)
        XCTAssertEqual(spiralIndex + 1, checkpointIndex)
    }

    func testSpiralReviewNodeCompletedState() {
        let deck = TopicDeckDTO(id: "deck_1", titleEn: "Food", titleVi: "Ẩm thực", iconName: "fork.knife", themeKey: "green", cefrLevel: "A1", sortOrder: 0)
        let stage = SubTopicStageDTO(id: "stage_1", deckId: "deck_1", titleEn: "Fruits", titleVi: "Trái cây", iconName: "apple", sortOrder: 0)
        let words = [
            TopicWordDTO(
                id: 1, stageId: "stage_1", lemma: "Apple", phonetic: "/ˈæp.əl/",
                pos: "noun", cefrLevel: "A1", definitionVi: "Quả táo", definitionEn: "A fruit",
                exampleEn: "Eat apple", exampleVi: "Ăn táo"
            )
        ]
        let progressList = [
            UserStageProgressData(stageId: "stage_1", deckId: "deck_1", isCompleted: true, score: 3, progressFraction: 1.0, completedAt: Date()),
            UserStageProgressData(stageId: "spiral_deck_1", deckId: "deck_1", isCompleted: true, score: 3, progressFraction: 1.0, completedAt: Date())
        ]
        let weakWordProgress = (1...5).map { UserWordProgressData(wordId: Int64($0), masteryLevel: 1, needsReview: true) }

        let sections = LearningPathDataMapper.map(
            decks: [deck],
            stages: [stage],
            words: words,
            progressList: progressList,
            weakWords: weakWordProgress
        )

        let nodes = sections.first?.nodes ?? []
        let spiralNode = nodes.first(where: { $0.kind == .spiralReview })
        XCTAssertNotNil(spiralNode)
        XCTAssertEqual(spiralNode?.state, .completed)
        XCTAssertEqual(spiralNode?.stars, 3)
    }

    func testSpiralReviewNodeTreatedAsCompletedWhenCheckpointCompleted() {
        let deck1 = TopicDeckDTO(id: "deck_1", titleEn: "Food", titleVi: "Ẩm thực", iconName: "fork.knife", themeKey: "green", cefrLevel: "A1", sortOrder: 0)
        let deck2 = TopicDeckDTO(id: "deck_2", titleEn: "Travel", titleVi: "Du lịch", iconName: "airplane", themeKey: "blue", cefrLevel: "A1", sortOrder: 1)
        let stage1 = SubTopicStageDTO(id: "stage_1", deckId: "deck_1", titleEn: "Fruits", titleVi: "Trái cây", iconName: "apple", sortOrder: 0)
        let stage2 = SubTopicStageDTO(id: "stage_2", deckId: "deck_2", titleEn: "Airport", titleVi: "Sân bay", iconName: "airplane", sortOrder: 0)
        let progressList = [
            UserStageProgressData(stageId: "stage_1", deckId: "deck_1", isCompleted: true, score: 3, progressFraction: 1.0, completedAt: Date()),
            UserStageProgressData(stageId: "checkpoint_deck_1", deckId: "deck_1", isCompleted: true, score: 3, progressFraction: 1.0, completedAt: Date())
        ]
        let weakWordProgress = (1...6).map { UserWordProgressData(wordId: Int64($0), masteryLevel: 1, needsReview: true) }

        let sections = LearningPathDataMapper.map(
            decks: [deck1, deck2],
            stages: [stage1, stage2],
            words: [],
            progressList: progressList,
            weakWords: weakWordProgress
        )

        let deck1Nodes = sections.first(where: { $0.id == "deck_1" })?.nodes ?? []
        let spiralNode = deck1Nodes.first(where: { $0.kind == .spiralReview })
        XCTAssertNotNil(spiralNode)
        XCTAssertEqual(spiralNode?.state, .completed)

        let deck2Nodes = sections.first(where: { $0.id == "deck_2" })?.nodes ?? []
        let deck2FirstStage = deck2Nodes.first(where: { $0.id == "stage_2" })
        XCTAssertEqual(deck2FirstStage?.state, .active)
    }
}
