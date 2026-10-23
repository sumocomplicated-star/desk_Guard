import Foundation

public final class MockLibraryService: LibraryServiceProtocol, @unchecked Sendable {
    private var mockSeats: [SeatMapItem] = []
    private var myState: MyStateResponse = MyStateResponse()
    private let lock = NSLock()

    public init() {
        resetToDemoState()
    }

    public func resetToDemoState() {
        lock.lock()
        defer { lock.unlock() }

        // Seed realistic library seats
        mockSeats = [
            // Floor 1 - Main Hall
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
                label: "A1",
                floorNumber: 1,
                zone: "Main Hall",
                xPosition: 1.0,
                yPosition: 1.0,
                features: ["Power Outlet", "Desk Lamp"],
                availabilityStatus: "available"
            ),
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
                label: "A2",
                floorNumber: 1,
                zone: "Main Hall",
                xPosition: 2.0,
                yPosition: 1.0,
                features: ["Power Outlet"],
                availabilityStatus: "occupied"
            ),
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000003")!,
                label: "A3",
                floorNumber: 1,
                zone: "Main Hall",
                xPosition: 3.0,
                yPosition: 1.0,
                features: ["Desk Lamp"],
                availabilityStatus: "available"
            ),
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000004")!,
                label: "A4",
                floorNumber: 1,
                zone: "Main Hall",
                xPosition: 4.0,
                yPosition: 1.0,
                features: ["Power Outlet", "Ergonomic Chair"],
                availabilityStatus: "temporarily_away"
            ),

            // Floor 1 - Quiet Zone
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000005")!,
                label: "B1",
                floorNumber: 1,
                zone: "Quiet Zone",
                xPosition: 1.0,
                yPosition: 2.0,
                features: ["Quiet Zone", "Power Outlet", "Study Carrel"],
                availabilityStatus: "available"
            ),
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000006")!,
                label: "B2",
                floorNumber: 1,
                zone: "Quiet Zone",
                xPosition: 2.0,
                yPosition: 2.0,
                features: ["Quiet Zone", "Study Carrel"],
                availabilityStatus: "occupied"
            ),
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000007")!,
                label: "B3",
                floorNumber: 1,
                zone: "Quiet Zone",
                xPosition: 3.0,
                yPosition: 2.0,
                features: ["Quiet Zone", "Power Outlet", "Ergonomic Chair"],
                availabilityStatus: "available"
            ),
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000008")!,
                label: "B4",
                floorNumber: 1,
                zone: "Quiet Zone",
                xPosition: 4.0,
                yPosition: 2.0,
                features: ["Quiet Zone", "Power Outlet", "Window View"],
                availabilityStatus: "available"
            ),

            // Floor 2 - Window Terrace
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000009")!,
                label: "C1",
                floorNumber: 2,
                zone: "Window Terrace",
                xPosition: 1.0,
                yPosition: 1.0,
                features: ["Window View", "Power Outlet", "Natural Light"],
                availabilityStatus: "available"
            ),
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000010")!,
                label: "C2",
                floorNumber: 2,
                zone: "Window Terrace",
                xPosition: 2.0,
                yPosition: 1.0,
                features: ["Window View", "Power Outlet"],
                availabilityStatus: "occupied"
            ),
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000011")!,
                label: "C3",
                floorNumber: 2,
                zone: "Window Terrace",
                xPosition: 3.0,
                yPosition: 1.0,
                features: ["Window View", "Standing Desk"],
                availabilityStatus: "available"
            ),

            // Floor 2 - Tech Lab
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000012")!,
                label: "D1",
                floorNumber: 2,
                zone: "Tech Lab",
                xPosition: 1.0,
                yPosition: 2.0,
                features: ["Dual Monitors", "Power Outlet", "Gigabit Ethernet"],
                availabilityStatus: "available"
            ),
            SeatMapItem(
                seatId: UUID(uuidString: "20000000-0000-0000-0000-000000000013")!,
                label: "D2",
                floorNumber: 2,
                zone: "Tech Lab",
                xPosition: 2.0,
                yPosition: 2.0,
                features: ["Dual Monitors", "Power Outlet"],
                availabilityStatus: "occupied"
            )
        ]

        myState = MyStateResponse(
            visitId: nil,
            visitStatus: nil,
            enteredAt: nil,
            bookingId: nil,
            seatId: nil,
            seatLabel: nil,
            bookingStatus: nil,
            graceDeadline: nil
        )
    }

    public func fetchSeatMap(libraryId: UUID) async throws -> [SeatMapItem] {
        lock.lock()
        defer { lock.unlock() }
        return mockSeats
    }

    public func fetchMyState(libraryId: UUID) async throws -> MyStateResponse {
        lock.lock()
        defer { lock.unlock() }
        return myState
    }

    public func scanEntry(libraryId: UUID) async throws -> ScanEntryResponse {
        lock.lock()
        defer { lock.unlock() }

        let nowISO = DateFormatterHelper.formatISO8601(Date())

        if let deadline = myState.graceDeadline,
           let deadlineDate = DateFormatterHelper.parseISO8601(deadline) {
            if Date() <= deadlineDate {
                // Returned during grace period
                myState = MyStateResponse(
                    visitId: myState.visitId ?? UUID(),
                    visitStatus: "active",
                    enteredAt: myState.enteredAt ?? nowISO,
                    bookingId: myState.bookingId,
                    seatId: myState.seatId,
                    seatLabel: myState.seatLabel,
                    bookingStatus: "active",
                    graceDeadline: nil
                )
                // Update seat status
                if let seatId = myState.seatId,
                   let idx = mockSeats.firstIndex(where: { $0.seatId == seatId }) {
                    let old = mockSeats[idx]
                    mockSeats[idx] = SeatMapItem(
                        seatId: old.seatId,
                        label: old.label,
                        floorNumber: old.floorNumber,
                        zone: old.zone,
                        xPosition: old.xPosition,
                        yPosition: old.yPosition,
                        features: old.features,
                        availabilityStatus: "mine",
                        isMine: true,
                        myBookingStatus: "active"
                    )
                }
                return ScanEntryResponse(
                    result: "returned",
                    visitId: myState.visitId,
                    visitStatus: myState.visitStatus,
                    enteredAt: myState.enteredAt,
                    bookingId: myState.bookingId,
                    seatId: myState.seatId,
                    seatLabel: myState.seatLabel,
                    bookingStatus: myState.bookingStatus,
                    graceDeadline: nil
                )
            } else {
                // Grace expired -> new visit
                let newVisitId = UUID()
                // Release old seat
                if let oldSeatId = myState.seatId,
                   let idx = mockSeats.firstIndex(where: { $0.seatId == oldSeatId }) {
                    let old = mockSeats[idx]
                    mockSeats[idx] = SeatMapItem(
                        seatId: old.seatId,
                        label: old.label,
                        floorNumber: old.floorNumber,
                        zone: old.zone,
                        xPosition: old.xPosition,
                        yPosition: old.yPosition,
                        features: old.features,
                        availabilityStatus: "available",
                        isMine: false,
                        myBookingStatus: nil
                    )
                }
                myState = MyStateResponse(
                    visitId: newVisitId,
                    visitStatus: "active",
                    enteredAt: nowISO,
                    bookingId: nil,
                    seatId: nil,
                    seatLabel: nil,
                    bookingStatus: nil,
                    graceDeadline: nil
                )
                return ScanEntryResponse(
                    result: "grace_expired_new_visit",
                    visitId: newVisitId,
                    visitStatus: "active",
                    enteredAt: nowISO
                )
            }
        }

        if myState.hasActiveVisit {
            return ScanEntryResponse(
                result: "already_inside",
                visitId: myState.visitId,
                visitStatus: myState.visitStatus,
                enteredAt: myState.enteredAt,
                bookingId: myState.bookingId,
                seatId: myState.seatId,
                seatLabel: myState.seatLabel,
                bookingStatus: myState.bookingStatus,
                graceDeadline: myState.graceDeadline
            )
        }

        // New Entry
        let visitId = UUID()
        myState = MyStateResponse(
            visitId: visitId,
            visitStatus: "active",
            enteredAt: nowISO
        )

        return ScanEntryResponse(
            result: "entered",
            visitId: visitId,
            visitStatus: "active",
            enteredAt: nowISO
        )
    }

    public func bookSeat(seatId: UUID) async throws -> BookSeatResponse {
        lock.lock()
        defer { lock.unlock() }

        guard myState.hasActiveVisit else {
            throw BookingError.notInsideLibrary
        }
        guard !myState.hasActiveSeat else {
            throw BookingError.alreadyHasSeat
        }

        guard let idx = mockSeats.firstIndex(where: { $0.seatId == seatId }) else {
            throw BookingError.seatUnavailable
        }

        let target = mockSeats[idx]
        guard target.effectiveStatus == .available else {
            throw BookingError.seatUnavailable
        }

        let bookingId = UUID()
        let nowISO = DateFormatterHelper.formatISO8601(Date())

        // Mark seat as mine
        mockSeats[idx] = SeatMapItem(
            seatId: target.seatId,
            label: target.label,
            floorNumber: target.floorNumber,
            zone: target.zone,
            xPosition: target.xPosition,
            yPosition: target.yPosition,
            features: target.features,
            availabilityStatus: "mine",
            isMine: true,
            myBookingStatus: "active"
        )

        myState = MyStateResponse(
            visitId: myState.visitId,
            visitStatus: myState.visitStatus,
            enteredAt: myState.enteredAt,
            bookingId: bookingId,
            seatId: target.seatId,
            seatLabel: target.label,
            bookingStatus: "active",
            graceDeadline: nil
        )

        return BookSeatResponse(
            bookingId: bookingId,
            seatId: target.seatId,
            seatLabel: target.label,
            bookingStatus: "active",
            createdAt: nowISO
        )
    }

    public func startGracePeriod(libraryId: UUID) async throws -> GracePeriodResponse {
        lock.lock()
        defer { lock.unlock() }

        guard let bookingId = myState.bookingId, let seatId = myState.seatId else {
            throw BookingError.serverError("No active booking to hold")
        }

        let deadlineDate = Date().addingTimeInterval(20 * 60) // 20 minutes
        let deadlineISO = DateFormatterHelper.formatISO8601(deadlineDate)

        myState = MyStateResponse(
            visitId: myState.visitId,
            visitStatus: myState.visitStatus,
            enteredAt: myState.enteredAt,
            bookingId: bookingId,
            seatId: seatId,
            seatLabel: myState.seatLabel,
            bookingStatus: "temporarily_away",
            graceDeadline: deadlineISO
        )

        if let idx = mockSeats.firstIndex(where: { $0.seatId == seatId }) {
            let old = mockSeats[idx]
            mockSeats[idx] = SeatMapItem(
                seatId: old.seatId,
                label: old.label,
                floorNumber: old.floorNumber,
                zone: old.zone,
                xPosition: old.xPosition,
                yPosition: old.yPosition,
                features: old.features,
                availabilityStatus: "mine",
                isMine: true,
                myBookingStatus: "temporarily_away",
                graceDeadline: deadlineISO
            )
        }

        return GracePeriodResponse(
            bookingId: bookingId,
            seatId: seatId,
            bookingStatus: "temporarily_away",
            graceDeadline: deadlineISO
        )
    }

    public func leaveLibrary(libraryId: UUID) async throws -> LeaveLibraryResponse {
        lock.lock()
        defer { lock.unlock() }

        let oldSeatId = myState.seatId
        if let seatId = oldSeatId,
           let idx = mockSeats.firstIndex(where: { $0.seatId == seatId }) {
            let old = mockSeats[idx]
            mockSeats[idx] = SeatMapItem(
                seatId: old.seatId,
                label: old.label,
                floorNumber: old.floorNumber,
                zone: old.zone,
                xPosition: old.xPosition,
                yPosition: old.yPosition,
                features: old.features,
                availabilityStatus: "available",
                isMine: false,
                myBookingStatus: nil
            )
        }

        myState = MyStateResponse()

        return LeaveLibraryResponse(
            result: "checked_out",
            visitStatus: "completed",
            bookingStatus: "completed",
            seatId: oldSeatId
        )
    }
}
