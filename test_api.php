<?php
// Test script to check if the API is working
$url = 'http://localhost/gym/api/coach_routine.php';

// Test data for createTemplate
$testData = [
    'action' => 'createTemplate',
    'created_by' => 59,
    'template_name' => 'Test Template',
    'goal' => 'General Fitness',
    'difficulty' => 'Beginner',
    'color' => '4283354564',
    'tags' => [],
    'notes' => 'Test notes',
    'duration' => '30',
    'exercises' => [
        [
            'id' => 14,
            'name' => 'Barbell Bench Press',
            'reps' => 10,
            'sets' => 3,
            'weight' => 0
        ]
    ]
];

// Make POST request
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Content-Length: ' . strlen(json_encode($testData))
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response: $response\n";

// Test getTemplates
echo "\n--- Testing getTemplates ---\n";
$getUrl = $url . '?action=getTemplates&coach_id=59';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $getUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response: $response\n";
?>
