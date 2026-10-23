import Foundation
import SwiftUI

public enum SeatAvailability: String, Codable, CaseIterable {
    case available = "available"
    case occupied = "occupied"
    case temporarilyAway = "temporarily_away"
    case mine = "mine"

    public var title: String {
        switch self {
        case .available:
            return "Available"
        case .occupied:
            return "Occupied"
        case .temporarilyAway:
            return "Temporarily Away"
        case .mine:
            return "My Seat"
        }
    }

    public var color: Color {
        switch self {
        case .available:
            return Color(red: 16/255, green: 185/255, blue: 129/255) // Emerald Green #10B981
        case .occupied:
            return Color(red: 239/255, green: 68/255, blue: 68/255)  // Rose Red #EF4444
        case .temporarilyAway:
            return Color(red: 245/255, green: 158/255, blue: 11/255) // Warm Amber #F59E0B
        case .mine:
            return Color(red: 59/255, green: 130/255, blue: 246/255) // Electric Blue #3B82F6
        }
    }

    public var iconName: String {
        switch self {
        case .available:
            return "checkmark.circle.fill"
        case .occupied:
            return "person.fill"
        case .temporarilyAway:
            return "clock.fill"
        case .mine:
            return "star.fill"
        }
    }
}

public enum BookingStatus: String, Codable, CaseIterable {
    case active = "active"
    case temporarilyAway = "temporarily_away"
    case expired = "expired"
    case completed = "completed"
    case cancelled = "cancelled"

    public var title: String {
        switch self {
        case .active:
            return "Active"
        case .temporarilyAway:
            return "Temporarily Away"
        case .expired:
            return "Expired"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
}

public struct SeatMapItem: Identifiable, Codable, Equatable, Hashable {
    public let seatId: UUID
    public let label: String
    public let floorNumber: Int
    public let zone: String
    public let xPosition: Double
    public let yPosition: Double
    public let features: [String]
    public let rawAvailabilityStatus: String
    public let isMine: Bool
    public let myBookingStatus: String?
    public let graceDeadline: String?

    public var id: UUID { seatId }

    enum CodingKeys: String, CodingKey {
        case seatId = "seat_id"
        case label
        case floorNumber = "floor_number"
        case zone
        case xPosition = "x_position"
        case yPosition = "y_position"
        case features
        case rawAvailabilityStatus = "availability_status"
        case isMine = "is_mine"
        case myBookingStatus = "my_booking_status"
        case graceDeadline = "grace_deadline"
    }

    public init(
        seatId: UUID,
        label: String,
        floorNumber: Int,
        zone: String,
        xPosition: Double,
        yPosition: Double,
        features: [String],
        availabilityStatus: String,
        isMine: Bool = false,
        myBookingStatus: String? = nil,
        graceDeadline: String? = nil
    ) {
        self.seatId = seatId
        self.label = label
        self.floorNumber = floorNumber
        self.zone = zone
        self.xPosition = xPosition
        self.yPosition = yPosition
        self.features = features
        self.rawAvailabilityStatus = availabilityStatus
        self.isMine = isMine
        self.myBookingStatus = myBookingStatus
        self.graceDeadline = graceDeadline
    }

    /// Authoritative visual status according to backend rules
    public var effectiveStatus: SeatAvailability {
        if isMine {
            return .mine
        }
        switch rawAvailabilityStatus.lowercased() {
        case "mine":
            return .mine
        case "occupied":
            return .occupied
        case "temporarily_away", "away":
            return .temporarilyAway
        default:
            return .available
        }
    }

    public var isSelectable: Bool {
        return effectiveStatus == .available
    }

    public var hasPowerOutlet: Bool {
        features.contains { $0.localizedCaseInsensitiveContains("power") || $0.localizedCaseInsensitiveContains("outlet") }
    }

    public var isQuietZone: Bool {
        features.contains { $0.localizedCaseInsensitiveContains("quiet") } || zone.localizedCaseInsensitiveContains("quiet")
    }

    public var isWindowSeat: Bool {
        features.contains { $0.localizedCaseInsensitiveContains("window") } || zone.localizedCaseInsensitiveContains("window")
    }
}
