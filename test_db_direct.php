<?php
// Direct database test for user 54
$host = "localhost";
$db_name = "cnergydb";
$username = "root";
$password = "";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
    exit;
}

$userId = 54;

echo "=== Testing Database Query for User $userId ===\n\n";

// Test the exact query from routines.php
$stmt = $pdo->prepare("SELECT s.id AS subscription_id, s.plan_id, s.start_date, s.end_date, ss.status_name, msp.plan_name, msp.price FROM Subscription s LEFT JOIN Subscription_Status ss ON s.status_id = ss.id LEFT JOIN Member_Subscription_Plan msp ON s.plan_id = msp.id WHERE s.user_id = :user_id AND s.end_date >= CURDATE() AND ss.status_name = 'approved' ORDER BY s.end_date DESC, s.id DESC");

$stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
$stmt->execute();

$results = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Query results:\n";
echo "Count: " . count($results) . "\n\n";

foreach ($results as $result) {
    echo "Subscription ID: {$result['subscription_id']}\n";
    echo "Plan ID: {$result['plan_id']}\n";
    echo "Plan Name: {$result['plan_name']}\n";
    echo "Status: {$result['status_name']}\n";
    echo "Start Date: {$result['start_date']}\n";
    echo "End Date: {$result['end_date']}\n";
    echo "Price: {$result['price']}\n";
    echo "---\n";
}

// Test the logic
$hasMemberFee = false;
$latestSubscription = null;

foreach ($results as $result) {
    if ((int)$result['plan_id'] === 1) {
        $hasMemberFee = true;
        $latestSubscription = $result;
        break;
    }
    if ($latestSubscription === null) {
        $latestSubscription = $result;
    }
}

$isPremium = $hasMemberFee;

echo "\n=== Logic Test ===\n";
echo "Has Plan ID 1: " . ($hasMemberFee ? 'YES' : 'NO') . "\n";
echo "Is Premium: " . ($isPremium ? 'YES' : 'NO') . "\n";
echo "Latest Subscription Plan ID: " . ($latestSubscription ? $latestSubscription['plan_id'] : 'None') . "\n";

?>
