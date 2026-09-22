import Foundation

public enum RoleplayScenarioCatalog: Sendable {
    public static let standardScenarios: [RoleplayScenario] = [
        RoleplayScenario(
            id: "cafe-order",
            titleKey: "app.ai_assistant.scenario.cafe.title",
            descriptionKey: "app.ai_assistant.scenario.cafe.desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Emma",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hello! Welcome to Craft Cafe. What can I get for you today?",
            targetWordIds: ["beverage", "pastry", "complimentary"],
            iconSymbol: "cup.and.saucer.fill"
        ),
        RoleplayScenario(
            id: "hotel-checkin",
            titleKey: "app.ai_assistant.scenario.hotel.title",
            descriptionKey: "app.ai_assistant.scenario.hotel.desc",
            topic: .travel,
            difficulty: .intermediate,
            characterName: "David",
            characterRole: "Front Desk Concierge",
            userRole: "Guest",
            initialGreeting: "Good afternoon, welcome to Grand Vista Hotel. Checking in?",
            targetWordIds: ["reservation", "amenities", "accommodate"],
            iconSymbol: "building.2.fill"
        ),
        RoleplayScenario(
            id: "job-interview",
            titleKey: "app.ai_assistant.scenario.interview.title",
            descriptionKey: "app.ai_assistant.scenario.interview.desc",
            topic: .interview,
            difficulty: .advanced,
            characterName: "Ms. Jenkins",
            characterRole: "Lead Hiring Manager",
            userRole: "Candidate",
            initialGreeting: "Thanks for joining us today. To start, tell me about a challenging project you managed.",
            targetWordIds: ["collaborate", "innovative", "initiative"],
            iconSymbol: "briefcase.fill"
        )
    ]
}
