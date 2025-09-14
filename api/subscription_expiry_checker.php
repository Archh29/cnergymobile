<?php
/**
 * Subscription Expiry Email Checker
 * 
 * This script checks for subscriptions that are expiring soon and sends
 * appropriate reminder emails. It should be run as a cron job daily.
 * 
 * Cron job example (run daily at 9:00 AM):
 * 0 9 * * * /usr/bin/php /path/to/your/api/subscription_expiry_checker.php
 * 
 * Usage:
 * php subscription_expiry_checker.php
 * 
 * @author CNERGY GYM System
 * @version 1.0
 */

// Set timezone
date_default_timezone_set('Asia/Manila');

// Include required files
require_once 'email_service.php';
require_once 'db.php';

// Set content type for web access
header('Content-Type: application/json');

// Function to log messages
function logMessage($message) {
    $timestamp = date('Y-m-d H:i:s');
    $logMessage = "[$timestamp] $message" . PHP_EOL;
    echo $logMessage;
    error_log($logMessage);
}

// Function to send summary email to admin
function sendAdminSummary($summary) {
    try {
        $emailService = new EmailService();
        
        $adminEmail = 'admin@cnergygym.com'; // Change this to your admin email
        $adminName = 'CNERGY GYM Admin';
        
        $subject = 'Daily Subscription Expiry Report - ' . date('Y-m-d');
        
        $htmlBody = "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='UTF-8'>
            <title>Subscription Expiry Report</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                .header { background: #FF6B35; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; }
                .summary { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; }
                .success { color: #28a745; }
                .error { color: #dc3545; }
                .details { margin-top: 20px; }
                table { width: 100%; border-collapse: collapse; margin-top: 10px; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f2f2f2; }
            </style>
        </head>
        <body>
            <div class='header'>
                <h1>CNERGY GYM</h1>
                <h2>Daily Subscription Expiry Report</h2>
                <p>" . date('F j, Y') . "</p>
            </div>
            <div class='content'>
                <div class='summary'>
                    <h3>Summary</h3>
                    <p><strong>Total Subscriptions Checked:</strong> " . $summary['total_checked'] . "</p>
                    <p><strong>Emails Sent Successfully:</strong> <span class='success'>" . $summary['emails_sent'] . "</span></p>
                    <p><strong>Errors:</strong> <span class='error'>" . $summary['errors'] . "</span></p>
                </div>
                
                <div class='details'>
                    <h3>Details</h3>
                    <table>
                        <tr>
                            <th>Member</th>
                            <th>Email</th>
                            <th>Days Remaining</th>
                            <th>Status</th>
                            <th>Error (if any)</th>
                        </tr>";
        
        foreach ($summary['details'] as $detail) {
            $statusClass = $detail['status'] === 'sent' ? 'success' : 'error';
            $htmlBody .= "
                        <tr>
                            <td>" . htmlspecialchars($detail['user']) . "</td>
                            <td>" . htmlspecialchars($detail['email']) . "</td>
                            <td>" . $detail['days_remaining'] . "</td>
                            <td class='$statusClass'>" . ucfirst($detail['status']) . "</td>
                            <td>" . htmlspecialchars($detail['error'] ?? '') . "</td>
                        </tr>";
        }
        
        $htmlBody .= "
                    </table>
                </div>
                
                <p style='margin-top: 30px; font-size: 12px; color: #666;'>
                    This report was generated automatically by the CNERGY GYM subscription expiry system.
                </p>
            </div>
        </body>
        </html>";
        
        $textBody = "
        CNERGY GYM - Daily Subscription Expiry Report
        ============================================
        
        Date: " . date('F j, Y') . "
        
        SUMMARY:
        - Total Subscriptions Checked: " . $summary['total_checked'] . "
        - Emails Sent Successfully: " . $summary['emails_sent'] . "
        - Errors: " . $summary['errors'] . "
        
        DETAILS:
        ";
        
        foreach ($summary['details'] as $detail) {
            $textBody .= "- " . $detail['user'] . " (" . $detail['email'] . ") - " . $detail['days_remaining'] . " days remaining - " . strtoupper($detail['status']);
            if (isset($detail['error'])) {
                $textBody .= " - Error: " . $detail['error'];
            }
            $textBody .= "\n";
        }
        
        $textBody .= "
        
        This report was generated automatically by the CNERGY GYM subscription expiry system.
        ";
        
        // Send email to admin
        $emailData = $emailService->createEmailHeaders($adminEmail, $adminName, $htmlBody, $textBody);
        $success = mail($adminEmail, $subject, $emailData['message'], $emailData['headers']);
        
        if ($success) {
            logMessage("Admin summary email sent successfully");
        } else {
            logMessage("Failed to send admin summary email");
        }
        
    } catch (Exception $e) {
        logMessage("Error sending admin summary: " . $e->getMessage());
    }
}

// Main execution
try {
    logMessage("Starting subscription expiry check...");
    
    // Initialize email service
    $emailService = new EmailService();
    
    // Check and send expiry emails
    $summary = $emailService->checkAndSendExpiryEmails();
    
    // Log summary
    logMessage("Subscription expiry check completed:");
    logMessage("- Total checked: " . $summary['total_checked']);
    logMessage("- Emails sent: " . $summary['emails_sent']);
    logMessage("- Errors: " . $summary['errors']);
    
    // Send admin summary if there were any subscriptions checked
    if ($summary['total_checked'] > 0) {
        sendAdminSummary($summary);
    }
    
    // Return JSON response for web access
    if (php_sapi_name() !== 'cli') {
        echo json_encode([
            'success' => true,
            'message' => 'Subscription expiry check completed successfully',
            'summary' => $summary,
            'timestamp' => date('Y-m-d H:i:s')
        ], JSON_PRETTY_PRINT);
    }
    
    logMessage("Subscription expiry check finished successfully");
    
} catch (Exception $e) {
    $errorMessage = "Subscription expiry check failed: " . $e->getMessage();
    logMessage($errorMessage);
    
    // Return error response for web access
    if (php_sapi_name() !== 'cli') {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => $errorMessage,
            'timestamp' => date('Y-m-d H:i:s')
        ], JSON_PRETTY_PRINT);
    }
    
    exit(1);
}

// Test function for manual testing
function testExpiryEmails() {
    logMessage("Running test for subscription expiry emails...");
    
    try {
        $emailService = new EmailService();
        
        // Test data
        $testUsers = [
            [
                'email' => 'test@example.com',
                'name' => 'Test User 1',
                'days_remaining' => 14,
                'expiry_date' => date('Y-m-d', strtotime('+14 days')),
                'subscription_details' => [
                    'plan_name' => 'Member Plan Monthly',
                    'price' => 999.00,
                    'subscription_id' => 999
                ]
            ],
            [
                'email' => 'test2@example.com',
                'name' => 'Test User 2',
                'days_remaining' => 1,
                'expiry_date' => date('Y-m-d', strtotime('+1 day')),
                'subscription_details' => [
                    'plan_name' => 'Non-Member Plan Monthly',
                    'price' => 1300.00,
                    'subscription_id' => 998
                ]
            ]
        ];
        
        foreach ($testUsers as $user) {
            $result = $emailService->sendSubscriptionExpiryEmail(
                $user['email'],
                $user['name'],
                $user['days_remaining'],
                $user['expiry_date'],
                $user['subscription_details']
            );
            
            logMessage("Test email to {$user['email']} (Days: {$user['days_remaining']}): " . 
                      ($result['success'] ? 'SUCCESS' : 'FAILED - ' . $result['message']));
        }
        
        logMessage("Test completed");
        
    } catch (Exception $e) {
        logMessage("Test failed: " . $e->getMessage());
    }
}

// Check if this is a test run
if (isset($argv[1]) && $argv[1] === 'test') {
    testExpiryEmails();
    exit(0);
}

// Check if this is a manual run with specific parameters
if (isset($argv[1]) && $argv[1] === 'manual') {
    $days = isset($argv[2]) ? (int)$argv[2] : 7;
    logMessage("Manual run for subscriptions expiring in $days days");
    
    try {
        $emailService = new EmailService();
        
        // Get subscriptions expiring in specific days
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
            AND DATEDIFF(s.end_date, CURDATE()) = $days
            ORDER BY s.end_date ASC
        ";
        
        $result = $conn->query($query);
        
        if (!$result) {
            throw new Exception("Database query failed: " . $conn->error);
        }
        
        $count = 0;
        while ($row = $result->fetch_assoc()) {
            $userName = $row['fname'] . ' ' . $row['lname'];
            $subscriptionDetails = [
                'plan_name' => $row['plan_name'],
                'price' => $row['price'],
                'subscription_id' => $row['id']
            ];
            
            $emailResult = $emailService->sendSubscriptionExpiryEmail(
                $row['email'],
                $userName,
                $row['days_remaining'],
                $row['end_date'],
                $subscriptionDetails
            );
            
            if ($emailResult['success']) {
                $count++;
                logMessage("Email sent to {$row['email']} ({$userName})");
            } else {
                logMessage("Failed to send email to {$row['email']}: " . $emailResult['message']);
            }
        }
        
        logMessage("Manual run completed. Emails sent: $count");
        
    } catch (Exception $e) {
        logMessage("Manual run failed: " . $e->getMessage());
        exit(1);
    }
    
    exit(0);
}

?>
