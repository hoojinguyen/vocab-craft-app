import Foundation
import SwiftUI

extension AppStrings {
    public enum Conversation {
        public static var lessonTitle: LocalizedStringKey { "app.conversation.lesson.title" }
        public static var lessonSubtitle: LocalizedStringKey { "app.conversation.lesson.subtitle" }
        public static var title: LocalizedStringKey { "app.conversation.title" }
        public static var simulationNotice: LocalizedStringKey { "app.conversation.simulation_notice" }
        public static var situation: LocalizedStringKey { "app.conversation.situation" }
        public static var rolePrompt: LocalizedStringKey { "app.conversation.role_prompt" }
        public static var roleA: String { AppLocalized.string("app.conversation.role_a") }
        public static var roleB: String { AppLocalized.string("app.conversation.role_b") }
        public static var start: LocalizedStringKey { "app.conversation.start" }
        public static var pause: LocalizedStringKey { "app.conversation.pause" }
        public static var resume: LocalizedStringKey { "app.conversation.resume" }
        public static var retry: LocalizedStringKey { "app.conversation.retry" }
        public static var `continue`: LocalizedStringKey { "app.conversation.continue" }
        public static var close: LocalizedStringKey { "app.conversation.close" }
        public static var newConversation: LocalizedStringKey { "app.conversation.new" }
        public static var returnToCurrent: LocalizedStringKey { "app.conversation.return_current" }
        public static var partnerSpeaking: LocalizedStringKey { "app.conversation.partner_speaking" }
        public static var mockListening: LocalizedStringKey { "app.conversation.mock_listening" }
        public static var waitingRetry: LocalizedStringKey { "app.conversation.waiting_retry" }
        public static var noSpeech: LocalizedStringKey { "app.conversation.no_speech" }
        public static var completed: LocalizedStringKey { "app.conversation.completed" }
        public static var debugScenario: LocalizedStringKey { "app.conversation.debug_scenario" }
        public static var outcomePass: String { AppLocalized.string("app.conversation.outcome.pass") }
        public static var outcomeRetry: String { AppLocalized.string("app.conversation.outcome.retry") }
        public static var outcomeNoSpeech: String { AppLocalized.string("app.conversation.outcome.no_speech") }
        public static var generationFailure: LocalizedStringKey { "app.conversation.generation_failure" }
        public static var simulateGenerationFailure: LocalizedStringKey { "app.conversation.simulate_generation_failure" }
        public static var switchRole: LocalizedStringKey { "app.conversation.switch_role" }
        public static var confirmReplaceTitle: LocalizedStringKey { "app.conversation.confirm_replace_title" }
        public static var confirmReplaceMessage: LocalizedStringKey { "app.conversation.confirm_replace_message" }
        public static var replace: LocalizedStringKey { "app.conversation.replace" }
        public static var cancel: LocalizedStringKey { "app.conversation.cancel" }
    }
}
