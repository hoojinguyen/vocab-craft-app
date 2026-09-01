import SwiftUI

// MARK: - Practice Selection & Drill Strings Extension
extension AppStrings {
    public enum Practice {
        // Navigation & Titles
        public static var title: LocalizedStringKey { "app.practice.selection.title" }
        public static var titleText: String {
            String(localized: "app.practice.selection.title", defaultValue: "Select Words", bundle: .module)
        }

        public static var back: LocalizedStringKey { "app.practice.selection.back" }
        public static var backText: String {
            String(localized: "app.practice.selection.back", defaultValue: "Back", bundle: .module)
        }

        public static var close: LocalizedStringKey { "app.practice.selection.close" }
        public static var closeText: String {
            String(localized: "app.practice.selection.close", defaultValue: "Close", bundle: .module)
        }

        // Selection Actions & Counts
        public static func selectedCount(_ count: Int) -> String {
            String(format: String(localized: "app.practice.selection.selected_count", defaultValue: "%lld selected", bundle: .module), count)
        }

        public static func totalCount(_ count: Int) -> String {
            String(format: String(localized: "app.practice.selection.total_count", defaultValue: "%lld words in list", bundle: .module), count)
        }

        public static var selectAll: LocalizedStringKey { "app.practice.selection.select_all" }
        public static var selectAllText: String {
            String(localized: "app.practice.selection.select_all", defaultValue: "Select All", bundle: .module)
        }

        public static var deselectAll: LocalizedStringKey { "app.practice.selection.deselect_all" }
        public static var deselectAllText: String {
            String(localized: "app.practice.selection.deselect_all", defaultValue: "Deselect All", bundle: .module)
        }

        public static var smartPick: LocalizedStringKey { "app.practice.selection.smart_pick" }
        public static var smartPickText: String {
            String(localized: "app.practice.selection.smart_pick", defaultValue: "Smart Practice", bundle: .module)
        }

        // CTA & Empty States
        public static func startButton(_ count: Int) -> String {
            String(format: String(localized: "app.practice.selection.start_button", defaultValue: "START PRACTICE (%lld WORDS)", bundle: .module), count)
        }

        public static var emptyPrompt: LocalizedStringKey { "app.practice.selection.empty_prompt" }
        public static var emptyPromptText: String {
            String(localized: "app.practice.selection.empty_prompt", defaultValue: "SELECT WORDS TO START", bundle: .module)
        }

        public static var emptyTitle: LocalizedStringKey { "app.practice.selection.empty_title" }
        public static var emptyTitleText: String {
            String(localized: "app.practice.selection.empty_title", defaultValue: "No vocabulary", bundle: .module)
        }

        public static var emptyMessage: LocalizedStringKey { "app.practice.selection.empty_message" }
        public static var emptyMessageText: String {
            String(localized: "app.practice.selection.empty_message", defaultValue: "No vocabulary found in this section.", bundle: .module)
        }

        // Countdown & Mixed Drill
        public static var mixedDrillTitle: LocalizedStringKey { "app.practice.countdown.mixed_title" }
        public static var mixedDrillTitleText: String {
            String(localized: "app.practice.countdown.mixed_title", defaultValue: "Mixed Reflex Drill", bundle: .module)
        }

        public static var mixedDrillSubtitle: LocalizedStringKey { "app.practice.countdown.mixed_subtitle" }
        public static var mixedDrillSubtitleText: String {
            String(localized: "app.practice.countdown.mixed_subtitle", defaultValue: "Multi-sensory reflex: Quiz, Typing, Listening & Speaking", bundle: .module)
        }

        // In-Drill Fallback
        public static var cantSpeakNow: LocalizedStringKey { "app.practice.drill.cant_speak_now" }
        public static var cantSpeakNowText: String {
            String(localized: "app.practice.drill.cant_speak_now", defaultValue: "Can't speak now", bundle: .module)
        }
        public static var cantSpeakNowCTA: String {
            cantSpeakNowText
        }

        // Modes & A11y
        public static func modeTitle(_ mode: ReflexBlitzMode) -> String {
            switch mode {
            case .speaking:
                return String(localized: "app.practice.selection.mode.speaking", defaultValue: "Speaking", bundle: .module)
            case .typing:
                return String(localized: "app.practice.selection.mode.typing", defaultValue: "Typing", bundle: .module)
            case .multipleChoice:
                return String(localized: "app.practice.selection.mode.multiple_choice", defaultValue: "Multiple Choice", bundle: .module)
            case .listening:
                return String(localized: "app.practice.selection.mode.listening", defaultValue: "Listening", bundle: .module)
            }
        }

        public static func modeAccessibilityLabel(mode: ReflexBlitzMode, isMastered: Bool) -> String {
            let modeName = modeTitle(mode)
            if isMastered {
                return String(format: String(localized: "app.practice.selection.mode_mastered", defaultValue: "Mastered: %@", bundle: .module), modeName)
            } else {
                return String(format: String(localized: "app.practice.selection.mode_unmastered", defaultValue: "Not mastered: %@", bundle: .module), modeName)
            }
        }

        public static func toggleA11yLabel(lemma: String) -> String {
            String(format: String(localized: "app.practice.selection.toggle_a11y", defaultValue: "Select word %@", bundle: .module), lemma)
        }

        public static func audioA11yLabel(lemma: String) -> String {
            String(format: String(localized: "app.practice.selection.audio_a11y", defaultValue: "Play pronunciation for %@", bundle: .module), lemma)
        }
    }
}
