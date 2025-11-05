<?php
// Test script for contact support system
header("Content-Type: application/json");

// Test data
$testData = [
    'action' => 'send_support_email',
    'email' => 'test@example.com',
    'subject' => 'Test Support Request',
    'message' => 'This is a test message to verify the contact support system is working properly.'
];

// Convert to JSON
$jsonData = json_encode($testData);

// Create context for POST request
$context = stream_context_create([
    'http' => [
        'method' => 'POST',
        'header' => 'Content-Type: application/json',
        'content' => $jsonData
    ]
]);

// Make request to contact support API
$result = file_get_contents('https://api.cnergy.site/contact_support_simple.php', false, $context);

if ($result === FALSE) {
    echo json_encode(['error' => 'Failed to make request to contact support API']);
} else {
    echo "Contact Support API Response:\n";
    echo $result;
}
?>














