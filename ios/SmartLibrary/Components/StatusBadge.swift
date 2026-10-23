import SwiftUI

public struct StatusBadge: View {
    public let status: SeatAvailability
    public var customLabel: String? = nil

    public init(status: SeatAvailability, customLabel: String? = nil) {
        self.status = status
        self.customLabel = customLabel
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.iconName)
                .font(.system(size: 11, weight: .bold))
            Text(customLabel ?? status.title)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.16))
        .foregroundColor(status.color)
        .clipShape(Capsule())
    }
}
