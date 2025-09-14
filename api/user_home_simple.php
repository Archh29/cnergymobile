<?php
// Simple version of user_home.php for testing CORS
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

// Return mock data for testing
echo json_encode([
    'success' => true,
    'data' => [
        'announcements' => [
            [
                'id' => 1,
                'title' => 'Test Announcement',
                'description' => 'This is a test announcement',
                'icon' => 'info',
                'color' => '#96CEB4',
                'isImportant' => false,
                'datePosted' => date('Y-m-d H:i:s')
            ]
        ],
        'merchandise' => [
            [
                'id' => 1,
                'name' => 'Test Product',
                'price' => '₱100.00',
                'description' => 'Test merchandise',
                'color' => '#FF6B35',
                'icon' => 'fitness_center',
                'imageUrl' => null,
                'createdAt' => date('Y-m-d H:i:s')
            ]
        ],
        'promotions' => [
            [
                'id' => 1,
                'title' => 'Test Promotion',
                'description' => 'This is a test promotion',
                'discount' => 'SPECIAL',
                'validUntil' => 'Valid for 30 more days',
                'color' => '#4ECDC4',
                'icon' => 'star',
                'startDate' => date('Y-m-d'),
                'endDate' => date('Y-m-d', strtotime('+30 days')),
                'createdAt' => date('Y-m-d H:i:s'),
                'isActive' => true
            ]
        ]
    ]
], JSON_UNESCAPED_UNICODE);
?>






