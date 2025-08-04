//
//  DefaultEmailTemplates.swift
//  DonkTool
//
//  Enhanced email templates for social engineering campaigns
//

import Foundation

struct DefaultEmailTemplates {
    
    static func getAllTemplates() -> [EmailTemplate] {
        return [
            passwordExpirationTemplate(),
            ceoFraudTemplate(),
            itSecurityUpdateTemplate(),
            hrPolicyUpdateTemplate(),
            cloudServiceSuspensionTemplate(),
            invoicePaymentTemplate(),
            linkedInConnectionTemplate(),
            microsoftOfficeUpdateTemplate()
        ]
    }
    
    // MARK: - Password Expiration Template
    
    static func passwordExpirationTemplate() -> EmailTemplate {
        return EmailTemplate(
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
            textContent: "Your password expires in 24 hours. Please update it immediately by visiting the password reset portal.",
            attachments: [],
            trackingEnabled: true,
            category: .password,
            difficulty: .medium,
            tags: ["password", "urgent", "it-security"]
        )
    }
    
    // MARK: - CEO Fraud Template
    
    static func ceoFraudTemplate() -> EmailTemplate {
        return EmailTemplate(
            name: "CEO Urgent Request",
            subject: "Urgent: Wire Transfer Required",
            senderName: "John Smith (CEO)",
            senderEmail: "ceo@company.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body style="font-family: Arial, sans-serif;">
                <p>Hi {{firstName}},</p>
                
                <p>I need you to process an urgent wire transfer. I'm in a meeting and can't call.</p>
                
                <p>Please <a href="{{link}}" style="color: #0066cc;">click here</a> to view the transfer details and authorization form.</p>
                
                <p>This needs to be completed before close of business today for a critical business transaction.</p>
                
                <p>Thanks,<br>John Smith<br>Chief Executive Officer</p>
                
                <p style="color: #666; font-size: 12px; margin-top: 30px;">
                Sent from my iPhone
                </p>
            </body>
            </html>
            """,
            textContent: "Urgent wire transfer required. Please process immediately.",
            attachments: [],
            trackingEnabled: true,
            category: .financial,
            difficulty: .hard,
            tags: ["ceo-fraud", "wire-transfer", "urgent", "executive"]
        )
    }
    
    // MARK: - IT Security Update Template
    
    static func itSecurityUpdateTemplate() -> EmailTemplate {
        return EmailTemplate(
            name: "Critical Security Update",
            subject: "URGENT: Critical Security Patch Required",
            senderName: "IT Security Team",
            senderEmail: "security@company.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <div style="background-color: #dc3545; color: white; padding: 20px; text-align: center;">
                    <h2>🚨 CRITICAL SECURITY ALERT 🚨</h2>
                </div>
                
                <div style="padding: 20px;">
                    <p>Dear {{firstName}},</p>
                    
                    <p><strong>A critical security vulnerability has been detected</strong> that affects all company devices.</p>
                    
                    <div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0;">
                        <strong>Immediate Action Required:</strong>
                        <ul>
                            <li>Install security patch within 4 hours</li>
                            <li>Verify your account credentials</li>
                            <li>Update your system settings</li>
                        </ul>
                    </div>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{{link}}" style="background-color: #dc3545; color: white; padding: 15px 40px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">INSTALL SECURITY PATCH</a>
                    </div>
                    
                    <p style="color: #dc3545; font-weight: bold;">Failure to install this patch may result in:</p>
                    <ul style="color: #dc3545;">
                        <li>Data breach and security compromise</li>
                        <li>Loss of access to company systems</li>
                        <li>Potential compliance violations</li>
                    </ul>
                    
                    <hr style="border: none; border-top: 1px solid #dee2e6; margin: 30px 0;">
                    
                    <p style="color: #6c757d; font-size: 12px;">
                        This is an automated security alert from the IT Department.<br>
                        For immediate assistance: security-emergency@company.com | (555) 123-4567
                    </p>
                </div>
            </body>
            </html>
            """,
            textContent: "CRITICAL: Security patch required immediately. Install now to prevent data breach.",
            attachments: [],
            trackingEnabled: true,
            category: .it,
            difficulty: .hard,
            tags: ["security", "critical", "patch", "urgent"]
        )
    }
    
    // MARK: - HR Policy Update Template
    
