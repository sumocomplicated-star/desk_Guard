import Foundation
import SwiftUI

@MainActor
public final class EntryScannerViewModel: ObservableObject {
    @Published public var isProcessing: Bool = false
    @Published public var scanResultOutcome: ScanEntryResult?
    @Published public var scanResultMessage: String?
    @Published public var errorMessage: String?
    @Published public var showOutcomeAlert: Bool = false

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
            // Strict parsing
            let payload = try QRParser.parse(rawCode, expectedLibraryId: appState.libraryId)

            guard payload.type == .entry else {
                HapticFeedback.error()
                errorMessage = "This is an EXIT QR code. Please scan the ENTRY QR code to check in."
                isProcessing = false
                scannerService.resumeScanning()
                return
            }

            // Call backend RPC scan_entry(p_library_id)
            let response = try await appState.libraryService.scanEntry(libraryId: payload.libraryId)

            HapticFeedback.success()
            self.scanResultOutcome = response.outcome
            self.scanResultMessage = response.outcome.message

            // Apply state to AppState
            appState.applyMyState(response.asMyState())

            // Show friendly notification if returned or grace expired
            if response.outcome == .returned || response.outcome == .graceExpiredNewVisit || response.outcome == .alreadyInside {
                self.showOutcomeAlert = true
            }

        } catch let parseError as QRParseError {
            HapticFeedback.error()
            errorMessage = parseError.localizedDescription
            scannerService.resumeScanning()
        } catch {
            HapticFeedback.error()
            errorMessage = "Entry validation failed: \(error.localizedDescription)"
            scannerService.resumeScanning()
        }

        isProcessing = false
    }

    public func scanDemoEntryQR() async {
        let demoPayload = "SLMS|ENTRY|\(appState.libraryId.uuidString)"
        await processScannedPayload(demoPayload)
    }

    public func retryScanning() {
        errorMessage = nil
        isProcessing = false
        scannerService.resumeScanning()
    }
}
