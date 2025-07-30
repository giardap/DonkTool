import SwiftUI

// Test program to verify IVRE connection
@main
struct TestIVREApp: App {
    var body: some Scene {
        WindowGroup {
            TestIVREView()
        }
    }
}

struct TestIVREView: View {
    @State private var status = "Not connected"
    @State private var hosts: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("IVRE Connection Test")
                .font(.title)
            
            Text(status)
                .foregroundColor(.secondary)
            
            Button("Test Connection") {
                Task {
                    await testConnection()
                }
            }
            .buttonStyle(.borderedProminent)
            
            List(hosts, id: \.self) { host in
                Text(host)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    func testConnection() async {
        status = "Testing..."
        
        do {
            // Test status endpoint
            let statusURL = URL(string: "http://localhost:8080/api/status")!
            let (statusData, _) = try await URLSession.shared.data(from: statusURL)
            let statusJson = try JSONSerialization.jsonObject(with: statusData) as? [String: Any]
            
            if let hostCount = statusJson?["hostCount"] as? Int {
                status = "Connected! Found \(hostCount) hosts"
            }
            
            // Test search endpoint
            let searchURL = URL(string: "http://localhost:8080/cgi/scans")!
            var request = URLRequest(url: searchURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["query": "", "limit": 5])
            
            let (searchData, _) = try await URLSession.shared.data(for: request)
            let searchJson = try JSONSerialization.jsonObject(with: searchData) as? [String: Any]
            
            if let hostsArray = searchJson?["hosts"] as? [[String: Any]] {
                hosts = hostsArray.compactMap { host in
                    if let ip = host["ip"] as? String,
                       let hostname = host["hostname"] as? String {
                        return "\(ip) - \(hostname)"
                    }
                    return nil
                }
            }
            
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }
}