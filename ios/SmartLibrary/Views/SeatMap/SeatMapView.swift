import SwiftUI

public struct SeatMapView: View {
    @ObservedObject public var appState: AppState
    @StateObject private var viewModel: SeatMapViewModel
    @Environment(\.scenePhase) private var scenePhase

    public init(appState: AppState) {
        self.appState = appState
        _viewModel = StateObject(wrappedValue: SeatMapViewModel(appState: appState))
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Theme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Realtime Pulse Header & Capacity Stats
                        VStack(spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(appState.realtimeService.isConnected ? Theme.available : Theme.away)
                                        .frame(width: 8, height: 8)
                                    Text(appState.realtimeService.isConnected ? "Live Realtime" : "Auto-Polling (8s)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())

                                Spacer()

                                if appState.myState.hasActiveSeat {
                                    Button(action: {
                                        appState.navigationStep = .mySeat
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                            Text("My Seat: \(appState.myState.seatLabel ?? "")")
                                        }
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.mine)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Theme.mine.opacity(0.12))
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            // Stats Cards
                            HStack(spacing: 12) {
                                StatCard(
                                    title: "Available",
                                    value: "\(viewModel.availableSeatsCount)",
                                    iconName: "checkmark.circle.fill",
                                    color: Theme.available
                                )
                                StatCard(
                                    title: "Occupied",
                                    value: "\(viewModel.totalSeatsCount - viewModel.availableSeatsCount)",
                                    iconName: "person.2.fill",
                                    color: Theme.occupied
                                )
                                StatCard(
                                    title: "Floor Desks",
                                    value: "\(viewModel.filteredSeats.count)",
                                    iconName: "square.grid.2x2.fill",
                                    color: Theme.primary
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Smart Recommendations Section
                        RecommendationCardView(viewModel: viewModel)
                            .padding(.horizontal, 20)

                        // Floor & Zone Filters + Legend
                        FilterBarView(
                            availableFloors: viewModel.availableFloors,
                            availableZones: viewModel.availableZones,
                            selectedFloor: $viewModel.selectedFloor,
                            selectedZone: $viewModel.selectedZone
                        )

                        // Error Banner if any
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Theme.occupied)
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.occupied)
                            }
                            .standardCard(cornerRadius: 12, padding: 12)
                            .padding(.horizontal, 20)
                        }

                        // Floor Plan Seat Grid
                        if viewModel.isLoading && viewModel.seats.isEmpty {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(Theme.primary)
                                Text("Loading floor plan...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else if viewModel.filteredSeats.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "chair.lounge")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)
                                Text("No seats found on this floor/zone.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 180)
                        } else {
                            SeatGridView(
                                seats: viewModel.filteredSeats,
                                selectedSeat: viewModel.selectedSeat,
                                onSelectSeat: { seat in
                                    viewModel.selectSeat(seat)
                                    viewModel.showBookingSheet = true
                                }
                            )
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 90)
                    }
                }
                .refreshable {
                    await viewModel.loadSeatMap()
                }

                // Selected Seat Bottom Bar Preview
                if let selected = viewModel.selectedSeat, !viewModel.showBookingSheet {
                    selectedSeatFloatingBar(selected)
                }
            }
            .navigationTitle("Library Floor Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.loadSeatMap()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
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
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    appState.realtimeService.handleForegroundReturn()
                }
            }
            .alert("Seat Availability", isPresented: $viewModel.showNoSeatsAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No seats available right now. Please check again shortly.")
            }
            .sheet(isPresented: $viewModel.showBookingSheet) {
                if let seat = viewModel.selectedSeat {
                    SeatDetailSheet(
                        seat: seat,
                        isBooking: viewModel.isBooking,
                        onConfirmBooking: {
                            Task {
                                await viewModel.bookSelectedSeat()
                            }
                        },
                        onDismiss: {
                            viewModel.showBookingSheet = false
                        }
                    )
                    .presentationDetents([.fraction(0.48), .medium])
                }
            }
        }
    }

    private func selectedSeatFloatingBar(_ seat: SeatMapItem) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Seat \(seat.label)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    StatusBadge(status: seat.effectiveStatus)
                }
                Text("Floor \(seat.floorNumber) • \(seat.zone)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                viewModel.showBookingSheet = true
            }) {
                Text(seat.isSelectable ? "Book Seat" : "View Details")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(seat.isSelectable ? Theme.primary : Color.secondary)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}
