<?php
// Test file for Coach Session Management API
// This file helps verify that the API endpoints are working correctly

header("Content-Type: application/json");

// Test configuration
$baseUrl = 'https://api.cnergy.site/coach_session_management.php';
$testMemberId = 1; // Replace with actual member ID for testing
$testUsageId = 1; // Replace with actual usage ID for testing

echo "=== Coach Session Management API Test ===\n\n";

// Test 1: Get Session History
echo "1. Testing get-session-history...\n";
$url = $baseUrl . "?action=get-session-history&member_id=" . $testMemberId;
$response = file_get_contents($url);
$data = json_decode($response, true);

if ($data && $data['success']) {
    echo "✅ SUCCESS: Session history retrieved\n";
    echo "   Records found: " . count($data['data']['history']) . "\n";
    if (isset($data['data']['current_info'])) {
        echo "   Current sessions: " . $data['data']['current_info']['remaining_sessions'] . "\n";
    }
} else {
    echo "❌ FAILED: " . ($data['message'] ?? 'Unknown error') . "\n";
}
echo "\n";

// Test 2: Get Member Session Info
echo "2. Testing get-member-session-info...\n";
$url = $baseUrl . "?action=get-member-session-info&member_id=" . $testMemberId;
$response = file_get_contents($url);
$data = json_decode($response, true);

if ($data && $data['success']) {
    echo "✅ SUCCESS: Member session info retrieved\n";
    echo "   Member: " . $data['data']['session_info']['member_name'] . "\n";
    echo "   Coach: " . $data['data']['session_info']['coach_name'] . "\n";
    echo "   Remaining sessions: " . $data['data']['session_info']['remaining_sessions'] . "\n";
} else {
    echo "❌ FAILED: " . ($data['message'] ?? 'Unknown error') . "\n";
}
echo "\n";

// Test 3: Test CORS headers
echo "3. Testing CORS headers...\n";
$headers = get_headers($baseUrl . "?action=get-session-history&member_id=" . $testMemberId, 1);
$corsHeaders = [
    'Access-Control-Allow-Origin',
    'Access-Control-Allow-Methods',
    'Access-Control-Allow-Headers'
];

$corsWorking = true;
foreach ($corsHeaders as $header) {
    if (isset($headers[$header])) {
        echo "✅ $header: " . $headers[$header] . "\n";
    } else {
        echo "❌ Missing $header\n";
        $corsWorking = false;
    }
}

if ($corsWorking) {
    echo "✅ CORS headers are properly configured\n";
} else {
    echo "❌ CORS headers are missing or incomplete\n";
}
echo "\n";

// Test 4: Test error handling
echo "4. Testing error handling...\n";
$url = $baseUrl . "?action=invalid-action";
$response = file_get_contents($url);
$data = json_decode($response, true);

if ($data && !$data['success']) {
    echo "✅ SUCCESS: Error handling works correctly\n";
    echo "   Error message: " . $data['message'] . "\n";
} else {
    echo "❌ FAILED: Error handling not working properly\n";
}
echo "\n";

// Test 5: Test missing parameters
echo "5. Testing missing parameters...\n";
$url = $baseUrl . "?action=get-session-history"; // Missing member_id
$response = file_get_contents($url);
$data = json_decode($response, true);

if ($data && !$data['success']) {
    echo "✅ SUCCESS: Parameter validation works\n";
    echo "   Error message: " . $data['message'] . "\n";
} else {
    echo "❌ FAILED: Parameter validation not working\n";
}
echo "\n";

echo "=== Test Complete ===\n";
echo "Note: To test POST endpoints (undo-session-usage, adjust-session-count), use a tool like Postman or curl.\n";
echo "Example curl commands:\n\n";

echo "# Undo session usage:\n";
echo "curl -X POST '$baseUrl?action=undo-session-usage' \\\n";
echo "  -H 'Content-Type: application/json' \\\n";
echo "  -d '{\"usage_id\": $testUsageId, \"member_id\": $testMemberId}'\n\n";

echo "# Adjust session count:\n";
echo "curl -X POST '$baseUrl?action=adjust-session-count' \\\n";
echo "  -H 'Content-Type: application/json' \\\n";
echo "  -d '{\"member_id\": $testMemberId, \"adjustment\": 2, \"reason\": \"Test adjustment\"}'\n\n";

echo "# Add session usage:\n";
echo "curl -X POST '$baseUrl?action=add-session-usage' \\\n";
echo "  -H 'Content-Type: application/json' \\\n";
echo "  -d '{\"member_id\": $testMemberId, \"coach_id\": 1, \"reason\": \"Test manual usage\"}'\n\n";
?>
