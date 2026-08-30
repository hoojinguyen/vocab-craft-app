import Foundation

// MARK: - CraftSymbol Enum

/// A curated, type-safe library of SF Symbols categorized for CraftUI apps and language learning.
public enum CraftSymbol: String, Sendable, CaseIterable, Equatable, Hashable {
    // MARK: Navigation & Structure
    case home = "house"
    case homeFill = "house.fill"
    case study = "character.book.closed"
    case booksFill = "books.vertical.fill"
    case practice = "bolt"
    case profile = "person.crop.circle"
    case profileFill = "person.crop.circle.fill"
    case settings = "gearshape"
    case settingsFill = "gearshape.fill"
    case chevronRight = "chevron.right"
    case chevronLeft = "chevron.left"
    case chevronDown = "chevron.down"
    case chevronUp = "chevron.up"
    case grid = "square.grid.2x2"
    case list = "list.bullet"

    // MARK: Actions & Tools
    case add = "plus"
    case search = "magnifyingglass"
    case clear = "xmark.circle"
    case close = "xmark"
    case edit = "pencil"
    case delete = "trash"
    case deleteFill = "trash.fill"
    case share = "square.and.arrow.up"
    case bookmark = "bookmark"
    case bookmarkFill = "bookmark.fill"
    case favorite = "heart"
    case favoriteFill = "heart.fill"
    case filter = "line.3.horizontal.decrease.circle"
    case refresh = "arrow.clockwise"
    case flip = "arrow.triangle.2.circlepath"

    // MARK: Audio & Media
    case audio = "speaker.wave.2.fill"
    case audioMute = "speaker.slash.fill"
    case mic = "mic.fill"
    case waveform = "waveform"
    case play = "play.fill"
    case pause = "pause.fill"

    // MARK: Feedback, Status & Learning
    case check = "checkmark"
    case checkmarkCircle = "checkmark.circle.fill"
    case wrongCircle = "xmark.circle.fill"
    case lock = "lock.fill"
    case unlock = "lock.open.fill"
    case sparkles = "sparkles"
    case streak = "flame.fill"
    case mastery = "medal.fill"
    case trophy = "trophy.fill"
    case lightbulb = "lightbulb.fill"
    case star = "star"
    case starFill = "star.fill"
    case info = "info.circle.fill"
    case warning = "exclamationmark.triangle.fill"
    case danger = "exclamationmark.circle.fill"
    case help = "questionmark.circle.fill"

    // MARK: Visibility
    case eye = "eye.fill"
    case eyeSlash = "eye.slash.fill"

    // MARK: Math & Operators
    case minus = "minus"

    // MARK: Celebration
    case partyPopper = "party.popper.fill"

    /// Underlying SF Symbol system name.
    public var systemName: String {
        rawValue
    }
}
