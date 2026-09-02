import CraftUIKit
import SwiftUI

/// A selectable row component representing a word in the Practice Selection sheet.
/// Complies with Apple HIG guidelines: minimum 44x44pt touch targets (56pt row height),
/// spring transitions, selection haptics, and accessible traits.
/// Minimalist layout displaying strictly word lemma and selection checkbox.
public struct PracticeSelectionRow: View {
    @Environment(\.craftTheme) private var theme

    public let word: VaultWordItem
    public let isSelected: Bool
    public let onToggle: () -> Void

    public init(
        word: VaultWordItem,
        isSelected: Bool,
        onToggle: @escaping () -> Void
    ) {
        self.word = word
        self.isSelected = isSelected
        self.onToggle = onToggle
    }

    public var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: theme.spacing.md) {
                Text(word.lemma)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: theme.spacing.xs)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(theme.typography.titleLarge)
                    .foregroundStyle(isSelected ? theme.colors.brandPrimary : theme.colors.textMuted.opacity(0.4))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.md)
            .frame(minHeight: 56)
            .background(theme.colors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .stroke(
                        isSelected ? theme.colors.brandPrimary.opacity(0.6) : theme.colors.borderDefault,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .craftShadow(isSelected ? theme.shadows.sm : CraftShadow(color: .clear, radius: 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(theme.animations.springSnappy, value: isSelected)
        .accessibilityLabel(AppStrings.Practice.toggleA11yLabel(lemma: word.lemma))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
