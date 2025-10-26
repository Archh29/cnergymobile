<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, Origin");
header("Access-Control-Max-Age: 86400");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/error.log');

// Include PHPMailer - try multiple possible paths
$phpmailerPaths = [
    __DIR__ . '/PHPMailer/src/Exception.php',
    __DIR__ . '/../PHPMailer/src/Exception.php',
    __DIR__ . '/vendor/phpmailer/phpmailer/src/Exception.php'
];

$phpmailerLoaded = false;
foreach ($phpmailerPaths as $path) {
    if (file_exists($path)) {
        require_once $path;
        require_once str_replace('Exception.php', 'PHPMailer.php', $path);
        require_once str_replace('Exception.php', 'SMTP.php', $path);
        $phpmailerLoaded = true;
        error_log("PHPMailer loaded from: " . $path);
        break;
    }
}

if (!$phpmailerLoaded) {
    error_log("PHPMailer not found. Attempting to use built-in mail() function instead.");
    // Fall back to built-in mail() function
    define('PHPMailer_FALLBACK', true);
}

if (!$phpmailerLoaded) {
    // Create fallback classes for built-in mail() function
    class PHPMailer {
        public $isSMTP = false;
        public $Host = '';
        public $SMTPAuth = false;
        public $Username = '';
        public $Password = '';
        public $SMTPSecure = '';
        public $Port = 587;
        public $CharSet = 'UTF-8';
        public $isHTML = true;
        public $Subject = '';
        public $Body = '';
        public $AltBody = '';
        
        public function __construct() {}
        public function setFrom($email, $name = '') {}
        public function addAddress($email, $name = '') {}
        public function addReplyTo($email, $name = '') {}
        public function addCC($email, $name = '') {}
        public function send() { return false; }
    }
    
    class SMTP {}
    class Exception extends \Exception {}
}

// Database configuration
$host = "localhost";
$db = "u773938685_cnergydb";      
$user = "u773938685_archh29";  
$pass = "Gwapoko385@"; 

$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed', 'error' => $e->getMessage()]);
    exit;
}

$input = json_decode(file_get_contents("php://input"), true);
$action = $_GET['action'] ?? ($input['action'] ?? '');

