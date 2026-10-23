import Foundation

public protocol LibraryServiceProtocol: Sendable {
    func fetchSeatMap(libraryId: UUID) async throws -> [SeatMapItem]
    func fetchMyState(libraryId: UUID) async throws -> MyStateResponse
    func scanEntry(libraryId: UUID) async throws -> ScanEntryResponse
    func bookSeat(seatId: UUID) async throws -> BookSeatResponse
    func startGracePeriod(libraryId: UUID) async throws -> GracePeriodResponse
    func leaveLibrary(libraryId: UUID) async throws -> LeaveLibraryResponse
}
