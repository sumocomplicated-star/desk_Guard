import SwiftUI

public struct MySeatView: View {
    @ObservedObject public var appState: AppState
    @StateObject private var viewModel: MySeatViewModel

    public init(appState: AppState) {
        self.appState = appState
        _viewModel = StateObject(wrappedValue: MySeatViewModel(appState: appState))
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Hero Seat Reservation Card
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("CURRENT DESK")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Theme.mine)
                                    Text("Seat \(viewModel.seatLabel)")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }

                                Spacer()

                                StatusBadge(
                                    status: viewModel.isTemporarilyAway ? .temporarilyAway : .mine,
                                    customLabel: viewModel.isTemporarilyAway ? "Temporarily Away" : "Reserved & Active"
                                )
                            }

                            Divider()

                            // Key Session Metrics
                            HStack(spacing: 16) {
                                sessionDetailItem(
                                    icon: "clock.fill",
                                    label: "Check-In Time",
                                    value: viewModel.entryTimeFormatted
                                )
                                Divider()
                                sessionDetailItem(
                                    icon: "timer",
                                    label: "Visit Duration",
                                    value: viewModel.elapsedTimeFormatted
                                )
                                Divider()
                                sessionDetailItem(
                                    icon: "building.2.fill",
                                    label: "Visit Status",
                                    value: appState.myState.visitStatus?.capitalized ?? "Active"
                                )
                            }
                        }
                        .standardCard(cornerRadius: 22, padding: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Theme.mine.opacity(0.3), lineWidth: 1.5)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        // Grace Period Countdown (Visible when temporarily away)
                        if viewModel.isTemporarilyAway {
                            GracePeriodCountdownView(
                                remainingSeconds: viewModel.remainingGraceSeconds,
                                formattedTime: viewModel.formattedCountdown
                            )
                            .padding(.horizontal, 20)
                        }

                        // Exit & Departure Action Card
                        VStack(spacing: 14) {
                            HStack {
                                Image(systemName: "figure.walk.departure")
                                    .font(.system(size: 20))
                                    .foregroundColor(Theme.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Leaving the Library?")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("Scan EXIT QR at the door to step out or release your seat")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }

                            PrimaryButton(
                                "Scan Exit QR Code",
                                iconName: "qrcode.viewfinder"
                            ) {
                                viewModel.showExitScanner = true
                            }
                        }
                        .standardCard(cornerRadius: 18, padding: 18)
                        .padding(.horizontal, 20)

                        // Explore Library Floor Map Button
                        Button(action: {
                            appState.navigationStep = .seatMap
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "map.fill")
                                Text("View Library Floor Map")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
                .refreshable {
                    await viewModel.onAppear()
                }
            }
            .navigationTitle("My Study Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            Task {
                                await appState.signOut()
                            }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.onAppear()
                }
            }
            .onDisappear {
                viewModel.onDisappear()
            }
            .sheet(isPresented: $viewModel.showExitScanner) {
                ExitScannerView(appState: appState)
            }
        }
    }

    private func sessionDetailItem(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