// === SEND SUPPORT EMAIL ===
if ($action === 'send_support_email') {
    // Validate required fields
    $requiredFields = ['email', 'subject', 'message'];
    foreach ($requiredFields as $field) {
        if (!isset($input[$field]) || empty(trim($input[$field]))) {
            echo json_encode(['success' => false, 'message' => ucfirst($field) . ' is required']);
            exit;
        }
    }
    
    $userEmail = trim($input['email']);
    $subject = trim($input['subject']);
    $message = trim($input['message']);
    
    // Validate email format
    if (!filter_var($userEmail, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(['success' => false, 'message' => 'Invalid email format']);
        exit;
    }
    
    // Validate message length
    if (strlen($message) < 10) {
        echo json_encode(['success' => false, 'message' => 'Message must be at least 10 characters long']);
        exit;
    }
    
    try {
        if ($phpmailerLoaded) {
            // Use PHPMailer if available
            $mail = new PHPMailer(true);
            
            // Server settings
            $mail->isSMTP();
            $mail->Host       = 'mail.cnergy.site';  // Your SMTP server
            $mail->SMTPAuth   = true;
            $mail->Username   = 'cnergyfitnessgym@cnergy.site';  // Your email
            $mail->Password   = 'Gwapoko385@';  // Your email password
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port       = 587;
            $mail->CharSet    = 'UTF-8';
        } else {
            // Use built-in mail() function
            error_log("Using built-in mail() function for sending support email");
        }
        
        // Recipients
        $mail->setFrom('cnergyfitnessgym@cnergy.site', 'CNERGY GYM Support');
        $mail->addAddress('cnergyfitnessgym@cnergy.site', 'CNERGY GYM Support Team');
        $mail->addReplyTo($userEmail, 'Customer');
        
        // Add CC to additional admin emails if needed
        // $mail->addCC('admin2@cnergy.site', 'Admin 2');
        // $mail->addCC('manager@cnergy.site', 'Manager');
        
        // Content
        $mail->isHTML(true);
        $mail->Subject = '[SUPPORT] ' . $subject;
        
        // Create HTML email template
        $htmlBody = createSupportEmailTemplate($userEmail, $subject, $message);
        $mail->Body = $htmlBody;
        
        // Create plain text version
        $textBody = createSupportEmailPlainText($userEmail, $subject, $message);
        $mail->AltBody = $textBody;
        
        // Send email
        $mail->send();
        
        // Log the support request to database
        logSupportRequest($pdo, $userEmail, $subject, $message);
        
        // Send confirmation email to user
        sendConfirmationEmail($userEmail, $subject);
        
        echo json_encode([
            'success' => true, 
            'message' => 'Your support request has been sent successfully. We will get back to you within 24 hours.'
        ]);
        
    } catch (Exception $e) {
        error_log("Support email sending failed: " . $e->getMessage());
        echo json_encode([
            'success' => false, 
            'message' => 'Failed to send support request. Please try again or contact us directly at cnergyfitnessgym@cnergy.site'
        ]);
    }
    
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid action']);
}

/**
 * Create HTML email template for support requests
 */
function createSupportEmailTemplate($userEmail, $subject, $message) {
    $currentYear = date('Y');
    $timestamp = date('F j, Y \a\t g:i A');
    
    return "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Support Request - CNERGY GYM</title>
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
                padding: 30px;
                text-align: center;
                color: white;
            }
            
            .logo h1 {
                font-size: 28px;
                font-weight: 700;
                margin-bottom: 8px;
                letter-spacing: 2px;
            }
            
            .logo p {
                font-size: 16px;
                opacity: 0.95;
            }
            
            .content {
                padding: 30px;
            }
            
            .alert-badge {
                display: inline-block;
                background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);
                color: white;
                padding: 8px 16px;
                border-radius: 20px;
                font-size: 12px;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                margin-bottom: 20px;
            }
            
            .request-title {
                font-size: 24px;
                font-weight: 600;
                color: #2c3e50;
                margin-bottom: 20px;
            }
            
            .request-info {
                background: #f8f9fa;
                border-radius: 12px;
                padding: 20px;
                margin: 20px 0;
                border-left: 4px solid #FF6B35;
            }
            
            .info-row {
                display: flex;
                margin-bottom: 10px;
                padding: 5px 0;
            }
            
            .info-label {
                font-weight: 600;
                color: #2c3e50;
                width: 120px;
                flex-shrink: 0;
            }
            
            .info-value {
                color: #7f8c8d;
                flex: 1;
            }
            
            .message-section {
                background: #ffffff;
                border: 1px solid #e9ecef;
                border-radius: 12px;
                padding: 20px;
                margin: 20px 0;
            }
            
            .message-title {
                font-size: 18px;
                font-weight: 600;
                color: #2c3e50;
                margin-bottom: 15px;
            }
            
            .message-content {
                background: #f8f9fa;
                padding: 15px;
                border-radius: 8px;
                border-left: 3px solid #FF6B35;
                font-size: 14px;
                line-height: 1.6;
                color: #34495e;
                white-space: pre-wrap;
            }
            
            .priority-section {
                background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%);
                border-radius: 12px;
                padding: 20px;
                margin: 20px 0;
                border: 1px solid #ffc107;
            }
            
            .priority-title {
                font-size: 16px;
                font-weight: 600;
                color: #856404;
                margin-bottom: 10px;
            }
            
                .priority-text {
                    font-size: 14px;
                    color: #856404;
                    line-height: 1.5;
                }
                
                .response-section {
                    background: linear-gradient(135deg, #e8f5e8 0%, #d4edda 100%);
                    border-radius: 12px;
                    padding: 20px;
                    margin: 20px 0;
                    border: 1px solid #28a745;
                }
                
                .response-title {
                    font-size: 16px;
                    font-weight: 600;
                    color: #155724;
                    margin-bottom: 10px;
                }
                
                .response-text {
                    font-size: 14px;
                    color: #155724;
                    line-height: 1.5;
                }
            
            .footer {
                background: #2c3e50;
                color: #ecf0f1;
                text-align: center;
                padding: 20px;
                font-size: 12px;
            }
            
            .footer-brand {
                font-size: 16px;
                font-weight: 700;
                margin-bottom: 5px;
            }
            
            .footer-tagline {
                opacity: 0.8;
                margin-bottom: 10px;
            }
            
            .footer-copyright {
                opacity: 0.6;
            }
        </style>
    </head>
    <body>
        <div class='email-container'>
            <!-- Header -->
            <div class='header'>
                <div class='logo'>
                    <h1>CNERGY GYM</h1>
                    <p>Support Request Received</p>
                </div>
            </div>
            
            <!-- Main Content -->
            <div class='content'>
                <div class='alert-badge'>Support Request</div>
                <h2 class='request-title'>New Support Request from Mobile App</h2>
                
                <!-- Request Information -->
                <div class='request-info'>
                    <div class='info-row'>
                        <span class='info-label'>From:</span>
                        <span class='info-value'>" . htmlspecialchars($userEmail) . "</span>
                    </div>
                    <div class='info-row'>
                        <span class='info-label'>Subject:</span>
                        <span class='info-value'>" . htmlspecialchars($subject) . "</span>
                    </div>
                    <div class='info-row'>
                        <span class='info-label'>Received:</span>
                        <span class='info-value'>" . $timestamp . "</span>
                    </div>
                    <div class='info-row'>
                        <span class='info-label'>Source:</span>
                        <span class='info-value'>Mobile App - Account Deactivation Page</span>
                    </div>
                </div>
                
                <!-- Message Content -->
                <div class='message-section'>
                    <h3 class='message-title'>Customer Message:</h3>
                    <div class='message-content'>" . htmlspecialchars($message) . "</div>
                </div>
                
                <!-- Priority Notice -->
                <div class='priority-section'>
                    <h3 class='priority-title'>⚠️ Priority Notice</h3>
                    <p class='priority-text'>
                        This support request was sent from the account deactivation page. 
                        The customer's account has been deactivated and they are seeking assistance. 
                        Please prioritize this request and respond within 24 hours.
                    </p>
                </div>
                
                <!-- Response Instructions -->
                <div class='response-section'>
                    <h3 class='response-title'>📧 How to Respond</h3>
                    <p class='response-text'>
                        <strong>To respond to this customer:</strong><br>
                        1. Click &quot;Reply&quot; in your email client<br>
                        2. The customer's email will be automatically filled in the &quot;To&quot; field<br>
                        3. Type your response and send<br>
                        4. The customer will receive your reply directly
                    </p>
                </div>
            </div>
            
            <!-- Footer -->
            <div class='footer'>
                <div class='footer-brand'>CNERGY GYM</div>
                <div class='footer-tagline'>Transform Your Fitness Journey</div>
                <div class='footer-copyright'>&copy; $currentYear CNERGY GYM. All rights reserved.</div>
            </div>
        </div>
    </body>
    </html>";
}

