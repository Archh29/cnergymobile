<?php
// Simple test for the session management API
header("Content-Type: application/json");

$memberId = 10; // Test with member ID 10
$baseUrl = 'https://api.cnergy.site/coach_session_management.php';

echo "Testing Session Management API for Member ID: $memberId\n\n";

// Test 1: Get Session History
echo "1. Testing get-session-history...\n";
$url = $baseUrl . "?action=get-session-history&member_id=" . $memberId;

$context = stream_context_create([
    'http' => [
        'method' => 'GET',
        'header' => 'Content-Type: application/json',
        'timeout' => 30
    ]
]);

$response = file_get_contents($url, false, $context);

if ($response === FALSE) {
    echo "❌ FAILED: Could not fetch response\n";
    $error = error_get_last();
    echo "Error: " . $error['message'] . "\n";
} else {
    echo "✅ Response received:\n";
    echo $response . "\n";
    
    $data = json_decode($response, true);
    if ($data) {
        if (isset($data['success']) && $data['success']) {
            echo "✅ SUCCESS: API call successful\n";
            echo "History records: " . count($data['data']['history']) . "\n";
            if (isset($data['data']['current_info'])) {
                echo "Current info available: Yes\n";
            } else {
                echo "Current info available: No\n";
            }
        } else {
            echo "❌ API returned error: " . ($data['message'] ?? 'Unknown error') . "\n";
        }
    } else {
        echo "❌ Invalid JSON response\n";
    }
}

echo "\n" . str_repeat("=", 50) . "\n";

// Test 2: Check if member exists in coach_member_list
echo "2. Testing direct database connection...\n";

try {
    $pdo = new PDO("mysql:host=localhost;dbname=u773938685_cnergydb", "u773938685_archh29", "Gwapoko385@");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Check if member exists in coach_member_list
    $stmt = $pdo->prepare("SELECT * FROM coach_member_list WHERE member_id = ?");
    $stmt->execute([$memberId]);
    $memberData = $stmt->fetchAll();
    
    echo "✅ Database connection successful\n";
    echo "Records in coach_member_list for member $memberId: " . count($memberData) . "\n";
    
    if (count($memberData) > 0) {
        echo "Member data:\n";
        foreach ($memberData as $row) {
            echo "- ID: " . $row['id'] . ", Status: " . $row['status'] . ", Rate Type: " . $row['rate_type'] . ", Remaining Sessions: " . $row['remaining_sessions'] . "\n";
        }
    }
    
    // Check session usage records
    $stmt = $pdo->prepare("
        SELECT csu.*, cml.member_id 
        FROM coach_session_usage csu
        JOIN coach_member_list cml ON csu.coach_member_id = cml.id
        WHERE cml.member_id = ?
    ");
    $stmt->execute([$memberId]);
    $usageData = $stmt->fetchAll();
    
    echo "Session usage records: " . count($usageData) . "\n";
    
} catch (PDOException $e) {
    echo "❌ Database error: " . $e->getMessage() . "\n";
}

echo "\nTest completed.\n";
?>
