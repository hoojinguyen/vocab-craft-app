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
        let progressList: [UserStageProgress] = []

        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: progressList
        )

        XCTAssertEqual(sections.count, 2)

        // Section 1: 2 standard stages + 1 checkpoint = 3 nodes
        let section1 = sections[0]
        XCTAssertEqual(section1.id, "deck_daily")
        XCTAssertEqual(section1.nodes.count, 3)
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

        // Section 2: All nodes locked
        let section2 = sections[1]
        XCTAssertEqual(section2.id, "deck_business")
        XCTAssertEqual(section2.nodes.count, 3)
        XCTAssertEqual(section2.progressText, AppStrings.Home.sectionProgress(completed: 0, total: 3))
        XCTAssertEqual(section2.progressValue ?? 0, 0.0, accuracy: 0.001)
        XCTAssertTrue(section2.nodes.allSatisfy { $0.state == .locked })
    }

    func test_completed_first_node_unlocks_second_node_with_stars() {
        let progressList = [
            UserStageProgress(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0)
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

        // Section 2 remains all locked
        let section2 = sections[1]
        XCTAssertTrue(section2.nodes.allSatisfy { $0.state == .locked })
    }

    func test_all_standard_nodes_completed_unlocks_checkpoint_node() {
        let progressList = [
            UserStageProgress(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0),
            UserStageProgress(stageId: "stage_daily_2", deckId: "deck_daily", isCompleted: true, score: 2, progressFraction: 1.0)
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

        // Section 2 Node 1 remains locked until checkpoint is completed
        let section2 = sections[1]
        XCTAssertEqual(section2.nodes[0].state, .locked)
    }

    func test_checkpoint_completed_unlocks_next_unit_first_node() {
        let progressList = [
            UserStageProgress(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0),
            UserStageProgress(stageId: "stage_daily_2", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0),
            UserStageProgress(stageId: "checkpoint_deck_daily", deckId: "deck_daily", isCompleted: true, score: 3, progressFraction: 1.0)
        ]

        let sections = LearningPathDataMapper.map(
            decks: sampleDecks,
            stages: sampleStages,
            words: sampleWords,
            progressList: progressList
        )

        // Section 1 is 100% completed (3/3)
        let section1 = sections[0]
        XCTAssertEqual(section1.progressText, AppStrings.Home.sectionProgress(completed: 3, total: 3))
        XCTAssertEqual(section1.progressValue, 1.0)
        XCTAssertEqual(section1.nodes[2].state, .completed)
        XCTAssertEqual(section1.nodes[2].stars, 3)

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
            UserStageProgress(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: false, score: 0, progressFraction: 0.5)
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
            UserStageProgress(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 98, progressFraction: 1.0),
            UserStageProgress(stageId: "stage_daily_2", deckId: "deck_daily", isCompleted: true, score: 85, progressFraction: 1.0),
            UserStageProgress(stageId: "checkpoint_deck_daily", deckId: "deck_daily", isCompleted: true, score: 75, progressFraction: 1.0)
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
        XCTAssertEqual(section1.title, AppStrings.Home.unitTitle(number: 1, title: "Daily Life"))
        XCTAssertNil(section1.subtitle)
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
    }
}
