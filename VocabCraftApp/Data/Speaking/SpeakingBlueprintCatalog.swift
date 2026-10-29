import Foundation

/// Provides the approved scenarios and open topics for Speaking practice.
enum SpeakingBlueprintCatalog {
    /// The twelve built-in scenarios and topics.
    static let all: [SpeakingBlueprint] = [
        SpeakingBlueprint(
            id: "cafe_order", kind: .scenario,
            titleKey: "app.speaking.blueprint.cafe_order.title",
            briefKey: "app.speaking.blueprint.cafe_order.brief",
            aiRole: "a friendly barista", setting: "a neighborhood cafe",
            objective: "Order a drink and ask one question about the menu."
        ),
        SpeakingBlueprint(
            id: "hotel_checkin", kind: .scenario,
            titleKey: "app.speaking.blueprint.hotel_checkin.title",
            briefKey: "app.speaking.blueprint.hotel_checkin.brief",
            aiRole: "a helpful hotel receptionist", setting: "a hotel front desk",
            objective: "Check in, confirm your room, and ask about one hotel service."
        ),
        SpeakingBlueprint(
            id: "ask_directions", kind: .scenario,
            titleKey: "app.speaking.blueprint.ask_directions.title",
            briefKey: "app.speaking.blueprint.ask_directions.brief",
            aiRole: "a friendly local resident", setting: "a busy city street",
            objective: "Ask how to get to a nearby place and clarify the route."
        ),
        SpeakingBlueprint(
            id: "doctor_visit", kind: .scenario,
            titleKey: "app.speaking.blueprint.doctor_visit.title",
            briefKey: "app.speaking.blueprint.doctor_visit.brief",
            aiRole: "a kind doctor", setting: "a local medical clinic",
            objective: "Describe a simple symptom and answer basic questions about it."
        ),
        SpeakingBlueprint(
            id: "job_interview_intro", kind: .scenario,
            titleKey: "app.speaking.blueprint.job_interview_intro.title",
            briefKey: "app.speaking.blueprint.job_interview_intro.brief",
            aiRole: "a welcoming interviewer", setting: "an entry-level job interview",
            objective: "Introduce yourself and describe one strength or experience."
        ),
        SpeakingBlueprint(
            id: "return_item_shop", kind: .scenario,
            titleKey: "app.speaking.blueprint.return_item_shop.title",
            briefKey: "app.speaking.blueprint.return_item_shop.brief",
            aiRole: "a polite shop assistant", setting: "a clothing store",
            objective: "Explain why you want to return an item and ask about the options."
        ),
        SpeakingBlueprint(
            id: "topic_daily_routine", kind: .topic,
            titleKey: "app.speaking.blueprint.topic_daily_routine.title",
            briefKey: "app.speaking.blueprint.topic_daily_routine.brief",
            aiRole: "a curious conversation partner", setting: "a relaxed chat about daily life",
            objective: nil
        ),
        SpeakingBlueprint(
            id: "topic_travel", kind: .topic,
            titleKey: "app.speaking.blueprint.topic_travel.title",
            briefKey: "app.speaking.blueprint.topic_travel.brief",
            aiRole: "a fellow traveler", setting: "a friendly conversation about travel",
            objective: nil
        ),
        SpeakingBlueprint(
            id: "topic_work_study", kind: .topic,
            titleKey: "app.speaking.blueprint.topic_work_study.title",
            briefKey: "app.speaking.blueprint.topic_work_study.brief",
            aiRole: "a supportive conversation partner", setting: "a chat about work and study",
            objective: nil
        ),
        SpeakingBlueprint(
            id: "topic_movies_music", kind: .topic,
            titleKey: "app.speaking.blueprint.topic_movies_music.title",
            briefKey: "app.speaking.blueprint.topic_movies_music.brief",
            aiRole: "a friendly fan of movies and music", setting: "a casual entertainment chat",
            objective: nil
        ),
        SpeakingBlueprint(
            id: "topic_food", kind: .topic,
            titleKey: "app.speaking.blueprint.topic_food.title",
            briefKey: "app.speaking.blueprint.topic_food.brief",
            aiRole: "a food-loving conversation partner", setting: "a casual conversation about food",
            objective: nil
        ),
        SpeakingBlueprint(
            id: "topic_weekend_plans", kind: .topic,
            titleKey: "app.speaking.blueprint.topic_weekend_plans.title",
            briefKey: "app.speaking.blueprint.topic_weekend_plans.brief",
            aiRole: "a cheerful friend", setting: "a conversation about weekend plans",
            objective: nil
        )
    ]

    /// Returns the built-in blueprint with the given identifier.
    static func blueprint(id: String) -> SpeakingBlueprint? {
        all.first { $0.id == id }
    }
}
