import SwiftUI

// MARK: - App Style Guide
struct AppStyle {
    // Colors - Using system colors to automatically adapt to dark mode
    static let primaryColor = Color.blue
    static let secondaryColor = Color.blue.opacity(0.8)
    static let backgroundColor = Color(.systemBackground) // Already adapts to dark mode
    static let textColor = Color(.label) // Already adapts to dark mode
    static let secondaryTextColor = Color(.secondaryLabel) // Already adapts to dark mode
    static let accentColor = Color.blue
    
    // Card background that adapts to light/dark mode
    static var cardBackgroundColor: Color {
        Color(.secondarySystemBackground)
    }
    
    // Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let button = Font.system(size: 16, weight: .semibold)
    }
    
    // Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    // Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    // Shadows
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        static let small = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppStyle.Spacing.medium)
            .background(AppStyle.cardBackgroundColor)
            .cornerRadius(AppStyle.CornerRadius.medium)
            .shadow(
                color: AppStyle.ShadowStyle.small.color,
                radius: AppStyle.ShadowStyle.small.radius,
                x: AppStyle.ShadowStyle.small.x,
                y: AppStyle.ShadowStyle.small.y
            )
    }
}

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppStyle.Typography.headline)
            .foregroundColor(AppStyle.textColor)
            .padding(.vertical, AppStyle.Spacing.small)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
    
    func sectionHeaderStyle() -> some View {
        self.modifier(SectionHeaderStyle())
    }
} 