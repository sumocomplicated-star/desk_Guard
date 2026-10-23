import Foundation
import Supabase

@MainActor
public final class RealtimeService: ObservableObject {
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var lastEventTimestamp: Date?

    private var currentChannel: RealtimeChannelV2?
    private var broadcastTask: Task<Void, Never>?
    private var pollingTimer: Timer?
    private var client: SupabaseClient?

    public var onSeatMapChanged: (() -> Void)?

    public init() {}

    deinit {
        // Stop polling timer if running
        pollingTimer?.invalidate()
        broadcastTask?.cancel()
    }

    /// Subscribes to the broadcast topic `library:<UUID>` for event `seat-map-changed`
    public func subscribe(libraryId: UUID, client: SupabaseClient?) async {
        self.client = client
        guard let client = client else {
            print("[RealtimeService] No Supabase client provided; relying on polling fallback.")
            return
        }

        // Unsubscribe prior channel if any
        await unsubscribe()

        let topic = "library:\(libraryId.uuidString)"
        let channel = client.channel(topic)
        self.currentChannel = channel

        let broadcastStream = channel.broadcastStream(event: "seat-map-changed")

        do {
            try await channel.subscribeWithError()
            self.isConnected = true
            print("[RealtimeService] Subscribed to broadcast channel '\(topic)'")

            broadcastTask = Task { [weak self] in
                for await _ in broadcastStream {
                    guard !Task.isCancelled else { break }
                    await MainActor.run {
                        self?.lastEventTimestamp = Date()
                        print("[RealtimeService] Received 'seat-map-changed' event! Triggering refresh.")
                        self?.onSeatMapChanged?()
                    }
                }
            }
        } catch {
            print("[RealtimeService] Realtime subscribe error: \(error). Fallback polling will take over.")
            self.isConnected = false
        }
    }

    /// Unsubscribes from current realtime channel
    public func unsubscribe() async {
        broadcastTask?.cancel()
        broadcastTask = nil

        if let channel = currentChannel, let client = client {
            await client.removeChannel(channel)
        }
        currentChannel = nil
        isConnected = false
    }

    // MARK: - Polling Fallback

    /// Starts polling every 8 seconds while screen is active
    public func startPolling(interval: TimeInterval = 8.0) {
        stopPolling()
        print("[RealtimeService] Starting polling fallback (interval: \(interval)s)")
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            print("[RealtimeService] Polling tick -> triggering map refresh")
            self.onSeatMapChanged?()
        }
    }

    /// Stops polling when screen becomes inactive or enters background
    public func stopPolling() {
        if pollingTimer != nil {
            print("[RealtimeService] Stopping polling fallback")
            pollingTimer?.invalidate()
            pollingTimer = nil
        }
    }

    /// Called on app foreground return
    public func handleForegroundReturn() {
        print("[RealtimeService] App returned to foreground -> refreshing map")
        onSeatMapChanged?()
    }
}
