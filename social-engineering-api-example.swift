//
//  SocialEngineeringAPIExample.swift
//  DonkTool
//
//  Example usage of the Social Engineering Module API
//

import Foundation
import SwiftUI

// MARK: - Example: Creating and Launching a Phishing Campaign

class PhishingCampaignExample {
    let socialManager = SocialEngineeringManager()
    
    // Example 1: Simple phishing campaign
    func createSimplePhishingCampaign() async throws {
        print("🎯 Creating Simple Phishing Campaign")
        
        // Step 1: Import targets from CSV
        let csvData = """
        email,firstName,lastName,department,position
        john.doe@example.com,John,Doe,Sales,Manager
        jane.smith@example.com,Jane,Smith,IT,Developer
        bob.wilson@example.com,Bob,Wilson,HR,Director
        """.data(using: .utf8)!
        
        let targets = try socialManager.importTargetsFromCSV(csvData)
        print("✅ Imported \(targets.count) targets")
        
        // Step 2: Select email template
        let template = EmailTemplate(
            name: "Password Expiration Notice",
            subject: "Action Required: Password Expires in 24 Hours",
            senderName: "IT Support",
            senderEmail: "it-support@company.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <div style="background-color: #f8f9fa; padding: 20px; text-align: center;">
                    <h2 style="color: #dc3545;">Password Expiration Notice</h2>
                </div>
                
                <div style="padding: 20px;">
                    <p>Dear {{firstName}},</p>
                    
                    <p>Your password for the corporate account <strong>{{email}}</strong> will expire in <strong>24 hours</strong>.</p>
                    
                    <p>To avoid any disruption to your work, please update your password immediately by clicking the button below:</p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{{link}}" style="background-color: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Update Password Now</a>
                    </div>
                    
                    <p style="color: #6c757d; font-size: 14px;">If you have already updated your password, please disregard this message.</p>
                    
                    <hr style="border: none; border-top: 1px solid #dee2e6; margin: 30px 0;">
                    
                    <p style="color: #6c757d; font-size: 12px;">
                        This is an automated message from the IT Security Team.<br>
                        For assistance, contact: it-helpdesk@company.com
                    </p>
                </div>
            </body>
            </html>
            """,
            textContent: "Your password expires in 24 hours. Please update it immediately.",
            attachments: [],
            trackingEnabled: true,
            category: .password,
            difficulty: .medium,
            tags: ["password", "urgent", "it-security"]
        )
        
        // Step 3: Create landing page
        let landingPage = LandingPageTemplate(
            name: "Password Reset Portal",
            url: "/password-reset",
            htmlContent: """
            <!DOCTYPE html>
            <html>
            <head>
                <title>Password Reset - Company Portal</title>
                <meta name="viewport" content="width=device-width, initial-scale=1">
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <img src="/company-logo.png" alt="Company" class="logo">
                        <h1>Password Reset Portal</h1>
                    </div>
                    
                    <div class="content">
                        <p class="warning">⚠️ Your password expires in less than 24 hours</p>
                        
                        <form id="passwordResetForm">
                            <div class="form-group">
                                <label>Current Username/Email</label>
                                <input type="email" name="username" required placeholder="user@company.com">
                            </div>
                            
                            <div class="form-group">
                                <label>Current Password</label>
                                <input type="password" name="currentPassword" required>
                            </div>
                            
                            <div class="form-group">
                                <label>New Password</label>
                                <input type="password" name="newPassword" required>
                                <small>Must be at least 12 characters with mixed case, numbers, and symbols</small>
                            </div>
                            
                            <div class="form-group">
                                <label>Confirm New Password</label>
                                <input type="password" name="confirmPassword" required>
                            </div>
                            
                            <button type="submit" class="submit-btn">Update Password</button>
                        </form>
                    </div>
                    
                    <div class="footer">
                        <p>© 2024 Company Inc. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            """,
            cssContent: """
            body {
                margin: 0;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: #f5f5f5;
                color: #333;
            }
            
            .container {
                max-width: 500px;
                margin: 40px auto;
                background: white;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                overflow: hidden;
            }
            
            .header {
                background: #1a73e8;
                color: white;
                padding: 30px;
                text-align: center;
            }
            
            .logo {
                height: 60px;
                margin-bottom: 20px;
            }
            
            .content {
                padding: 40px;
            }
            
            .warning {
                background: #ffeaa7;
                border-left: 4px solid #fdcb6e;
                padding: 15px;
                margin-bottom: 30px;
                font-weight: 600;
            }
            
            .form-group {
                margin-bottom: 20px;
            }
            
            label {
                display: block;
                margin-bottom: 8px;
                font-weight: 600;
                color: #555;
            }
            
            input {
                width: 100%;
                padding: 12px;
                border: 1px solid #ddd;
                border-radius: 4px;
                font-size: 16px;
                box-sizing: border-box;
            }
            
            small {
                display: block;
                margin-top: 5px;
                color: #666;
                font-size: 13px;
            }
            
            .submit-btn {
                width: 100%;
                padding: 15px;
                background: #1a73e8;
                color: white;
                border: none;
                border-radius: 4px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                margin-top: 20px;
            }
            
            .submit-btn:hover {
                background: #1557b0;
            }
            
            .footer {
                background: #f8f9fa;
                padding: 20px;
                text-align: center;
                color: #666;
                font-size: 14px;
            }
            """,
            jsContent: """
            document.getElementById('passwordResetForm').addEventListener('submit', async function(e) {
                e.preventDefault();
                
                // Get form data
                const formData = new FormData(e.target);
                const data = Object.fromEntries(formData);
                
                // Basic validation
                if (data.newPassword !== data.confirmPassword) {
                    alert('New passwords do not match!');
                    return;
                }
                
                // Show loading state
                const submitBtn = e.target.querySelector('.submit-btn');
                submitBtn.textContent = 'Updating...';
                submitBtn.disabled = true;
                
                // Send to tracking server
                try {
                    await fetch('/api/track', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            trackingId: new URLSearchParams(window.location.search).get('id'),
                            formData: data,
                            timestamp: new Date().toISOString()
                        })
                    });
                } catch (error) {
                    console.error('Tracking error:', error);
                }
                
                // Show completion message
                setTimeout(() => {
                    e.target.innerHTML = `
                        <div style="text-align: center; padding: 40px;">
                            <h2 style="color: #28a745;">✓ Password Updated Successfully</h2>
                            <p>Your password has been updated. You will be redirected to the login page.</p>
                            <p style="color: #dc3545; font-weight: bold; margin-top: 30px;">
                                This was a security awareness test. Your credentials were not actually changed.
                            </p>
                            <p>Please report this email to security@company.com</p>
                        </div>
                    `;
                    
                    // Redirect after delay
                    setTimeout(() => {
                        window.location.href = 'https://real-company-site.com/security-training';
                    }, 10000);
                }, 1500);
            });
            """,
            captureCredentials: true,
            redirectUrl: "https://real-company-site.com/security-training",
            customFields: [],
            pageType: .login
        )
        
        // Step 4: Configure campaign settings
        let settings = CampaignSettings(
            sendingProfile: SendingProfile(
                name: "AWS SES",
                smtpHost: "email-smtp.us-east-1.amazonaws.com",
                smtpPort: 587,
                username: "AKIAIOSFODNN7EXAMPLE",
                password: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
                useTLS: true,
                useStartTLS: true,
                sendRate: 100
            ),
            schedule: CampaignSchedule(
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                sendingDays: Set([.monday, .tuesday, .wednesday, .thursday, .friday]),
                sendingHours: 8...18,
                timezone: TimeZone.current
            ),
            trackingOptions: TrackingOptions(
                trackEmailOpens: true,
                trackLinkClicks: true,
                trackCredentials: true,
                trackUserAgent: true,
                trackLocation: true,
                useUniqueLinks: true,
                pixelTracking: true
            ),
            notifications: NotificationSettings(
                notifyOnOpen: false,
                notifyOnClick: true,
                notifyOnSubmit: true,
                notifyOnReport: true,
                notificationEmail: "security-team@company.com",
                webhookUrl: nil
            )
        )
        
        // Step 5: Create the campaign
        let campaign = PhishingCampaign(
            name: "Q4 2024 Password Security Test",
            description: "Testing employee awareness of password reset phishing attempts",
            targetOrganization: "Example Corporation",
            status: .ready,
            createdAt: Date(),
            launchedAt: nil,
            completedAt: nil,
            targets: targets,
            emailTemplate: template,
            landingPage: landingPage,
            metrics: CampaignMetrics(),
            settings: settings
        )
        
        socialManager.createCampaign(campaign)
        print("✅ Campaign created: \(campaign.name)")
        
        // Step 6: Launch the campaign
        try await socialManager.launchCampaign(campaign.id)
        print("🚀 Campaign launched successfully!")
    }
    
    // Example 2: Advanced spear-phishing campaign
    func createSpearPhishingCampaign() async throws {
        print("🎯 Creating Advanced Spear-Phishing Campaign")
        
        // Target specific high-value individuals
        let executiveTargets = [
            PhishingTarget(
                email: "ceo@example.com",
                firstName: "Alice",
                lastName: "Johnson",
                department: "Executive",
                position: "Chief Executive Officer",
                customFields: [
                    "company": "Example Corp",
                    "assistant": "Mary Smith",
                    "direct_reports": "12"
                ],
                status: .pending,
                emailSentAt: nil,
                emailOpenedAt: nil,
                linkClickedAt: nil,
                credentialsSubmittedAt: nil,
                reportedAsPhishingAt: nil,
                interactions: []
            ),
            PhishingTarget(
                email: "cfo@example.com",
                firstName: "Robert",
                lastName: "Chen",
                department: "Finance",
                position: "Chief Financial Officer",
                customFields: [
                    "company": "Example Corp",
                    "reports_to": "CEO",
                    "budget_authority": "$10M"
                ],
                status: .pending,
                emailSentAt: nil,
                emailOpenedAt: nil,
                linkClickedAt: nil,
                credentialsSubmittedAt: nil,
                reportedAsPhishingAt: nil,
                interactions: []
            )
        ]
        
        // Create highly targeted template
        let spearPhishingTemplate = EmailTemplate(
            name: "Board Meeting Document Request",
            subject: "Re: Confidential - Q4 Board Meeting Materials",
            senderName: "Alice Johnson",
            senderEmail: "alice.j@example-corp.com", // Typosquatted domain
            replyTo: "alice.johnson@legitimate-email.com",
            htmlContent: """
            <html>
            <body style="font-family: Arial, sans-serif;">
                <p>Hi {{firstName}},</p>
                
                <p>Following up on our discussion yesterday about the Q4 board presentation.</p>
                
                <p>I've uploaded the confidential financial projections to our secure document portal. 
                Given the sensitive nature of the acquisition details, I've password-protected the files.</p>
                
                <p><a href="{{link}}" style="color: #0066cc;">Access Board Documents</a></p>
                
                <p>Please review sections 3 and 7 specifically - I need your input on the revenue 
                projections before tomorrow's committee meeting.</p>
                
                <p>Thanks,<br>
                Alice</p>
                
                <p style="color: #666; font-size: 12px; margin-top: 30px;">
                Sent from my iPhone
                </p>
            </body>
            </html>
            """,
            textContent: "Please review the Q4 board meeting materials...",
            attachments: [],
            trackingEnabled: true,
            category: .corporate,
            difficulty: .expert,
            tags: ["spear-phishing", "executive", "targeted"]
        )
        
        print("✅ Created spear-phishing template targeting executives")
        
        // Continue with campaign creation...
    }
    
    // Example 3: Monitor campaign progress
    func monitorCampaignProgress(campaignId: UUID) async {
        print("📊 Monitoring Campaign Progress")
        
        // Poll for updates every 30 seconds
        for _ in 1...20 {
            if let analytics = socialManager.getCampaignAnalytics(campaignId) {
                print("""
                
                📈 Campaign Metrics Update:
                ├─ Emails Sent: \(analytics.emailsSent)
                ├─ Emails Opened: \(analytics.emailsOpened) (\(String(format: "%.1f%%", analytics.emailsOpened > 0 ? Double(analytics.emailsOpened) / Double(analytics.emailsSent) * 100 : 0)))
                ├─ Links Clicked: \(analytics.linksClicked)
                ├─ Credentials Submitted: \(analytics.credentialsSubmitted)
                └─ Reported as Phishing: \(analytics.reported)
                
                """)
                
                if let avgTimeToClick = analytics.averageTimeToClick {
                    print("⏱️ Average time to click: \(formatDuration(avgTimeToClick))")
                }
                
                if analytics.overallRiskScore > 0 {
                    print("⚠️ Overall Risk Score: \(String(format: "%.1f", analytics.overallRiskScore))/100")
                }
            }
            
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
        }
    }
    
    // Example 4: Generate campaign report
    func generateCampaignReport(campaignId: UUID) async throws {
        print("📄 Generating Campaign Report")
        
        guard let campaign = socialManager.campaigns.first(where: { $0.id == campaignId }) else {
            throw CampaignError.campaignNotFound
        }
        
        let report = """
        # Phishing Campaign Report
        
        ## Campaign: \(campaign.name)
        
        ### Executive Summary
        
        The phishing simulation campaign "\(campaign.name)" was conducted from \(campaign.launchedAt?.formatted() ?? "N/A") 
        to test the security awareness of \(campaign.targets.count) employees at \(campaign.targetOrganization).
        
        ### Key Findings
        
        - **Email Open Rate**: \(String(format: "%.1f%%", campaign.metrics.openRate))
        - **Click Rate**: \(String(format: "%.1f%%", campaign.metrics.clickRate))
        - **Credential Submission Rate**: \(String(format: "%.1f%%", campaign.metrics.submissionRate))
        - **Phishing Report Rate**: \(String(format: "%.1f%%", campaign.metrics.reportRate))
        
        ### Risk Assessment
        
        Based on the campaign results, the organization's susceptibility to phishing attacks is:
        \(calculateRiskLevel(campaign.metrics))
        
        ### Recommendations
        
        1. Conduct targeted security awareness training for departments with high click rates
        2. Implement additional email security controls
        3. Reward employees who correctly identified and reported the phishing attempt
        4. Schedule follow-up campaigns to measure improvement
        
        ### Detailed Results by Department
        
        \(generateDepartmentBreakdown(campaign))
        
        ---
        Generated on: \(Date().formatted())
        """
        
        print(report)
        
        // Save report to file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let reportPath = documentsPath.appendingPathComponent("campaign_\(campaignId.uuidString)_report.md")
        try report.write(to: reportPath, atomically: true, encoding: .utf8)
        
        print("✅ Report saved to: \(reportPath.path)")
    }
    
    // Helper functions
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    private func calculateRiskLevel(_ metrics: CampaignMetrics) -> String {
        let riskScore = (metrics.clickRate * 0.3) + (metrics.submissionRate * 0.5) - (metrics.reportRate * 0.2)
        
        switch riskScore {
        case ..<10: return "**LOW** - Excellent security awareness"
        case 10..<30: return "**MEDIUM** - Moderate risk, training recommended"
        case 30..<50: return "**HIGH** - Significant risk, immediate action required"
        default: return "**CRITICAL** - Severe vulnerability to phishing attacks"
        }
    }
    
    private func generateDepartmentBreakdown(_ campaign: PhishingCampaign) -> String {
        // Group targets by department
        let departments = Dictionary(grouping: campaign.targets, by: { $0.department ?? "Unknown" })
        
        var breakdown = ""
        for (dept, targets) in departments.sorted(by: { $0.key < $1.key }) {
            let clicked = targets.filter { $0.linkClickedAt != nil }.count
            let submitted = targets.filter { $0.credentialsSubmittedAt != nil }.count
            let reported = targets.filter { $0.reportedAsPhishingAt != nil }.count
            
            breakdown += """
            
            **\(dept)**
            - Targets: \(targets.count)
            - Clicked: \(clicked) (\(String(format: "%.1f%%", Double(clicked) / Double(targets.count) * 100)))
            - Submitted: \(submitted) (\(String(format: "%.1f%%", Double(submitted) / Double(targets.count) * 100)))
            - Reported: \(reported) (\(String(format: "%.1f%%", Double(reported) / Double(targets.count) * 100)))
            
            """
        }
        
        return breakdown
    }
}

// MARK: - SwiftUI Preview for Testing

struct SocialEngineeringAPIExampleView: View {
    @State private var output: String = ""
    @State private var isRunning = false
    
    let example = PhishingCampaignExample()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Social Engineering API Examples")
                .font(.title)
                .fontWeight(.bold)
            
            Text("⚠️ These examples are for demonstration only. Do not run against real targets without authorization.")
                .font(.caption)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button("Run Simple Campaign Example") {
                    runExample {
                        try await example.createSimplePhishingCampaign()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning)
                
                Button("Run Spear-Phishing Example") {
                    runExample {
                        try await example.createSpearPhishingCampaign()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isRunning)
            }
            
            ScrollView {
                Text(output)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            if isRunning {
                ProgressView("Running example...")
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
    
    private func runExample(example: @escaping () async throws -> Void) {
        isRunning = true
        output = ""
        
        Task {
            do {
                // Capture console output
                let pipe = Pipe()
                let originalStdout = dup(STDOUT_FILENO)
                dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
                
                try await example()
                
                // Restore stdout
                dup2(originalStdout, STDOUT_FILENO)
                close(originalStdout)
                
                // Read captured output
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                output = String(data: data, encoding: .utf8) ?? "No output"
                
            } catch {
                output = "Error: \(error.localizedDescription)"
            }
            
            isRunning = false
        }
    }
}

#Preview {
    SocialEngineeringAPIExampleView()
}