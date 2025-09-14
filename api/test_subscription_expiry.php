<?php
/**
 * Test Script for Subscription Expiry Email System
 * 
 * This script demonstrates how to use the subscription expiry email system
 * and can be used for testing purposes.
 * 
 * Usage:
 * php test_subscription_expiry.php
 */

// Include required files
require_once 'email_service.php';

// Set timezone
date_default_timezone_set('Asia/Manila');

echo "=== CNERGY GYM Subscription Expiry Email System Test ===\n\n";

try {
    // Initialize email service
    $emailService = new EmailService();
    echo "✓ Email service initialized successfully\n";
    
    // Test data for different expiry scenarios
    $testScenarios = [
        [
            'name' => '2 Weeks Remaining',
            'user_email' => 'test1@example.com',
            'user_name' => 'John Doe',
            'days_remaining' => 14,
            'expiry_date' => date('Y-m-d', strtotime('+14 days')),
            'subscription_details' => [
                'plan_name' => 'Member Plan Monthly',
                'price' => 999.00,
                'subscription_id' => 1
            ]
        ],
        [
            'name' => '1 Week Remaining',
            'user_email' => 'test2@example.com',
            'user_name' => 'Jane Smith',
            'days_remaining' => 7,
            'expiry_date' => date('Y-m-d', strtotime('+7 days')),
            'subscription_details' => [
                'plan_name' => 'Non-Member Plan Monthly',
                'price' => 1300.00,
                'subscription_id' => 2
            ]
        ],
        [
            'name' => '3 Days Remaining',
            'user_email' => 'test3@example.com',
            'user_name' => 'Mike Johnson',
            'days_remaining' => 3,
            'expiry_date' => date('Y-m-d', strtotime('+3 days')),
            'subscription_details' => [
                'plan_name' => 'Member Fee',
                'price' => 500.00,
                'subscription_id' => 3
            ]
        ],
        [
            'name' => '1 Day Remaining (URGENT)',
            'user_email' => 'test4@example.com',
            'user_name' => 'Sarah Wilson',
            'days_remaining' => 1,
            'expiry_date' => date('Y-m-d', strtotime('+1 day')),
            'subscription_details' => [
                'plan_name' => 'Member Plan Monthly',
                'price' => 999.00,
                'subscription_id' => 4
            ]
        ]
    ];
    
    echo "\n=== Testing Individual Expiry Emails ===\n";
    
    foreach ($testScenarios as $scenario) {
        echo "\n--- Testing: {$scenario['name']} ---\n";
        echo "User: {$scenario['user_name']} ({$scenario['user_email']})\n";
        echo "Days Remaining: {$scenario['days_remaining']}\n";
        echo "Plan: {$scenario['subscription_details']['plan_name']}\n";
        echo "Price: ₱" . number_format($scenario['subscription_details']['price'], 2) . "\n";
        
        $result = $emailService->sendSubscriptionExpiryEmail(
            $scenario['user_email'],
            $scenario['user_name'],
            $scenario['days_remaining'],
            $scenario['expiry_date'],
            $scenario['subscription_details']
        );
        
        if ($result['success']) {
            echo "✓ Email sent successfully\n";
        } else {
            echo "✗ Failed to send email: " . $result['message'] . "\n";
        }
    }
    
    echo "\n=== Testing Bulk Expiry Check ===\n";
    echo "Note: This will check the actual database for expiring subscriptions\n";
    
    // Test the bulk checker (this will query the actual database)
    $summary = $emailService->checkAndSendExpiryEmails();
    
    echo "Bulk check results:\n";
    echo "- Total subscriptions checked: " . $summary['total_checked'] . "\n";
    echo "- Emails sent successfully: " . $summary['emails_sent'] . "\n";
    echo "- Errors: " . $summary['errors'] . "\n";
    
    if (!empty($summary['details'])) {
        echo "\nDetails:\n";
        foreach ($summary['details'] as $detail) {
            $status = $detail['status'] === 'sent' ? '✓' : '✗';
            echo "  $status {$detail['user']} ({$detail['email']}) - {$detail['days_remaining']} days remaining\n";
            if (isset($detail['error'])) {
                echo "    Error: {$detail['error']}\n";
            }
        }
    }
    
    echo "\n=== Test Completed Successfully ===\n";
    echo "All tests have been completed. Check your email inbox for the test emails.\n";
    echo "Note: If you're using a local development environment, emails might not be delivered.\n";
    echo "Check your server's mail logs for delivery status.\n";
    
} catch (Exception $e) {
    echo "✗ Test failed with error: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}

echo "\n=== Usage Instructions ===\n";
echo "1. To run the daily expiry check as a cron job:\n";
echo "   0 9 * * * /usr/bin/php /path/to/api/subscription_expiry_checker.php\n\n";
echo "2. To test the system manually:\n";
echo "   php subscription_expiry_checker.php test\n\n";
echo "3. To check specific day expiry:\n";
echo "   php subscription_expiry_checker.php manual 7\n\n";
echo "4. To access via web browser:\n";
echo "   http://yoursite.com/api/subscription_expiry_checker.php\n\n";

?>
