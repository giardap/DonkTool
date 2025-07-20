//
//  DesignSystem.swift
//  DonkTool
//
//  Unified design system for consistent UI across the application
//

import SwiftUI
import Foundation

// MARK: - Color System

extension Color {
    // Modern dark theme backgrounds - inspired by PadraigAIO aesthetic
    static let primaryBackground = Color(red: 0.12, green: 0.12, blue: 0.15)     // Main app background
    static let secondaryBackground = Color(red: 0.18, green: 0.18, blue: 0.22)  // Card/content background
    static let surfaceBackground = Color(red: 0.15, green: 0.15, blue: 0.18)    // Sidebar/surface background
    
    // Card backgrounds with transparency
    static let cardBackground = Color(red: 0.18, green: 0.18, blue: 0.22).opacity(0.95)
    static let elevatedBackground = Color(red: 0.22, green: 0.22, blue: 0.28).opacity(0.9)
    
    // Accent backgrounds with transparency
    static let accentBackground = Color.blue.opacity(0.1)
    static let successBackground = Color.green.opacity(0.1)
    static let warningBackground = Color.orange.opacity(0.1)
    static let dangerBackground = Color.red.opacity(0.1)
    
    // Border colors for dark theme
    static let borderPrimary = Color.white.opacity(0.1)
    static let borderSecondary = Color.white.opacity(0.05)
    static let borderAccent = Color.blue.opacity(0.3)
    
    // Status colors
    static let statusSuccess = Color.green
    static let statusWarning = Color.orange
    static let statusDanger = Color.red
    static let statusInfo = Color.blue
    
    // Text colors for dark theme
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.8, green: 0.8, blue: 0.8)
    static let tertiaryText = Color(red: 0.6, green: 0.6, blue: 0.6)
}

// MARK: - Spacing System

extension CGFloat {
    // Standard spacing scale (8pt grid)
    static let spacing_xxs: CGFloat = 2
    static let spacing_xs: CGFloat = 4
    static let spacing_sm: CGFloat = 8
    static let spacing_md: CGFloat = 16
    static let spacing_lg: CGFloat = 24
    static let spacing_xl: CGFloat = 32
    static let spacing_xxl: CGFloat = 48
    
    // Common radius values
    static let radius_sm: CGFloat = 6
    static let radius_md: CGFloat = 8
    static let radius_lg: CGFloat = 12
    static let radius_xl: CGFloat = 16
}

// MARK: - Typography System

extension Font {
    // Headers
    static let headerPrimary = Font.title2.weight(.bold)
    static let headerSecondary = Font.headline.weight(.semibold)
    static let headerTertiary = Font.subheadline.weight(.medium)
    
    // Body text
    static let bodyPrimary = Font.body
    static let bodySecondary = Font.body.weight(.medium)
    static let bodySmall = Font.callout
    
    // Supporting text
    static let captionPrimary = Font.caption
    static let captionSecondary = Font.caption2
    
    // Monospace (for code/terminal)
    static let codePrimary = Font.system(.body, design: .monospaced)
    static let codeSmall = Font.system(.caption, design: .monospaced)
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    let elevation: CardElevation
    
    enum CardElevation {
        case low, medium, high
        
        var shadow: (radius: CGFloat, y: CGFloat) {
            switch self {
            case .low: return (2, 1)
            case .medium: return (4, 2)
            case .high: return (8, 4)
            }
        }
        
        var background: Color {
            switch self {
            case .low: return .cardBackground
            case .medium: return .elevatedBackground
            case .high: return .elevatedBackground
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.spacing_md)
            .background(elevation.background, in: RoundedRectangle(cornerRadius: .radius_lg))
            .overlay(
                RoundedRectangle(cornerRadius: .radius_lg)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: elevation.shadow.radius, x: 0, y: elevation.shadow.y)
    }
}

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headerSecondary)
            .foregroundColor(.primary)
            .padding(.horizontal, .spacing_md)
            .padding(.vertical, .spacing_sm)
    }
}

struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.bordered)
            .controlSize(.regular)
    }
}

struct DangerButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.regular)
    }
}

struct StatusIndicator: ViewModifier {
    let status: StatusType
    
    enum StatusType {
        case success, warning, danger, info, neutral
        
        var color: Color {
            switch self {
            case .success: return .statusSuccess
            case .warning: return .statusWarning
            case .danger: return .statusDanger
            case .info: return .statusInfo
            case .neutral: return .secondary
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .success: return .successBackground
            case .warning: return .warningBackground
            case .danger: return .dangerBackground
            case .info: return .accentBackground
            case .neutral: return .elevatedBackground
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, .spacing_sm)
            .padding(.vertical, .spacing_xs)
            .background(status.backgroundColor, in: Capsule())
            .foregroundColor(status.color)
            .font(.captionPrimary.weight(.medium))
    }
}

struct StandardContainer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.spacing_md)
            .background(Color.surfaceBackground)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(elevation: CardStyle.CardElevation = .medium) -> some View {
        modifier(CardStyle(elevation: elevation))
    }
    
    func sectionHeader() -> some View {
        modifier(SectionHeaderStyle())
    }
    
    func primaryButton() -> some View {
        modifier(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        modifier(SecondaryButtonStyle())
    }
    
    func dangerButton() -> some View {
        modifier(DangerButtonStyle())
    }
    
    func statusIndicator(_ status: StatusIndicator.StatusType) -> some View {
        modifier(StatusIndicator(status: status))
    }
    
    func standardContainer() -> some View {
        modifier(StandardContainer())
    }
    
}

// MARK: - Common Components

struct ProgressCard: View {
    let title: String
    let value: Double
    let subtitle: String?
    let color: Color
    
    init(title: String, value: Double, subtitle: String? = nil, color: Color = .blue) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing_sm) {
            Text(title)
                .font(.headerTertiary)
                .foregroundColor(.primary)
            
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 4)
            
            HStack {
                Text("\(Int(value * 100))%")
                    .font(.captionPrimary)
                    .foregroundColor(color)
                
                Spacer()
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.captionPrimary)
                        .foregroundColor(.secondary)
                }
            }
        }
        .cardStyle()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let trend: TrendDirection?
    let color: Color
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .secondary
            }
        }
    }
    
    init(title: String, value: String, trend: TrendDirection? = nil, color: Color = .primary) {
        self.title = title
        self.value = value
        self.trend = trend
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing_xs) {
            Text(title)
                .font(.captionPrimary)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.headerPrimary)
                    .foregroundColor(color)
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.captionPrimary)
                        .foregroundColor(trend.color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(icon: String, title: String, subtitle: String, action: (() -> Void)? = nil, actionTitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: .spacing_lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: .spacing_sm) {
                Text(title)
                    .font(.headerSecondary)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.bodyPrimary)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .primaryButton()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.spacing_xl)
    }
}

// MARK: - Layout Helpers

struct ResponsiveStack<Content: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if sizeClass == .regular {
            HStack { content }
        } else {
            VStack { content }
        }
    }
}