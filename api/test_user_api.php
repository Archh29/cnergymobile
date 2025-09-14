<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Accept, Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

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
    echo json_encode(['success' => true, 'message' => 'Database connection successful']);
    
    // Test table existence
    $tables = ['user', 'subscription', 'subscription_status'];
    foreach ($tables as $table) {
        $stmt = $pdo->prepare("SHOW TABLES LIKE ?");
        $stmt->execute([$table]);
        $exists = $stmt->fetch();
        echo json_encode(['table' => $table, 'exists' => $exists ? true : false]);
    }
    
    // Test user query
    $stmt = $pdo->prepare("SELECT id, fname, lname, email FROM user WHERE id = 7");
    $stmt->execute();
    $user = $stmt->fetch();
    echo json_encode(['user_test' => $user]);
    
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed', 'error' => $e->getMessage()]);
}
?>

