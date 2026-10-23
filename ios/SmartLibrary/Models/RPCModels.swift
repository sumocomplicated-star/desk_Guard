import Foundation

public enum ScanEntryResult: String, Codable {
    case entered = "entered"
    case alreadyInside = "already_inside"
    case returned = "returned"
    case graceExpiredNewVisit = "grace_expired_new_visit"

    public var title: String {
        switch self {
        case .entered:
            return "Welcome to the Library"
        case .alreadyInside:
            return "Session Restored"
        case .returned:
            return "Welcome Back!"
        case .graceExpiredNewVisit:
            return "Grace Period Expired"
        }
    }

    public var message: String {
        switch self {
        case .entered:
            return "Your entry is confirmed. Please pick an available seat on the floor map."
        case .alreadyInside:
            return "You are already checked in. Your current seat session has been resumed."
        case .returned:
            return "You returned within the 20-minute window! Your reserved seat has been preserved."
        case .graceExpiredNewVisit:
            return "Your 20-minute temporary absence elapsed, so your previous seat was released. A new visit has begun—please select another seat."
        }
    }
}

public struct MyStateResponse: Codable, Equatable {
    public let visitId: UUID?
    public let visitStatus: String?
    public let enteredAt: String?
    public let bookingId: UUID?
    public let seatId: UUID?
    public let seatLabel: String?
    public let bookingStatus: String?
    public let graceDeadline: String?

    enum CodingKeys: String, CodingKey {
        case visitId = "visit_id"
        case visitStatus = "visit_status"
        case enteredAt = "entered_at"
        case bookingId = "booking_id"
        case seatId = "seat_id"
        case seatLabel = "seat_label"
        case bookingStatus = "booking_status"
        case graceDeadline = "grace_deadline"
    }

    public init(
        visitId: UUID? = nil,
        visitStatus: String? = nil,
        enteredAt: String? = nil,
        bookingId: UUID? = nil,
        seatId: UUID? = nil,
        seatLabel: String? = nil,
        bookingStatus: String? = nil,
        graceDeadline: String? = nil
    ) {
        self.visitId = visitId
        self.visitStatus = visitStatus
        self.enteredAt = enteredAt
        self.bookingId = bookingId
        self.seatId = seatId
        self.seatLabel = seatLabel
        self.bookingStatus = bookingStatus
        self.graceDeadline = graceDeadline
    }

    public var hasActiveVisit: Bool {
        guard let status = visitStatus?.lowercased() else { return false }
        return status == "active" || status == "inside" || status == "entered" || status == "temporarily_away"
    }

    public var hasActiveSeat: Bool {
        return bookingId != nil && seatLabel != nil && (bookingStatus?.lowercased() == "active" || bookingStatus?.lowercased() == "temporarily_away")
    }

    public var isTemporarilyAway: Bool {
        return bookingStatus?.lowercased() == "temporarily_away"
    }
}

public struct ScanEntryResponse: Codable, Equatable {
    public let result: String
    public let visitId: UUID?
    public let visitStatus: String?
    public let enteredAt: String?
    public let bookingId: UUID?
    public let seatId: UUID?
    public let seatLabel: String?
    public let bookingStatus: String?
    public let graceDeadline: String?

    enum CodingKeys: String, CodingKey {
        case result
        case visitId = "visit_id"
        case visitStatus = "visit_status"
        case enteredAt = "entered_at"
        case bookingId = "booking_id"
        case seatId = "seat_id"
        case seatLabel = "seat_label"
        case bookingStatus = "booking_status"
        case graceDeadline = "grace_deadline"
    }

    public init(
        result: String,
        visitId: UUID? = nil,
        visitStatus: String? = nil,
        enteredAt: String? = nil,
        bookingId: UUID? = nil,
        seatId: UUID? = nil,
        seatLabel: String? = nil,
        bookingStatus: String? = nil,
        graceDeadline: String? = nil
    ) {
        self.result = result
        self.visitId = visitId
        self.visitStatus = visitStatus
        self.enteredAt = enteredAt
        self.bookingId = bookingId
        self.seatId = seatId
        self.seatLabel = seatLabel
        self.bookingStatus = bookingStatus
        self.graceDeadline = graceDeadline
    }

