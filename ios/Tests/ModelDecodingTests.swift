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
        let now = Date(timeIntervalSince1970: 1700000000)
        let futureDate = now.addingTimeInterval(125) // 2 mins 5 seconds
        let futureISO = DateFormatterHelper.formatISO8601(futureDate)

        let remaining = DateFormatterHelper.remainingSeconds(from: futureISO, relativeTo: now)
        XCTAssertEqual(remaining, 125)

        let formatted = DateFormatterHelper.formatCountdown(seconds: remaining)
        XCTAssertEqual(formatted, "02:05")
    }

    func testGracePeriodBoundaryHandling() {
        let now = Date(timeIntervalSince1970: 1700000000)
        
        // Exact boundary (0 seconds remaining)
        let exactDeadline = DateFormatterHelper.formatISO8601(now)
        let zeroRemaining = DateFormatterHelper.remainingSeconds(from: exactDeadline, relativeTo: now)
        XCTAssertEqual(zeroRemaining, 0)
        XCTAssertEqual(DateFormatterHelper.formatCountdown(seconds: zeroRemaining), "00:00")

        // Past boundary (already expired)
        let pastDate = now.addingTimeInterval(-60)
        let pastDeadline = DateFormatterHelper.formatISO8601(pastDate)
        let pastRemaining = DateFormatterHelper.remainingSeconds(from: pastDeadline, relativeTo: now)
        XCTAssertEqual(pastRemaining, 0, "Expired deadline must clamp to 0 seconds")
        XCTAssertEqual(DateFormatterHelper.formatCountdown(seconds: pastRemaining), "00:00")

        // 20-minute standard grace period boundary
        let twentyMins = now.addingTimeInterval(1200)
        let twentyMinsISO = DateFormatterHelper.formatISO8601(twentyMins)
        let twentyMinsRemaining = DateFormatterHelper.remainingSeconds(from: twentyMinsISO, relativeTo: now)
        XCTAssertEqual(twentyMinsRemaining, 1200)
        XCTAssertEqual(DateFormatterHelper.formatCountdown(seconds: twentyMinsRemaining), "20:00")
    }

    func testAllRequiredBackendErrorMappings() {
        XCTAssertEqual(BookingError.from(message: "Error: SEAT_UNAVAILABLE"), .seatUnavailable)
        XCTAssertEqual(BookingError.from(message: "ALREADY_HAS_SEAT: Active reservation exists"), .alreadyHasSeat)
        XCTAssertEqual(BookingError.from(message: "NOT_INSIDE_LIBRARY: Must scan entry first"), .notInsideLibrary)
        XCTAssertEqual(BookingError.from(message: "NO_ACTIVE_VISIT: No active entry"), .noActiveVisit)
        XCTAssertEqual(BookingError.from(message: "UNAUTHORIZED: Token expired"), .unauthorized)
        XCTAssertEqual(BookingError.from(message: "NO_ASSIGNED_SEAT: No seat to hold"), .noAssignedSeat)
        XCTAssertEqual(BookingError.from(message: "CUSTOM_UNKNOWN_ERROR"), .serverError("CUSTOM_UNKNOWN_ERROR"))

        // Verify friendly descriptions
        XCTAssertFalse(BookingError.seatUnavailable.localizedDescription.isEmpty)
        XCTAssertFalse(BookingError.alreadyHasSeat.localizedDescription.isEmpty)
        XCTAssertFalse(BookingError.notInsideLibrary.localizedDescription.isEmpty)
        XCTAssertFalse(BookingError.noActiveVisit.localizedDescription.isEmpty)
        XCTAssertFalse(BookingError.unauthorized.localizedDescription.isEmpty)
        XCTAssertFalse(BookingError.noAssignedSeat.localizedDescription.isEmpty)
    }

    func testDecodeBookSeatResponse() throws {
        let json = """
        {
            "booking_id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            "seat_id": "11111111-2222-3333-4444-555555555555",
            "seat_label": "B2",
            "booking_status": "active",
            "created_at": "2026-10-24T03:00:00Z"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(BookSeatResponse.self, from: json)
        XCTAssertEqual(response.seatLabel, "B2")
        XCTAssertEqual(response.bookingStatus, "active")
        XCTAssertEqual(response.bookingId, UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"))
    }

    func testDecodeStartGracePeriodResponse() throws {
        let json = """
        {
            "booking_id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            "seat_id": "11111111-2222-3333-4444-555555555555",
            "booking_status": "temporarily_away",
            "grace_deadline": "2026-10-24T03:20:00Z"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(GracePeriodResponse.self, from: json)
        XCTAssertEqual(response.bookingStatus, "temporarily_away")
        XCTAssertEqual(response.graceDeadline, "2026-10-24T03:20:00Z")
    }

    func testDecodeLeaveLibraryResponse() throws {
        let json = """
        {
            "result": "left_library",
            "visit_status": "completed",
            "booking_status": "completed",
            "seat_id": "11111111-2222-3333-4444-555555555555"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LeaveLibraryResponse.self, from: json)
        XCTAssertEqual(response.result, "left_library")
        XCTAssertEqual(response.visitStatus, "completed")
        XCTAssertEqual(response.bookingStatus, "completed")
    }
}
