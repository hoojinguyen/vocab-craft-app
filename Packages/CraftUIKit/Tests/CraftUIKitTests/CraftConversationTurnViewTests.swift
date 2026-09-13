import SwiftUI
import Testing
@testable import CraftUIKit

@Suite("Conversation turn component")
struct CraftConversationTurnViewTests {
    @Test("turn exposes localized speaker and translation accessibility text")
    func localizedLabels() {
        #expect(CraftLocalized.string("craft.conversation.speaker_a", language: "en") == "Role A")
        #expect(CraftLocalized.string("craft.conversation.speaker_a", language: "vi") == "Vai A")
        #expect(CraftLocalized.string("craft.conversation.show_translation_a11y", language: "en") == "Show Vietnamese translation")
        #expect(CraftLocalized.string("craft.conversation.show_translation_a11y", language: "vi") == "Hiện bản dịch tiếng Việt")
    }

    @Test("turn accepts active, passed, and translated states")
    @MainActor
    func stateSurface() {
        let view = CraftConversationTurnView(
            speaker: .speakerA,
            english: "Could you help me?",
            vietnamese: "Bạn có thể giúp tôi không?",
            isCurrent: true,
            isPassed: true,
            showsTranslation: true,
            onToggleTranslation: {}
        )
        #expect(view.isCurrent)
        #expect(view.isPassed)
        #expect(view.showsTranslation)
        #expect(view.accessibilityText.contains("Bạn có thể giúp tôi không?"))
    }
}
