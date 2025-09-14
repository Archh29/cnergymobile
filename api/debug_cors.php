<?php
// Debug CORS issues
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Debug information
$debug_info = [
    'success' => true,
    'message' => 'CORS Debug Information',
    'timestamp' => date('Y-m-d H:i:s'),
    'request_method' => $_SERVER['REQUEST_METHOD'],
    'request_uri' => $_SERVER['REQUEST_URI'],
    'http_host' => $_SERVER['HTTP_HOST'],
    'server_name' => $_SERVER['SERVER_NAME'],
    'php_version' => phpversion(),
    'headers_sent' => headers_sent(),
    'all_headers' => getallheaders(),
    'request_headers' => apache_request_headers(),
    'cors_headers_set' => [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers' => 'Content-Type, Authorization, X-Requested-With, Accept, Origin',
        'Access-Control-Max-Age' => '86400'
    ]
];

echo json_encode($debug_info, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>






