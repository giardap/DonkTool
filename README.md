# DonkTool

A native macOS penetration testing suite built with Swift and SwiftUI.

## ⚠️ Legal Notice

This tool is intended for authorized penetration testing and security assessment only. Users are responsible for ensuring they have proper authorization before testing any systems. Unauthorized use may violate local, state, and federal laws.

## Features

- **CVE Management**: Real-time CVE database integration and search
- **Network Scanner**: Port scanning and service enumeration
- **Web Application Testing**: SQL injection, XSS, and other web vulnerability testing
- **Reporting**: Comprehensive vulnerability reports with export capabilities
- **Plugin Architecture**: Modular design for easy extension

## Project Structure

```
DonkTool/
├── DonkTool/                 # Main application source
│   ├── Core/                 # Core application logic
│   ├── Modules/              # Feature modules
│   │   ├── CVEManager/       # CVE database and search
│   │   ├── NetworkScanner/   # Network scanning tools
│   │   ├── WebTesting/       # Web application testing
│   │   └── Reporting/        # Report generation
│   ├── UI/                   # User interface components
│   │   ├── Views/            # SwiftUI views
│   │   └── ViewModels/       # View models
│   ├── Data/                 # Data models and persistence
│   └── Resources/            # Assets and resources
├── DonkToolTests/            # Unit tests
├── DonkToolUITests/          # UI tests
└── Documentation/            # Project documentation
```

## Getting Started

1. Open DonkTool.xcodeproj in Xcode 15+
2. Build and run the application
3. Review the legal disclaimer and accept terms
4. Begin your authorized penetration testing

## Requirements

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## Contributing

Please read our contribution guidelines before submitting pull requests.

## License

MIT License - See LICENSE file for details
