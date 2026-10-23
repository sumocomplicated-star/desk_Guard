import XCTest
@testable import SmartLibrary

final class ModelDecodingTests: XCTestCase {
    func testDecodeSeatMapItem() throws {
        let json = """
        {
            "seat_id": "11111111-2222-3333-4444-555555555555",
            "label": "B4",
            "floor_number": 2,
            "zone": "Quiet Zone",
            "x_position": 4.5,
            "y_position": 2.0,
            "features": ["Power Outlet", "Window View"],
            "availability_status": "available",
            "is_mine": false,
            "my_booking_status": null,
            "grace_deadline": null
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(SeatMapItem.self, from: json)
        XCTAssertEqual(item.seatId, UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
        XCTAssertEqual(item.label, "B4")
        XCTAssertEqual(item.floorNumber, 2)
        XCTAssertEqual(item.zone, "Quiet Zone")
        XCTAssertEqual(item.effectiveStatus, .available)
        XCTAssertTrue(item.hasPowerOutlet)
        XCTAssertTrue(item.isQuietZone)
        XCTAssertTrue(item.isWindowSeat)
    }

    func testDecodeMyStateResponseWithNulls() throws {
        let json = """
        {
            "visit_id": null,
            "visit_status": null,
            "entered_at": null,
            "booking_id": null,
            "seat_id": null,
            "seat_label": null,
            "booking_status": null,
            "grace_deadline": null
        }
        """.data(using: .utf8)!

        let state = try JSONDecoder().decode(MyStateResponse.self, from: json)
        XCTAssertNil(state.visitId)
        XCTAssertFalse(state.hasActiveVisit)
        XCTAssertFalse(state.hasActiveSeat)
    }

    func testDecodeScanEntryResponse() throws {
        let json = """
        {
            "result": "returned",
            "visit_id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            "visit_status": "active",
            "entered_at": "2026-10-23T14:00:00Z",
            "booking_id": "11111111-2222-3333-4444-555555555555",
            "seat_id": "22222222-3333-4444-5555-666666666666",
            "seat_label": "A1",
            "booking_status": "active",
            "grace_deadline": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ScanEntryResponse.self, from: json)
        XCTAssertEqual(response.result, "returned")
        XCTAssertEqual(response.outcome, .returned)
        XCTAssertEqual(response.seatLabel, "A1")
        XCTAssertTrue(response.asMyState().hasActiveSeat)
    }

    func testDateCountdownCalculation() {
        let now = Date()
        let futureDate = now.addingTimeInterval(125) // 2 mins 5 seconds
        let futureISO = DateFormatterHelper.formatISO8601(futureDate)

        let remaining = DateFormatterHelper.remainingSeconds(from: futureISO, relativeTo: now)
        XCTAssertEqual(remaining, 125)

        let formatted = DateFormatterHelper.formatCountdown(seconds: remaining)
        XCTAssertEqual(formatted, "02:05")
    }

    func testBookingErrorMapping() {
        let err1 = BookingError.from(message: "Error: SEAT_UNAVAILABLE - The selected seat is already occupied")
        XCTAssertEqual(err1, .seatUnavailable)

        let err2 = BookingError.from(message: "ALREADY_HAS_SEAT: User has an active booking")
        XCTAssertEqual(err2, .alreadyHasSeat)

        let err3 = BookingError.from(message: "NOT_INSIDE_LIBRARY: Must scan entry first")
        XCTAssertEqual(err3, .notInsideLibrary)
    }
}
