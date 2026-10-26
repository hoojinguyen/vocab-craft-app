import Foundation

public struct WidgetDeckStore: Sendable {
    private static let deckFileName = "widget_deck.json"
    private static let interactionFileName = "widget_interaction.json"

    private let directoryURL: URL

    public init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    public static func appGroup(fileManager: FileManager = .default) -> WidgetDeckStore {
        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: SharedAppGroupContainer.appGroupID) {
            return WidgetDeckStore(directoryURL: groupURL.appendingPathComponent("widget", isDirectory: true))
        } else if let baseSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return WidgetDeckStore(
                directoryURL: baseSupportURL
                    .appendingPathComponent("VocabCraft", isDirectory: true)
                    .appendingPathComponent("widget", isDirectory: true)
            )
        } else {
            return WidgetDeckStore(
                directoryURL: URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("widget", isDirectory: true)
            )
        }
    }

    public func loadDeck() -> WidgetDeck? {
        guard let data = try? Data(contentsOf: fileURL(Self.deckFileName)),
              let deck = try? Self.makeDecoder().decode(WidgetDeck.self, from: data),
              (WidgetDeck.minimumSupportedVersion...WidgetDeck.currentVersion).contains(deck.version) else {
            return nil
        }
        return deck
    }

    public func saveDeck(_ deck: WidgetDeck) throws {
        try write(deck, to: Self.deckFileName)
    }

    public func loadInteraction() -> WidgetInteractionState {
        guard let data = try? Data(contentsOf: fileURL(Self.interactionFileName)),
              let state = try? Self.makeDecoder().decode(WidgetInteractionState.self, from: data) else {
            return .empty
        }
        return state
    }

    public func saveInteraction(_ state: WidgetInteractionState) throws {
        try write(state, to: Self.interactionFileName)
    }

    private func fileURL(_ name: String) -> URL {
        directoryURL.appendingPathComponent(name)
    }

    private func write<T: Encodable>(_ value: T, to name: String) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Self.makeFractionalFormatter().string(from: date))
        }
        try encoder.encode(value).write(to: fileURL(name), options: .atomic)
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            // Fractional seconds first; plain ISO 8601 keeps files written before the change loadable.
            if let date = makeFractionalFormatter().date(from: text) ?? makePlainFormatter().date(from: text) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO 8601 date: \(text)"
            )
        }
        return decoder
    }

    private static func makeFractionalFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private static func makePlainFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}