    static func hrPolicyUpdateTemplate() -> EmailTemplate {
        return EmailTemplate(
            name: "HR Policy Update",
            subject: "Updated Employee Handbook - Acknowledgment Required",
            senderName: "Human Resources",
            senderEmail: "hr@company.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body style="font-family: Arial, sans-serif;">
                <p>Dear {{firstName}},</p>
                
                <p>We have updated our Employee Handbook with important policy changes effective immediately.</p>
                
                <p><strong>Key Updates Include:</strong></p>
                <ul>
                    <li>Remote work policy changes</li>
                    <li>Updated IT security requirements</li>
                    <li>New expense reporting procedures</li>
                    <li>Revised PTO accrual rates</li>
                </ul>
                
                <p>Please <a href="{{link}}" style="color: #0066cc;">review the updated handbook</a> and complete the acknowledgment form by Friday.</p>
                
                <p>Failure to acknowledge these updates may affect your access to company systems and benefits.</p>
                
                <p>Best regards,<br>
                Sarah Johnson<br>
                Director of Human Resources</p>
            </body>
            </html>
            """,
            textContent: "Employee handbook updated. Please review and acknowledge by Friday.",
            attachments: [],
            trackingEnabled: true,
            category: .hr,
            difficulty: .easy,
            tags: ["hr", "policy", "handbook", "acknowledgment"]
        )
    }
    
    // MARK: - Cloud Service Suspension Template
    
    static func cloudServiceSuspensionTemplate() -> EmailTemplate {
        return EmailTemplate(
            name: "Cloud Service Suspension Notice",
            subject: "Account Suspended - Immediate Action Required",
            senderName: "Cloud Services Team",
            senderEmail: "no-reply@cloudservices.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body style="font-family: Arial, sans-serif;">
                <div style="background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 15px; margin-bottom: 20px; border-radius: 5px;">
                    <strong>⚠️ Account Suspension Notice</strong>
                </div>
                
                <p>Dear {{firstName}},</p>
                
                <p>Your cloud service account ({{email}}) has been temporarily suspended due to suspicious activity detected on your account.</p>
                
                <p><strong>Suspension Reason:</strong> Multiple failed login attempts from unauthorized locations</p>
                
                <p>To restore your account access and prevent permanent deletion:</p>
                
                <ol>
                    <li>Verify your identity</li>
                    <li>Update your account security settings</li>
                    <li>Confirm your account information</li>
                </ol>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{{link}}" style="background-color: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">RESTORE ACCOUNT ACCESS</a>
                </div>
                
                <p style="color: #dc3545;"><strong>Important:</strong> If no action is taken within 48 hours, your account and all data will be permanently deleted.</p>
                
                <p>Thank you,<br>
                Cloud Services Security Team</p>
            </body>
            </html>
            """,
            textContent: "Your cloud account has been suspended. Restore access immediately to prevent data loss.",
            attachments: [],
            trackingEnabled: true,
            category: .cloud,
            difficulty: .medium,
            tags: ["cloud", "suspension", "security", "urgent"]
        )
    }
    
    // MARK: - Invoice Payment Template
    