    public var outcome: ScanEntryResult {
        return ScanEntryResult(rawValue: result) ?? .entered
    }

    public func asMyState() -> MyStateResponse {
        return MyStateResponse(
            visitId: visitId,
            visitStatus: visitStatus,
            enteredAt: enteredAt,
            bookingId: bookingId,
            seatId: seatId,
            seatLabel: seatLabel,
            bookingStatus: bookingStatus,
            graceDeadline: graceDeadline
        )
    }
}

public struct BookSeatResponse: Codable, Equatable {
    public let bookingId: UUID
    public let seatId: UUID
    public let seatLabel: String
    public let bookingStatus: String
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case bookingId = "booking_id"
        case seatId = "seat_id"
        case seatLabel = "seat_label"
        case bookingStatus = "booking_status"
        case createdAt = "created_at"
    }

    public init(
        bookingId: UUID,
        seatId: UUID,
        seatLabel: String,
        bookingStatus: String,
        createdAt: String
    ) {
        self.bookingId = bookingId
        self.seatId = seatId
        self.seatLabel = seatLabel
        self.bookingStatus = bookingStatus
        self.createdAt = createdAt
    }
}

public struct GracePeriodResponse: Codable, Equatable {
    public let bookingId: UUID?
    public let seatId: UUID?
    public let bookingStatus: String?
    public let graceDeadline: String?

    enum CodingKeys: String, CodingKey {
        case bookingId = "booking_id"
        case seatId = "seat_id"
        case bookingStatus = "booking_status"
        case graceDeadline = "grace_deadline"
    }

    public init(
        bookingId: UUID? = nil,
        seatId: UUID? = nil,
        bookingStatus: String? = nil,
        graceDeadline: String? = nil
    ) {
        self.bookingId = bookingId
        self.seatId = seatId
        self.bookingStatus = bookingStatus
        self.graceDeadline = graceDeadline
    }
}

public struct LeaveLibraryResponse: Codable, Equatable {
    public let result: String
    public let visitStatus: String?
    public let bookingStatus: String?
    public let seatId: UUID?

    enum CodingKeys: String, CodingKey {
        case result
        case visitStatus = "visit_status"
        case bookingStatus = "booking_status"
        case seatId = "seat_id"
    }

    public init(
        result: String,
        visitStatus: String? = nil,
        bookingStatus: String? = nil,
        seatId: UUID? = nil
    ) {
        self.result = result
        self.visitStatus = visitStatus
        self.bookingStatus = bookingStatus
        self.seatId = seatId
    }
}

public enum BookingError: LocalizedError, Equatable {
    case seatUnavailable
    case alreadyHasSeat
    case notInsideLibrary
    case noActiveVisit
    case unauthorized
    case serverError(String)
    case unknown

    public static func from(message: String) -> BookingError {
        let upper = message.uppercased()
        if upper.contains("SEAT_UNAVAILABLE") || upper.contains("ALREADY_BOOKED") || upper.contains("NOT_AVAILABLE") {
            return .seatUnavailable
        } else if upper.contains("ALREADY_HAS_SEAT") || upper.contains("ALREADY_RESERVED") {
            return .alreadyHasSeat
        } else if upper.contains("NOT_INSIDE_LIBRARY") {
            return .notInsideLibrary
        } else if upper.contains("NO_ACTIVE_VISIT") {
            return .noActiveVisit
        } else if upper.contains("UNAUTHORIZED") || upper.contains("JWT") || upper.contains("EXPIRED") {
            return .unauthorized
        } else {
            return .serverError(message)
        }
    }

    public var errorDescription: String? {
        switch self {
        case .seatUnavailable:
            return "This seat was just taken by another student. Please pick another seat."
        case .alreadyHasSeat:
            return "You already have an active seat reservation."
        case .notInsideLibrary:
            return "You must scan into the library before booking a seat."
        case .noActiveVisit:
            return "No active visit found. Please scan the entry QR at the front desk."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .serverError(let raw):
            return "Booking failed: \(raw)"
        case .unknown:
            return "An unexpected error occurred while booking. Please try again."
        }
    }
}
