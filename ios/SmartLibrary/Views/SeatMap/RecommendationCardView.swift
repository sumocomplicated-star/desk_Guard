import SwiftUI

public struct RecommendationCardView: View {
    @ObservedObject public var viewModel: SeatMapViewModel

    public var body: some View {
        VStack(spacing: 16) {
            // Header with Preferences Toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Suggestions")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Tailored to your study preferences")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    viewModel.showRecommendationsSheet = true
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Filters")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.primary.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            // Recommendations List
            if viewModel.topRecommendations.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    Text("No available seats match all current preferences. Try adjusting filters.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.topRecommendations) { rec in
                        Button(action: {
                            viewModel.selectSeat(rec.seat)
                            viewModel.showBookingSheet = true
                        }) {
                            HStack(spacing: 12) {
                                // Seat Badge
                                VStack {
                                    Text(rec.seat.label)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.available)
                                    Text("F\(rec.seat.floorNumber)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 44, height: 44)
                                .background(Theme.available.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                // Reasons & Zone
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(rec.seat.zone)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("Score \(rec.score)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.primary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Theme.primary.opacity(0.1))
                                            .clipShape(Capsule())
                                    }

                                    Text(rec.summaryReason)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                            .background(Theme.pageBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .standardCard(cornerRadius: 16, padding: 16)
        .sheet(isPresented: $viewModel.showRecommendationsSheet) {
            RecommendationPreferencesSheet(viewModel: viewModel)
        }
    }
}

public struct RecommendationPreferencesSheet: View {
    @ObservedObject public var viewModel: SeatMapViewModel
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Study Preferences")) {
                    Toggle("Quiet Study Area", isOn: $viewModel.preferences.quietZone)
                        .tint(Theme.primary)
                    Toggle("Power Outlet Required", isOn: $viewModel.preferences.powerOutlet)
                        .tint(Theme.primary)
                    Toggle("Natural Window Light", isOn: $viewModel.preferences.nearWindow)
                        .tint(Theme.primary)
                }

                Section(header: Text("Preferred Zone")) {
                    Picker("Zone", selection: $viewModel.preferences.preferredZone) {
                        Text("Any Zone").tag(String?.none)
                        ForEach(viewModel.availableZones, id: \.self) { zone in
                            Text(zone).tag(String?.some(zone))
                        }
                    }
                }

                Section {
                    Button("Reset to Default") {
                        viewModel.preferences = RecommendationPreferences()
                        viewModel.updateRecommendations()
                    }
                    .foregroundColor(Theme.occupied)
                }
            }
            .navigationTitle("Recommendation Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.updateRecommendations()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
