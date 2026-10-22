import Foundation

/// Curated registry of guided communication practice templates across pedagogical context families.
public struct PracticeTemplateCatalog: Sendable {
    /// Six curated baseline templates (3 context families: dining, shopping, planning; 1 basic + 1 transfer each).
    public static let templates: [PracticeTemplate] = [
        // MARK: - Dining Family

        PracticeTemplate(
            id: "dining_basic_v1",
            version: 1,
            contextFamily: .dining,
            titleKey: "app.ai_assistant.guided.template.dining_basic_v1.title",
            briefKey: "app.ai_assistant.guided.template.dining_basic_v1.brief",
            roleKeys: [
                "app.ai_assistant.guided.template.dining_basic_v1.role.learner",
                "app.ai_assistant.guided.template.dining_basic_v1.role.character"
            ],
            objectiveIds: ["order_food", "express_gratitude", "ask_recommendation"],
            supportedWordSenses: [
                PracticeWordSense(wordId: 4, sense: "expressing appreciation for food, service, or dining advice"),
                PracticeWordSense(wordId: 11, sense: "pausing or wavering over menu choices before ordering"),
                PracticeWordSense(wordId: 13, sense: "describing authentic culinary flavours or fresh ingredients"),
                PracticeWordSense(wordId: 3, sense: "making an impulsive dish selection or unreserved drop-in visit")
            ],
            variants: ["casual_bistro", "family_dinner"],
            difficultyBounds: PracticeDifficultyBounds(
                // swiftlint:disable:next force_try
                min: try! PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 0),
                // swiftlint:disable:next force_try
                max: try! PracticeDifficulty(taskConstraints: 2, characterDirectness: 2, contextNovelty: 0)
            ),
            shadowingVideoId: nil
        ),