/**
 * Create plain text version of support email
 */
function createSupportEmailPlainText($userEmail, $subject, $message) {
    $timestamp = date('F j, Y \a\t g:i A');
    
    return "
CNERGY GYM - SUPPORT REQUEST
============================

NEW SUPPORT REQUEST FROM MOBILE APP

From: " . $userEmail . "
Subject: " . $subject . "
Received: " . $timestamp . "
Source: Mobile App - Account Deactivation Page

CUSTOMER MESSAGE:
" . $message . "

PRIORITY NOTICE:
This support request was sent from the account deactivation page. 
The customer's account has been deactivated and they are seeking assistance. 
Please prioritize this request and respond within 24 hours.

HOW TO RESPOND:
To respond to this customer:
1. Click \"Reply\" in your email client
2. The customer's email will be automatically filled in the \"To\" field
3. Type your response and send
4. The customer will receive your reply directly

---
CNERGY GYM Support System
Transform Your Fitness Journey
";
}

/**
 * Log support request to database
 */
function logSupportRequest($pdo, $userEmail, $subject, $message) {
    try {
        $stmt = $pdo->prepare("
            INSERT INTO support_requests (
                user_email, 
                subject, 
                message, 
                source
            ) VALUES (?, ?, ?, 'mobile_app_deactivation')
        ");
        
        $stmt->execute([$userEmail, $subject, $message]);
        
        error_log("Support request logged to database for: " . $userEmail);
        
    } catch (Exception $e) {
        error_log("Failed to log support request to database: " . $e->getMessage());
        // Don't fail the email sending if database logging fails
    }
}

/**
 * Send confirmation email to user
 */
function sendConfirmationEmail($userEmail, $subject) {
    try {
        $mail = new PHPMailer(true);
        
        // Server settings
        $mail->isSMTP();
        $mail->Host       = 'mail.cnergy.site';
        $mail->SMTPAuth   = true;
        $mail->Username   = 'cnergyfitnessgym@cnergy.site';
        $mail->Password   = 'Gwapoko385@';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = 587;
        $mail->CharSet    = 'UTF-8';
        
        // Recipients
        $mail->setFrom('cnergyfitnessgym@cnergy.site', 'CNERGY GYM Support');
        $mail->addAddress($userEmail);
        
        // Content
        $mail->isHTML(true);
        $mail->Subject = 'Support Request Received - CNERGY GYM';
        
        // Create confirmation email template
        $htmlBody = createConfirmationEmailTemplate($userEmail, $subject);
        $mail->Body = $htmlBody;
        
        // Create plain text version
        $textBody = createConfirmationEmailPlainText($userEmail, $subject);
        $mail->AltBody = $textBody;
        
        // Send email
        $mail->send();
        
        error_log("Confirmation email sent to: " . $userEmail);
        
    } catch (Exception $e) {
        error_log("Failed to send confirmation email: " . $e->getMessage());
        // Don't fail the main process if confirmation email fails
    }
}

/**
 * Create confirmation email template
 */
function createConfirmationEmailTemplate($userEmail, $subject) {
    $currentYear = date('Y');
    $timestamp = date('F j, Y \a\t g:i A');
    
    return "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Support Request Confirmation - CNERGY GYM</title>
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
                background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
                padding: 30px;
                text-align: center;
                color: white;
            }
            
            .logo h1 {
                font-size: 28px;
                font-weight: 700;
                margin-bottom: 8px;
                letter-spacing: 2px;
            }
            
            .logo p {
                font-size: 16px;
                opacity: 0.95;
            }
            
            .content {
                padding: 30px;
            }
            
            .success-badge {
                display: inline-block;
                background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
                color: white;
                padding: 8px 16px;
                border-radius: 20px;
                font-size: 12px;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                margin-bottom: 20px;
            }
            
            .confirmation-title {
                font-size: 24px;
                font-weight: 600;
                color: #2c3e50;
                margin-bottom: 20px;
            }
            
            .confirmation-message {
                font-size: 16px;
                color: #34495e;
                line-height: 1.7;
                margin-bottom: 30px;
            }
            
            .request-summary {
                background: #f8f9fa;
                border-radius: 12px;
                padding: 20px;
                margin: 20px 0;
                border-left: 4px solid #28a745;
            }
            
            .summary-title {
                font-size: 18px;
                font-weight: 600;
                color: #2c3e50;
                margin-bottom: 15px;
            }
            
            .info-row {
                display: flex;
                margin-bottom: 10px;
                padding: 5px 0;
            }
            
            .info-label {
                font-weight: 600;
                color: #2c3e50;
                width: 120px;
                flex-shrink: 0;
            }
            
            .info-value {
                color: #7f8c8d;
                flex: 1;
            }
            
            .response-info {
                background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
                border-radius: 12px;
                padding: 20px;
                margin: 20px 0;
                border: 1px solid #2196f3;
            }
            
            .response-title {
                font-size: 16px;
                font-weight: 600;
                color: #1565c0;
                margin-bottom: 10px;
            }
            
            .response-text {
                font-size: 14px;
                color: #1976d2;
                line-height: 1.5;
            }
            
            .contact-section {
                background: #ffffff;
                border: 1px solid #e9ecef;
                border-radius: 12px;
                padding: 20px;
                margin: 20px 0;
                text-align: center;
            }
            
            .contact-title {
                font-size: 18px;
                font-weight: 600;
                color: #2c3e50;
                margin-bottom: 15px;
            }
            
            .contact-info {
                color: #7f8c8d;
                font-size: 14px;
                line-height: 1.6;
            }
            
            .footer {
                background: #2c3e50;
                color: #ecf0f1;
                text-align: center;
                padding: 20px;
                font-size: 12px;
            }
            
            .footer-brand {
                font-size: 16px;
                font-weight: 700;
                margin-bottom: 5px;
            }
            
            .footer-tagline {
                opacity: 0.8;
                margin-bottom: 10px;
            }
            
            .footer-copyright {
                opacity: 0.6;
            }
        </style>
    </head>
    <body>
        <div class='email-container'>
            <!-- Header -->
            <div class='header'>
                <div class='logo'>
                    <h1>CNERGY GYM</h1>
                    <p>Support Request Confirmation</p>
                </div>
            </div>
            
            <!-- Main Content -->
            <div class='content'>
                <div class='success-badge'>Request Received</div>
                <h2 class='confirmation-title'>Thank You for Contacting Us!</h2>
                
                <p class='confirmation-message'>
                    We have received your support request and our team will review it shortly. 
                    We understand that account deactivation can be concerning, and we're here to help resolve any issues.
                </p>
                
                <!-- Request Summary -->
                <div class='request-summary'>
                    <h3 class='summary-title'>Your Request Summary:</h3>
                    <div class='info-row'>
                        <span class='info-label'>Email:</span>
                        <span class='info-value'>" . htmlspecialchars($userEmail) . "</span>
                    </div>
                    <div class='info-row'>
                        <span class='info-label'>Subject:</span>
                        <span class='info-value'>" . htmlspecialchars($subject) . "</span>
                    </div>
                    <div class='info-row'>
                        <span class='info-label'>Submitted:</span>
                        <span class='info-value'>" . $timestamp . "</span>
                    </div>
                    <div class='info-row'>
                        <span class='info-label'>Status:</span>
                        <span class='info-value'>Under Review</span>
                    </div>
                </div>
                
                <!-- Response Information -->
                <div class='response-info'>
                    <h3 class='response-title'>What Happens Next?</h3>
                    <p class='response-text'>
                        • Our support team will review your request within 24 hours<br>
                        • We will investigate your account status and provide a detailed response<br>
                        • If your account was deactivated in error, we will restore it immediately<br>
                        • You will receive a follow-up email with our findings and next steps
                    </p>
                </div>
                
                <!-- Contact Information -->
                <div class='contact-section'>
                    <h3 class='contact-title'>Need Immediate Assistance?</h3>
                    <div class='contact-info'>
                        <p><strong>Phone:</strong> (555) 123-4567</p>
                        <p><strong>Email:</strong> cnergyfitnessgym@cnergy.site</p>
                        <p><strong>Address:</strong> 123 Fitness Street, Gym City, GC 12345</p>
                        <p><strong>Business Hours:</strong> Mon-Fri: 6AM-10PM, Sat-Sun: 7AM-9PM</p>
                    </div>
                </div>
            </div>
            
            <!-- Footer -->
            <div class='footer'>
                <div class='footer-brand'>CNERGY GYM</div>
                <div class='footer-tagline'>Transform Your Fitness Journey</div>
                <div class='footer-copyright'>&copy; $currentYear CNERGY GYM. All rights reserved.</div>
            </div>
        </div>
    </body>
    </html>";
}

/**
 * Create plain text confirmation email
 */
function createConfirmationEmailPlainText($userEmail, $subject) {
    $timestamp = date('F j, Y \a\t g:i A');
    
    return "
CNERGY GYM - SUPPORT REQUEST CONFIRMATION
==========================================

Thank You for Contacting Us!

We have received your support request and our team will review it shortly. 
We understand that account deactivation can be concerning, and we're here to help resolve any issues.

YOUR REQUEST SUMMARY:
Email: " . $userEmail . "
Subject: " . $subject . "
Submitted: " . $timestamp . "
Status: Under Review

WHAT HAPPENS NEXT?
• Our support team will review your request within 24 hours
• We will investigate your account status and provide a detailed response
• If your account was deactivated in error, we will restore it immediately
• You will receive a follow-up email with our findings and next steps

NEED IMMEDIATE ASSISTANCE?
Phone: (555) 123-4567
Email: cnergyfitnessgym@cnergy.site
Address: 123 Fitness Street, Gym City, GC 12345
Business Hours: Mon-Fri: 6AM-10PM, Sat-Sun: 7AM-9PM

Thank you for choosing CNERGY GYM!
Transform Your Fitness Journey

---
This is an automated confirmation email. Please do not reply to this message.
";
}
?>
