//
//  APIKeyField.swift
//  DonkTool
//
//  Secure API key input field with help text and website links
//

import SwiftUI

struct APIKeyField: View {
    let title: String
    let placeholder: String
    @Binding var value: String
    let helpText: String
    let website: String
    let isRequired: Bool
    
    @State private var isSecured = true
    @State private var showingHelp = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if !helpText.isEmpty {
                        Button(action: { showingHelp.toggle() }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !website.isEmpty {
                        Button(action: { 
                            if let url = URL(string: website) {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            HStack {
                Group {
                    if isSecured {
                        SecureField(placeholder, text: $value)
                    } else {
                        TextField(placeholder, text: $value)
                    }
                }
                .textFieldStyle(.roundedBorder)
                
                Button(action: { isSecured.toggle() }) {
                    Image(systemName: isSecured ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if showingHelp && !helpText.isEmpty {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        APIKeyField(
            title: "Shodan API Key",
            placeholder: "Enter Shodan API key",
            value: .constant(""),
            helpText: "Provides access to internet-connected device discovery",
            website: "https://www.shodan.io/",
            isRequired: true
        )
        
        APIKeyField(
            title: "Optional Service",
            placeholder: "Enter API key",
            value: .constant("test-key-123"),
            helpText: "",
            website: "",
            isRequired: false
        )
    }
    .padding()
}