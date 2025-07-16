//
//  ContentView.swift
//  DonkTool
//
//  Main application interface
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            DetailView()
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List(AppState.MainTab.allCases, id: \.self, selection: $appState.currentTab) { tab in
            NavigationLink(value: tab) {
                Label(tab.title, systemImage: tab.systemImage)
            }
        }
        .navigationTitle("DonkTool")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // Quick scan action
                }) {
                    Image(systemName: "play.circle.fill")
                }
                .help("Quick Scan")
            }
        }
    }
}

struct DetailView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            switch appState.currentTab {
            case .dashboard:
                DashboardView()
            case .cveManager:
                CVEManagerView()
            case .networkScanner:
                NetworkScannerView()
            case .webTesting:
                WebTestingView()
            case .reporting:
                ReportingView()
            case .settings:
                SettingsView()
            }
        }
        .navigationTitle(appState.currentTab.title)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
