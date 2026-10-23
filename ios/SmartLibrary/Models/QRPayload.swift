import Foundation

public enum QRType: String, Codable, CaseIterable {
    case entry = "ENTRY"
    case exit = "EXIT"
}

public struct QRPayload: Equatable {
    public let type: QRType
    public let libraryId: UUID
    public let rawPayload: String

    public init(type: QRType, libraryId: UUID, rawPayload: String) {
        self.type = type
        self.libraryId = libraryId
        self.rawPayload = rawPayload
    }
}

public enum QRParseError: LocalizedError, Equatable {
    case empty
    case invalidFormat
    case unknownType(String)
    case invalidUUID(String)
    case unsupportedLibrary(UUID)

    public var errorDescription: String? {
        switch self {
        case .empty:
            return "QR payload is empty. Please scan a valid library QR code."
        case .invalidFormat:
            return "Invalid QR code format. Expected format: SLMS|<ACTION>|<LIBRARY_ID>"
        case .unknownType(let type):
            return "Unknown QR action '\(type)'. Expected ENTRY or EXIT."
        case .invalidUUID(let idString):
            return "Malformed library UUID in QR code: \(idString)"
        case .unsupportedLibrary(let uuid):
            return "Library \(uuid.uuidString) is not supported by this station."
        }
    }
}

public enum QRParser {
    public static let prefix = "SLMS"

    public static func parse(_ raw: String, expectedLibraryId: UUID? = nil) throws -> QRPayload {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw QRParseError.empty
        }

        let parts = trimmed.components(separatedBy: "|")
        guard parts.count == 3 else {
            throw QRParseError.invalidFormat
        }

        guard parts[0].uppercased() == prefix else {
            throw QRParseError.invalidFormat
        }

        guard let qrType = QRType(rawValue: parts[1].uppercased()) else {
            throw QRParseError.unknownType(parts[1])
        }

        guard let libraryUUID = UUID(uuidString: parts[2]) else {
            throw QRParseError.invalidUUID(parts[2])
        }

        if let expected = expectedLibraryId, libraryUUID != expected {
            throw QRParseError.unsupportedLibrary(libraryUUID)
        }

        return QRPayload(type: qrType, libraryId: libraryUUID, rawPayload: trimmed)
    }
}
