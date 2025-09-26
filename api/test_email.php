<?php
// Simple test script for email service
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Include the email service
require_once __DIR__ . '/email_service.php';

try {
    $emailService = new EmailService();
    
    // Get test email from query parameter or use default
    $testEmail = $_GET['email'] ?? 'uyguangco.francisbaron@gmail.com';
    $testName = $_GET['name'] ?? 'Test User';
    
    // Send test email
    $result = $emailService->sendTestEmail($testEmail, $testName);
    
    echo json_encode([
        'success' => $result['success'],
        'message' => $result['message'],
        'test_email' => $testEmail,
        'test_name' => $testName,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Test failed: ' . $e->getMessage(),
        'error' => $e->getMessage()
    ]);
}
?>

















