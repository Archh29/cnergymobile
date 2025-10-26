<?php
// Password Reset Email Functions
// This file contains functions for sending password reset emails using the existing email service

// Function to create HTML email template for password reset
function createPasswordResetHTML($userName, $resetUrl, $expiresInMinutes) {
    $currentYear = date('Y');
    
    return "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Password Reset - CNERGY GYM</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333333; background-color: #f8f9fa; }
            .email-container { max-width: 600px; margin: 0 auto; background-color: #ffffff; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); }
            .header { background: linear-gradient(135deg, #FF6B35 0%, #FF8E53 100%); padding: 40px 30px; text-align: center; }
            .logo h1 { color: #ffffff; font-size: 32px; font-weight: 700; margin-bottom: 8px; letter-spacing: 2px; }
            .logo p { color: #ffffff; font-size: 16px; opacity: 0.95; margin: 0; }
            .reset-badge { display: inline-block; background: rgba(255, 255, 255, 0.2); color: #ffffff; padding: 8px 16px; border-radius: 20px; font-size: 14px; font-weight: 600; text-transform: uppercase; margin-top: 16px; }
            .content { padding: 40px 30px; }
            .reset-section { text-align: center; margin-bottom: 40px; }
            .reset-icon { font-size: 64px; margin-bottom: 20px; }
            .reset-title { font-size: 28px; font-weight: 600; color: #2c3e50; margin-bottom: 16px; }
            .reset-subtitle { font-size: 18px; color: #7f8c8d; margin-bottom: 24px; }
            .reset-message { font-size: 16px; color: #34495e; line-height: 1.7; max-width: 500px; margin: 0 auto; }
            .reset-card { background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); border-radius: 12px; padding: 32px 24px; margin: 32px 0; border-left: 4px solid #FF6B35; text-align: center; }
            .reset-card h3 { color: #FF6B35; font-size: 18px; font-weight: 600; margin-bottom: 20px; }
            .reset-button { display: inline-block; background: linear-gradient(135deg, #FF6B35 0%, #FF8E53 100%); color: #ffffff; padding: 16px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px; margin: 20px 0; transition: transform 0.2s; }
            .reset-button:hover { transform: translateY(-2px); }
            .expiry-info { background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 12px 16px; margin: 20px 0; color: #856404; font-size: 14px; font-weight: 500; }
            .security-notice { background: #d1ecf1; border: 1px solid #bee5eb; border-radius: 8px; padding: 16px; margin: 20px 0; color: #0c5460; font-size: 14px; }
            .footer { background: #2c3e50; color: #ecf0f1; text-align: center; padding: 32px 30px; }
            .footer-brand { font-size: 20px; font-weight: 700; margin-bottom: 8px; }
            .footer-copyright { font-size: 12px; opacity: 0.6; margin-bottom: 8px; }
        </style>
    </head>
    <body>
        <div class='email-container'>
            <div class='header'>
                <div class='logo'>
                    <h1>CNERGY GYM</h1>
                    <p>Transform Your Fitness Journey</p>
                    <div class='reset-badge'>Password Reset</div>
                </div>
            </div>
            <div class='content'>
                <div class='reset-section'>
                    <div class='reset-icon'>🔐</div>
                    <h2 class='reset-title'>Reset Your Password</h2>
                    <p class='reset-subtitle'>Secure your CNERGY GYM account</p>
                    <p class='reset-message'>
                        Hi " . htmlspecialchars($userName) . "! 
                        We received a request to reset your password for your CNERGY GYM account.
                        Click the button below to create a new password.
                    </p>
                </div>
                <div class='reset-card'>
                    <h3>Reset Your Password</h3>
                    <a href='" . htmlspecialchars($resetUrl) . "' class='reset-button'>
                        Reset Password
                    </a>
                    <div class='expiry-info'>
                        ⏰ This link expires in " . $expiresInMinutes . " minutes
                    </div>
                    <p style='color: #7f8c8d; font-size: 14px; margin-top: 16px;'>
                        If the button doesn't work, copy and paste this link into your browser:<br>
                        <span style='word-break: break-all; color: #FF6B35;'>" . htmlspecialchars($resetUrl) . "</span>
                    </p>
                </div>
                <div class='security-notice'>
                    <strong>🔒 Security Notice:</strong><br>
                    If you didn't request this password reset, please ignore this email. 
                    Your password will remain unchanged. For security reasons, this link will expire in " . $expiresInMinutes . " minutes.
                </div>
            </div>
            <div class='footer'>
                <div class='footer-brand'>CNERGY GYM</div>
                <div class='footer-copyright'>&copy; $currentYear CNERGY GYM. All rights reserved.</div>
            </div>
        </div>
    </body>
    </html>";
}

// Function to send password reset email
function sendPasswordResetEmail($to, $userName, $resetUrl, $expiresInMinutes = 60) {
    try {
        // Include the existing email service
        require_once 'email_service.php';
        $emailService = new EmailService();
        
        $subject = "Reset Your Password - CNERGY GYM";
        $htmlBody = createPasswordResetHTML($userName, $resetUrl, $expiresInMinutes);
        $textBody = "
        CNERGY GYM - PASSWORD RESET
        ===========================
        
        Hi $userName!
        
        We received a request to reset your password for your CNERGY GYM account.
        
        To reset your password, click the link below:
        $resetUrl
        
        This link expires in $expiresInMinutes minutes.
        
        If you didn't request this password reset, please ignore this email. 
        Your password will remain unchanged.
        
        For security reasons, this link will expire in $expiresInMinutes minutes.
        
        Best regards,
        CNERGY GYM Team
        ";
        
        // Use reflection to access private method (same as your existing code)
        $reflection = new ReflectionClass($emailService);
        $method = $reflection->getMethod('createEmailHeaders');
        $method->setAccessible(true);
        $emailData = $method->invoke($emailService, $to, $userName, $htmlBody, $textBody);
        
        $success = mail($to, $subject, $emailData['message'], $emailData['headers']);
        
        if ($success) {
            error_log("Password reset email sent successfully to: " . $to);
            return true;
        } else {
            error_log("Failed to send password reset email to: " . $to);
            return false;
        }
        
    } catch (Exception $e) {
        error_log("Password reset email sending failed to " . $to . ": " . $e->getMessage());
        return false;
    }
}
?>
