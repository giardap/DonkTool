//
//  DesignSystem.swift
//  DonkTool
//
//  Unified design system for modern UI
//

import SwiftUI

// Re-export AnimationExtensions for convenience
public typealias AnimationExtensions = ()

// MARK: - Typography System
struct Typography {
    // Headers
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Body
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let caption1 = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)
    
    // Code
    static let code = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let codeSmall = Font.system(size: 11, weight: .regular, design: .monospaced)
}

// MARK: - Spacing System
struct Spacing {
    static let xxSmall: CGFloat = 4
    static let xSmall: CGFloat = 8
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 20
    static let xLarge: CGFloat = 24
    static let xxLarge: CGFloat = 32
    static let xxxLarge: CGFloat = 40
}

// MARK: - Theme Management
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme = .dark {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "AppTheme")
        }
    }
    
    enum Theme: String, CaseIterable {
        case dark = "Dark"
        
        var colorScheme: ColorScheme? {
            return .dark
        }
    }
    
    private init() {
        // Always use dark theme
        self.currentTheme = .dark
    }
}

// MARK: - Color Palette
extension Color {
    // Primary Colors - Dark theme only
    static let primaryAccent = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let secondaryAccent = Color(red: 0.7, green: 0.3, blue: 0.95)
    static let tertiaryAccent = Color(red: 0.2, green: 0.85, blue: 0.5)
    
    // Semantic Colors - Dark theme only
    static let successGreen = Color(red: 0.3, green: 0.9, blue: 0.4)
    static let warningOrange = Color(red: 1.0, green: 0.7, blue: 0.2)
    static let dangerRed = Color(red: 1.0, green: 0.4, blue: 0.4)
    static let infoBlue = Color(red: 0.2, green: 0.7, blue: 1.0)
    
    // Background Colors - Dark theme optimized
    static let appPrimaryBackground = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let appSecondaryBackground = Color(red: 0.15, green: 0.15, blue: 0.16)
    static let appTertiaryBackground = Color(red: 0.19, green: 0.19, blue: 0.20)
    static let appCardBackground = Color(red: 0.13, green: 0.13, blue: 0.14).opacity(0.8)
    
    // Surface Colors
    static let appSurfaceBackground = Color(red: 0.17, green: 0.17, blue: 0.18)
    static let appElevatedSurface = Color(red: 0.22, green: 0.22, blue: 0.23)
    
    // Text Colors - Dark theme optimized
    static let primaryText = Color.white.opacity(0.9)
    static let secondaryText = Color.white.opacity(0.7)
    static let tertiaryText = Color.white.opacity(0.5)
    
    // Special Purpose - Dark theme only
    static let codeSurface = Color(red: 0.11, green: 0.11, blue: 0.118)
    static let codeText = Color(red: 0.596, green: 0.765, blue: 0.471)
    
    // Border Colors - Dark theme only
    static let borderPrimary = Color.gray.opacity(0.3)
    static let borderSecondary = Color.gray.opacity(0.2)
    
