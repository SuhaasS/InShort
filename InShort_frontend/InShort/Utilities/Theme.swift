import SwiftUI

// MARK: - Colors
struct AppColors {
    // Modern brand colors
    static let primary = Color(red: 0.2, green: 0.6, blue: 1.0) // Modern blue
    static let secondary = Color(red: 0.3, green: 0.8, blue: 0.5) // Modern green
    static let accent = Color(red: 1.0, green: 0.6, blue: 0.2) // Modern orange
    
    // Background system
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.systemGray6)
    static let cardBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    
    // Text colors
    static let text = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    
    // Semantic colors
    static let destructive = Color.red
    static let success = Color.green
    static let warning = Color.orange
    static let info = Color.blue
    
    // Enhanced party colors
    static let democratic = Color(red: 0.2, green: 0.4, blue: 0.9)
    static let republican = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let bipartisan = Color(red: 0.6, green: 0.4, blue: 0.9)
    
    // Enhanced party gradients with better colors
    static func partyGradient(score: Double) -> LinearGradient {
        if score > 0 {
            return LinearGradient(
                gradient: Gradient(colors: [democratic, Color(red: 0.4, green: 0.6, blue: 1.0)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if score < 0 {
            return LinearGradient(
                gradient: Gradient(colors: [republican, Color(red: 1.0, green: 0.4, blue: 0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [bipartisan, Color(red: 0.8, green: 0.6, blue: 1.0)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Subtle background color based on party score
    static func partyBackgroundColor(score: Double) -> Color {
        if score > 0 {
            return democratic.opacity(min(abs(score), 1.0) * 0.08)
        } else if score < 0 {
            return republican.opacity(min(abs(score), 1.0) * 0.08)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Typography
struct AppTypography {
    // Hierarchy for better readability
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.bold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.medium)
    static let headline = Font.headline.weight(.semibold)
    static let subheadline = Font.subheadline.weight(.medium)
    static let body = Font.body
    static let bodyEmphasized = Font.body.weight(.medium)
    static let callout = Font.callout
    static let caption = Font.caption
    static let caption2 = Font.caption2
    static let footnote = Font.footnote
}

// MARK: - Layout
struct AppLayout {
    // Spacing system
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let spacing: CGFloat = 16
    static let large: CGFloat = 20
    static let xLarge: CGFloat = 24
    static let xxLarge: CGFloat = 32
    
    // Padding system
    static let padding: CGFloat = 16
    static let cardPadding: CGFloat = 20
    static let screenPadding: CGFloat = 20
    
    // Border radius system
    static let smallRadius: CGFloat = 8
    static let cornerRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
    static let xlRadius: CGFloat = 20
    
    // Shadow system
    static let subtleShadow = Shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    static let cardShadow = Shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    static let prominentShadow = Shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions
extension View {
    // Accessibility helper
    func accessibilityElement(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
    
    // Shadow helpers
    func cardShadow() -> some View {
        self.shadow(
            color: AppLayout.cardShadow.color,
            radius: AppLayout.cardShadow.radius,
            x: AppLayout.cardShadow.x,
            y: AppLayout.cardShadow.y
        )
    }
    
    func subtleShadow() -> some View {
        self.shadow(
            color: AppLayout.subtleShadow.color,
            radius: AppLayout.subtleShadow.radius,
            x: AppLayout.subtleShadow.x,
            y: AppLayout.subtleShadow.y
        )
    }
    
    func prominentShadow() -> some View {
        self.shadow(
            color: AppLayout.prominentShadow.color,
            radius: AppLayout.prominentShadow.radius,
            x: AppLayout.prominentShadow.x,
            y: AppLayout.prominentShadow.y
        )
    }
    
    // Modern card styling
    func modernCard(padding: CGFloat = AppLayout.cardPadding) -> some View {
        self
            .padding(padding)
            .background(AppColors.cardBackground)
            .cornerRadius(AppLayout.largeRadius)
            .cardShadow()
    }
    
    // Glassmorphism effect
    func glassCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppLayout.largeRadius)
                    .fill(AppColors.cardBackground.opacity(0.8))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppLayout.largeRadius))
            )
            .cardShadow()
    }
}

// MARK: - Common UI Components
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let size: ButtonSize
    
    enum ButtonSize {
        case small, medium, large
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            }
        }
        
        var font: Font {
            switch self {
            case .small: return AppTypography.caption
            case .medium: return AppTypography.callout
            case .large: return AppTypography.headline
            }
        }
    }
    
    init(title: String, size: ButtonSize = .medium, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppLayout.small) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(size.padding)
            .background(
                LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundColor(.white)
            .cornerRadius(AppLayout.cornerRadius)
            .shadow(color: AppColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let size: PrimaryButton.ButtonSize
    
    init(title: String, size: PrimaryButton.ButtonSize = .medium, action: @escaping () -> Void) {
        self.title = title
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(size.font)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(size.padding)
                .background(AppColors.cardBackground)
                .foregroundColor(AppColors.primary)
                .cornerRadius(AppLayout.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    let style: IconButtonStyle
    
    enum IconButtonStyle {
        case primary, secondary, ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AppColors.primary
            case .secondary: return AppColors.cardBackground
            case .ghost: return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return AppColors.primary
            case .ghost: return AppColors.text
            }
        }
    }
    
    init(icon: String, style: IconButtonStyle = .secondary, action: @escaping () -> Void) {
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(style.foregroundColor)
                .frame(width: 36, height: 36)
                .background(style.backgroundColor)
                .cornerRadius(AppLayout.smallRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.smallRadius)
                        .stroke(AppColors.primary.opacity(style == .secondary ? 0.2 : 0), lineWidth: 1)
                )
        }
    }
}