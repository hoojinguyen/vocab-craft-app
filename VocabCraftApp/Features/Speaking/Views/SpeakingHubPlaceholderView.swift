import CraftUIKit
import SwiftUI

/// Temporary destination while the Speaking feature is rebuilt.
struct SpeakingHubPlaceholderView: View {
    @Environment(\.craftTheme) private var theme

    var body: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                CraftText(LocalizedStringKey("app.speaking.hub.title"), style: .titleMedium)
                CraftText(LocalizedStringKey("app.speaking.hub.coming_soon"), style: .bodyMedium)
            }
        }
        .padding(theme.spacing.base)
    }
}
