//
//  BluetoothToolsManager.swift
//  DonkTool
//
//  Bluetooth security tools management
//

import Foundation

class BluetoothToolsManager {
    
    // MARK: - Tool Detection
    
    func isToolInstalled(_ toolName: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [toolName]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    // MARK: - SDP Tool Integration
    
    func executeSDPTool(arguments: [String]) async -> String {
        return await executeSystemTool("sdptool", arguments: arguments)
    }
    
    // MARK: - HCI Tool Integration
    
    func executeHCITool(arguments: [String]) async -> String {
        return await executeSystemTool("hcitool", arguments: arguments)
    }
    
    // MARK: - BTScanner Integration
    
    func executeBTScanner(arguments: [String]) async -> String {
        return await executeSystemTool("btscanner", arguments: arguments)
    }
    
    // MARK: - macOS System Profiler Integration
    
    func executeSystemProfiler(arguments: [String] = []) async -> String {
        return await executeSystemTool("system_profiler", arguments: ["SPBluetoothDataType"] + arguments)
    }
    
    func executeSystemProfilerJSON() async -> String {
        return await executeSystemTool("system_profiler", arguments: ["SPBluetoothDataType", "-json"])
    }
    
    // MARK: - macOS BLE Scanner Integration
    
    func executeBLEScanner(arguments: [String] = []) async -> String {
        let bleScannerPath = "\(NSHomeDirectory())/bluetooth_security_tools/ble_scanner.py"
        
        // Check if BLE scanner exists
        guard FileManager.default.fileExists(atPath: bleScannerPath) else {
            return "BLE Scanner not found. Creating default scanner..."
        }
        
        return await executePythonScript("""
        #!/usr/bin/env python3
        import asyncio
        import platform
        from bleak import BleakScanner
        
        async def scan_devices():
            print("Scanning for BLE devices on macOS...")
            devices = await BleakScanner.discover(timeout=10.0)
            
            for device in devices:
                print(f"Device: {device.name or 'Unknown'}")
                print(f"  Address: {device.address}")
                print(f"  RSSI: {device.rssi}")
                if hasattr(device, 'metadata') and device.metadata:
                    print(f"  Metadata: {device.metadata}")
                print()
        
        if __name__ == "__main__":
            if platform.system() == "Darwin":
                asyncio.run(scan_devices())
            else:
                print("This script is designed for macOS")
        """)
    }
    
    // MARK: - Scapy Bluetooth Integration
    
    func executeScapyBluetoothScan(targetMAC: String? = nil) async -> String {
        let scapyScript = """
        #!/usr/bin/env python3
        '''
        Professional Bluetooth Security Scanning with Scapy
        '''
        
        try:
            from scapy.all import *
            from scapy.layers.bluetooth import *
            import sys
            import time
            
            def bluetooth_scan(target_mac=None):
                print("[+] Starting professional Bluetooth scan with Scapy...")
                
                # Basic HCI device scan
                try:
                    print("[+] Scanning for Bluetooth devices...")
                    
                    # If target MAC provided, focus scan
                    if target_mac:
                        print(f"[+] Focused scan on target: {target_mac}")
                        
                        # L2CAP ping test
                        try:
                            ping_pkt = L2CAP_Hdr()/L2CAP_EchoReq()
                            result = sr1(ping_pkt, timeout=5, verbose=0)
                            if result:
                                print(f"[+] L2CAP ping successful to {target_mac}")
                            else:
                                print(f"[-] L2CAP ping failed to {target_mac}")
                        except Exception as e:
                            print(f"[-] L2CAP test error: {e}")
                        
                        # SDP service discovery
                        try:
                            sdp_pkt = L2CAP_Hdr()/SDP_ServiceSearchRequest()
                            result = sr1(sdp_pkt, timeout=10, verbose=0)
                            if result:
                                print(f"[+] SDP services discovered on {target_mac}")
                                print(f"    Services: {result.summary()}")
                            else:
                                print(f"[-] No SDP response from {target_mac}")
                        except Exception as e:
                            print(f"[-] SDP discovery error: {e}")
                    
                    else:
                        print("[+] General Bluetooth environment scan...")
                        # General Bluetooth traffic monitoring
                        try:
                            packets = sniff(count=10, timeout=15, filter="bluetooth")
                            print(f"[+] Captured {len(packets)} Bluetooth packets")
                            for pkt in packets:
                                print(f"    {pkt.summary()}")
                        except Exception as e:
                            print(f"[-] Traffic monitoring error: {e}")
                    
                    print("[+] Scapy Bluetooth scan completed")
                    return True
                    
                except Exception as e:
                    print(f"[-] Bluetooth scan error: {e}")
                    return False
            
            if __name__ == "__main__":
                target = "\(targetMAC ?? "")" if "\(targetMAC ?? "")" else None
                success = bluetooth_scan(target)
                print("SCAN_SUCCESS" if success else "SCAN_FAILED")
                
        except ImportError as e:
            print(f"[-] Scapy Bluetooth modules not available: {e}")
            print("[-] Install with: pip3 install scapy[bluetooth]")
            print("SCAN_FAILED")
        except Exception as e:
            print(f"[-] Unexpected error: {e}")
            print("SCAN_FAILED")
        """
        
        return await executePythonScript(scapyScript)
    }
    
    private func executePythonScript(_ script: String) async -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let scriptFile = tempDir.appendingPathComponent("scapy_bt_\(UUID().uuidString).py")
        
        do {
            try script.write(to: scriptFile, atomically: true, encoding: .utf8)
            
            let process = Process()
            let pipe = Pipe()
            
            process.standardOutput = pipe
            process.standardError = pipe
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = [scriptFile.path]
            
            // Set Python environment
            var environment = ProcessInfo.processInfo.environment
            environment["PYTHONPATH"] = "/usr/local/lib/python3.*/site-packages:/opt/homebrew/lib/python3.*/site-packages"
            environment["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
            process.environment = environment
            
            try process.run()
            
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 45_000_000_000) // 45 seconds
                if process.isRunning {
                    process.terminate()
                }
            }
            
            process.waitUntilExit()
            timeoutTask.cancel()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "No output"
            
            try? FileManager.default.removeItem(at: scriptFile)
            return output
            
        } catch {
            return "Error executing Scapy script: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Generic Tool Execution
    
    private func executeSystemTool(_ toolName: String, arguments: [String]) async -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Try common installation paths
        let possiblePaths = [
            "/usr/bin/\(toolName)",
            "/usr/local/bin/\(toolName)",
            "/opt/homebrew/bin/\(toolName)",
            "/usr/sbin/\(toolName)"
        ]
        
        var toolPath: String?
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                toolPath = path
                break
            }
        }
        
        guard let executablePath = toolPath else {
            return "Error: \(toolName) not found in system PATH"
        }
        
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        
        // Set environment
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = environment
        
        do {
            try process.run()
            
            // Set timeout for tool execution
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                if process.isRunning {
                    process.terminate()
                }
            }
            
            process.waitUntilExit()
            timeoutTask.cancel()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "No output"
            
            return output
            
        } catch {
            return "Error executing \(toolName): \(error.localizedDescription)"
        }
    }
    
    // MARK: - Tool Availability Check
    
    func getAvailableTools() -> [String: Bool] {
        let macOSTools = [
            "system_profiler": "macOS Bluetooth system information",
            "defaults": "macOS Bluetooth preferences",
            "python3": "Python for BLE scanning", 
            "ble_scanner": "Custom BLE scanner",
            "ble_security_test": "BLE security testing tool"
        ]
        
        var toolStatus: [String: Bool] = [:]
        
        // Check macOS system tools
        toolStatus["system_profiler"] = isToolInstalled("system_profiler")
        toolStatus["defaults"] = isToolInstalled("defaults")
        toolStatus["python3"] = isToolInstalled("python3")
        
        // Check custom tools
        let bleScanner = "\(NSHomeDirectory())/bluetooth_security_tools/ble_scanner.py"
        let bleSecurityTest = "\(NSHomeDirectory())/bluetooth_security_tools/ble_security_test.py"
        
        toolStatus["ble_scanner"] = FileManager.default.fileExists(atPath: bleScanner)
        toolStatus["ble_security_test"] = FileManager.default.fileExists(atPath: bleSecurityTest)
        
        return toolStatus
    }
    
    // MARK: - Tool Installation Verification
    
    func verifyToolInstallation() -> String {
        var report: [String] = []
        report.append("macOS Bluetooth Security Tools Status Report")
        report.append("=" * 50)
        
        let toolStatus = getAvailableTools()
        
        for (tool, isAvailable) in toolStatus.sorted(by: { $0.key < $1.key }) {
            let status = isAvailable ? "✅ Available" : "❌ Not Found"
            report.append("\(tool): \(status)")
        }
        
        report.append("")
        report.append("Python Libraries:")
        
        // Check macOS-compatible Python libraries
        let pythonLibs = ["bleak", "scapy", "CoreBluetooth", "IOBluetooth"]
        for lib in pythonLibs {
            let available = checkPythonLibrary(lib)
            let status = available ? "✅ Available" : "❌ Not Found"
            report.append("\(lib): \(status)")
        }
        
        report.append("")
        report.append("System Information:")
        
        // Add system Bluetooth status
        let bluetoothStatus = getBluetoothSystemStatus()
        report.append(bluetoothStatus)
        
        return report.joined(separator: "\n")
    }
    
    private func getBluetoothSystemStatus() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        task.arguments = ["SPBluetoothDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if output.contains("State: On") {
                    return "Bluetooth: ✅ Enabled"
                } else if output.contains("State: Off") {
                    return "Bluetooth: ❌ Disabled"
                } else {
                    return "Bluetooth: ⚠️ Unknown state"
                }
            }
        } catch {
            return "Bluetooth: ❌ Error checking status"
        }
        
        return "Bluetooth: ⚠️ Could not determine status"
    }
    
    private func checkPythonLibrary(_ library: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-c", "import \(library)"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

// MARK: - String Extension for Repeat

extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}