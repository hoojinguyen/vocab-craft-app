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
            iconSymbol: "cup.and.saucer.fill",
            starterSuggestions: [
                "Hi! I'd like to order a warm beverage and a fresh pastry, please.",
                "Hello! Could I get an iced beverage? Do you offer any complimentary snacks?",
                "Good morning! What pastry would you recommend with a coffee beverage?"
            ]
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
            iconSymbol: "building.2.fill",
            starterSuggestions: [
                "Hello! Yes, I have a reservation under my name for two nights.",
                "Hi there, I'd like to check in. Could you tell me about the hotel amenities?",
                "Good afternoon! We have a reservation and wonder if you can accommodate an early check-in."
            ]
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
            iconSymbol: "briefcase.fill",
            starterSuggestions: [
                "Thank you! In my last role, I took the initiative to collaborate across teams on an innovative launch.",
                "Thanks for having me. I had to collaborate closely with clients to deliver an innovative solution.",
                "It's a pleasure to be here. I took initiative on a complex project where we collaborated cross-functionally."
            ]
        )
    ]
}
