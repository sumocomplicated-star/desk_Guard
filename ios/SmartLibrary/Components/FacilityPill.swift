import SwiftUI

public struct FacilityPill: View {
    public let title: String

    public init(_ title: String) {
        self.title = title
    }

    private var iconName: String {
        let lower = title.lowercased()
        if lower.contains("power") || lower.contains("outlet") {
            return "bolt.fill"
        } else if lower.contains("quiet") {
            return "speaker.slash.fill"
        } else if lower.contains("window") {
            return "sun.max.fill"
        } else if lower.contains("monitor") {
            return "display"
        } else if lower.contains("chair") || lower.contains("ergo") {
            return "chair.lounge.fill"
        } else if lower.contains("standing") {
            return "figure.stand"
        } else if lower.contains("lamp") {
            return "lightbulb.fill"
        } else if lower.contains("ethernet") {
            return "network"
        } else {
            return "sparkles"
        }
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .medium))
            Text(title)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.12))
        .foregroundColor(.primary)
        .clipShape(Capsule())
    }
}
