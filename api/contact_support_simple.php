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
        // Use the existing email service
        $emailServicePath = __DIR__ . '/email_service.php';
        if (!file_exists($emailServicePath)) {
            throw new Exception("Email service file not found");
        }
        
        require_once $emailServicePath;
        
        if (!class_exists('EmailService')) {
            throw new Exception("EmailService class not found");
        }
        
        $emailService = new EmailService();
        
        // Send notification email to admin
        $adminEmailResult = sendSupportNotificationToAdmin($emailService, $userEmail, $subject, $message);
        
        // Send confirmation email to user
        $userEmailResult = sendConfirmationToUser($emailService, $userEmail, $subject);
        
        // Log support request to database
        logSupportRequest($pdo, $userEmail, $subject, $message);
        
        if ($adminEmailResult['success']) {
            echo json_encode([
                'success' => true, 
                'message' => 'Your support request has been sent successfully. We will get back to you within 24 hours.'
            ]);
        } else {
            echo json_encode([
                'success' => false, 
                'message' => 'Failed to send support request. Please try again or contact us directly at cnergyfitnessgym@cnergy.site'
            ]);
        }
        
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
 * Send support notification email to admin
 */
function sendSupportNotificationToAdmin($emailService, $userEmail, $subject, $message) {
    try {
        // Create email content for admin
        $adminSubject = '[SUPPORT REQUEST] ' . $subject;
        $adminMessage = createAdminNotificationMessage($userEmail, $subject, $message);
        
        // Send email to admin using existing email service
        $result = $emailService->sendSupportEmail(
            'cnergyfitnessgym@cnergy.site',  // Admin email
            'CNERGY GYM Support Team',       // Admin name
            $adminSubject,                   // Subject
            $adminMessage,                   // Message
            $userEmail                       // Reply-to email
        );
        
        error_log("Admin notification email result: " . json_encode($result));
        return $result;
        
    } catch (Exception $e) {
        error_log("Failed to send admin notification: " . $e->getMessage());
        return ['success' => false, 'message' => $e->getMessage()];
    }
}

/**
 * Send confirmation email to user
 */
function sendConfirmationToUser($emailService, $userEmail, $subject) {
    try {
        $confirmationSubject = 'Support Request Received - CNERGY GYM';
        $confirmationMessage = createUserConfirmationMessage($userEmail, $subject);
        
        $result = $emailService->sendSupportEmail(
            $userEmail,                      // User email
            'Customer',                       // User name
            $confirmationSubject,            // Subject
            $confirmationMessage,            // Message
            'cnergyfitnessgym@cnergy.site'   // Reply-to admin email
        );
        
        error_log("User confirmation email result: " . json_encode($result));
        return $result;
        
    } catch (Exception $e) {
        error_log("Failed to send user confirmation: " . $e->getMessage());
        return ['success' => false, 'message' => $e->getMessage()];
    }
}

/**
 * Create admin notification message
 */
function createAdminNotificationMessage($userEmail, $subject, $message) {
    $timestamp = date('F j, Y \a\t g:i A');
    
    return "
    🚨 NEW SUPPORT REQUEST - ACCOUNT DEACTIVATION 🚨
    
    A customer has contacted support regarding account deactivation.
    
    CUSTOMER DETAILS:
    Email: {$userEmail}
    Subject: {$subject}
    Time: {$timestamp}
    Source: Mobile App - Account Deactivation Page
    
    CUSTOMER MESSAGE:
    {$message}
    
    ⚠️ PRIORITY NOTICE:
    This request is from the account deactivation page. The customer's account has been deactivated and they are seeking assistance. Please prioritize this request and respond within 24 hours.
    
    📧 HOW TO RESPOND:
    1. Reply directly to this email
    2. The customer's email ({$userEmail}) will be automatically filled in the 'To' field
    3. Type your response and send
    4. The customer will receive your reply directly
    
    ---
    CNERGY GYM Support System
    Transform Your Fitness Journey
    ";
}

/**
 * Create user confirmation message
 */
function createUserConfirmationMessage($userEmail, $subject) {
    $timestamp = date('F j, Y \a\t g:i A');
    
    return "
    ✅ SUPPORT REQUEST RECEIVED
    
    Hello,
    
    Thank you for contacting CNERGY GYM support. We have received your request regarding account deactivation.
    
    REQUEST DETAILS:
    Email: {$userEmail}
    Subject: {$subject}
    Submitted: {$timestamp}
    Status: Under Review
    
    WHAT HAPPENS NEXT:
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
?>





