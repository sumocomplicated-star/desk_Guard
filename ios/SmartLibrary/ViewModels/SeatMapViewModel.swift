import Foundation
import SwiftUI

@MainActor
public final class SeatMapViewModel: ObservableObject {
    @Published public var seats: [SeatMapItem] = []
    @Published public var isLoading: Bool = false
    @Published public var isBooking: Bool = false
    @Published public var errorMessage: String?
    @Published public var selectedSeat: SeatMapItem?
    @Published public var showBookingSheet: Bool = false
    @Published public var showNoSeatsAlert: Bool = false
    @Published public var showRecommendationsSheet: Bool = false

    // Filters
    @Published public var selectedFloor: Int = 1
    @Published public var selectedZone: String? = nil

    // Preferences for Recommendations
    @Published public var preferences = RecommendationPreferences()
    @Published public var topRecommendations: [RecommendedSeat] = []

    private let appState: AppState

    public init(appState: AppState) {
        self.appState = appState
        setupRealtime()
    }

    private func setupRealtime() {
        appState.realtimeService.onSeatMapChanged = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.loadSeatMap(isBackgroundRefresh: true)
            }
        }
    }

    public func onAppear() async {
        await loadSeatMap()
        // Subscribe to Realtime broadcast and start polling fallback
        await appState.realtimeService.subscribe(
            libraryId: appState.libraryId,
            client: appState.isMockMode ? nil : appState.supabaseService.client
        )
        appState.realtimeService.startPolling(interval: 8.0)
    }

    public func onDisappear() {
        appState.realtimeService.stopPolling()
    }

    public func loadSeatMap(isBackgroundRefresh: Bool = false) async {
        if !isBackgroundRefresh {
            isLoading = true
        }
        errorMessage = nil

        do {
            let fetched = try await appState.libraryService.fetchSeatMap(libraryId: appState.libraryId)
            self.seats = fetched

            // Check if any seat is available
            let availableCount = fetched.filter { $0.effectiveStatus == .available }.count
            if availableCount == 0 && !isBackgroundRefresh {
                self.showNoSeatsAlert = true
            }

            // Update recommendations
            self.updateRecommendations()

            // Keep selected seat reference fresh if open
            if let selected = selectedSeat {
                self.selectedSeat = fetched.first { $0.id == selected.id }
            }
        } catch {
            if !isBackgroundRefresh {
                self.errorMessage = "Failed to load seat map: \(error.localizedDescription)"
            }
        }

        if !isBackgroundRefresh {
            isLoading = false
        }
    }

    public func updateRecommendations() {
        self.topRecommendations = RecommendationEngine.rank(
            seats: seats,
            preferences: preferences,
            limit: 3
        )
    }

    // MARK: - Filtering

    public var availableFloors: [Int] {
        let floors = Set(seats.map { $0.floorNumber })
        return floors.sorted()
    }

    public var availableZones: [String] {
        let zones = Set(seats.filter { $0.floorNumber == selectedFloor }.map { $0.zone })
        return zones.sorted()
    }

    public var filteredSeats: [SeatMapItem] {
        seats.filter { seat in
            if seat.floorNumber != selectedFloor {
                return false
            }
            if let zone = selectedZone, !zone.isEmpty, seat.zone != zone {
                return false
            }
            return true
        }
    }

    public var availableSeatsCount: Int {
        seats.filter { $0.effectiveStatus == .available }.count
    }

    public var totalSeatsCount: Int {
        seats.count
    }

    // MARK: - Seat Selection & Booking

    public func selectSeat(_ seat: SeatMapItem) {
        self.selectedSeat = seat
        HapticFeedback.selection()
    }

    public func bookSelectedSeat() async {
        guard let seat = selectedSeat else { return }
        isBooking = true
        errorMessage = nil

        do {
            let response = try await appState.libraryService.bookSeat(seatId: seat.seatId)
            HapticFeedback.success()

            // Update AppState
            appState.applyMyState(MyStateResponse(
                visitId: appState.myState.visitId,
                visitStatus: appState.myState.visitStatus,
                enteredAt: appState.myState.enteredAt,
                bookingId: response.bookingId,
                seatId: response.seatId,
                seatLabel: response.seatLabel,
                bookingStatus: response.bookingStatus,
                graceDeadline: nil
            ))

            showBookingSheet = false
            selectedSeat = nil

            // Reload seat map
            await loadSeatMap(isBackgroundRefresh: true)

            appState.triggerToast("Seat \(response.seatLabel) reserved successfully!")
        } catch let bookingError as BookingError {
            HapticFeedback.error()
            self.errorMessage = bookingError.localizedDescription
            // Refresh map to get latest status
            await loadSeatMap(isBackgroundRefresh: true)
        } catch {
            HapticFeedback.error()
            self.errorMessage = "Booking failed: \(error.localizedDescription)"
            await loadSeatMap(isBackgroundRefresh: true)
        }

        isBooking = false
    }
}
