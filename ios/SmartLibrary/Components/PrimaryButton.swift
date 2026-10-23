import SwiftUI

public struct PrimaryButton: View {
    public let title: String
    public var iconName: String? = nil
    public var isLoading: Bool = false
    public var isDestructive: Bool = false
    public var isOutlined: Bool = false
    public var action: () -> Void

    public init(
        _ title: String,
        iconName: String? = nil,
        isLoading: Bool = false,
        isDestructive: Bool = false,
        isOutlined: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.isLoading = isLoading
        self.isDestructive = isDestructive
        self.isOutlined = isOutlined
        self.action = action
    }

    public var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(isOutlined ? Theme.primary : .white)
                } else {
                    if let icon = iconName {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: isOutlined ? 1.5 : 0)
            )
            .shadow(color: shadowColor, radius: 6, x: 0, y: 3)
        }
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        if isOutlined {
            return .clear
        }
        if isDestructive {
            return Theme.occupied
        }
        return Theme.primary
    }

    private var foregroundColor: Color {
        if isOutlined {
            return isDestructive ? Theme.occupied : Theme.primary
        }
        return .white
    }

    private var borderColor: Color {
        if isDestructive {
            return Theme.occupied
        }
        return Theme.primary
    }

    private var shadowColor: Color {
        if isOutlined { return .clear }
        return (isDestructive ? Theme.occupied : Theme.primary).opacity(0.25)
    }
}
