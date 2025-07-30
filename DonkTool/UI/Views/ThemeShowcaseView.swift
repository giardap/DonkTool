//
//  ThemeShowcaseView.swift
//  DonkTool
//
//  Theme showcase for demonstrating dark mode support
//

import SwiftUI

struct ThemeShowcaseView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedColor = Color.primaryAccent
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Theme Showcase")
                        .font(Typography.largeTitle)
                        .foregroundColor(.primaryText)
                    
                    Text("Demonstrating DonkTool's comprehensive dark mode support")
                        .font(Typography.headline)
                        .foregroundColor(.secondaryText)
                    
                    HStack {
                        ForEach(ThemeManager.Theme.allCases, id: \.self) { theme in
                            ThemeButton(
                                theme: theme,
                                isSelected: themeManager.currentTheme == theme
                            ) {
                                withAnimation(.smoothSpring) {
                                    themeManager.currentTheme = theme
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Color Palette
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Color Palette", icon: "paintpalette")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ColorCard(name: "Primary", color: .primaryAccent)
                        ColorCard(name: "Secondary", color: .secondaryAccent)
                        ColorCard(name: "Tertiary", color: .tertiaryAccent)
                        ColorCard(name: "Success", color: .successGreen)
                        ColorCard(name: "Warning", color: .warningOrange)
                        ColorCard(name: "Danger", color: .dangerRed)
                    }
                }
                
                // Components
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Components", icon: "square.stack.3d.up")
                    
                    ModernCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Modern Card Component")
                                .font(Typography.headline)
                            Text("This card adapts to both light and dark themes seamlessly")
                                .font(Typography.body)
                                .foregroundColor(.secondaryText)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        GradientButton("Primary Action", icon: "play.fill") {
                            isLoading.toggle()
                        }
                        
                        Button("Secondary Action") {
                            // Action
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Status Badges
                    HStack(spacing: 12) {
                        StatusBadge(status: .active, text: "Active")
                        StatusBadge(status: .warning, text: "Warning")
                        StatusBadge(status: .error, text: "Error")
                        StatusBadge(status: .success, text: "Success")
                    }
                }
                
                // Typography
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Typography", icon: "textformat")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Large Title").font(Typography.largeTitle)
                        Text("Title 1").font(Typography.title1)
                        Text("Title 2").font(Typography.title2)
                        Text("Headline").font(Typography.headline)
                        Text("Body").font(Typography.body)
                        Text("Caption").font(Typography.caption1)
                        Text("print(\"Hello, Dark Mode!\")").font(Typography.code)
                    }
                    .padding()
                    .background(Color.appElevatedSurface)
                    .cornerRadius(12)
                }
                
                // Loading States
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Loading States", icon: "hourglass")
                    
                    HStack(spacing: 20) {
                        LoadingDots(size: 12, color: .primaryAccent)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        
                        if isLoading {
                            Text("Loading...")
                                .font(Typography.caption1)
                                .foregroundColor(.secondaryText)
                                .pulse()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(8)
                }
                
                // Code Surface
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader("Code Surface", icon: "chevron.left.forwardslash.chevron.right")
                    
                    VStack(alignment: .leading) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text("""
                            func performSecurityScan() async {
                                let scanner = NetworkScanner()
                                let results = await scanner.scan(target: "192.168.1.0/24")
                                print("Found \\(results.count) hosts")
                            }
                            """)
                            .font(Typography.code)
                            .foregroundColor(.codeText)
                            .padding()
                        }
                    }
                    .background(Color.codeSurface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.borderPrimary, lineWidth: 1)
                    )
                }
            }
            .padding(24)
        }
        .background(Color.appPrimaryBackground)
        .fadeIn()
    }
}

struct ThemeButton: View {
    let theme: ThemeManager.Theme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconForTheme)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primaryText)
                
                Text(theme.rawValue)
                    .font(Typography.caption1)
                    .foregroundColor(isSelected ? .white : .primaryText)
            }
            .frame(width: 100, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primaryAccent : Color.appCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.borderPrimary, lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: isSelected ? Color.primaryAccent.opacity(0.3) : Color.clear, radius: 8)
        }
        .buttonStyle(.plain)
        .hoverEffect()
    }
    
    var iconForTheme: String {
        switch theme {
        case .dark: return "moon.fill"
        }
    }
}

struct ColorCard: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    Text(name)
                        .font(Typography.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                )
            
            Text(name)
                .font(Typography.caption2)
                .foregroundColor(.secondaryText)
        }
        .scaleIn()
    }
}

#Preview {
    ThemeShowcaseView()
        .environmentObject(ThemeManager.shared)
        .frame(width: 900, height: 800)
}