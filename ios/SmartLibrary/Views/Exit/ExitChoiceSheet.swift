import SwiftUI

public struct ExitChoiceSheet: View {
    @ObservedObject public var viewModel: ExitScannerViewModel
    public var onDismiss: () -> Void

    public var body: some View {
        VStack(spacing: 24) {
            // Drag Indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            // Header
            VStack(spacing: 6) {
                Image(systemName: "door.right.hand.open")
                    .font(.system(size: 38))
                    .foregroundColor(Theme.primary)

                Text("Library Departure")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Please specify whether you are stepping out temporarily or completing your visit.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.occupied)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.occupied)
                }
                .padding(12)
                .background(Theme.occupied.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(spacing: 14) {
                // Option B: Stepping Out (20 min Grace Period)
                Button(action: {
                    Task {
                        let success = await viewModel.stepOutTemporarily()
                        if success {
                            onDismiss()
                        }
                    }
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock.badge.checkmark.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.away)

                            Text("Stepping Out Temporarily")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Text("Hold 20m")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.away)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.away.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Text("Keep your seat reserved while you take a short break. You must scan the ENTRY QR within 20 minutes.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.pageBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.away.opacity(0.3), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isProcessing)

                // Option A: Leaving Permanently
                Button(action: {
                    Task {
                        let success = await viewModel.leavePermanently()
                        if success {
                            onDismiss()
                        }
                    }
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.occupied)

                            Text("Leaving Permanently")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Text("Release Seat")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.occupied)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.occupied.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Text("End your session immediately and release your reserved seat to other students.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.pageBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.occupied.opacity(0.3), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isProcessing)
            }

            if viewModel.isProcessing {
                ProgressView("Updating visit status...")
                    .tint(Theme.primary)
            }

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .background(Theme.cardBackground)
    }
}