    static func invoicePaymentTemplate() -> EmailTemplate {
        return EmailTemplate(
            name: "Overdue Invoice Payment",
            subject: "Overdue Payment Notice - Account #{{customField:account_number}}",
            senderName: "Accounts Receivable",
            senderEmail: "billing@vendor.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body style="font-family: Arial, sans-serif;">
                <p>Dear {{firstName}} {{lastName}},</p>
                
                <p>Our records indicate that the following invoice is past due:</p>
                
                <table style="border-collapse: collapse; width: 100%; margin: 20px 0;">
                    <tr style="background-color: #f8f9fa;">
                        <td style="border: 1px solid #dee2e6; padding: 8px;"><strong>Invoice #</strong></td>
                        <td style="border: 1px solid #dee2e6; padding: 8px;">INV-2024-001234</td>
                    </tr>
                    <tr>
                        <td style="border: 1px solid #dee2e6; padding: 8px;"><strong>Amount Due</strong></td>
                        <td style="border: 1px solid #dee2e6; padding: 8px;">$2,847.50</td>
                    </tr>
                    <tr style="background-color: #f8f9fa;">
                        <td style="border: 1px solid #dee2e6; padding: 8px;"><strong>Due Date</strong></td>
                        <td style="border: 1px solid #dee2e6; padding: 8px;">March 15, 2024</td>
                    </tr>
                </table>
                
                <p>To avoid service interruption and late fees, please make payment immediately:</p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{{link}}" style="background-color: #28a745; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">PAY INVOICE NOW</a>
                </div>
                
                <p>If payment has already been made, please disregard this notice.</p>
                
                <p>Thank you,<br>
                Accounts Receivable Department</p>
            </body>
            </html>
            """,
            textContent: "Invoice overdue. Please make payment immediately to avoid service interruption.",
            attachments: [],
            trackingEnabled: true,
            category: .financial,
            difficulty: .medium,
            tags: ["invoice", "payment", "overdue", "billing"]
        )
    }
    
    // MARK: - LinkedIn Connection Template
    
    static func linkedInConnectionTemplate() -> EmailTemplate {
        return EmailTemplate(
            name: "LinkedIn Connection Request",
            subject: "{{customField:sender_name}} wants to connect with you",
            senderName: "LinkedIn",
            senderEmail: "invitations-noreply@linkedin.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body style="font-family: Arial, sans-serif;">
                <div style="background-color: #0077b5; color: white; padding: 20px; text-align: center;">
                    <h2>LinkedIn</h2>
                </div>
                
                <div style="padding: 20px;">
                    <p>Hi {{firstName}},</p>
                    
                    <p><strong>{{customField:sender_name}}</strong> wants to connect with you on LinkedIn.</p>
                    
                    <div style="border: 1px solid #ddd; padding: 15px; margin: 20px 0; background-color: #f9f9f9;">
                        <p><strong>{{customField:sender_name}}</strong><br>
                        {{customField:sender_title}} at {{customField:sender_company}}</p>
                        
                        <p style="font-style: italic;">"I'd like to add you to my professional network on LinkedIn."</p>
                    </div>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{{link}}" style="background-color: #0077b5; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Accept Invitation</a>
                    </div>
                    
                    <p style="font-size: 12px; color: #666;">
                        You received this invitation because {{customField:sender_name}} imported contacts from their email account or because someone believes you know each other.
                    </p>
                </div>
            </body>
            </html>
            """,
            textContent: "LinkedIn connection request from {{customField:sender_name}}. Accept invitation to connect.",
            attachments: [],
            trackingEnabled: true,
            category: .social,
            difficulty: .easy,
            tags: ["linkedin", "social", "connection", "professional"]
        )
    }
    
    // MARK: - Microsoft Office Update Template
    
    static func microsoftOfficeUpdateTemplate() -> EmailTemplate {
        return EmailTemplate(
            name: "Microsoft Office Update",
            subject: "Microsoft Office - Security Update Available",
            senderName: "Microsoft Office Team",
            senderEmail: "office-noreply@microsoft.com",
            replyTo: nil,
            htmlContent: """
            <html>
            <body style="font-family: Segoe UI, Arial, sans-serif;">
                <div style="background-color: #0078d4; color: white; padding: 20px;">
                    <h2>Microsoft Office</h2>
                </div>
                
                <div style="padding: 20px;">
                    <p>Hello {{firstName}},</p>
                    
                    <p>A new security update is available for Microsoft Office applications on your device.</p>
                    
                    <div style="background-color: #fff4e6; border-left: 4px solid #ff8c00; padding: 15px; margin: 20px 0;">
                        <strong>Security Update Details:</strong>
                        <ul>
                            <li>Fixes critical vulnerabilities in Word, Excel, and PowerPoint</li>
                            <li>Improves overall application security</li>
                            <li>Enhanced protection against malicious documents</li>
                        </ul>
                    </div>
                    
                    <p>To install this update:</p>
                    
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{{link}}" style="background-color: #0078d4; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Download Update</a>
                    </div>
                    
                    <p style="font-size: 14px; color: #666;">
                        This update is recommended for all Office users to ensure optimal security and performance.
                    </p>
                    
                    <p>Best regards,<br>
                    The Microsoft Office Team</p>
                </div>
            </body>
            </html>
            """,
            textContent: "Microsoft Office security update available. Download and install to protect your system.",
            attachments: [],
            trackingEnabled: true,
            category: .software,
            difficulty: .medium,
            tags: ["microsoft", "office", "update", "security"]
        )
    }
}