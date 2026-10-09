import Foundation

public enum InDomainTopic: Sendable, Equatable {
    case wifi
    case openingHours
    case restroom
    case recommendation
    case decaf
    case amenities
    case breakfast
}

public enum UserIntent: Sendable, Equatable {
    case greeting
    case nonEnglish(detectedText: String)
    case inDomainInquiry(topic: InDomainTopic)
    case outOfDomainQuestion
    case ordering
    case customizing
    case paymentAction
    case closing
    case generalStatement
}

public struct DialogueIntentClassifier: Sendable {
    public init() {}

    private static let vietnameseDiacritics: CharacterSet = CharacterSet(
        charactersIn: "àáảãạăằắẳẵặâầấẩẫậđèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬĐÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴ"
    )

    private static let unaccentedVietnameseTokens: [String] = [
        "cho toi", "cho em", "ly ca phe", "ca phe", "bao nhieu", "co banh",
        "cam on", "tam biet", "nuoc loc", "tinh tien", "muon goi", "khong co",
        "lam on", "o dau", "may gio", "phong ve sinh", "co wifi"
    ]

    public func isVietnamese(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        // Tier 1: Check for Vietnamese accented characters
        if trimmed.unicodeScalars.contains(where: { Self.vietnameseDiacritics.contains($0) }) {
            return true
        }

        // Tier 2: Check for unaccented common Vietnamese word patterns
        let lower = trimmed.lowercased()
        for token in Self.unaccentedVietnameseTokens where lower.contains(token) {
            return true
        }

        return false
    }

    public func classify(utterance: String, scenario: RoleplayScenario) -> UserIntent {
        let trimmed = utterance.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .generalStatement }

        if isVietnamese(trimmed) {
            return .nonEnglish(detectedText: trimmed)
        }

        let lower = trimmed.lowercased()

        if isClosingPhrase(lower) {
            return .closing
        }
        if isPaymentPhrase(lower) {
            return .paymentAction
        }
        if let topic = detectInDomainInquiry(lower, scenarioTopic: scenario.topic) {
            return .inDomainInquiry(topic: topic)
        }
        if isOrderingPhrase(lower) {
            return .ordering
        }
        if isCustomizingPhrase(lower) {
            return .customizing
        }
        if isGreetingPhrase(lower) {
            return .greeting
        }
        if lower.hasSuffix("?") && isOutOfDomainQuestion(lower) {
            return .outOfDomainQuestion
        }

        return .generalStatement
    }

    private func detectInDomainInquiry(_ lower: String, scenarioTopic: RoleplayTopic) -> InDomainTopic? {
        if lower.contains("wifi") || lower.contains("wi-fi") || lower.contains("internet") {
            return .wifi
        }
        if lower.contains("open") || lower.contains("close") || lower.contains("hours") {
            return .openingHours
        }
        if lower.contains("restroom") || lower.contains("bathroom") || lower.contains("toilet") {
            return .restroom
        }
        if lower.contains("recommend") || lower.contains("specialty") || lower.contains("best-seller") || lower.contains("popular") {
            return .recommendation
        }
        if lower.contains("decaf") {
            return .decaf
        }
        if lower.contains("amenities") || lower.contains("pool") || lower.contains("gym") {
            return .amenities
        }
        if lower.contains("breakfast") {
            return .breakfast
        }
        return nil
    }

    private func isClosingPhrase(_ text: String) -> Bool {
        let closingTokens = [
            "goodbye", "bye", "see you", "that's all", "that is all",
            "thank you, bye", "have a good day", "have a great day", "check please"
        ]
        return closingTokens.contains { text.contains($0) }
    }

    private func isPaymentPhrase(_ text: String) -> Bool {
        let paymentTokens = [
            "card", "cash", "tap", "receipt", "keep the change", "pay", "here you go", "here is my"
        ]
        return paymentTokens.contains { text.contains($0) }
    }

    private func isOrderingPhrase(_ text: String) -> Bool {
        let orderingPhrases = [
            "i would like", "i'd like", "could i have", "can i get",
            "may i have", "please give me", "i will take", "i'll have",
            "order", "i want"
        ]
        return orderingPhrases.contains { text.contains($0) }
    }

    private func isCustomizingPhrase(_ text: String) -> Bool {
        let customizingTokens = [
            "hot", "iced", "warm", "heated", "large", "small", "medium", "single", "double", "regular"
        ]
        return customizingTokens.contains { text.contains($0) }
    }

    private func isGreetingPhrase(_ text: String) -> Bool {
        let greetings = ["hello", "hi", "hey", "good morning", "good afternoon", "good evening"]
        return greetings.contains {
            text == $0 || text.hasPrefix($0 + " ") || text.hasPrefix($0 + ",") || text.hasPrefix($0 + "!")
        }
    }

    private func isOutOfDomainQuestion(_ text: String) -> Bool {
        let unrelated = ["football", "soccer", "president", "weather", "crypto", "capital"]
        return unrelated.contains { text.contains($0) }
    }
}