    // Shadow Colors - Dark theme only
    static let shadowColor = Color.black.opacity(0.5)
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primaryAccent, secondaryAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkGradient = LinearGradient(
        colors: [Color.black.opacity(0.8), Color.black.opacity(0.4)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [appPrimaryBackground, appSecondaryBackground],
        startPoint: .top,
        endPoint: .bottom
    )
}


// MARK: - Shadows
struct Shadows {
    static func small(color: Color = .black) -> some View {
        EmptyView().shadow(color: color.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    static func medium(color: Color = .black) -> some View {
        EmptyView().shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    static func large(color: Color = .black) -> some View {
        EmptyView().shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    static func xlarge(color: Color = .black) -> some View {
        EmptyView().shadow(color: color.opacity(0.25), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Animation
struct Animations {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

// MARK: - Reusable Components

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16 // Spacing.medium
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ModernCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(Spacing.medium)
            .background(Color.appCardBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
            .shadow(color: Color.shadowColor, radius: 4, x: 0, y: 2)
    }
}

struct GradientButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var gradient: LinearGradient = Color.primaryGradient
    
    init(_ title: String, icon: String? = nil, gradient: LinearGradient = Color.primaryGradient, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(gradient)
            .cornerRadius(10)
            .shadow(color: Color.primaryAccent.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct StatusBadge: View {
    enum Status {
        case active, inactive, warning, error, success
        
        var color: Color {
            switch self {
            case .active: return .successGreen
            case .inactive: return .gray
            case .warning: return .warningOrange
            case .error: return .dangerRed
            case .success: return .successGreen
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "circle.fill"
            case .inactive: return "circle"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }
    
    let status: Status
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.system(size: 10))
                .foregroundColor(status.color)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct IconLabel: View {
    let icon: String
    let text: String
    var color: Color = .primary
    var font: Font = .subheadline
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(font.weight(.medium))
                .foregroundColor(color)
            
            Text(text)
                .font(font)
                .foregroundColor(.primary)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    
    init(_ title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.primaryGradient)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.title3)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - View Extensions

// MARK: - Animation Constants from AnimationExtensions
struct AnimationConstants {
    static let quickDuration: Double = 0.2
    static let standardDuration: Double = 0.3
    static let slowDuration: Double = 0.5
    static let verySlowDuration: Double = 0.8
    
    static let springResponse: Double = 0.3
    static let springDamping: Double = 0.7
    static let bounceResponse: Double = 0.4
    static let bounceDamping: Double = 0.5
}

// MARK: - Custom Animations
extension Animation {
    static var smoothSpring: Animation {
        .spring(response: AnimationConstants.springResponse, dampingFraction: AnimationConstants.springDamping)
    }
    
    static var bounceSpring: Animation {
        .spring(response: AnimationConstants.bounceResponse, dampingFraction: AnimationConstants.bounceDamping)
    }
    
    static var quickEaseInOut: Animation {
        .easeInOut(duration: AnimationConstants.quickDuration)
    }
    
    static var standardEaseInOut: Animation {
        .easeInOut(duration: AnimationConstants.standardDuration)
    }
    
    static var slowEaseInOut: Animation {
        .easeInOut(duration: AnimationConstants.slowDuration)
    }
    
    static var customInteractive: Animation {
        .interactiveSpring(response: 0.15, dampingFraction: 0.86, blendDuration: 0.25)
    }
}

// MARK: - Transition Extensions
extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
    
    static var bounceIn: AnyTransition {
        .scale(scale: 0.3)
            .combined(with: .opacity)
            .animation(.bounceSpring)
    }
    
    static func delayedFade(delay: Double) -> AnyTransition {
        .opacity.animation(.easeInOut.delay(delay))
    }
}

// MARK: - View Modifiers
struct FadeInModifier: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct SlideInModifier: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    let edge: Edge
    
    func body(content: Content) -> some View {
        content
            .offset(x: offsetX, y: offsetY)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.smoothSpring.delay(delay)) {
                    isVisible = true
                }
            }
    }
    
    private var offsetX: CGFloat {
        guard !isVisible else { return 0 }
        switch edge {
        case .leading: return -50
        case .trailing: return 50
        default: return 0
        }
    }
    
    private var offsetY: CGFloat {
        guard !isVisible else { return 0 }
        switch edge {
        case .top: return -50
        case .bottom: return 50
        default: return 0
        }
    }
}

struct ScaleInModifier: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : scale)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.bounceSpring.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct HoverEffectModifier: ViewModifier {
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .onHover { hovering in
                withAnimation(.smoothSpring) {
                    isHovering = hovering
                }
            }
    }
}

struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.quickEaseInOut) {
                    isPressed = pressing
                }
            }, perform: { })
    }
}

// MARK: - Loading Animation Views
struct LoadingDots: View {
    @State private var animating = false
    let dotSize: CGFloat
    let dotColor: Color
    
    init(size: CGFloat = 8, color: Color = .primary) {
        self.dotSize = size
        self.dotColor = color
    }
    
    var body: some View {
        HStack(spacing: dotSize / 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(dotColor)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Animated Button Styles  
struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.quickEaseInOut, value: configuration.isPressed)
    }
}

// MARK: - Sheet Management
struct ReliableSheetModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    let item: Binding<Item?>
    let onDismiss: (() -> Void)?
    let content: (Item) -> SheetContent
    
    init(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> SheetContent) {
        self.item = item
        self.onDismiss = onDismiss
        self.content = content
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(item: item, onDismiss: onDismiss) { item in
                self.content(item)
                    .id(item.id) // Force refresh
                    .onAppear {
                        // Ensure sheet loads properly
                    }
            }
    }
}

struct ReliableSheetBoolModifier<SheetContent: View>: ViewModifier {
    let isPresented: Binding<Bool>
    let onDismiss: (() -> Void)?
    let content: () -> SheetContent
    @State private var isContentReady = false
    
    init(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> SheetContent) {
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        self.content = content
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: isPresented, onDismiss: {
                isContentReady = false
                onDismiss?()
            }) {
                if isContentReady {
                    self.content()
                } else {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            // Small delay to ensure proper initialization
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isContentReady = true
                            }
                        }
                }
            }
            .onChange(of: isPresented.wrappedValue) { _, newValue in
                if newValue {
                    isContentReady = false
                }
            }
    }
}

extension View {
    func reliableSheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        modifier(ReliableSheetModifier(item: item, onDismiss: onDismiss, content: content))
    }
    
    func reliableSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(ReliableSheetBoolModifier(isPresented: isPresented, onDismiss: onDismiss, content: content))
    }
    
    // Helper function for reliable button-triggered sheet presentations
    func onTapGesture<T>(
        presentSheet isPresented: Binding<Bool>,
        withValue value: T,
        assignTo binding: Binding<T?>
    ) -> some View {
        self.onTapGesture {
            // Reset state first
            binding.wrappedValue = nil
            isPresented.wrappedValue = false
            
            // Small delay to ensure state change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                binding.wrappedValue = value
                isPresented.wrappedValue = true
            }
        }
    }
    
    func glow(color: Color = .primaryAccent, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.3), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius * 2)
    }
    
    func shimmer() -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width)
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: true
                    )
                }
                .mask(self)
            )
    }
    
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInModifier(delay: delay))
    }
    
    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        modifier(SlideInModifier(delay: delay, edge: edge))
    }
    
    func scaleIn(from scale: CGFloat = 0.8, delay: Double = 0) -> some View {
        modifier(ScaleInModifier(delay: delay, scale: scale))
    }
    
    func pulse(duration: Double = 1.5) -> some View {
        modifier(PulseModifier(duration: duration))
    }
    
    func hoverEffect() -> some View {
        modifier(HoverEffectModifier())
    }
    
    func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }
}