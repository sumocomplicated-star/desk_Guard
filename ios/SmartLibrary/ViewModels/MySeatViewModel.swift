import Foundation
import SwiftUI

@MainActor
public final class MySeatViewModel: ObservableObject {
    @Published public var remainingGraceSeconds: Int = 0
    @Published public var showExitScanner: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    private var countdownTimer: Timer?
    public let appState: AppState

    public init(appState: AppState) {
        self.appState = appState
        updateCountdown()
        startTimer()
    }

    deinit {
        countdownTimer?.invalidate()
    }

    public func onAppear() async {
        await appState.refreshMyState()
        updateCountdown()
        startTimer()
    }

    public func onDisappear() {
        stopTimer()
    }

    public func startTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateCountdown()
            }
        }
    }

    public func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    public func updateCountdown() {
        guard let deadline = appState.myState.graceDeadline else {
            remainingGraceSeconds = 0
            return
        }
        remainingGraceSeconds = DateFormatterHelper.remainingSeconds(from: deadline)
    }

    public var isTemporarilyAway: Bool {
        return appState.myState.isTemporarilyAway
    }

    public var formattedCountdown: String {
        DateFormatterHelper.formatCountdown(seconds: remainingGraceSeconds)
    }

    public var entryTimeFormatted: String {
        DateFormatterHelper.formatTimeOnly(DateFormatterHelper.parseISO8601(appState.myState.enteredAt))
    }

    public var elapsedTimeFormatted: String {
        DateFormatterHelper.formatElapsedTime(from: appState.myState.enteredAt)
    }

    public var seatLabel: String {
        appState.myState.seatLabel ?? "N/A"
    }
}
