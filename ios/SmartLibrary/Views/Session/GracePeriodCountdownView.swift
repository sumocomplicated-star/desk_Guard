import SwiftUI

public struct GracePeriodCountdownView: View {
    public let remainingSeconds: Int
    public let formattedTime: String

    public var body: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.away)
                        .frame(width: 8, height: 8)
                    Text("Temporary Absence Active")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.away)
                }

                Spacer()

                Text("20-Min Grace")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                // Large Countdown Display
                VStack(spacing: 2) {
                    Text(formattedTime)
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .foregroundColor(remainingSeconds > 0 ? Theme.away : Theme.occupied)

                    Text("REMAINING TIME")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.away.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Theme.away)
                        .font(.system(size: 13))
                    Text("Return Notice")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                }
                Text("Scan the ENTRY QR at the library entrance when you return. If this timer runs out, your seat will be automatically released to other students.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .standardCard(cornerRadius: 18, padding: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.away.opacity(0.4), lineWidth: 1.5)
        )
    }
}
