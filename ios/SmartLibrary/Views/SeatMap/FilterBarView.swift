import SwiftUI

public struct FilterBarView: View {
    public let availableFloors: [Int]
    public let availableZones: [String]
    @Binding public var selectedFloor: Int
    @Binding public var selectedZone: String?

    public var body: some View {
        VStack(spacing: 12) {
            // Floor Picker
            if availableFloors.count > 1 {
                Picker("Floor", selection: $selectedFloor) {
                    ForEach(availableFloors, id: \.self) { floor in
                        Text("Floor \(floor)").tag(floor)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
            }

            // Zone Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ZoneChip(
                        title: "All Zones",
                        isSelected: selectedZone == nil || selectedZone?.isEmpty == true
                    ) {
                        selectedZone = nil
                        HapticFeedback.selection()
                    }

                    ForEach(availableZones, id: \.self) { zone in
                        ZoneChip(
                            title: zone,
                            isSelected: selectedZone == zone
                        ) {
                            if selectedZone == zone {
                                selectedZone = nil
                            } else {
                                selectedZone = zone
                            }
                            HapticFeedback.selection()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // Status Legend
            HStack(spacing: 14) {
                LegendItem(color: Theme.available, label: "Available")
                LegendItem(color: Theme.occupied, label: "Occupied")
                LegendItem(color: Theme.away, label: "Away")
                LegendItem(color: Theme.mine, label: "My Seat")
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
    }
}

private struct ZoneChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.primary : Theme.cardBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}
