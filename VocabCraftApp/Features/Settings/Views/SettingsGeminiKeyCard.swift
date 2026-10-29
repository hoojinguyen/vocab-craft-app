import CraftUIKit
import SwiftUI

@MainActor
struct SettingsGeminiKeyCard: View {
    @Bindable var store: UserSettingsStore

    var body: some View {
        CraftCard(style: .outlined) {
            CraftTextField(
                LocalizedStringKey("app.settings.gemini_key.title"),
                text: $store.geminiApiKey,
                label: LocalizedStringKey("app.settings.gemini_key.title"),
                helperText: LocalizedStringKey("app.settings.gemini_key.caption"),
                isSecure: true
            )
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
        }
    }
}
