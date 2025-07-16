//
//  DonkToolApp.swift
//  DonkTool
//
//  Created by DonkTool Development Team
//

import SwiftUI

@main
struct DonkToolApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    showLegalDisclaimer()
                }
        }
        .windowResizability(.contentSize)
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
        #endif
    }
    
    private func showLegalDisclaimer() {
        // Show legal disclaimer on first launch
        if !UserDefaults.standard.bool(forKey: "legal_disclaimer_accepted") {
            // TODO: Implement legal disclaimer view
        }
    }
}
