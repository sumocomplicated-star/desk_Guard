import SwiftUI

public struct SeatNodeView: View {
    public let seat: SeatMapItem
    public let isSelected: Bool
    public var onSelect: () -> Void

    public var body: some View {
        Button(action: {
            onSelect()
        }) {
            VStack(spacing: 4) {
                // Top icons (power / quiet / window)
                HStack(spacing: 3) {
                    if seat.hasPowerOutlet {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                    }
                    if seat.isQuietZone {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 8))
                    }
                    if seat.isWindowSeat {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 8))
                    }
                }
                .foregroundColor(iconColor)
                .frame(height: 10)

                // Seat Label
                Text(seat.label)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)

                // Mini Status Dot
                Circle()
                    .fill(seat.effectiveStatus.color)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 68, height: 68)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: isSelected ? 2.5 : 1)
            )
            .shadow(color: isSelected ? seat.effectiveStatus.color.opacity(0.35) : Color.black.opacity(0.04), radius: isSelected ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        if isSelected {
            return seat.effectiveStatus.color.opacity(0.18)
        }
        return Theme.cardBackground
    }

    private var borderColor: Color {
        if isSelected {
            return seat.effectiveStatus.color
        }
        return seat.effectiveStatus.color.opacity(0.35)
    }

    private var textColor: Color {
        return .primary
    }

    private var iconColor: Color {
        return seat.effectiveStatus.color
    }
}
