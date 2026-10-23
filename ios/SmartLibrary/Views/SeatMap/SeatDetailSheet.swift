import SwiftUI

public struct SeatDetailSheet: View {
    public let seat: SeatMapItem
    public let isBooking: Bool
    public var onConfirmBooking: () -> Void
    public var onDismiss: () -> Void

    public var body: some View {
        VStack(spacing: 20) {
            // Drag Indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            // Header: Seat Label & Status Badge
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seat \(seat.label)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Floor \(seat.floorNumber) • \(seat.zone)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: seat.effectiveStatus)
            }

            Divider()

            // Facilities & Features
            VStack(alignment: .leading, spacing: 10) {
                Text("Desk Amenities")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                if seat.features.isEmpty {
                    Text("Standard study desk with desk lamp")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(seat.features, id: \.self) { feature in
                            FacilityPill(feature)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Booking / Action Area
            VStack(spacing: 12) {
                if seat.isSelectable {
                    PrimaryButton(
                        "Confirm & Reserve Seat \(seat.label)",
                        iconName: "checkmark.seal.fill",
                        isLoading: isBooking
                    ) {
                        onConfirmBooking()
                    }
                } else if seat.effectiveStatus == .mine {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.mine)
                        Text("This is currently your active seat.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.mine)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.mine.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        Text("This seat is currently \(seat.effectiveStatus.title.lowercased()) and cannot be reserved.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.pageBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 8)

            Spacer(minLength: 10)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .background(Theme.cardBackground)
    }
}

/// Simple flow layout helper for facility tags
public struct FlowLayout: Layout {
    public var spacing: CGFloat = 8

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: width, height: currentY + rowHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
