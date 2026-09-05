import Foundation

public enum CanonicalUUIDValidator {
    public static func isValidCanonicalUUIDv4(_ text: String) -> Bool {
        guard text.count == 36 else { return false }
        let utf8 = Array(text.utf8)
        guard utf8.count == 36 else { return false }

        // Hyphens at indices 8, 13, 18, 23
        guard utf8[8] == 45, utf8[13] == 45, utf8[18] == 45, utf8[23] == 45 else {
            return false
        }

        // Version 4 at index 14 ('4' has ascii 52)
        guard utf8[14] == 52 else { return false }

        // RFC 4122 variant at index 19 must be '8' (56), '9' (57), 'a' (97), or 'b' (98)
        let variantChar = utf8[19]
        guard variantChar == 56 || variantChar == 57 || variantChar == 97 || variantChar == 98 else {
            return false
        }

        // All non-hyphen chars must be lowercase hex: '0'...'9' (48...57) or 'a'...'f' (97...102)
        for idx in 0..<36 where idx != 8 && idx != 13 && idx != 18 && idx != 23 {
            let byte = utf8[idx]
            let isDigit = byte >= 48 && byte <= 57
            let isLowerHex = byte >= 97 && byte <= 102
            guard isDigit || isLowerHex else { return false }
        }

        guard let uuid = UUID(uuidString: text), uuid.uuidString.lowercased() == text else {
            return false
        }

        return true
    }
}

public protocol CanonicalUUIDIdentifiable: Hashable, Sendable, Codable, CustomStringConvertible, RawRepresentable where RawValue == UUID {
    init(rawValue: UUID)
}

extension CanonicalUUIDIdentifiable {
    public init?(uuidString: String) {
        guard CanonicalUUIDValidator.isValidCanonicalUUIDv4(uuidString),
              let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        self.init(rawValue: uuid)
    }

    public init(from decoder: Decoder) throws {
        let box = try decoder.singleValueContainer()
        let text = try box.decode(String.self)
        guard CanonicalUUIDValidator.isValidCanonicalUUIDv4(text),
              let uuid = UUID(uuidString: text) else {
            throw DecodingError.dataCorruptedError(
                in: box,
                debugDescription: "Invalid canonical UUID v4 for \(Self.self): \(text)"
            )
        }
        self.init(rawValue: uuid)
    }

    public func encode(to encoder: Encoder) throws {
        var box = encoder.singleValueContainer()
        try box.encode(rawValue.uuidString.lowercased())
    }

    public var description: String {
        rawValue.uuidString.lowercased()
    }
}

public struct EntryID: CanonicalUUIDIdentifiable, Identifiable {
    public let rawValue: UUID
    public var id: Self { self }
    public init(rawValue: UUID) { self.rawValue = rawValue }
}

public struct SenseID: CanonicalUUIDIdentifiable, Identifiable {
    public let rawValue: UUID
    public var id: Self { self }
    public init(rawValue: UUID) { self.rawValue = rawValue }
}

public struct LessonID: CanonicalUUIDIdentifiable, Identifiable {
    public let rawValue: UUID
    public var id: Self { self }
    public init(rawValue: UUID) { self.rawValue = rawValue }
}

public struct DeckID: CanonicalUUIDIdentifiable, Identifiable {
    public let rawValue: UUID
    public var id: Self { self }
    public init(rawValue: UUID) { self.rawValue = rawValue }
}

public struct ProfileID: CanonicalUUIDIdentifiable, Identifiable {
    public let rawValue: UUID
    public var id: Self { self }
    public init(rawValue: UUID) { self.rawValue = rawValue }
}

public struct AttemptID: CanonicalUUIDIdentifiable, Identifiable {
    public let rawValue: UUID
    public var id: Self { self }
    public init(rawValue: UUID) { self.rawValue = rawValue }
}

public struct DeviceID: CanonicalUUIDIdentifiable, Identifiable {
    public let rawValue: UUID
    public var id: Self { self }
    public init(rawValue: UUID) { self.rawValue = rawValue }
}

public struct EventID: CanonicalUUIDIdentifiable, Identifiable {
    public let rawValue: UUID
    public var id: Self { self }
    public init(rawValue: UUID) { self.rawValue = rawValue }
}
