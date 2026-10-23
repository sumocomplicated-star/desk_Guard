import SwiftUI

public enum Theme {
    public static let primary = Color(red: 79/255, green: 70/255, blue: 229/255) // Indigo #4F46E5
    public static let primaryDark = Color(red: 67/255, green: 56/255, blue: 202/255) // Deep Indigo #4338CA
    public static let accent = Color(red: 14/255, green: 165/255, blue: 233/255) // Sky #0EA5E9
    
    // Status Colors
    public static let available = Color(red: 16/255, green: 185/255, blue: 129/255) // Emerald #10B981
    public static let occupied = Color(red: 239/255, green: 68/255, blue: 68/255)  // Rose #EF4444
    public static let away = Color(red: 245/255, green: 158/255, blue: 11/255)     // Amber #F59E0B
    public static let mine = Color(red: 59/255, green: 130/255, blue: 246/255)    // Electric Blue #3B82F6

    // Adaptive Card Backgrounds
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    public static let pageBackground = Color(uiColor: .systemGroupedBackground)
    public static let elevatedBackground = Color(uiColor: .tertiarySystemGroupedBackground)
}

public struct CardModifier: ViewModifier {
    public var cornerRadius: CGFloat = 16
    public var padding: CGFloat = 16

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

public extension View {
    func standardCard(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}
