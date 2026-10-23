import Foundation

public struct RecommendationPreferences: Equatable {
    public var quietZone: Bool
    public var powerOutlet: Bool
    public var nearWindow: Bool
    public var preferredZone: String?

    public init(
        quietZone: Bool = false,
        powerOutlet: Bool = false,
        nearWindow: Bool = false,
        preferredZone: String? = nil
    ) {
        self.quietZone = quietZone
        self.powerOutlet = powerOutlet
        self.nearWindow = nearWindow
        self.preferredZone = preferredZone
    }

    public var isDefault: Bool {
        !quietZone && !powerOutlet && !nearWindow && (preferredZone == nil || preferredZone?.isEmpty == true)
    }
}

public struct RecommendedSeat: Identifiable, Equatable {
    public let seat: SeatMapItem
    public let score: Int
    public let reasons: [String]

    public var id: UUID { seat.id }

    public var summaryReason: String {
        if reasons.isEmpty {
            return "Good all-around available study spot."
        }
        return reasons.joined(separator: " • ")
    }
}

public enum RecommendationEngine {
    public static func rank(
        seats: [SeatMapItem],
        preferences: RecommendationPreferences,
        limit: Int = 3
    ) -> [RecommendedSeat] {
        // Only available seats can be recommended
        let available = seats.filter { $0.effectiveStatus == .available }
        guard !available.isEmpty else { return [] }

        var scoredList: [RecommendedSeat] = []

        for seat in available {
            var score = 0
            var reasons: [String] = []

            // Power outlet
            if preferences.powerOutlet {
                if seat.hasPowerOutlet {
                    score += 10
                    reasons.append("⚡️ Power outlet")
                } else {
                    score -= 5
                }
            } else if seat.hasPowerOutlet {
                score += 2
                reasons.append("⚡️ Has power")
            }

            // Quiet zone
            if preferences.quietZone {
                if seat.isQuietZone {
                    score += 10
                    reasons.append("🤫 Quiet study area")
                } else {
                    score -= 5
                }
            } else if seat.isQuietZone {
                score += 1
            }

            // Near window
            if preferences.nearWindow {
                if seat.isWindowSeat {
                    score += 8
                    reasons.append("🪟 Natural window light")
                }
            } else if seat.isWindowSeat {
                score += 2
            }

            // Preferred Zone
            if let pref = preferences.preferredZone, !pref.isEmpty {
                if seat.zone.localizedCaseInsensitiveCompare(pref) == .orderedSame {
                    score += 10
                    reasons.append("📍 In \(seat.zone)")
                }
            }

            // Base score for well-situated seats
            score += 1

            if reasons.isEmpty {
                reasons.append("✨ Available study seat")
            }

            scoredList.append(RecommendedSeat(seat: seat, score: score, reasons: reasons))
        }

        // Sort descending by score, then label
        let sorted = scoredList.sorted { a, b in
            if a.score != b.score {
                return a.score > b.score
            }
            return a.seat.label < b.seat.label
        }

        return Array(sorted.prefix(limit))
    }
}
