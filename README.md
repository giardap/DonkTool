# 🛡️ DonkTool

<div align="center">

**Advanced macOS Penetration Testing & Security Assessment Suite**

[![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/xcode-15.0%2B-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Security](https://img.shields.io/badge/security-professional%20grade-red.svg)](#)

*Professional-grade security testing with Bluetooth, Web, Network, and DoS capabilities*

</div>

---

## ⚠️ **CRITICAL LEGAL NOTICE**

**DonkTool is intended for AUTHORIZED penetration testing and defensive security assessment ONLY.**

🚨 **Unauthorized use is illegal and can result in criminal charges**
- Use only on systems you own or have explicit written permission to test
- Follow all applicable laws and regulations
- Read our [Ethical Use Policy](ETHICAL_USE_POLICY.md) before use

---

## 🎯 **Overview**

DonkTool is a native macOS penetration testing suite built with Swift and SwiftUI, providing comprehensive security assessment capabilities across multiple attack surfaces. It combines Bluetooth security testing, web application analysis, network reconnaissance, and DoS testing with a modern, professional interface designed for authorized security professionals.

### **Key Strengths**
- 🚀 **Native Performance**: Swift-based for optimal macOS integration and CoreBluetooth support
- 🎨 **Modern UI**: Professional dark-themed SwiftUI interface with real-time monitoring
- 🔧 **Real Tool Integration**: Uses actual penetration testing tools, not simulations
- 🛡️ **Ethical Safeguards**: Built-in authorization checks and ethical guidelines
- 📊 **Comprehensive Reporting**: Detailed vulnerability reports with CVE correlation
- 🔄 **Real-Time Monitoring**: Live attack progress and output streaming
- 📱 **Bluetooth Security**: Advanced Bluetooth LE and Classic security testing
- 🌐 **Multi-Protocol Support**: HTTP/HTTPS, Bluetooth, TCP/UDP, and more

---

## 🚀 **Features**

### **📱 Bluetooth Security Testing** (NEW!)
- **Native macOS CoreBluetooth Integration** for real-time device discovery
- **Bluetooth LE (BLE) Security Analysis** with vulnerability detection
- **Classic Bluetooth Assessment** using IOBluetooth framework
- **Advanced Attack Vectors**:
  - BIAS (Bluetooth Impersonation Attack)
  - KNOB (Key Negotiation of Bluetooth)
  - BlueFrag vulnerability testing
  - BLE pairing and authentication bypass
  - Service enumeration and characteristic analysis
- **Real-Time Device Monitoring** with RSSI tracking
- **Professional Attack Execution** with live exploit code generation
- **CVE Integration** with clickable exploit code viewing
- **Evidence Generation** with detailed security analysis reports

### **🌐 Web Application Security Testing**
- **SQL Injection Testing** with SQLMap integration and real-time output
- **Cross-Site Scripting (XSS)** vulnerability detection
- **Directory/File Enumeration** using Gobuster, Dirb, and FFuF
- **SSL/TLS Analysis** with SSLyze and comprehensive cipher testing
- **Comprehensive Vulnerability Scanning** via Nuclei (9000+ templates)
- **HTTP Service Analysis** with HTTPx and technology detection
- **Subdomain Discovery** using Subfinder with passive reconnaissance
- **Advanced Web Fuzzing** with parameter discovery and custom payloads

### **🔍 Network Security Assessment**
- **Advanced Port Scanning** with Nmap integration and service fingerprinting
- **Service Enumeration** with version detection and vulnerability correlation
- **Network Discovery** and host identification with attack vector mapping
- **Vulnerability Assessment** across network services with CVE correlation
- **Attack Execution Framework** with real exploit payload generation
- **Professional Reporting** with detailed findings and remediation guidance

### **💥 DoS/Stress Testing (Authorized Use Only)**
- **HTTP Load Testing** with WRK and Artillery
- **Application Layer Attacks**:
  - Slowloris attacks (slowhttptest, pyloris)
  - HTTP floods (HULK, GoldenEye, MHDDoS)
  - Slow POST attacks (Torshammer)
- **Network Layer Attacks**:
  - TCP SYN floods (hping3, Xerxes, T50)
  - UDP floods (Xerxes, MHDDoS)
  - Connection exhaustion attacks
- **Protocol-Specific Testing**:
  - SSL/TLS DoS (thc-ssl-dos)
  - ICMP floods (Hyenae)
- **Multi-Vector Attacks** (PentMENU, MHDDoS)
- **Real-Time Attack Monitoring** with verbose output
- **22 Attack Vectors** across 4 categories

### **🗄️ CVE Management & Intelligence**
- **Live CVE Database** integration with NVD API and automatic updates
- **Advanced Vulnerability Search** with filtering and correlation
- **CVE-to-Attack Mapping** for targeted exploit testing
- **Clickable Exploit Code Viewing** with professional attack analysis
- **SearchSploit Integration** for exploit discovery and validation
- **Real-Time CVE Monitoring** with severity-based alerting

### **📊 Advanced Reporting & Analytics**
- **Professional Evidence Generation** with detailed security analysis
- **Multi-Tab Attack Results** with exploit code and payload viewing
- **Executive Summary Reports** with risk scoring and business impact
- **Technical Deep-Dive Reports** with proof-of-concept demonstrations
- **Export Capabilities** (PDF, HTML, JSON, CSV) for compliance requirements
- **Attack Session Tracking** with comprehensive audit trails

### **🎮 Professional Attack Management**
- **Real-Time Attack Execution** with live output streaming and progress tracking
- **Multi-Protocol Attack Coordination** across Bluetooth, Web, and Network services
- **Attack Session Management** with concurrent execution support
- **Professional Evidence Collection** with timestamped findings
- **Automatic Attack Termination** with configurable duration limits
- **Comprehensive Error Handling** with detailed logging and recovery

---

## 🛠️ **Installation & Setup**

### **System Requirements**
- **macOS 14.0+** (Sonoma or later)
- **Xcode 15.0+** with Swift 5.9+
- **Command Line Tools** for Xcode
- **Homebrew** (recommended for tool installation)

### **Quick Start**
1. **Clone the Repository**
   ```bash
   git clone https://github.com/giardap/DonkTool.git
   cd DonkTool
   ```

2. **Master Installation (Recommended)**
   ```bash
   # Run the comprehensive master installation script
   ./master-install.sh
   
   # This will install:
   # - All core penetration testing tools
   # - Web application security tools
   # - Network assessment tools
   # - Bluetooth security tools
   # - DoS testing tools (with authorization prompts)
   ```

3. **Alternative: Individual Tool Installation**
   ```bash
   # Core penetration testing tools
   ./install-pentest-tools.sh
   
   # DoS testing tools (requires authorization confirmation)
   ./install_dos_tools.sh
   
   # Bluetooth security tools
   ./macos_bluetooth_tools.sh
   ```

4. **Build and Run**
   ```bash
   # Open in Xcode
   open DonkTool.xcodeproj
   
   # Or build from command line
   xcodebuild -project DonkTool.xcodeproj -scheme DonkTool build
   ```

5. **Launch Application**
   - Build and run in Xcode (⌘+R)
   - Review and accept the ethical use policy
   - Verify tool installation status in Settings
   - Begin authorized security testing

### **Tool Installation Status**
See [TOOLS_STATUS.md](TOOLS_STATUS.md) for complete installation details.

**Core Penetration Testing Tools (✅ Working):**
- nmap, nikto, sqlmap, gobuster, dirb, ffuf
- nuclei, httpx, subfinder, katana
- sslyze, dirsearch, feroxbuster
- hydra, john, hashcat, metasploit

**Web Application Security Tools (✅ Working):**
- burp-suite, zaproxy, wfuzz, xsstrike
- testssl.sh, sslscan, whatweb
- dirb, gobuster, ffuf, feroxbuster

**Bluetooth Security Tools (✅ Working):**
- Native macOS CoreBluetooth and IOBluetooth frameworks
- bluez-tools, ubertooth (via Homebrew)
- bettercap, hcitool, gatttool
- Custom Swift-based Bluetooth security framework

**DoS Testing Tools (✅ Working):**
- slowhttptest, goldeneye, hulk, t50, thc-ssl-dos
- mhddos, torshammer, pyloris, xerxes, pentmenu, hyenae
- wrk, artillery, siege (load testing)

---

## 📖 **Usage Guide**

### **🎯 Dashboard Overview**
The main dashboard provides:
- **Multi-Protocol Security Overview** with Bluetooth, Web, and Network statistics
- **Real-Time Attack Monitoring** across all attack surfaces
- **CVE Intelligence** with recent updates and clickable exploits
- **Quick Access** to all security testing modules
- **Evidence Manager** with professional reporting capabilities

### **📱 Bluetooth Security Testing** (NEW!)
1. **Device Discovery**
   - Automatic scanning for Bluetooth LE and Classic devices
   - Real-time RSSI monitoring and device tracking
   - Device classification and manufacturer identification

2. **Security Analysis**
   - Comprehensive vulnerability assessment
   - CVE correlation with Bluetooth-specific vulnerabilities
   - Service enumeration and characteristic analysis

3. **Attack Execution**
   - Professional attack vector selection
   - Real-time exploit code generation
   - Live attack execution with evidence collection

4. **CVE Integration**
   - Click on "View Exploit" for detailed attack code
   - Professional exploit analysis with warnings
   - Links to official CVE databases

### **🔍 Network Scanner**
1. **Configure Target**
   - Enter IP address or domain
   - Select port range or specific ports
   - Choose scan type (TCP/UDP/SYN)

2. **Execute Scan**
   - Real-time progress monitoring with corrected IP:PORT targeting
   - Service detection and enumeration
   - Vulnerability identification with attack vector mapping

3. **Attack Execution**
   - Click "Execute Attack" on discovered services
   - Professional attack framework with real exploit payloads
   - Multi-tab results viewing (Output, Exploit Code, Payload)

### **🌐 Web Application Testing**
1. **Target Configuration**
   - Enter web application URL
   - Configure authentication if needed
   - Select testing modules

2. **Vulnerability Testing**
   - SQL injection with SQLMap
   - XSS detection and exploitation
   - Directory enumeration
   - SSL/TLS analysis

3. **Review Findings**
   - Vulnerability details and severity
   - Proof-of-concept payloads
   - Remediation recommendations

### **💥 DoS/Stress Testing** (⚠️ Authorized Use Only)

#### **Configuration Steps:**
1. **Target Setup**
   ```
   Target: example.com
   Port: 80/443
   Protocol: HTTP/HTTPS
   ```

2. **Attack Parameters**
   ```
   Duration: 60 seconds
   Intensity: High (1000 threads, 10000 req/s)
   Attack Type: HTTP Stress Testing
   ```

3. **Authorization Requirements**
   - ✅ Explicit written permission confirmed
   - ✅ Ethical use agreement accepted
   - ✅ Target is authorized for testing

#### **Attack Categories:**

**Application Layer (L7):**
- HTTP Stress Testing (WRK, Artillery)
- Slowloris Attacks (slowhttptest, pyloris)
- HTTP Floods (HULK, GoldenEye)
- Slow POST Attacks (Torshammer)

**Network Layer (L3/L4):**
- TCP SYN Floods (hping3, Xerxes)
- UDP Floods (Xerxes, MHDDoS)
- Connection Exhaustion

**Protocol-Specific:**
- SSL/TLS DoS (thc-ssl-dos)
- ICMP Floods (Hyenae)

#### **Real-Time Monitoring**
```
🚀 STARTING ATTACK: wrk
🎯 Target: example.com:80
⏱️ Duration: 60 seconds
🔥 Attack Type: HTTP STRESS TEST
============================================================
📊 LIVE OUTPUT: Running 60s test @ http://example.com
⚡ ATTACK PROGRESS: 15.0s elapsed | 45.0s remaining | 25.0% complete
📊 LIVE OUTPUT: Thread Stats   Avg      Stdev     Max
⚡ ATTACK PROGRESS: 30.0s elapsed | 30.0s remaining | 50.0% complete
✅ ATTACK SUCCESSFUL: WRK completed in 60.2s
```

### **🗄️ CVE Management**
1. **Database Updates**
   - Automatic NVD API synchronization
   - Rate-limited requests (no API key required)
   - Local caching for performance

2. **Vulnerability Search**
   - Search by CVE ID, vendor, or product
   - Severity filtering (Critical/High/Medium/Low)
   - Date range selection

3. **Attack Integration**
   - CVE-to-exploit mapping
   - Automated testing suggestions
   - Vulnerability validation

---

## 🏗️ **Architecture**

### **Project Structure**
```
DonkTool/
├── DonkTool/                     # Main application source
│   ├── Core/                     # Core application logic
│   │   ├── AppState.swift        # Central state management
│   │   ├── AttackFramework.swift # Attack orchestration
│   │   └── DoSTestManager.swift  # DoS testing coordination
│   ├── Data/                     # Data models and persistence
│   │   ├── Models.swift          # Core data models
│   │   ├── CVEModels.swift       # CVE-specific models
│   │   └── ToolDetection.swift   # Tool installation detection
│   ├── Modules/                  # Feature modules
│   │   └── CVEManager/           # CVE database integration
│   │       └── CVEDatabase.swift # NVD API integration
│   ├── UI/Views/                 # SwiftUI user interface
│   │   ├── DashboardView.swift   # Main dashboard
│   │   ├── NetworkScannerView.swift
│   │   ├── ModernWebTestingView.swift
│   │   ├── DoSTestingView.swift  # DoS testing interface
│   │   ├── CVEManagerView.swift  # CVE management
│   │   └── ReportingView.swift   # Report generation
│   ├── ContentView.swift         # Main app container
│   └── DonkToolApp.swift         # App entry point
├── DonkToolTests/                # Unit tests
├── DonkToolUITests/              # UI automation tests
└── Scripts/                      # Installation scripts
    ├── install-pentest-tools-fixed.sh
    └── install_dos_tools_fixed.sh
```

### **Core Components**

#### **AppState (@Observable)**
Central application state management using Swift's new @Observable macro:
- Target management and configuration
- Attack session coordination  
- Real-time status updates
- Cross-module communication

#### **DoSTestManager**
Comprehensive DoS testing orchestration:
- 22 attack vector implementations
- Real-time progress monitoring
- Process lifecycle management
- Safety and ethical controls

#### **AttackFramework**
Modular attack execution system:
- Tool integration and wrapping
- Parameter validation and sanitization
- Output parsing and analysis
- Error handling and recovery

#### **CVEDatabase**
NVD API integration for vulnerability data:
- Automatic database updates
- Rate limiting and caching
- Search and filtering capabilities
- CVE-to-attack correlation

### **Tool Integration**

#### **Real Tool Execution**
DonkTool integrates with actual penetration testing tools:

**Web Application Testing:**
- `sqlmap` - SQL injection testing
- `nikto` - Web vulnerability scanning
- `nuclei` - Template-based vulnerability detection
- `ffuf` - Fast web fuzzing

**Network Assessment:**
- `nmap` - Port scanning and service detection
- `gobuster` - Directory/file enumeration
- `feroxbuster` - Fast content discovery

**DoS/Stress Testing:**
- `wrk` - HTTP load testing
- `artillery` - Advanced load testing
- `slowhttptest` - Slowloris attacks
- `hping3` - Network packet crafting

#### **Tool Detection and Management**
```swift
class ToolDetection {
    func isToolInstalled(_ toolName: String) -> Bool
    func getToolPath(_ toolName: String) -> String?
    func installTool(_ toolName: String) async -> Bool
    func refreshToolStatus() async
}
```

---

## 🔐 **Security & Ethics**

### **Built-in Safeguards**
- **Authorization Checks**: Explicit confirmation required before DoS testing
- **Ethical Agreements**: User must accept ethical use policy
- **Duration Limits**: Automatic termination after specified time
- **Intensity Controls**: Configurable attack parameters with safety limits
- **Target Validation**: Hostname parsing and validation
- **Process Management**: Clean termination and resource cleanup

### **Ethical Use Requirements**
1. **Written Authorization**: Always obtain explicit written permission
2. **Scope Definition**: Test only specified systems within defined timeframes  
3. **Impact Assessment**: Understand potential business impact
4. **Incident Response**: Have procedures in place for issues
5. **Professional Standards**: Follow industry ethical guidelines

### **Legal Compliance**
- Computer Fraud and Abuse Act (CFAA) compliance
- International cybercrime law adherence
- Professional certification requirements (CISSP, CEH, OSCP)
- Responsible disclosure practices

### **Professional Certifications**
DonkTool usage aligns with requirements for:
- CISSP (Certified Information Systems Security Professional)
- CEH (Certified Ethical Hacker)
- OSCP (Offensive Security Certified Professional)
- GCIH (GIAC Certified Incident Handler)

---

## 📊 **Testing Capabilities**

### **Vulnerability Categories**
- **OWASP Top 10** comprehensive testing
- **CVE-based** vulnerability validation
- **Network service** security assessment
- **SSL/TLS** configuration analysis
- **DoS/DDoS** resilience testing
- **Application logic** flaw detection

### **Attack Techniques**
- **SQL Injection** (Boolean, Time-based, Error-based, Union-based)
- **Cross-Site Scripting** (Reflected, Stored, DOM-based)
- **Directory Traversal** and file inclusion
- **Authentication Bypass** and session management flaws
- **Denial of Service** (Application and Network layer)
- **SSL/TLS** vulnerabilities and misconfigurations

### **Reporting Features**
- **Executive Summary** with risk overview
- **Technical Details** with proof-of-concept
- **Remediation Guidance** with specific recommendations  
- **Risk Scoring** based on CVSS methodology
- **Export Formats** (PDF, HTML, JSON, CSV)

---

## 🚀 **Performance & Monitoring**

### **Real-Time Capabilities**
- **Live Attack Monitoring** with second-by-second updates
- **Process Management** with automatic termination
- **Output Streaming** for immediate feedback
- **Progress Tracking** with detailed metrics
- **Error Detection** and recovery mechanisms

### **Performance Metrics**
- **Request Rates** (requests per second)
- **Response Times** (average, median, p95, p99)
- **Success Rates** and error rates
- **Bandwidth Usage** and data transfer
- **Connection Metrics** and concurrency levels
- **Packet Statistics** for network-layer attacks

### **System Requirements**
- **CPU**: Multi-core recommended for concurrent attacks
- **Memory**: 8GB+ RAM for large-scale testing
- **Storage**: 1GB+ for CVE database and logs
- **Network**: Stable internet for CVE updates and testing

---

## 🧪 **Testing & Quality Assurance**

### **Test Coverage**
```
DonkToolTests/          # Unit tests
├── CoreTests/          # Core functionality tests
├── ModuleTests/        # Feature module tests
├── DataTests/          # Data model tests
└── IntegrationTests/   # Tool integration tests

DonkToolUITests/        # UI automation tests
├── NavigationTests/    # UI navigation tests
├── WorkflowTests/      # End-to-end workflows
└── AccessibilityTests/ # Accessibility compliance
```

### **Quality Assurance**
- **Unit Testing**: Core functionality validation
- **Integration Testing**: Tool integration verification
- **UI Testing**: User interface automation
- **Performance Testing**: Load and stress testing
- **Security Testing**: Self-assessment with included tools

### **Continuous Integration**
- Xcode project with automated building
- Swift testing framework integration
- Code quality validation
- Documentation generation

---

## 🤝 **Contributing**

We welcome contributions from the security community! Please follow these guidelines:

### **Development Setup**
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Install development dependencies
4. Follow Swift coding standards
5. Add tests for new functionality
6. Update documentation

### **Contribution Types**
- **Bug Fixes**: Security vulnerabilities, stability issues
- **Feature Additions**: New testing modules, tool integrations
- **Documentation**: Improved guides, examples, tutorials
- **Testing**: Additional test coverage, quality assurance
- **Tool Integration**: Support for new penetration testing tools

### **Security Considerations**
- All contributions must maintain ethical use requirements
- Security enhancements are prioritized
- Vulnerability reports should follow responsible disclosure
- Code must pass security review before merging

### **Submission Process**
1. Ensure all tests pass
2. Update documentation
3. Submit pull request with detailed description
4. Participate in code review process
5. Address feedback and suggestions

---

## 📋 **Roadmap**

### **Version 2.0 (Planned)**
- [ ] **Advanced Exploit Framework** with Metasploit integration
- [ ] **Machine Learning** vulnerability prediction
- [ ] **Cloud Security** testing capabilities (AWS, Azure, GCP)
- [ ] **Mobile Application** security testing
- [ ] **API Security** testing framework
- [ ] **Automated Reporting** with customizable templates

### **Version 1.5 (In Progress)**
- [x] **DoS Testing Module** with 22 attack vectors ✅
- [x] **Real-Time Monitoring** with verbose output ✅
- [x] **Dark Mode UI** with modern design ✅
- [ ] **CVE Integration** with attack vectors
- [ ] **Advanced Reporting** with executive summaries
- [ ] **Plugin Architecture** for extensibility

### **Community Requests**
- **Docker Support** for containerized testing
- **CI/CD Integration** for automated security testing
- **REST API** for programmatic access
- **Custom Payloads** and wordlist management
- **Team Collaboration** features

---

## 📚 **Resources**

### **Documentation**
- [Ethical Use Policy](ETHICAL_USE_POLICY.md) - Legal and ethical guidelines
- [Tools Status](TOOLS_STATUS.md) - Installation and compatibility
- [Installation Troubleshooting](INSTALL_TROUBLESHOOTING.md) - Common issues
- [Quick Install Fix](QUICK_INSTALL_FIX.md) - Rapid setup guide

### **Security Standards**
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [SANS Penetration Testing](https://www.sans.org/penetration-testing/)
- [PCI DSS Security Standards](https://www.pcisecuritystandards.org/)

### **Professional Development**
- [(ISC)² CISSP Certification](https://www.isc2.org/Certifications/CISSP)
- [EC-Council CEH Certification](https://www.eccouncil.org/programs/certified-ethical-hacker-ceh/)
- [Offensive Security OSCP](https://www.offensive-security.com/pwk-oscp/)
- [GIAC Security Certifications](https://www.giac.org/)

### **Legal Resources**
- [Computer Fraud and Abuse Act (CFAA)](https://www.law.cornell.edu/uscode/text/18/1030)
- [Penetration Testing Legal Guidelines](https://www.sans.org/reading-room/whitepapers/legal/)
- [Responsible Disclosure Practices](https://www.bugcrowd.com/resource/responsible-disclosure-guide/)

---

## 📄 **License & Disclaimer**

### **MIT License**
```
MIT License

Copyright (c) 2025 DonkTool Development Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### **Disclaimer**
DonkTool is provided for educational and authorized testing purposes only. The developers are not responsible for any misuse of this software. Users are solely responsible for ensuring they have proper authorization before testing any systems.

**Use at your own risk. Always obtain explicit written permission before testing.**

---

## 📞 **Support & Contact**

### **Getting Help**
- **Documentation**: Check our comprehensive guides
- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Join community discussions
- **Email**: Contact the development team

### **Security Issues**
For security vulnerabilities in DonkTool itself:
- **DO NOT** create public GitHub issues
- Email security concerns privately
- Follow responsible disclosure practices
- Allow reasonable time for fixes

### **Professional Services**
For enterprise support, custom development, or professional penetration testing services, contact our team for consulting opportunities.

---

<div align="center">

**🛡️ Built for Security Professionals, by Security Professionals**

*DonkTool - Advanced macOS Penetration Testing Suite*

[Documentation](docs/) • [Installation](INSTALL_TROUBLESHOOTING.md) • [Ethics](ETHICAL_USE_POLICY.md) • [License](LICENSE)

</div>
