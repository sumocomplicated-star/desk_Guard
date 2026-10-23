import SwiftUI

public struct LoadingOverlay: View {
    public let message: String

    public init(_ message: String = "Loading...") {
        self.message = message
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Theme.primary)
                Text(message)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
        }
    }
}

public struct ToastView: View {
    public let message: String
    public var isError: Bool = false

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? Theme.occupied : Theme.available)
                .font(.system(size: 16, weight: .semibold))

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}
