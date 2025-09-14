<?php
// Test script to check user 53's subscriptions
header('Content-Type: application/json');

$host = "localhost";
$db_name = "cnergydb";
$username = "root";
$password = "";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo json_encode(["error" => "Connection failed: " . $e->getMessage()]);
    exit;
}

$userId = 53;

echo "=== Checking User $userId Subscriptions ===\n\n";

// Get ALL subscriptions for this user
$stmt = $pdo->prepare("SELECT s.id AS subscription_id, s.plan_id, s.start_date, s.end_date, ss.status_name, msp.plan_name, msp.price FROM Subscription s LEFT JOIN Subscription_Status ss ON s.status_id = ss.id LEFT JOIN Member_Subscription_Plan msp ON s.plan_id = msp.id WHERE s.user_id = ? ORDER BY s.end_date DESC, s.id DESC");
$stmt->execute([$userId]);
$allSubscriptions = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "ALL subscriptions for user $userId:\n";
foreach ($allSubscriptions as $sub) {
    echo "- ID: {$sub['subscription_id']}, Plan ID: {$sub['plan_id']}, Plan Name: {$sub['plan_name']}, Status: {$sub['status_name']}, End Date: {$sub['end_date']}\n";
}

echo "\n=== Active Subscriptions (end_date >= CURDATE() AND status = 'approved') ===\n";

// Get active subscriptions
$stmt = $pdo->prepare("SELECT s.id AS subscription_id, s.plan_id, s.start_date, s.end_date, ss.status_name, msp.plan_name, msp.price FROM Subscription s LEFT JOIN Subscription_Status ss ON s.status_id = ss.id LEFT JOIN Member_Subscription_Plan msp ON s.plan_id = msp.id WHERE s.user_id = ? AND s.end_date >= CURDATE() AND ss.status_name = 'approved' ORDER BY s.end_date DESC, s.id DESC");
$stmt->execute([$userId]);
$activeSubscriptions = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Active subscriptions for user $userId:\n";
foreach ($activeSubscriptions as $sub) {
    echo "- ID: {$sub['subscription_id']}, Plan ID: {$sub['plan_id']}, Plan Name: {$sub['plan_name']}, Status: {$sub['status_name']}, End Date: {$sub['end_date']}\n";
}

echo "\n=== Premium Logic Check ===\n";

// Check if user has Plan ID 1
$hasPlan1 = false;
$latestSubscription = null;

foreach ($activeSubscriptions as $sub) {
    if ((int)$sub['plan_id'] === 1) {
        $hasPlan1 = true;
        $latestSubscription = $sub;
        break;
    }
    // Keep track of the latest subscription for details
    if ($latestSubscription === null) {
        $latestSubscription = $sub;
    }
}

echo "Has Plan ID 1 (Member Fee): " . ($hasPlan1 ? 'YES' : 'NO') . "\n";
echo "Should be Premium: " . ($hasPlan1 ? 'YES' : 'NO') . "\n";

if ($latestSubscription) {
    echo "Latest subscription details:\n";
    echo "- Plan ID: {$latestSubscription['plan_id']}\n";
    echo "- Plan Name: {$latestSubscription['plan_name']}\n";
    echo "- Status: {$latestSubscription['status_name']}\n";
    echo "- End Date: {$latestSubscription['end_date']}\n";
}

echo "\n=== Testing routines.php API ===\n";

// Test the actual API call
$url = "http://localhost/cynergy/routines.php?action=fetch&user_id=$userId";
$response = file_get_contents($url);
$data = json_decode($response, true);

echo "API Response:\n";
echo "Success: " . ($data['success'] ? 'true' : 'false') . "\n";
echo "Is Premium: " . ($data['is_premium'] ? 'true' : 'false') . "\n";
if (isset($data['membership_status']['subscription_details'])) {
    $subDetails = $data['membership_status']['subscription_details'];
    echo "Subscription Details:\n";
    echo "- Plan ID: {$subDetails['plan_id']}\n";
    echo "- Plan Name: {$subDetails['plan_name']}\n";
    echo "- Status: {$subDetails['status']}\n";
}

?>
