import SwiftUI

// MARK: - App Style Guide
struct AppStyle {
    // Colors - Distinct accent (indigo); change to Color.accentColor to follow system
    static let primaryColor = Color.indigo
    static let secondaryColor = Color.indigo.opacity(0.85)
    static let backgroundColor = Color(.systemBackground)
    static let textColor = Color(.label)
    static let secondaryTextColor = Color(.secondaryLabel)
    static let accentColor = Color.indigo
    
    // Card background that adapts to light/dark mode
    static var cardBackgroundColor: Color {
        Color(.secondarySystemBackground)
    }
    
    // Typography - Dynamic Type: scales with Settings → Display → Text Size
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title
        static let headline = Font.headline
        static let body = Font.body
        static let subheadline = Font.subheadline
        static let caption = Font.caption
        static let button = Font.body.weight(.semibold)
    }
    
    // Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    // Corner Radius (slightly larger for a more modern, soft look)
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
    }
    
    // Shadows (softer for a cleaner, less heavy look)
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        static let small = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 6,
            x: 0,
            y: 2
        )
        
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 10,
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
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.CornerRadius.medium, style: .continuous))
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
    
    /// Continuous corner radius (iOS-style rounded corners). Use for cards, buttons, and grouped content.
    func continuousCornerRadius(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
