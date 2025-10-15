<?php
// Test the progress tracker API endpoints
$baseUrl = 'https://api.cnergy.site/progress_tracker.php';

echo "🧪 Testing Progress Tracker API Endpoints\n";
echo "==========================================\n\n";

// Test 1: Save a lift
echo "1. Testing save_lift endpoint...\n";
$saveData = [
    'action' => 'save_lift',
    'data' => [
        'user_id' => 61,
        'exercise_name' => 'Bench Press',
        'muscle_group' => 'Chest',
        'weight' => 80.0,
        'reps' => 8,
        'sets' => 3,
        'notes' => 'API Test',
        'program_name' => 'Test Program',
        'program_id' => 1
    ]
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($saveData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "   HTTP Code: $httpCode\n";
echo "   Response: $response\n";

if ($httpCode == 200) {
    echo "   ✅ save_lift endpoint working\n";
} else {
    echo "   ❌ save_lift endpoint failed\n";
}

echo "\n";

// Test 2: Get all progress
echo "2. Testing get_all_progress endpoint...\n";
$url = $baseUrl . '?action=get_all_progress&user_id=61';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "   HTTP Code: $httpCode\n";
echo "   Response: " . substr($response, 0, 200) . "...\n";

if ($httpCode == 200) {
    echo "   ✅ get_all_progress endpoint working\n";
} else {
    echo "   ❌ get_all_progress endpoint failed\n";
}

echo "\n";

// Test 3: Get exercise progress
echo "3. Testing get_exercise_progress endpoint...\n";
$url = $baseUrl . '?action=get_exercise_progress&user_id=61&exercise_name=Bench Press&limit=5';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "   HTTP Code: $httpCode\n";
echo "   Response: " . substr($response, 0, 200) . "...\n";

if ($httpCode == 200) {
    echo "   ✅ get_exercise_progress endpoint working\n";
} else {
    echo "   ❌ get_exercise_progress endpoint failed\n";
}

echo "\n";

// Test 4: Get progress by program
echo "4. Testing get_progress_by_program endpoint...\n";
$url = $baseUrl . '?action=get_progress_by_program&user_id=61&program_id=1';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "   HTTP Code: $httpCode\n";
echo "   Response: " . substr($response, 0, 200) . "...\n";

if ($httpCode == 200) {
    echo "   ✅ get_progress_by_program endpoint working\n";
} else {
    echo "   ❌ get_progress_by_program endpoint failed\n";
}

echo "\n";
echo "🎉 API endpoint testing completed!\n";
?>
