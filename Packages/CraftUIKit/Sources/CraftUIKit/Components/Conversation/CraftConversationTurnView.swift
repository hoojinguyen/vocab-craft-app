import SwiftUI

public enum CraftConversationSpeaker: String, Sendable {
    case speakerA
    case speakerB
}

public struct CraftConversationTurnView: View {
    @Environment(\.craftTheme) private var theme

    public let speaker: CraftConversationSpeaker
    public let english: String
    public let vietnamese: String
    public let isCurrent: Bool
    public let isPassed: Bool
    public let showsTranslation: Bool
    public let onToggleTranslation: () -> Void

    public init(
        speaker: CraftConversationSpeaker,
        english: String,
        vietnamese: String,
        isCurrent: Bool,
        isPassed: Bool,
        showsTranslation: Bool,
        onToggleTranslation: @escaping () -> Void
    ) {
        self.speaker = speaker
        self.english = english
        self.vietnamese = vietnamese
        self.isCurrent = isCurrent
        self.isPassed = isPassed
        self.showsTranslation = showsTranslation
        self.onToggleTranslation = onToggleTranslation
    }

    public var body: some View {
        Button(action: onToggleTranslation) {
            CraftCard(
                style: isCurrent ? .outlined : .flat,
                customTint: isCurrent ? theme.colors.surfaceElevated : theme.colors.surfaceCard,
                customBorderColor: isCurrent ? theme.colors.borderFocus : theme.colors.borderDefault
            ) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    HStack(spacing: theme.spacing.sm) {
                        CraftBadge(
                            verbatim: CraftLocalized.string(speakerKey),
                            variant: .subtle,
                            tone: speaker == .speakerA ? .primary : .neutral,
                            size: .sm
                        )
                        Spacer()
                        if isPassed {
                            CraftIcon(.checkmarkCircle, size: .sm, color: theme.colors.statusSuccess)
                        }
                    }
                    Text(verbatim: english)
                        .font(theme.typography.bodyLarge)
                        .foregroundStyle(theme.colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if showsTranslation {
                        Text(verbatim: vietnamese)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: theme.spacing.xxl)
        .contentShape(Rectangle())
        .accessibilityLabel(Text(verbatim: accessibilityText))
        .accessibilityHint(CraftLocalized.string(showsTranslation ? "craft.conversation.hide_translation_a11y" : "craft.conversation.show_translation_a11y"))
    }

    var accessibilityText: String {
        if showsTranslation {
            return CraftLocalized.format("craft.conversation.expanded_a11y", CraftLocalized.string(speakerKey), english, vietnamese)
        }
        return CraftLocalized.format("craft.conversation.collapsed_a11y", CraftLocalized.string(speakerKey), english)
    }

    private var speakerKey: String {
        speaker == .speakerA ? "craft.conversation.speaker_a" : "craft.conversation.speaker_b"
    }
}
