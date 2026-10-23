import SwiftUI

public struct SeatGridView: View {
    public let seats: [SeatMapItem]
    public let selectedSeat: SeatMapItem?
    public var onSelectSeat: (SeatMapItem) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 70, maximum: 80), spacing: 14)
    ]

    public var body: some View {
        let groupedByZone = Dictionary(grouping: seats, by: { $0.zone })
        let sortedZones = groupedByZone.keys.sorted()

        VStack(spacing: 20) {
            ForEach(sortedZones, id: \.self) { zone in
                VStack(alignment: .leading, spacing: 10) {
                    // Zone Header
                    HStack {
                        Image(systemName: zoneIcon(zone))
                            .foregroundColor(Theme.primary)
                            .font(.system(size: 13, weight: .bold))

                        Text(zone)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Spacer()

                        let zoneSeats = groupedByZone[zone] ?? []
                        let available = zoneSeats.filter { $0.effectiveStatus == .available }.count
                        Text("\(available)/\(zoneSeats.count) free")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(available > 0 ? Theme.available : .secondary)
                    }
                    .padding(.horizontal, 4)

                    // Seats Grid
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(groupedByZone[zone] ?? []) { seat in
                            SeatNodeView(
                                seat: seat,
                                isSelected: selectedSeat?.id == seat.id,
                                onSelect: {
                                    onSelectSeat(seat)
                                }
                            )
                        }
                    }
                    .padding(14)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                }
            }
        }
    }

    private func zoneIcon(_ zone: String) -> String {
        let lower = zone.lowercased()
        if lower.contains("quiet") {
            return "speaker.slash.fill"
        } else if lower.contains("window") || lower.contains("terrace") {
            return "sun.max.fill"
        } else if lower.contains("tech") || lower.contains("lab") {
            return "desktopcomputer"
        } else {
            return "books.vertical.fill"
        }
    }
}
