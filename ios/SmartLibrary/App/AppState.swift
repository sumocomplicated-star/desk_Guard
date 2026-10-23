import Foundation
import SwiftUI
import Supabase

public enum AppNavigationStep: Equatable {
    case auth
    case entryScan
    case seatMap
    case mySeat
}

@MainActor
public final class AppState: ObservableObject {
    @Published public var navigationStep: AppNavigationStep = .auth
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUserEmail: String?
    @Published public var isRestoringSession: Bool = true
    @Published public var errorMessage: String?
    @Published public var showToast: Bool = false
    @Published public var toastMessage: String = ""

    // Session State
    @Published public var myState: MyStateResponse = MyStateResponse()
    @Published public var isMockMode: Bool = AppConfig.shared.isMockMode

    // Services
    public let supabaseService: SupabaseService
    public let mockLibraryService: MockLibraryService
    public let realtimeService: RealtimeService

    public var libraryService: LibraryServiceProtocol {
        if isMockMode {
            return mockLibraryService
        } else {
            return supabaseService
        }
    }

    public var libraryId: UUID {
        AppConfig.shared.defaultLibraryId
    }

    public init() {
        let config = AppConfig.shared
        self.supabaseService = SupabaseService(url: config.supabaseURL, anonKey: config.supabaseAnonKey)
        self.mockLibraryService = MockLibraryService()
        self.realtimeService = RealtimeService()

        Task {
            await restoreSession()
        }
    }

    // MARK: - Session Restoration

    public func restoreSession() async {
        isRestoringSession = true
        defer { isRestoringSession = false }

        if isMockMode {
            // Mock mode session restore
            self.isAuthenticated = true
            self.currentUserEmail = "demo_student@university.edu"
            await refreshMyState()
            return
        }

        guard let user = supabaseService.getCurrentUser() else {
            self.isAuthenticated = false
            self.currentUserEmail = nil
            self.navigationStep = .auth
            return
        }

        self.isAuthenticated = true
        self.currentUserEmail = user.email
        await refreshMyState()
    }

    public func refreshMyState() async {
        do {
            let state = try await libraryService.fetchMyState(libraryId: libraryId)
            self.applyMyState(state)
        } catch {
            print("[AppState] fetchMyState error: \(error)")
            // If failed to fetch state but authenticated, prompt entry scan
            if navigationStep == .auth {
                self.navigationStep = .entryScan
            }
        }
    }

    public func applyMyState(_ state: MyStateResponse) {
        self.myState = state

        if state.hasActiveSeat {
            self.navigationStep = .mySeat
        } else if state.hasActiveVisit {
            self.navigationStep = .seatMap
        } else {
            // No active visit -> user must scan ENTRY QR first
            self.navigationStep = .entryScan
        }
    }

    // MARK: - Auth Operations

    public func didSignIn(email: String) async {
        self.isAuthenticated = true
        self.currentUserEmail = email
        await refreshMyState()
    }

    public func signOut() async {
        do {
            if !isMockMode {
                try await supabaseService.signOut()
            }
            await realtimeService.unsubscribe()
            self.isAuthenticated = false
            self.currentUserEmail = nil
            self.myState = MyStateResponse()
            self.navigationStep = .auth
            triggerToast("Signed out successfully")
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Toast Feedback

    public func triggerToast(_ message: String) {
        self.toastMessage = message
        self.showToast = true
    }

    public func toggleMockMode() {
        self.isMockMode.toggle()
        Task {
            await refreshMyState()
        }
    }
}
