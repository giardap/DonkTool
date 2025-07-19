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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
