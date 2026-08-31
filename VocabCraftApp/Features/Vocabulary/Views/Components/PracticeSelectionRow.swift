import CraftUIKit
import SwiftUI

/// A selectable row component representing a word in the Practice Selection sheet.
/// Complies with Apple HIG guidelines: minimum 44x44pt touch targets, native SF Symbols,
/// spring transitions, and haptic feedback.
/// Displays word lemma, phonetic, audio button, CEFR/POS badges, definition, 4 mini sensory icons (🎙️ ⌨️ 🔲 🎧),
/// and a selection checkbox.
public struct PracticeSelectionRow: View {
    @Environment(\.craftTheme) private var theme

    public let word: VaultWordItem
    public let isSelected: Bool
    public let onToggle: () -> Void
    public let onAudioTap: (() -> Void)?

    public init(
        word: VaultWordItem,
        isSelected: Bool,
        onToggle: @escaping () -> Void,
        onAudioTap: (() -> Void)? = nil
    ) {
        self.word = word
        self.isSelected = isSelected
        self.onToggle = onToggle
        self.onAudioTap = onAudioTap
    }

    public var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: theme.spacing.md) {
                // Word Details
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack(alignment: .center, spacing: theme.spacing.xs) {
                        Text(word.lemma)
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.colors.textPrimary)
                            .multilineTextAlignment(.leading)

                        if !word.phonetic.isEmpty {
                            Text(word.phonetic)
                                .font(theme.typography.phonetic)
                                .foregroundStyle(theme.colors.textSecondary)
                        }

                        if let onAudioTap {
                            Button(action: onAudioTap) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(theme.colors.brandPrimary)
                                    .frame(width: 32, height: 32)
                                    .background(theme.colors.brandPrimary.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                            .accessibilityLabel(AppStrings.Practice.audioA11yLabel(lemma: word.lemma))
                        }
                    }

                    HStack(spacing: theme.spacing.xs) {
                        if !word.cefrLevel.isEmpty {
                            CraftBadge(
                                verbatim: word.cefrLevel.uppercased(),
                                variant: .subtle,
                                tone: .primary,
                                size: .sm
                            )
                        }

                        if !word.pos.isEmpty {
                            CraftBadge(
                                verbatim: word.pos,
                                variant: .subtle,
                                tone: .neutral,
                                size: .sm
                            )
                        }

                        Text(word.definitionVi)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(1)
                    }

                    // 4 Mini Sensory Icons Indicator Row (🎙️ ⌨️ 🔲 🎧)
                    sensoryIconsRow
                        .padding(.top, 2)
                }

                Spacer(minLength: theme.spacing.xs)

                // Selection Checkbox
                ZStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isSelected ? theme.colors.brandPrimary : theme.colors.textMuted.opacity(0.4))
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
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

    // MARK: - 4 Mini Sensory Icons Row (🎙️ ⌨️ 🔲 🎧)
    private var sensoryIconsRow: some View {
        HStack(spacing: 6) {
            ForEach(ReflexBlitzMode.allCases) { mode in
                let isMastered = word.modeStats.count(for: mode) > 0 || word.practicedModes.contains(mode)
                let iconName = modeIcon(for: mode)

                HStack(spacing: 2) {
                    Image(systemName: iconName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isMastered ? theme.colors.brandPrimary : theme.colors.textMuted.opacity(0.35))
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(
                    isMastered
                        ? theme.colors.brandPrimary.opacity(0.12)
                        : theme.colors.surfaceSubtle.opacity(0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .accessibilityLabel(AppStrings.Practice.modeAccessibilityLabel(mode: mode, isMastered: isMastered))
            }
        }
    }

    private func modeIcon(for mode: ReflexBlitzMode) -> String {
        switch mode {
        case .speaking:
            return "mic.fill"
        case .typing:
            return "keyboard.fill"
        case .multipleChoice:
            return "square.grid.2x2.fill"
        case .listening:
            return "headphones"
        }
    }
}
