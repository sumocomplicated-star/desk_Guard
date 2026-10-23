import SwiftUI

public struct ExitScannerView: View {
    @ObservedObject public var appState: AppState
    @StateObject private var viewModel: ExitScannerViewModel
    @Environment(\.dismiss) private var dismiss

    public init(appState: AppState) {
        self.appState = appState
        _viewModel = StateObject(wrappedValue: ExitScannerViewModel(appState: appState))
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
                            Text("Scan Exit QR at Door")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text("Scan the EXIT QR code at the turnstile to step out temporarily or conclude your visit.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 16)

                        // Camera Viewfinder
                        QRScannerCameraView(scannerService: viewModel.scannerService)
                            .padding(.horizontal, 20)

                        if viewModel.isProcessing {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(Theme.primary)
                                Text("Validating EXIT QR...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Error Banner
                        if let error = viewModel.errorMessage {
                            VStack(spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.octagon.fill")
                                        .foregroundColor(Theme.occupied)
                                    Text(error)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.occupied)
                                }

                                Button("Try Again") {
                                    viewModel.retryScanning()
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.primary)
                            }
                            .standardCard(cornerRadius: 14, padding: 14)
                            .padding(.horizontal, 20)
                        }

                        // Testing & Simulator Options
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.secondary)
                                Text("Simulator Test Option")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }

                            Text("Expected QR: SLMS|EXIT|\(appState.libraryId.uuidString)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            PrimaryButton(
                                "Simulate Scan EXIT QR",
                                iconName: "qrcode.viewfinder",
                                isOutlined: true
                            ) {
                                Task {
                                    await viewModel.scanDemoExitQR()
                                }
                            }
                        }
                        .standardCard(cornerRadius: 16, padding: 16)
                        .padding(.horizontal, 20)

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("Exit Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showExitChoiceSheet) {
                ExitChoiceSheet(viewModel: viewModel) {
                    viewModel.showExitChoiceSheet = false
                    dismiss()
                }
                .presentationDetents([.fraction(0.55), .medium])
            }
        }
    }
}
