<?php
// Standalone Email Service without Composer/PHPMailer dependency
// Uses PHP's built-in mail() function with proper headers

class EmailService {
    private $isConfigured = false;
    private $fromEmail = 'cnergyfitnessgym@cnergy.site';
    private $fromName = 'CNERGY GYM';
    
    public function __construct() {
        $this->isConfigured = true; // Always configured since we use built-in mail()
        error_log("EmailService initialized with built-in mail() function");
    }
    
    public function sendWelcomeEmail($userEmail, $userName, $userDetails = []) {
        if (!$this->isConfigured) {
            return ['success' => false, 'message' => 'Email service not properly configured'];
        }
        
        try {
            // Email content
            $subject = 'Welcome to CNERGY GYM - Account Created Successfully!';
            $htmlBody = $this->createModernWelcomeEmailTemplate($userName, $userDetails);
            $textBody = $this->createPlainTextWelcome($userName);
            
            // Email headers and message
            $emailData = $this->createEmailHeaders($userEmail, $userName, $htmlBody, $textBody);
            
            // Add some debugging
            error_log("Attempting to send welcome email to: " . $userEmail);
            error_log("Email subject: " . $subject);
            
            // Send email using PHP's built-in mail() function
            $success = mail($userEmail, $subject, $emailData['message'], $emailData['headers']);
            
            if ($success) {
                error_log("Welcome email sent successfully to: " . $userEmail);
                return ['success' => true, 'message' => 'Welcome email sent successfully'];
            } else {
                error_log("Failed to send welcome email to: " . $userEmail);
                return ['success' => false, 'message' => 'Failed to send welcome email - mail() function returned false'];
            }
            
        } catch (Exception $e) {
            error_log("Email sending failed to " . $userEmail . ": " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to send welcome email: ' . $e->getMessage()];
        }
    }
    
    // Test method to verify email service is working
    public function sendTestEmail($userEmail, $userName = 'Test User') {
        if (!$this->isConfigured) {
            return ['success' => false, 'message' => 'Email service not properly configured'];
        }
        
        try {
            // Email content
            $subject = 'Test Email from CNERGY GYM System';
            $htmlBody = $this->createTestEmailTemplate($userName);
            $textBody = 'Test Email - This is a test email from the CNERGY GYM registration system. If you received this, the email service is working correctly!';
            
            // Email headers and message
            $emailData = $this->createEmailHeaders($userEmail, $userName, $htmlBody, $textBody);
            
            // Send email using PHP's built-in mail() function
            $success = mail($userEmail, $subject, $emailData['message'], $emailData['headers']);
            
            if ($success) {
                error_log("Test email sent successfully to: " . $userEmail);
                return ['success' => true, 'message' => 'Test email sent successfully'];
            } else {
                error_log("Failed to send test email to: " . $userEmail);
                return ['success' => false, 'message' => 'Failed to send test email - mail() function returned false'];
            }
            
        } catch (Exception $e) {
            error_log("Test email sending failed to " . $userEmail . ": " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to send test email: ' . $e->getMessage()];
        }
    }
    
    private function createEmailHeaders($toEmail, $toName, $htmlBody, $textBody) {
        $boundary = md5(uniqid(time()));
        
        $headers = "From: {$this->fromName} <{$this->fromEmail}>\r\n";
        $headers .= "Reply-To: {$this->fromEmail}\r\n";
        $headers .= "MIME-Version: 1.0\r\n";
        $headers .= "Content-Type: multipart/alternative; boundary=\"{$boundary}\"\r\n";
        $headers .= "X-Mailer: PHP/" . phpversion() . "\r\n";
        $headers .= "X-Priority: 3\r\n";
        
        // Create multipart message body
        $message = "--{$boundary}\r\n";
        $message .= "Content-Type: text/plain; charset=UTF-8\r\n";
        $message .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
        $message .= $textBody . "\r\n\r\n";
        
        $message .= "--{$boundary}\r\n";
        $message .= "Content-Type: text/html; charset=UTF-8\r\n";
        $message .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
        $message .= $htmlBody . "\r\n\r\n";
        
        $message .= "--{$boundary}--\r\n";
        
        return ['headers' => $headers, 'message' => $message];
    }
    
    private function createModernWelcomeEmailTemplate($userName, $userDetails) {
        $currentYear = date('Y');
        $registrationDate = date('F j, Y');
        
        return "
        <!DOCTYPE html>
        <html lang='en'>
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
            <title>Welcome to CNERGY GYM</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    line-height: 1.6;
                    color: #333333;
                    background-color: #f8f9fa;
                }
                
                .email-container {
                    max-width: 600px;
                    margin: 0 auto;
                    background-color: #ffffff;
                    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                }
                
                .header {
                    background: linear-gradient(135deg, #FF6B35 0%, #FF8E53 100%);
                    padding: 40px 30px;
                    text-align: center;
                    position: relative;
                    overflow: hidden;
                }
                
                .logo h1 {
                    color: #ffffff;
                    font-size: 32px;
                    font-weight: 700;
                    margin-bottom: 8px;
                    letter-spacing: 2px;
                    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
                }
                
                .logo p {
                    color: #ffffff;
                    font-size: 16px;
                    font-weight: 400;
                    opacity: 0.95;
                    margin: 0;
                }
                
                .content {
                    padding: 40px 30px;
                }
                
                .welcome-section {
                    text-align: center;
                    margin-bottom: 40px;
                }
                
                .welcome-title {
                    font-size: 28px;
                    font-weight: 600;
                    color: #2c3e50;
                    margin-bottom: 16px;
                }
                
                .welcome-subtitle {
                    font-size: 18px;
                    color: #7f8c8d;
                    margin-bottom: 24px;
                }
                
                .welcome-message {
                    font-size: 16px;
                    color: #34495e;
                    line-height: 1.7;
                    max-width: 500px;
                    margin: 0 auto;
                }
                
                .info-card {
                    background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
                    border-radius: 12px;
                    padding: 24px;
                    margin: 32px 0;
                    border-left: 4px solid #FF6B35;
                }
                
                .info-card h3 {
                    color: #FF6B35;
                    font-size: 18px;
                    font-weight: 600;
                    margin-bottom: 16px;
                }
                
                .info-row {
                    display: flex;
                    justify-content: space-between;
                    margin-bottom: 8px;
                    padding: 4px 0;
                }
                
                .info-label {
                    font-weight: 600;
                    color: #2c3e50;
                }
                
                .info-value {
                    color: #7f8c8d;
                }
                
                .status-badge {
                    display: inline-block;
                    background: linear-gradient(135deg, #ffc107 0%, #ffca28 100%);
                    color: #ffffff;
                    padding: 4px 12px;
                    border-radius: 20px;
                    font-size: 12px;
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
                
                .steps-section {
                    background: #ffffff;
                    border: 1px solid #e9ecef;
                    border-radius: 12px;
                    padding: 32px;
                    margin: 32px 0;
                }
                
                .steps-title {
                    font-size: 20px;
                    font-weight: 600;
                    color: #2c3e50;
                    margin-bottom: 24px;
                    text-align: center;
                }
                
                .step {
                    display: flex;
                    align-items: flex-start;
                    margin-bottom: 24px;
                    padding-bottom: 24px;
                    border-bottom: 1px solid #f1f3f4;
                }
                
                .step:last-child {
                    margin-bottom: 0;
                    padding-bottom: 0;
                    border-bottom: none;
                }
                
                .step-number {
                    background: linear-gradient(135deg, #FF6B35 0%, #FF8E53 100%);
                    color: #ffffff;
                    width: 32px;
                    height: 32px;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-weight: 700;
                    font-size: 14px;
                    margin-right: 16px;
                    flex-shrink: 0;
                }
                
                .step-content h4 {
                    font-size: 16px;
                    font-weight: 600;
                    color: #2c3e50;
                    margin-bottom: 4px;
                }
                
                .step-content p {
                    font-size: 14px;
                    color: #7f8c8d;
                    line-height: 1.5;
                }
                
                .contact-section {
                    background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
                    border-radius: 12px;
                    padding: 24px;
                    margin: 32px 0;
                    text-align: center;
                }
                
                .contact-title {
                    font-size: 18px;
                    font-weight: 600;
                    color: #1565c0;
                    margin-bottom: 16px;
                }
                
                .contact-info {
                    color: #1976d2;
                    font-size: 14px;
                    line-height: 1.6;
                }
                
                .contact-info strong {
                    color: #0d47a1;
                }
                
                .footer {
                    background: #2c3e50;
                    color: #ecf0f1;
                    text-align: center;
                    padding: 32px 30px;
                }
                
                .footer-brand {
                    font-size: 20px;
                    font-weight: 700;
                    margin-bottom: 8px;
                    letter-spacing: 1px;
                }
                
                .footer-tagline {
                    font-size: 14px;
                    opacity: 0.8;
                    margin-bottom: 16px;
                }
                
                .footer-copyright {
                    font-size: 12px;
                    opacity: 0.6;
                    margin-bottom: 8px;
                }
                
                .footer-disclaimer {
                    font-size: 11px;
                    opacity: 0.5;
                    line-height: 1.4;
                    max-width: 400px;
                    margin: 0 auto;
                }
            </style>
        </head>
        <body>
            <div class='email-container'>
                <!-- Header -->
                <div class='header'>
                    <div class='logo'>
                        <h1>CNERGY GYM</h1>
                        <p>Transform Your Fitness Journey</p>
                    </div>
                </div>
                
                <!-- Main Content -->
                <div class='content'>
                    <!-- Welcome Section -->
                    <div class='welcome-section'>
                        <h2 class='welcome-title'>Welcome, " . htmlspecialchars($userName) . "!</h2>
                        <p class='welcome-subtitle'>Your fitness journey starts here</p>
                        <p class='welcome-message'>
                            Congratulations! Your CNERGY GYM account has been created successfully. 
                            We're excited to have you join our community of fitness enthusiasts and help you achieve your goals.
                        </p>
                    </div>
                    
                    <!-- Account Info Card -->
                    <div class='info-card'>
                        <h3>Account Information</h3>
                        <div class='info-row'>
                            <span class='info-label'>Name:</span>
                            <span class='info-value'>" . htmlspecialchars($userName) . "</span>
                        </div>
                        <div class='info-row'>
                            <span class='info-label'>Email:</span>
                            <span class='info-value'>" . htmlspecialchars($userDetails['email'] ?? 'N/A') . "</span>
                        </div>
                        <div class='info-row'>
                            <span class='info-label'>Status:</span>
                            <span class='status-badge'>Pending Verification</span>
                        </div>
                        <div class='info-row'>
                            <span class='info-label'>Registration Date:</span>
                            <span class='info-value'>" . $registrationDate . "</span>
                        </div>
                    </div>
                    
                    <!-- Next Steps -->
                    <div class='steps-section'>
                        <h3 class='steps-title'>Next Steps to Get Started</h3>
                        
                        <div class='step'>
                            <div class='step-number'>1</div>
                            <div class='step-content'>
                                <h4>Visit Our Front Desk</h4>
                                <p>Come to our gym location during business hours to complete your account verification process.</p>
                            </div>
                        </div>
                        
                        <div class='step'>
                            <div class='step-number'>2</div>
                            <div class='step-content'>
                                <h4>Bring Valid Identification</h4>
                                <p>Please bring a government-issued photo ID (driver's license, passport, or national ID) for identity verification.</p>
                            </div>
                        </div>
                        
                        <div class='step'>
                            <div class='step-number'>3</div>
                            <div class='step-content'>
                                <h4>Complete Your Profile</h4>
                                <p>Once verified, you can complete your fitness profile in our mobile app to get personalized workout recommendations.</p>
                            </div>
                        </div>
                        
                        <div class='step'>
                            <div class='step-number'>4</div>
                            <div class='step-content'>
                                <h4>Start Your Fitness Journey</h4>
                                <p>Begin training with our state-of-the-art equipment, expert trainers, and comprehensive fitness programs.</p>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Contact Information -->
                    <div class='contact-section'>
                        <h3 class='contact-title'>Gym Information</h3>
                        <div class='contact-info'>
                            <p><strong>Address:</strong> 123 Fitness Street, Gym City, GC 12345</p>
                            <p><strong>Phone:</strong> (555) 123-4567</p>
                            <p><strong>Email:</strong> cnergyfitnessgym@cnergy.site</p>
                        </div>
                    </div>
                </div>
                
                <!-- Footer -->
                <div class='footer'>
                    <div class='footer-brand'>CNERGY GYM</div>
                    <div class='footer-tagline'>Transform Your Fitness Journey</div>
                    <div class='footer-copyright'>&copy; $currentYear CNERGY GYM. All rights reserved.</div>
                    <div class='footer-disclaimer'>
                        This email was sent to " . htmlspecialchars($userDetails['email'] ?? '') . " because you created an account with CNERGY GYM.
                        If you did not create this account, please contact us immediately.
                    </div>
                </div>
            </div>
        </body>
        </html>";
    }
    
    private function createTestEmailTemplate($userName) {
        return "
        <!DOCTYPE html>
        <html lang='en'>
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
            <title>Test Email - CNERGY GYM</title>
            <style>
                body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    line-height: 1.6;
                    color: #333333;
                    background-color: #f8f9fa;
                    margin: 0;
                    padding: 20px;
                }
                
                .container {
                    max-width: 600px;
                    margin: 0 auto;
                    background-color: #ffffff;
                    border-radius: 12px;
                    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                    overflow: hidden;
                }
                
                .header {
                    background: linear-gradient(135deg, #FF6B35 0%, #FF8E53 100%);
                    padding: 30px;
                    text-align: center;
                    color: white;
                }
                
                .header h1 {
                    margin: 0;
                    font-size: 28px;
                    font-weight: 700;
                    letter-spacing: 1px;
                }
                
                .content {
                    padding: 40px 30px;
                    text-align: center;
                }
                
                .test-badge {
                    display: inline-block;
                    background: linear-gradient(135deg, #28a745 0%, #34ce57 100%);
                    color: white;
                    padding: 8px 16px;
                    border-radius: 20px;
                    font-size: 12px;
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    margin-bottom: 20px;
                }
                
                .message {
                    font-size: 18px;
                    color: #2c3e50;
                    margin-bottom: 20px;
                }
                
                .success-icon {
                    font-size: 48px;
                    margin-bottom: 20px;
                }
                
                .footer {
                    background: #2c3e50;
                    color: #ecf0f1;
                    text-align: center;
                    padding: 20px;
                    font-size: 14px;
                }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h1>CNERGY GYM</h1>
                </div>
                <div class='content'>
                    <div class='test-badge'>Test Email</div>
                    <div class='success-icon'>✅</div>
                    <h2>Hello, " . htmlspecialchars($userName) . "!</h2>
                    <p class='message'>
                        This is a test email from the CNERGY GYM registration system.
                        If you received this message, the email service is working correctly!
                    </p>
                    <p>Email system status: <strong style='color: #28a745;'>OPERATIONAL</strong></p>
                </div>
                <div class='footer'>
                    <p>&copy; " . date('Y') . " CNERGY GYM. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>";
    }
    
    private function createPlainTextWelcome($userName) {
        return "
        WELCOME TO CNERGY GYM!
        
        Hello $userName!
        
        Congratulations! Your CNERGY GYM account has been created successfully.
        We're excited to have you join our fitness community.
        
        NEXT STEPS:
        1. Visit our front desk during business hours
        2. Bring a valid government-issued photo ID
        3. Complete your account verification
        4. Start your fitness journey!
        
        GYM INFORMATION:
        Address: 123 Fitness Street, Gym City, GC 12345
        Phone: (555) 123-4567
        Email: cnergyfitnessgym@cnergy.site
        
        BUSINESS HOURS:
        Monday - Friday: 6:00 AM - 10:00 PM
        Saturday - Sunday: 7:00 AM - 9:00 PM
        
        Questions? Contact us at cnergyfitnessgym@cnergy.site or call (555) 123-4567
        
        Thank you for choosing CNERGY GYM!
        Transform Your Fitness Journey
        ";
    }
    
    // ========================================
    // SUBSCRIPTION EXPIRY EMAIL SYSTEM
    // ========================================
    
    /**
     * Send subscription expiry reminder email
     * @param string $userEmail - User's email address
     * @param string $userName - User's name
     * @param int $daysRemaining - Days remaining until expiry
     * @param string $expiryDate - Expiry date
     * @param array $subscriptionDetails - Additional subscription details
     * @return array - Success/failure response
     */
    public function sendSubscriptionExpiryEmail($userEmail, $userName, $daysRemaining, $expiryDate, $subscriptionDetails = []) {
        if (!$this->isConfigured) {
            return ['success' => false, 'message' => 'Email service not properly configured'];
        }
        
        try {
            // Determine email type based on days remaining
            $emailType = $this->getExpiryEmailType($daysRemaining);
            
            // Email content
            $subject = $this->getExpiryEmailSubject($daysRemaining);
            $htmlBody = $this->createExpiryEmailTemplate($userName, $daysRemaining, $expiryDate, $subscriptionDetails, $emailType);
            $textBody = $this->createExpiryPlainText($userName, $daysRemaining, $expiryDate, $subscriptionDetails, $emailType);
            
            // Email headers and message
            $emailData = $this->createEmailHeaders($userEmail, $userName, $htmlBody, $textBody);
            
            // Add some debugging
            error_log("Attempting to send subscription expiry email to: " . $userEmail . " (Days remaining: " . $daysRemaining . ")");
            error_log("Email subject: " . $subject);
            
            // Send email using PHP's built-in mail() function
            $success = mail($userEmail, $subject, $emailData['message'], $emailData['headers']);
            
            if ($success) {
                error_log("Subscription expiry email sent successfully to: " . $userEmail);
                return ['success' => true, 'message' => 'Subscription expiry email sent successfully'];
            } else {
                error_log("Failed to send subscription expiry email to: " . $userEmail);
                return ['success' => false, 'message' => 'Failed to send subscription expiry email - mail() function returned false'];
            }
            
        } catch (Exception $e) {
            error_log("Subscription expiry email sending failed to " . $userEmail . ": " . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to send subscription expiry email: ' . $e->getMessage()];
        }
    }
    
    /**
     * Check all active subscriptions and send appropriate expiry emails
     * This method should be called by a cron job or scheduled task
     * @return array - Summary of emails sent
     */
    public function checkAndSendExpiryEmails() {
        try {
            // Include database connection
            require_once 'db.php';
            
            $summary = [
                'total_checked' => 0,
                'emails_sent' => 0,
                'errors' => 0,
                'details' => []
            ];
            
            // Get all active subscriptions that are expiring soon
            $query = "
                SELECT 
                    s.id,
                    s.user_id,
                    s.end_date,
                    s.plan_id,
                    u.fname,
                    u.lname,
                    u.email,
                    msp.plan_name,
                    msp.price,
                    DATEDIFF(s.end_date, CURDATE()) as days_remaining
                FROM subscription s
                JOIN user u ON s.user_id = u.id
                JOIN member_subscription_plan msp ON s.plan_id = msp.id
                WHERE s.status_id = 2 
                AND s.end_date >= CURDATE()
                AND DATEDIFF(s.end_date, CURDATE()) IN (14, 7, 3, 1)
                ORDER BY s.end_date ASC
            ";
            
            $result = $conn->query($query);
            
            if (!$result) {
                throw new Exception("Database query failed: " . $conn->error);
            }
            
            $summary['total_checked'] = $result->num_rows;
            
            while ($row = $result->fetch_assoc()) {
                $userName = $row['fname'] . ' ' . $row['lname'];
                $subscriptionDetails = [
                    'plan_name' => $row['plan_name'],
                    'price' => $row['price'],
                    'subscription_id' => $row['id']
                ];
                
                $emailResult = $this->sendSubscriptionExpiryEmail(
                    $row['email'],
                    $userName,
                    $row['days_remaining'],
                    $row['end_date'],
                    $subscriptionDetails
                );
                
                if ($emailResult['success']) {
                    $summary['emails_sent']++;
                    $summary['details'][] = [
                        'user' => $userName,
                        'email' => $row['email'],
                        'days_remaining' => $row['days_remaining'],
                        'status' => 'sent'
                    ];
                } else {
                    $summary['errors']++;
                    $summary['details'][] = [
                        'user' => $userName,
                        'email' => $row['email'],
                        'days_remaining' => $row['days_remaining'],
                        'status' => 'failed',
                        'error' => $emailResult['message']
                    ];
                }
            }
            
            error_log("Subscription expiry check completed. Total: " . $summary['total_checked'] . ", Sent: " . $summary['emails_sent'] . ", Errors: " . $summary['errors']);
            
            return $summary;
            
        } catch (Exception $e) {
            error_log("Subscription expiry check failed: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Failed to check subscription expiry: ' . $e->getMessage(),
                'total_checked' => 0,
                'emails_sent' => 0,
                'errors' => 1
            ];
        }
    }
    
    /**
     * Get the type of expiry email based on days remaining
     * @param int $daysRemaining
     * @return string
     */
    private function getExpiryEmailType($daysRemaining) {
        switch ($daysRemaining) {
            case 14:
                return 'two_weeks';
            case 7:
                return 'one_week';
            case 3:
                return 'three_days';
            case 1:
                return 'one_day';
            default:
                return 'general';
        }
    }
    
    /**
     * Get the email subject based on days remaining
     * @param int $daysRemaining
     * @return string
     */
    private function getExpiryEmailSubject($daysRemaining) {
        switch ($daysRemaining) {
            case 14:
                return 'CNERGY GYM - Your Membership Expires in 2 Weeks';
            case 7:
                return 'CNERGY GYM - Your Membership Expires in 1 Week';
            case 3:
                return 'CNERGY GYM - Your Membership Expires in 3 Days';
            case 1:
                return 'CNERGY GYM - Your Membership Expires Tomorrow!';
            default:
                return 'CNERGY GYM - Membership Expiry Reminder';
        }
    }
    
    /**
     * Create HTML template for subscription expiry emails
     * @param string $userName
     * @param int $daysRemaining
     * @param string $expiryDate
     * @param array $subscriptionDetails
     * @param string $emailType
     * @return string
     */
    private function createExpiryEmailTemplate($userName, $daysRemaining, $expiryDate, $subscriptionDetails, $emailType) {
        $currentYear = date('Y');
        $urgencyLevel = $this->getUrgencyLevel($daysRemaining);
        $urgencyColor = $this->getUrgencyColor($daysRemaining);
        $callToActionText = $this->getCallToActionText($daysRemaining);
        
        return "
        <!DOCTYPE html>
        <html lang='en'>
        <head>
            <meta charset='UTF-8'>
            <meta name='viewport' content='width=device-width, initial-scale=1.0'>
            <title>Membership Expiry - CNERGY GYM</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    line-height: 1.6;
                    color: #333333;
                    background-color: #f8f9fa;
                }
                
                .email-container {
                    max-width: 600px;
                    margin: 0 auto;
                    background-color: #ffffff;
                    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                }
                
                .header {
                    background: linear-gradient(135deg, {$urgencyColor} 0%, #FF8E53 100%);
                    padding: 40px 30px;
                    text-align: center;
                    position: relative;
                    overflow: hidden;
                }
                
                .logo h1 {
                    color: #ffffff;
                    font-size: 32px;
                    font-weight: 700;
                    margin-bottom: 8px;
                    letter-spacing: 2px;
                    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
                }
                
                .logo p {
                    color: #ffffff;
                    font-size: 16px;
                    font-weight: 400;
                    opacity: 0.95;
                    margin: 0;
                }
                
                .urgency-badge {
                    display: inline-block;
                    background: rgba(255, 255, 255, 0.2);
                    color: #ffffff;
                    padding: 8px 16px;
                    border-radius: 20px;
                    font-size: 14px;
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    margin-top: 16px;
                }
                
                .content {
                    padding: 40px 30px;
                }
                
                .alert-section {
                    text-align: center;
                    margin-bottom: 40px;
                }
                
                .alert-icon {
                    font-size: 64px;
                    margin-bottom: 20px;
                }
                
                .alert-title {
                    font-size: 28px;
                    font-weight: 600;
                    color: #2c3e50;
                    margin-bottom: 16px;
                }
                
                .alert-subtitle {
                    font-size: 18px;
                    color: #7f8c8d;
                    margin-bottom: 24px;
                }
                
                .alert-message {
                    font-size: 16px;
                    color: #34495e;
                    line-height: 1.7;
                    max-width: 500px;
                    margin: 0 auto;
                }
                
                .subscription-card {
                    background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
                    border-radius: 12px;
                    padding: 24px;
                    margin: 32px 0;
                    border-left: 4px solid {$urgencyColor};
                }
                
                .subscription-card h3 {
                    color: {$urgencyColor};
                    font-size: 18px;
                    font-weight: 600;
                    margin-bottom: 16px;
                }
                
                .info-row {
                    display: flex;
                    justify-content: space-between;
                    margin-bottom: 8px;
                    padding: 4px 0;
                }
                
                .info-label {
                    font-weight: 600;
                    color: #2c3e50;
                }
                
                .info-value {
                    color: #7f8c8d;
                }
                
                .expiry-highlight {
                    background: {$urgencyColor};
                    color: #ffffff;
                    padding: 4px 12px;
                    border-radius: 20px;
                    font-size: 12px;
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
                
                .cta-section {
                    background: #ffffff;
                    border: 2px solid {$urgencyColor};
                    border-radius: 12px;
                    padding: 32px;
                    margin: 32px 0;
                    text-align: center;
                }
                
                .cta-title {
                    font-size: 20px;
                    font-weight: 600;
                    color: #2c3e50;
                    margin-bottom: 16px;
                }
                
                .cta-button {
                    display: inline-block;
                    background: linear-gradient(135deg, {$urgencyColor} 0%, #FF8E53 100%);
                    color: #ffffff;
                    padding: 16px 32px;
                    border-radius: 8px;
                    text-decoration: none;
                    font-weight: 600;
                    font-size: 16px;
                    margin: 16px 0;
                    transition: transform 0.2s ease;
                }
                
                .cta-button:hover {
                    transform: translateY(-2px);
                }
                
                .contact-section {
                    background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
                    border-radius: 12px;
                    padding: 24px;
                    margin: 32px 0;
                    text-align: center;
                }
                
                .contact-title {
                    font-size: 18px;
                    font-weight: 600;
                    color: #1565c0;
                    margin-bottom: 16px;
                }
                
                .contact-info {
                    color: #1976d2;
                    font-size: 14px;
                    line-height: 1.6;
                }
                
                .contact-info strong {
                    color: #0d47a1;
                }
                
                .footer {
                    background: #2c3e50;
                    color: #ecf0f1;
                    text-align: center;
                    padding: 32px 30px;
                }
                
                .footer-brand {
                    font-size: 20px;
                    font-weight: 700;
                    margin-bottom: 8px;
                    letter-spacing: 1px;
                }
                
                .footer-tagline {
                    font-size: 14px;
                    opacity: 0.8;
                    margin-bottom: 16px;
                }
                
                .footer-copyright {
                    font-size: 12px;
                    opacity: 0.6;
                    margin-bottom: 8px;
                }
                
                .footer-disclaimer {
                    font-size: 11px;
                    opacity: 0.5;
                    line-height: 1.4;
                    max-width: 400px;
                    margin: 0 auto;
                }
            </style>
        </head>
        <body>
            <div class='email-container'>
                <!-- Header -->
                <div class='header'>
                    <div class='logo'>
                        <h1>CNERGY GYM</h1>
                        <p>Transform Your Fitness Journey</p>
                        <div class='urgency-badge'>{$urgencyLevel}</div>
                    </div>
                </div>
                
                <!-- Main Content -->
                <div class='content'>
                    <!-- Alert Section -->
                    <div class='alert-section'>
                        <div class='alert-icon'>" . $this->getAlertIcon($daysRemaining) . "</div>
                        <h2 class='alert-title'>" . $this->getAlertTitle($daysRemaining) . "</h2>
                        <p class='alert-subtitle'>" . $this->getAlertSubtitle($daysRemaining) . "</p>
                        <p class='alert-message'>
                            " . $this->getAlertMessage($userName, $daysRemaining) . "
                        </p>
                    </div>
                    
                    <!-- Subscription Info Card -->
                    <div class='subscription-card'>
                        <h3>Membership Details</h3>
                        <div class='info-row'>
                            <span class='info-label'>Member:</span>
                            <span class='info-value'>" . htmlspecialchars($userName) . "</span>
                        </div>
                        <div class='info-row'>
                            <span class='info-label'>Plan:</span>
                            <span class='info-value'>" . htmlspecialchars($subscriptionDetails['plan_name'] ?? 'N/A') . "</span>
                        </div>
                        <div class='info-row'>
                            <span class='info-label'>Monthly Fee:</span>
                            <span class='info-value'>₱" . number_format($subscriptionDetails['price'] ?? 0, 2) . "</span>
                        </div>
                        <div class='info-row'>
                            <span class='info-label'>Expiry Date:</span>
                            <span class='expiry-highlight'>" . date('F j, Y', strtotime($expiryDate)) . "</span>
                        </div>
                        <div class='info-row'>
                            <span class='info-label'>Days Remaining:</span>
                            <span class='expiry-highlight'>{$daysRemaining} " . ($daysRemaining == 1 ? 'Day' : 'Days') . "</span>
                        </div>
                    </div>
                    
                    <!-- Call to Action -->
                    <div class='cta-section'>
                        <h3 class='cta-title'>{$callToActionText}</h3>
                        <p>Don't let your fitness journey pause! Renew your membership now to continue enjoying all our premium facilities and services.</p>
                        <a href='#' class='cta-button'>Renew Membership Now</a>
                        <p style='font-size: 14px; color: #7f8c8d; margin-top: 16px;'>
                            Visit our front desk or contact us to renew your membership
                        </p>
                    </div>
                    
                    <!-- Contact Information -->
                    <div class='contact-section'>
                        <h3 class='contact-title'>Need Help?</h3>
                        <div class='contact-info'>
                            <p><strong>Address:</strong> 123 Fitness Street, Gym City, GC 12345</p>
                            <p><strong>Phone:</strong> (555) 123-4567</p>
                            <p><strong>Email:</strong> cnergyfitnessgym@cnergy.site</p>
                            <p><strong>Business Hours:</strong> Mon-Fri: 6AM-10PM, Sat-Sun: 7AM-9PM</p>
                        </div>
                    </div>
                </div>
                
                <!-- Footer -->
                <div class='footer'>
                    <div class='footer-brand'>CNERGY GYM</div>
                    <div class='footer-tagline'>Transform Your Fitness Journey</div>
                    <div class='footer-copyright'>&copy; $currentYear CNERGY GYM. All rights reserved.</div>
                    <div class='footer-disclaimer'>
                        This email was sent to " . htmlspecialchars($userName) . " regarding your membership expiry.
                        If you have already renewed, please ignore this email.
                    </div>
                </div>
            </div>
        </body>
        </html>";
    }
    
    /**
     * Create plain text version of subscription expiry email
     * @param string $userName
     * @param int $daysRemaining
     * @param string $expiryDate
     * @param array $subscriptionDetails
     * @param string $emailType
     * @return string
     */
    private function createExpiryPlainText($userName, $daysRemaining, $expiryDate, $subscriptionDetails, $emailType) {
        $urgencyLevel = $this->getUrgencyLevel($daysRemaining);
        $callToActionText = $this->getCallToActionText($daysRemaining);
        
        return "
        CNERGY GYM - MEMBERSHIP EXPIRY NOTICE
        =====================================
        
        Hello $userName!
        
        {$urgencyLevel} - Your CNERGY GYM membership is expiring soon!
        
        MEMBERSHIP DETAILS:
        - Plan: " . ($subscriptionDetails['plan_name'] ?? 'N/A') . "
        - Monthly Fee: ₱" . number_format($subscriptionDetails['price'] ?? 0, 2) . "
        - Expiry Date: " . date('F j, Y', strtotime($expiryDate)) . "
        - Days Remaining: $daysRemaining " . ($daysRemaining == 1 ? 'Day' : 'Days') . "
        
        {$callToActionText}
        
        Don't let your fitness journey pause! Renew your membership now to continue enjoying:
        - Access to all gym facilities
        - Premium equipment
        - Expert trainer guidance
        - Group fitness classes
        - Locker room access
        
        HOW TO RENEW:
        1. Visit our front desk during business hours
        2. Call us at (555) 123-4567
        3. Email us at cnergyfitnessgym@cnergy.site
        
        GYM INFORMATION:
        Address: 123 Fitness Street, Gym City, GC 12345
        Phone: (555) 123-4567
        Email: cnergyfitnessgym@cnergy.site
        
        BUSINESS HOURS:
        Monday - Friday: 6:00 AM - 10:00 PM
        Saturday - Sunday: 7:00 AM - 9:00 PM
        
        Thank you for being a valued member of CNERGY GYM!
        Transform Your Fitness Journey
        
        ---
        This email was sent regarding your membership expiry.
        If you have already renewed, please ignore this email.
        ";
    }
    
    /**
     * Get urgency level based on days remaining
     * @param int $daysRemaining
     * @return string
     */
    private function getUrgencyLevel($daysRemaining) {
        switch ($daysRemaining) {
            case 14:
                return 'Gentle Reminder';
            case 7:
                return 'Important Notice';
            case 3:
                return 'Urgent Reminder';
            case 1:
                return 'Final Notice';
            default:
                return 'Reminder';
        }
    }
    
    /**
     * Get urgency color based on days remaining
     * @param int $daysRemaining
     * @return string
     */
    private function getUrgencyColor($daysRemaining) {
        switch ($daysRemaining) {
            case 14:
                return '#28a745'; // Green
            case 7:
                return '#ffc107'; // Yellow
            case 3:
                return '#fd7e14'; // Orange
            case 1:
                return '#dc3545'; // Red
            default:
                return '#FF6B35'; // Default orange
        }
    }
    
    /**
     * Get call to action text based on days remaining
     * @param int $daysRemaining
     * @return string
     */
    private function getCallToActionText($daysRemaining) {
        switch ($daysRemaining) {
            case 14:
                return 'Plan Your Renewal';
            case 7:
                return 'Renew This Week';
            case 3:
                return 'Renew Now - Time is Running Out!';
            case 1:
                return 'URGENT: Renew Today to Avoid Service Interruption!';
            default:
                return 'Renew Your Membership';
        }
    }
    
    /**
     * Get alert icon based on days remaining
     * @param int $daysRemaining
     * @return string
     */
    private function getAlertIcon($daysRemaining) {
        switch ($daysRemaining) {
            case 14:
                return '📅';
            case 7:
                return '⚠️';
            case 3:
                return '🚨';
            case 1:
                return '🔥';
            default:
                return '📢';
        }
    }
    
    /**
     * Get alert title based on days remaining
     * @param int $daysRemaining
     * @return string
     */
    private function getAlertTitle($daysRemaining) {
        switch ($daysRemaining) {
            case 14:
                return 'Your Membership Expires in 2 Weeks';
            case 7:
                return 'Your Membership Expires in 1 Week';
            case 3:
                return 'Your Membership Expires in 3 Days';
            case 1:
                return 'Your Membership Expires Tomorrow!';
            default:
                return 'Membership Expiry Reminder';
        }
    }
    
    /**
     * Get alert subtitle based on days remaining
     * @param int $daysRemaining
     * @return string
     */
    private function getAlertSubtitle($daysRemaining) {
        switch ($daysRemaining) {
            case 14:
                return 'Time to plan your renewal';
            case 7:
                return 'Don\'t miss out on your fitness goals';
            case 3:
                return 'Last chance to renew without interruption';
            case 1:
                return 'Final day to renew your membership';
            default:
                return 'Please renew your membership';
        }
    }
    
    /**
     * Get alert message based on days remaining
     * @param string $userName
     * @param int $daysRemaining
     * @return string
     */
    private function getAlertMessage($userName, $daysRemaining) {
        switch ($daysRemaining) {
            case 14:
                return "Hi $userName, we wanted to give you a friendly heads up that your CNERGY GYM membership will expire in 2 weeks. This is a great time to plan your renewal and continue your fitness journey without any interruption.";
            case 7:
                return "Hi $userName, your CNERGY GYM membership expires in 1 week. We'd love to keep you as part of our fitness community. Renew now to avoid any service interruption and continue achieving your fitness goals.";
            case 3:
                return "Hi $userName, your CNERGY GYM membership expires in just 3 days! Don't let your fitness momentum slow down. Renew now to ensure uninterrupted access to all our premium facilities and services.";
            case 1:
                return "Hi $userName, this is your final reminder - your CNERGY GYM membership expires tomorrow! Renew today to avoid any service interruption and keep your fitness journey on track.";
            default:
                return "Hi $userName, your CNERGY GYM membership is expiring soon. Please renew to continue enjoying all our premium facilities and services.";
        }
    }
}
?>

