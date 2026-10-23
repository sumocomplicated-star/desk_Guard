import SwiftUI

public struct EntryScannerView: View {
    @ObservedObject public var appState: AppState
    @StateObject private var viewModel: EntryScannerViewModel

    public init(appState: AppState) {
        self.appState = appState
        _viewModel = StateObject(wrappedValue: EntryScannerViewModel(appState: appState))
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Title / Instructions
                        VStack(spacing: 8) {
                            Text("Step 1 of 2: Library Check-In")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.primary)
                                .textCase(.uppercase)

                            Text("Scan Front Desk QR")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text("Please point your camera at the library's ENTRY QR code to check in and unlock seat selection.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 16)

                        // Camera Viewfinder Card
                        QRScannerCameraView(scannerService: viewModel.scannerService)
                            .padding(.horizontal, 20)

                        // Processing Indicator
                        if viewModel.isProcessing {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(Theme.primary)
                                Text("Validating library access...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }

                        // Error message banner
                        if let error = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.octagon.fill")
                                        .foregroundColor(Theme.occupied)
                                    Text(error)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.occupied)
                                        .multilineTextAlignment(.leading)
                                }

                                Button(action: {
                                    viewModel.retryScanning()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Tap to Scan Again")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.primary)
                                }
                            }
                            .standardCard(cornerRadius: 14, padding: 14)
                            .padding(.horizontal, 20)
                        }

                        // Simulator & Demo Testing Card
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.secondary)
                                Text("Hackathon / Simulator Testing")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }

                            Text("Expected QR: SLMS|ENTRY|\(appState.libraryId.uuidString)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            PrimaryButton(
                                "Simulate Scan ENTRY QR",
                                iconName: "qrcode.viewfinder",
                                isOutlined: true
                            ) {
                                Task {
                                    await viewModel.scanDemoEntryQR()
                                }
                            }
                        }
                        .standardCard(cornerRadius: 16, padding: 16)
                        .padding(.horizontal, 20)

                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationTitle("Library Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await appState.signOut()
                        }
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert(viewModel.scanResultOutcome?.title ?? "Check-In", isPresented: $viewModel.showOutcomeAlert) {
                Button("Continue", role: .cancel) {}
            } message: {
                Text(viewModel.scanResultMessage ?? "")
            }
        }
    }
}