        PracticeTemplate(
            id: "dining_transfer_v1",
            version: 1,
            contextFamily: .dining,
            titleKey: "app.ai_assistant.guided.template.dining_transfer_v1.title",
            briefKey: "app.ai_assistant.guided.template.dining_transfer_v1.brief",
            roleKeys: [
                "app.ai_assistant.guided.template.dining_transfer_v1.role.learner",
                "app.ai_assistant.guided.template.dining_transfer_v1.role.character"
            ],
            objectiveIds: ["resolve_order_issue", "reach_compromise", "confirm_resolution"],
            supportedWordSenses: [
                PracticeWordSense(wordId: 8, sense: "settling on a food substitution or adjusted bill agreement"),
                PracticeWordSense(wordId: 9, sense: "clarifying an incorrect dish order or special diet request"),
                PracticeWordSense(wordId: 6, sense: "acknowledging busy restaurant staff during peak rush periods"),
                PracticeWordSense(wordId: 7, sense: "recommending dependable service or consistent dish quality")
            ],
            variants: ["dietary_substitution", "billing_adjustment"],
            difficultyBounds: PracticeDifficultyBounds(
                // swiftlint:disable:next force_try
                min: try! PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 1),
                // swiftlint:disable:next force_try
                max: try! PracticeDifficulty(taskConstraints: 2, characterDirectness: 2, contextNovelty: 2)
            ),
            shadowingVideoId: nil
        ),

        // MARK: - Shopping Family

        PracticeTemplate(
            id: "shopping_basic_v1",
            version: 1,
            contextFamily: .shopping,
            titleKey: "app.ai_assistant.guided.template.shopping_basic_v1.title",
            briefKey: "app.ai_assistant.guided.template.shopping_basic_v1.brief",
            roleKeys: [
                "app.ai_assistant.guided.template.shopping_basic_v1.role.learner",
                "app.ai_assistant.guided.template.shopping_basic_v1.role.character"
            ],
            objectiveIds: ["inquire_item", "evaluate_quality", "decide_purchase"],
            supportedWordSenses: [
                PracticeWordSense(wordId: 7, sense: "inquiring about dependable product quality and warranty"),
                PracticeWordSense(wordId: 13, sense: "verifying authentic brand craftsmanship versus imitations"),
                PracticeWordSense(wordId: 11, sense: "hesitating over a high price tag or contrasting items"),
                PracticeWordSense(wordId: 8, sense: "balancing budget limits with desired product specifications")
            ],
            variants: ["electronics_store", "boutique_clothing"],
            difficultyBounds: PracticeDifficultyBounds(
                // swiftlint:disable:next force_try
                min: try! PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 0),
                // swiftlint:disable:next force_try
                max: try! PracticeDifficulty(taskConstraints: 2, characterDirectness: 2, contextNovelty: 0)
            ),
            shadowingVideoId: nil
        ),

        PracticeTemplate(
            id: "shopping_transfer_v1",
            version: 1,
            contextFamily: .shopping,
            titleKey: "app.ai_assistant.guided.template.shopping_transfer_v1.title",
            briefKey: "app.ai_assistant.guided.template.shopping_transfer_v1.brief",
            roleKeys: [
                "app.ai_assistant.guided.template.shopping_transfer_v1.role.learner",
                "app.ai_assistant.guided.template.shopping_transfer_v1.role.character"
            ],
            objectiveIds: ["discuss_terms", "request_incentive", "finalize_agreement"],
            supportedWordSenses: [
                PracticeWordSense(wordId: 20, sense: "discussing bulk purchase terms, bundle deals, or pricing"),
                PracticeWordSense(wordId: 24, sense: "asking about promotional discounts, member perks, or points"),
                PracticeWordSense(wordId: 25, sense: "requesting upfront pricing without hidden charges or terms"),
                PracticeWordSense(wordId: 9, sense: "resolving price tag confusion or warranty misunderstandings")
            ],
            variants: ["bulk_order", "return_counter"],
            difficultyBounds: PracticeDifficultyBounds(
                // swiftlint:disable:next force_try
                min: try! PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 1),
                // swiftlint:disable:next force_try
                max: try! PracticeDifficulty(taskConstraints: 2, characterDirectness: 2, contextNovelty: 2)
            ),
            shadowingVideoId: nil
        ),

        // MARK: - Planning Family

        PracticeTemplate(
            id: "planning_basic_v1",
            version: 1,
            contextFamily: .planning,
            titleKey: "app.ai_assistant.guided.template.planning_basic_v1.title",
            briefKey: "app.ai_assistant.guided.template.planning_basic_v1.brief",
            roleKeys: [
                "app.ai_assistant.guided.template.planning_basic_v1.role.learner",
                "app.ai_assistant.guided.template.planning_basic_v1.role.character"
            ],
            objectiveIds: ["propose_schedule", "set_priorities", "agree_deadlines"],
            supportedWordSenses: [
                PracticeWordSense(wordId: 14, sense: "arranging essential agenda items or travel stops first"),
                PracticeWordSense(wordId: 15, sense: "establishing target completion times and milestone dates"),
                PracticeWordSense(wordId: 16, sense: "coordinating responsibilities with project or travel partners"),
                PracticeWordSense(wordId: 50, sense: "evaluating whether an itinerary or schedule is realistically doable")
            ],
            variants: ["weekend_itinerary", "study_group_plan"],
            difficultyBounds: PracticeDifficultyBounds(
                // swiftlint:disable:next force_try
                min: try! PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 0),
                // swiftlint:disable:next force_try
                max: try! PracticeDifficulty(taskConstraints: 2, characterDirectness: 2, contextNovelty: 0)
            ),
            shadowingVideoId: nil
        ),

        PracticeTemplate(
            id: "planning_transfer_v1",
            version: 1,
            contextFamily: .planning,
            titleKey: "app.ai_assistant.guided.template.planning_transfer_v1.title",
            briefKey: "app.ai_assistant.guided.template.planning_transfer_v1.brief",
            roleKeys: [
                "app.ai_assistant.guided.template.planning_transfer_v1.role.learner",
                "app.ai_assistant.guided.template.planning_transfer_v1.role.character"
            ],
            objectiveIds: ["address_schedule_conflict", "adjust_timeline", "reaffirm_commitment"],
            supportedWordSenses: [
                PracticeWordSense(wordId: 2, sense: "communicating schedule overcommitment or heavy workloads"),
                PracticeWordSense(wordId: 1, sense: "adapting plans smoothly in response to disruptions or weather"),
                PracticeWordSense(wordId: 17, sense: "celebrating key phase milestones despite timeline shifts"),
                PracticeWordSense(wordId: 8, sense: "negotiating alternative meeting slots or adjusted deliverables")
            ],
            variants: ["project_scope_change", "travel_delay_rescheduling"],
            difficultyBounds: PracticeDifficultyBounds(
                // swiftlint:disable:next force_try
                min: try! PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 1),
                // swiftlint:disable:next force_try
                max: try! PracticeDifficulty(taskConstraints: 2, characterDirectness: 2, contextNovelty: 2)
            ),
            shadowingVideoId: nil
        )
    ]

    /// Retrieves a curated template by its unique identifier.
    public static func template(withId id: String) -> PracticeTemplate? {
        templates.first { $0.id == id }
    }
}
