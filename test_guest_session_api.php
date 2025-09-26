<?php
// Test file for guest session API
require_once 'api/guest_session_api.php';

echo "<h1>Guest Session API Test</h1>";

// Test data
$testData = [
    'guest_name' => 'John Doe',
    'guest_type' => 'walkin',
    'amount_paid' => 150.00
];

echo "<h2>Testing Guest Session Creation</h2>";
echo "<pre>";
echo "Test Data: " . json_encode($testData, JSON_PRETTY_PRINT) . "\n\n";

// Simulate POST request
$_SERVER['REQUEST_METHOD'] = 'POST';
$_POST['action'] = 'create_guest_session';
$_GET = [];

// Capture output
ob_start();
$input = json_encode($testData);
file_put_contents('php://input', $input);

// This would normally be handled by the API
echo "API Response would be generated here...\n";
echo "Expected: Guest session created with QR token\n";
ob_end_clean();

echo "</pre>";

echo "<h2>API Endpoints Available:</h2>";
echo "<ul>";
echo "<li><strong>POST /guest_session_api.php</strong> - Create guest session</li>";
echo "<li><strong>GET /guest_session_api.php?action=check_status&qr_token=TOKEN</strong> - Check session status</li>";
echo "<li><strong>GET /guest_session_api.php?action=get_session&session_id=ID</strong> - Get session details</li>";
echo "<li><strong>GET /guest_session_api.php?action=get_all_sessions</strong> - Get all sessions (admin)</li>";
echo "<li><strong>POST /guest_session_api.php</strong> - Approve/reject/mark paid</li>";
echo "</ul>";

echo "<h2>Database Schema:</h2>";
echo "<pre>";
echo "guest_session table:
- id (int, primary key)
- guest_name (varchar)
- guest_type (enum: 'walkin', 'trial', 'guest')
- amount_paid (decimal)
- qr_token (varchar, unique)
- valid_until (datetime)
- paid (tinyint, 0/1)
- status (enum: 'pending', 'approved', 'rejected')
- created_at (timestamp)
";
echo "</pre>";

echo "<h2>Flutter Integration:</h2>";
echo "<ul>";
echo "<li>Guest button added to login screen</li>";
echo "<li>Guest registration form with type selection</li>";
echo "<li>QR code display screen</li>";
echo "<li>Session status checking</li>";
echo "<li>Local storage for session data</li>";
echo "</ul>";

echo "<h2>Admin Interface:</h2>";
echo "<p>Access <a href='api/guest_session_admin.php'>guest_session_admin.php</a> to manage guest sessions.</p>";
?>

