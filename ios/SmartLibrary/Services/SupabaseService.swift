import Foundation
import Supabase

public final class SupabaseService: LibraryServiceProtocol, @unchecked Sendable {
    public let client: SupabaseClient

    public init(url: URL, anonKey: String) {
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    // MARK: - Auth Operations

    public func signUp(email: String, password: String) async throws -> AuthResponse {
        return try await client.auth.signUp(email: email, password: password)
    }

    public func signIn(email: String, password: String) async throws -> Session {
        return try await client.auth.signIn(email: email, password: password)
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    public func getCurrentSession() -> Session? {
        return client.auth.currentSession
    }

    public func getCurrentUser() -> User? {
        return client.auth.currentSession?.user
    }

    // MARK: - Library RPC Operations

    public func fetchSeatMap(libraryId: UUID) async throws -> [SeatMapItem] {
        do {
            let seats: [SeatMapItem] = try await client
                .rpc("get_seat_map", params: ["p_library_id": libraryId.uuidString])
                .execute()
                .value
            return seats
        } catch {
            print("[SupabaseService] fetchSeatMap error: \(error)")
            throw error
        }
    }

    public func fetchMyState(libraryId: UUID) async throws -> MyStateResponse {
        do {
            let state: MyStateResponse = try await client
                .rpc("get_my_state", params: ["p_library_id": libraryId.uuidString])
                .execute()
                .value
            return state
        } catch {
            print("[SupabaseService] fetchMyState error: \(error)")
            throw error
        }
    }

    public func scanEntry(libraryId: UUID) async throws -> ScanEntryResponse {
        do {
            let response: ScanEntryResponse = try await client
                .rpc("scan_entry", params: ["p_library_id": libraryId.uuidString])
                .execute()
                .value
            return response
        } catch {
            print("[SupabaseService] scanEntry error: \(error)")
            throw error
        }
    }

    public func bookSeat(seatId: UUID) async throws -> BookSeatResponse {
        do {
            let response: BookSeatResponse = try await client
                .rpc("book_seat", params: ["p_seat_id": seatId.uuidString])
                .execute()
                .value
            return response
        } catch {
            print("[SupabaseService] bookSeat error: \(error)")
            let description = error.localizedDescription
            throw BookingError.from(message: description)
        }
    }

    public func startGracePeriod(libraryId: UUID) async throws -> GracePeriodResponse {
        do {
            let response: GracePeriodResponse = try await client
                .rpc("start_grace_period", params: ["p_library_id": libraryId.uuidString])
                .execute()
                .value
            return response
        } catch {
            print("[SupabaseService] startGracePeriod error: \(error)")
            throw error
        }
    }

    public func leaveLibrary(libraryId: UUID) async throws -> LeaveLibraryResponse {
        do {
            let response: LeaveLibraryResponse = try await client
                .rpc("leave_library", params: ["p_library_id": libraryId.uuidString])
                .execute()
                .value
            return response
        } catch {
            print("[SupabaseService] leaveLibrary error: \(error)")
            throw error
        }
    }
}
