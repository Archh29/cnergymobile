<?php
// Script to create support_requests table if it doesn't exist
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Database configuration (matching contact_support.php)
$host = "localhost";
$db = "u773938685_cnergydb";      
$user = "u773938685_archh29";  
$pass = "Gwapoko385@"; 

$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
    
    // Check if table already exists
    $stmt = $pdo->prepare("SHOW TABLES LIKE 'support_requests'");
    $stmt->execute();
    $tableExists = $stmt->fetch();
    
    if ($tableExists) {
        echo json_encode([
            'success' => true,
            'message' => 'support_requests table already exists',
            'action' => 'no_action_needed'
        ]);
        exit;
    }
    
    // Create the table
    $sql = "CREATE TABLE IF NOT EXISTS `support_requests` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `user_email` varchar(255) NOT NULL,
        `subject` varchar(500) NOT NULL,
        `message` text NOT NULL,
        `source` varchar(100) NOT NULL DEFAULT 'mobile_app',
        `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `idx_user_email` (`user_email`),
        KEY `idx_created_at` (`created_at`),
        KEY `idx_source` (`source`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
    
    $pdo->exec($sql);
    
    echo json_encode([
        'success' => true,
        'message' => 'support_requests table created successfully',
        'action' => 'table_created'
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to create support_requests table',
        'error' => $e->getMessage()
    ]);
}
?>





