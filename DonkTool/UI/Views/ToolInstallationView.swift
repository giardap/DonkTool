import SwiftUI

struct ToolInstallationView: View {
    let missingTools: [ToolRequirement]
    
    private let installInstructions: [String: String] = [
        "nmap": "brew install nmap",
        "gobuster": "brew install gobuster",
        "dirb": "brew install dirb",
        "nikto": "brew install nikto",
        "burpsuite": "Download from https://portswigger.net/burp/communitydownload",
        "sqlmap": "brew install sqlmap",
        "hydra": "brew install hydra",
        "smbclient": "brew install samba",
        "rdesktop": "brew install rdesktop"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Missing Required Tools")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Install these tools to enable all attack vectors")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            ForEach(missingTools, id: \.name) { tool in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: getIconForTool(tool.name))
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tool.name)
                            .fontWeight(.medium)
                        
                        Text(tool.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let instruction = installInstructions[tool.name] {
                            Text(instruction)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                    
                    if tool.type == .optional {
                        Text("Optional")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 4)
            }
            
            if !missingTools.isEmpty {
                Divider()
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    
                    Text("Most tools can be installed using Homebrew. Run 'brew install <tool-name>' in Terminal.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func getIconForTool(_ toolName: String) -> String {
        switch toolName.lowercased() {
        case "nmap":
            return "network"
        case "burpsuite", "burp-suite":
            return "shield.lefthalf.fill"
        case "gobuster", "dirb":
            return "folder.fill.badge.questionmark"
        case "nikto":
            return "magnifyingglass"
        case "sqlmap":
            return "cylinder.split.1x2"
        case "hydra":
            return "key.fill"
        default:
            return "terminal"
        }
    }
}

#Preview {
    ToolInstallationView(missingTools: [
        ToolRequirement(name: "nmap", type: .tool, description: "Network discovery and security auditing"),
        ToolRequirement(name: "gobuster", type: .optional, description: "Directory/file/DNS busting tool")
    ])
    .padding()
}
