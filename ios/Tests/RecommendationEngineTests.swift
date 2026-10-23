import XCTest
@testable import SmartLibrary

final class RecommendationEngineTests: XCTestCase {
    let seatA1 = SeatMapItem(
        seatId: UUID(),
        label: "A1",
        floorNumber: 1,
        zone: "Quiet Zone",
        xPosition: 1.0,
        yPosition: 1.0,
        features: ["Power Outlet", "Quiet Zone"],
        availabilityStatus: "available"
    )

    let seatA2 = SeatMapItem(
        seatId: UUID(),
        label: "A2",
        floorNumber: 1,
        zone: "Main Hall",
        xPosition: 2.0,
        yPosition: 1.0,
        features: ["Desk Lamp"],
        availabilityStatus: "available"
    )

    let seatA3Occupied = SeatMapItem(
        seatId: UUID(),
        label: "A3",
        floorNumber: 1,
        zone: "Quiet Zone",
        xPosition: 3.0,
        yPosition: 1.0,
        features: ["Power Outlet", "Quiet Zone", "Window View"],
        availabilityStatus: "occupied"
    )

    func testNeverRecommendsOccupiedSeats() {
        let seats = [seatA1, seatA2, seatA3Occupied]
        let prefs = RecommendationPreferences(quietZone: true, powerOutlet: true)
        let recs = RecommendationEngine.rank(seats: seats, preferences: prefs, limit: 3)

        // seatA3Occupied should never appear in recommendations
        XCTAssertFalse(recs.contains { $0.seat.id == seatA3Occupied.id })
    }

    func testPreferenceRanking() {
        let seats = [seatA1, seatA2]
        let prefs = RecommendationPreferences(quietZone: true, powerOutlet: true)
        let recs = RecommendationEngine.rank(seats: seats, preferences: prefs, limit: 2)

        XCTAssertEqual(recs.count, 2)
        // A1 has both power and quiet zone, so it should rank first with higher score
        XCTAssertEqual(recs.first?.seat.label, "A1")
        XCTAssertTrue(recs[0].score > recs[1].score)
        XCTAssertTrue(recs[0].summaryReason.contains("Power outlet"))
    }

    func testLimitParameter() {
        let seats = [seatA1, seatA2]
        let prefs = RecommendationPreferences()
        let recs = RecommendationEngine.rank(seats: seats, preferences: prefs, limit: 1)

        XCTAssertEqual(recs.count, 1)
    }

    func testEmptyWhenAllOccupied() {
        let seats = [seatA3Occupied]
        let prefs = RecommendationPreferences()
        let recs = RecommendationEngine.rank(seats: seats, preferences: prefs, limit: 3)

        XCTAssertTrue(recs.isEmpty)
    }
}
