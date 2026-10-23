import Foundation
import SwiftUI

@MainActor
public final class ExitScannerViewModel: ObservableObject {
    @Published public var isProcessing: Bool = false
    @Published public var showExitChoiceSheet: Bool = false
    @Published public var errorMessage: String?
    @Published public var validatedLibraryId: UUID?

    public let scannerService = QRCodeScannerService()
    private let appState: AppState

    public init(appState: AppState) {
        self.appState = appState
        setupScanner()
    }

    private func setupScanner() {
        scannerService.onCodeScanned = { [weak self] rawCode in
            Task { @MainActor [weak self] in
                await self?.processScannedPayload(rawCode)
            }
        }
    }

    public func processScannedPayload(_ rawCode: String) async {
        guard !isProcessing else { return }
        isProcessing = true
        errorMessage = nil

        do {
            let payload = try QRParser.parse(rawCode, expectedLibraryId: appState.libraryId)

            guard payload.type == .exit else {
                HapticFeedback.error()
                errorMessage = "This is an ENTRY QR code. Please scan the EXIT QR code to depart."
                isProcessing = false
                scannerService.resumeScanning()
                return
            }

            self.validatedLibraryId = payload.libraryId
            HapticFeedback.selection()
            self.showExitChoiceSheet = true

        } catch let parseError as QRParseError {
            HapticFeedback.error()
            errorMessage = parseError.localizedDescription
            scannerService.resumeScanning()
        } catch {
            HapticFeedback.error()
            errorMessage = "QR scan failed: \(error.localizedDescription)"
            scannerService.resumeScanning()
        }

        isProcessing = false
    }

    // MARK: - Option A: Leaving Permanently

    public func leavePermanently() async -> Bool {
        guard let libraryId = validatedLibraryId ?? Optional(appState.libraryId) else { return false }
        isProcessing = true
        errorMessage = nil

        do {
            _ = try await appState.libraryService.leaveLibrary(libraryId: libraryId)
            HapticFeedback.success()

            // Reset visit and seat
            appState.applyMyState(MyStateResponse())
            appState.triggerToast("Thank you for visiting! Your seat has been released.")
            showExitChoiceSheet = false
            isProcessing = false
            return true
        } catch {
            HapticFeedback.error()
            errorMessage = "Check out failed: \(error.localizedDescription)"
            isProcessing = false
            return false
        }
    }

    // MARK: - Option B: Stepping Out (20 min Grace Period)

    public func stepOutTemporarily() async -> Bool {
        guard let libraryId = validatedLibraryId ?? Optional(appState.libraryId) else { return false }

        // Check if user has an assigned seat
        guard appState.myState.hasActiveSeat else {
            HapticFeedback.warning()
            errorMessage = "You do not have an active seat reservation. Stepping out cannot hold a seat you haven't booked."
            return false
        }

        isProcessing = true
        errorMessage = nil

        do {
            let response = try await appState.libraryService.startGracePeriod(libraryId: libraryId)
            HapticFeedback.success()

            // Update app state with grace deadline
            appState.applyMyState(MyStateResponse(
                visitId: appState.myState.visitId,
                visitStatus: appState.myState.visitStatus,
                enteredAt: appState.myState.enteredAt,
                bookingId: response.bookingId ?? appState.myState.bookingId,
                seatId: response.seatId ?? appState.myState.seatId,
                seatLabel: appState.myState.seatLabel,
                bookingStatus: response.bookingStatus ?? "temporarily_away",
                graceDeadline: response.graceDeadline
            ))

            appState.triggerToast("Seat held for 20 minutes! Please scan ENTRY QR upon return.")
            showExitChoiceSheet = false
            isProcessing = false
            return true
        } catch {
            HapticFeedback.error()
            errorMessage = "Failed to start temporary absence: \(error.localizedDescription)"
            isProcessing = false
            return false
        }
    }

    public func scanDemoExitQR() async {
        let demoPayload = "SLMS|EXIT|\(appState.libraryId.uuidString)"
        await processScannedPayload(demoPayload)
    }

    public func retryScanning() {
        errorMessage = nil
        isProcessing = false
        scannerService.resumeScanning()
    }
}
