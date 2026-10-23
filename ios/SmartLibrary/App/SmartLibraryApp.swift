import SwiftUI

@main
struct SmartLibraryApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                mainContentView
                    .animation(.easeInOut(duration: 0.3), value: appState.navigationStep)
                    .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)

                // Toast Notification Overlay
                if appState.showToast {
                    ToastView(message: appState.toastMessage)
                        .padding(.top, 50)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation {
                                    appState.showToast = false
                                }
                            }
                        }
                }

                // Loading overlay during session restore
                if appState.isRestoringSession {
                    LoadingOverlay("Restoring study session...")
                        .zIndex(200)
                }
            }
        }
    }

    @ViewBuilder
    private var mainContentView: some View {
        if !appState.isAuthenticated {
            AuthView(appState: appState)
        } else {
            switch appState.navigationStep {
            case .auth:
                AuthView(appState: appState)
            case .entryScan:
                EntryScannerView(appState: appState)
            case .seatMap:
                SeatMapView(appState: appState)
            case .mySeat:
                MySeatView(appState: appState)
            }
        }
    }
}
