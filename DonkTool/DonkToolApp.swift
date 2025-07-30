//
//  DonkToolApp.swift
//  DonkTool
//
//  Created by DonkTool Development Team
//

import SwiftUI

@main
struct DonkToolApp: App {
    @State private var appState = AppState()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.dark) // Always use dark mode
                .environmentObject(themeManager)
        }
        .windowStyle(DefaultWindowStyle())
    }
}
