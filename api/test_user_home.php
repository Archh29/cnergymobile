<?php
// Simple test script for user_home.php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

echo json_encode([
    'message' => 'Test script is working',
    'timestamp' => date('Y-m-d H:i:s'),
    'server_info' => [
        'php_version' => phpversion(),
        'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
        'request_method' => $_SERVER['REQUEST_METHOD'],
        'request_uri' => $_SERVER['REQUEST_URI'] ?? 'Unknown'
    ]
]);
?>






