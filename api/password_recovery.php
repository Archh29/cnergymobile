<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration
$host = "localhost";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Function to send JSON response
function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

// Function to send error response
function sendError($message, $statusCode = 400) {
    http_response_code($statusCode);
    echo json_encode(['error' => $message], JSON_UNESCAPED_UNICODE);
    exit();
}

// Function to generate OTP
function generateOTP($length = 5) {
    return str_pad(rand(0, pow(10, $length) - 1), $length, '0', STR_PAD_LEFT);
}

// Include your existing email service
require_once 'email_service.php';

// Function to create HTML email template for password reset
function createPasswordResetEmailHTML($userName, $otp, $expiresInMinutes) {
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
            .header { background: linear-gradient(135deg, #4ECDC4 0%, #44A08D 100%); padding: 40px 30px; text-align: center; }
            .logo h1 { color: #ffffff; font-size: 32px; font-weight: 700; margin-bottom: 8px; letter-spacing: 2px; }
            .logo p { color: #ffffff; font-size: 16px; opacity: 0.95; margin: 0; }
            .security-badge { display: inline-block; background: rgba(255, 255, 255, 0.2); color: #ffffff; padding: 8px 16px; border-radius: 20px; font-size: 14px; font-weight: 600; text-transform: uppercase; margin-top: 16px; }
            .content { padding: 40px 30px; }
            .reset-section { text-align: center; margin-bottom: 40px; }
            .reset-icon { font-size: 64px; margin-bottom: 20px; }
            .reset-title { font-size: 28px; font-weight: 600; color: #2c3e50; margin-bottom: 16px; }
            .reset-subtitle { font-size: 18px; color: #7f8c8d; margin-bottom: 24px; }
            .reset-message { font-size: 16px; color: #34495e; line-height: 1.7; max-width: 500px; margin: 0 auto; }
            .otp-card { background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); border-radius: 12px; padding: 32px 24px; margin: 32px 0; border-left: 4px solid #4ECDC4; text-align: center; }
            .otp-card h3 { color: #4ECDC4; font-size: 18px; font-weight: 600; margin-bottom: 20px; }
            .otp-code { background: #ffffff; border: 2px solid #4ECDC4; border-radius: 12px; padding: 20px; margin: 20px 0; font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #2c3e50; font-family: 'Courier New', monospace; }
            .expiry-info { background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 8px; padding: 12px 16px; margin: 20px 0; color: #856404; font-size: 14px; font-weight: 500; }
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
                    <div class='security-badge'>Password Reset</div>
                </div>
            </div>
            <div class='content'>
                <div class='reset-section'>
                    <div class='reset-icon'>🔐</div>
                    <h2 class='reset-title'>Password Reset Request</h2>
                    <p class='reset-subtitle'>We received a request to reset your password</p>
                    <p class='reset-message'>
                        Hi " . htmlspecialchars($userName) . "! Someone requested a password reset for your CNERGY GYM account. 
                        If this was you, use the verification code below to reset your password.
                    </p>
                </div>
                <div class='otp-card'>
                    <h3>Your Verification Code</h3>
                    <div class='otp-code'>" . $otp . "</div>
                    <div class='expiry-info'>
                        ⏰ This code expires in " . $expiresInMinutes . " minutes
                    </div>
                    <p style='color: #7f8c8d; font-size: 14px; margin-top: 16px;'>
                        Enter this code in the CNERGY GYM app to continue with your password reset.
                    </p>
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

// Function to send password recovery email using your EmailService
function sendEmail($to, $subject, $message) {
    try {
        // Use your existing EmailService class
        $emailService = new EmailService();
        
        // Extract user name from email (simple approach)
        $userName = explode('@', $to)[0];
        $userName = ucfirst($userName);
        
        // Create proper email headers using your existing method
        $htmlBody = $message; // Use the message as HTML body
        $textBody = strip_tags($message); // Strip HTML for plain text version
        
        // Use your existing createEmailHeaders method
        $reflection = new ReflectionClass($emailService);
        $method = $reflection->getMethod('createEmailHeaders');
        $method->setAccessible(true);
        $emailData = $method->invoke($emailService, $to, $userName, $htmlBody, $textBody);
        
        // Send email using PHP's built-in mail() function (same as your service)
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

try {
    // Database connection
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    // Get action from request
    $action = $_GET['action'] ?? $_POST['action'] ?? '';
    
    // Get input data
    $input = json_decode(file_get_contents("php://input"), true);
    if (!$input) {
        $input = $_POST;
    }

    switch ($action) {
        case 'send_reset_code':
            $email = $input['email'] ?? '';
            
            if (empty($email)) {
                sendError('Email is required', 400);
            }
            
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                sendError('Invalid email format', 400);
            }
            
            // Check if user exists
            $userStmt = $pdo->prepare("SELECT id, fname, lname FROM user WHERE email = ?");
            $userStmt->execute([$email]);
            $user = $userStmt->fetch();
            
            if (!$user) {
                sendError('No account found with this email address', 404);
            }
            
            // Generate OTP
            $otp = generateOTP(5);
            $expiresAt = date('Y-m-d H:i:s', strtotime('+15 minutes')); // OTP expires in 15 minutes
            
            // Store OTP in database (create table if not exists)
            $createTableQuery = "
                CREATE TABLE IF NOT EXISTS password_reset_tokens (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_id INT NOT NULL,
                    email VARCHAR(255) NOT NULL,
                    token VARCHAR(10) NOT NULL,
                    expires_at DATETIME NOT NULL,
                    used TINYINT(1) DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_email (email),
                    INDEX idx_token (token),
                    INDEX idx_expires (expires_at)
                )
            ";
            $pdo->exec($createTableQuery);
            
            // Delete any existing unused tokens for this email
            $deleteStmt = $pdo->prepare("DELETE FROM password_reset_tokens WHERE email = ? AND used = 0");
            $deleteStmt->execute([$email]);
            
            // Insert new token
            $insertStmt = $pdo->prepare("
                INSERT INTO password_reset_tokens (user_id, email, token, expires_at) 
                VALUES (?, ?, ?, ?)
            ");
            $insertStmt->execute([$user['id'], $email, $otp, $expiresAt]);
            
            // Send email with proper HTML template
            $userName = trim($user['fname'] . ' ' . $user['lname']);
            $subject = "Password Reset Code - CNERGY Gym";
            $message = createPasswordResetEmailHTML($userName, $otp, 15);
            
            $emailSent = sendEmail($email, $subject, $message);
            
            if ($emailSent) {
                sendResponse([
                    'success' => true,
                    'message' => 'Reset code sent to your email',
                    'email' => $email,
                    'expires_in_minutes' => 15
                ]);
            } else {
                sendError('Failed to send email. Please try again later.', 500);
            }
            break;
            
        case 'verify_reset_code':
            $email = $input['email'] ?? '';
            $code = $input['code'] ?? '';
            
            if (empty($email) || empty($code)) {
                sendError('Email and verification code are required', 400);
            }
            
            // Check if code is valid and not expired
            $tokenStmt = $pdo->prepare("
                SELECT id, user_id FROM password_reset_tokens 
                WHERE email = ? AND token = ? AND expires_at > NOW() AND used = 0
            ");
            $tokenStmt->execute([$email, $code]);
            $token = $tokenStmt->fetch();
            
            if (!$token) {
                sendError('Invalid or expired verification code', 400);
            }
            
            sendResponse([
                'success' => true,
                'message' => 'Code verified successfully',
                'reset_token_id' => $token['id'],
                'user_id' => $token['user_id']
            ]);
            break;
            
        case 'reset_password':
            $email = $input['email'] ?? '';
            $code = $input['code'] ?? '';
            $newPassword = $input['new_password'] ?? '';
            $confirmPassword = $input['confirm_password'] ?? '';
            
            if (empty($email) || empty($code) || empty($newPassword) || empty($confirmPassword)) {
                sendError('All fields are required', 400);
            }
            
            if ($newPassword !== $confirmPassword) {
                sendError('Passwords do not match', 400);
            }
            
            if (strlen($newPassword) < 8) {
                sendError('Password must be at least 8 characters long', 400);
            }
            
            // Verify code again
            $tokenStmt = $pdo->prepare("
                SELECT id, user_id FROM password_reset_tokens 
                WHERE email = ? AND token = ? AND expires_at > NOW() AND used = 0
            ");
            $tokenStmt->execute([$email, $code]);
            $token = $tokenStmt->fetch();
            
            if (!$token) {
                sendError('Invalid or expired verification code', 400);
            }
            
            // Hash new password
            $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
            
            // Update user password
            $updateStmt = $pdo->prepare("UPDATE user SET password = ? WHERE id = ?");
            $updateStmt->execute([$hashedPassword, $token['user_id']]);
            
            // Mark token as used
            $markUsedStmt = $pdo->prepare("UPDATE password_reset_tokens SET used = 1 WHERE id = ?");
            $markUsedStmt->execute([$token['id']]);
            
            sendResponse([
                'success' => true,
                'message' => 'Password reset successfully'
            ]);
            break;
            
        case 'resend_code':
            $email = $input['email'] ?? '';
            
            if (empty($email)) {
                sendError('Email is required', 400);
            }
            
            // Check if user exists
            $userStmt = $pdo->prepare("SELECT id, fname, lname FROM user WHERE email = ?");
            $userStmt->execute([$email]);
            $user = $userStmt->fetch();
            
            if (!$user) {
                sendError('No account found with this email address', 404);
            }
            
            // Check if there's a recent request (prevent spam)
            $recentStmt = $pdo->prepare("
                SELECT created_at FROM password_reset_tokens 
                WHERE email = ? AND created_at > DATE_SUB(NOW(), INTERVAL 1 MINUTE)
                ORDER BY created_at DESC LIMIT 1
            ");
            $recentStmt->execute([$email]);
            $recent = $recentStmt->fetch();
            
            if ($recent) {
                sendError('Please wait at least 1 minute before requesting a new code', 429);
            }
            
            // Generate new OTP
            $otp = generateOTP(5);
            $expiresAt = date('Y-m-d H:i:s', strtotime('+15 minutes'));
            
            // Delete existing unused tokens
            $deleteStmt = $pdo->prepare("DELETE FROM password_reset_tokens WHERE email = ? AND used = 0");
            $deleteStmt->execute([$email]);
            
            // Insert new token
            $insertStmt = $pdo->prepare("
                INSERT INTO password_reset_tokens (user_id, email, token, expires_at) 
                VALUES (?, ?, ?, ?)
            ");
            $insertStmt->execute([$user['id'], $email, $otp, $expiresAt]);
            
            // Send email with proper HTML template
            $userName = trim($user['fname'] . ' ' . $user['lname']);
            $subject = "New Password Reset Code - CNERGY Gym";
            $message = createPasswordResetEmailHTML($userName, $otp, 15);
            
            $emailSent = sendEmail($email, $subject, $message);
            
            if ($emailSent) {
                sendResponse([
                    'success' => true,
                    'message' => 'New reset code sent to your email'
                ]);
            } else {
                sendError('Failed to send email. Please try again later.', 500);
            }
            break;
            
        default:
            sendError('Invalid action', 400);
            break;
    }

} catch(PDOException $e) {
    error_log('Database error in password_recovery.php: ' . $e->getMessage());
    sendError('Database error: ' . $e->getMessage(), 500);
} catch(Exception $e) {
    error_log('Server error in password_recovery.php: ' . $e->getMessage());
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>



