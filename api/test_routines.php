<?php
// Test endpoint for routines API
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin");
header("Access-Control-Max-Age: 86400");
header("Content-Type: application/json");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = "localhost";
$db_name = "u773938685_cnergydb";      
$username = "u773938685_archh29";  
$password = "Gwapoko385@"; 

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Test table existence
    $tables = ['member_programhdr', 'member_program_workout', 'member_workout_exercise', 'subscription', 'subscription_status', 'member_subscription_plan'];
    $tableStatus = [];
    
    foreach ($tables as $table) {
        $stmt = $pdo->prepare("SHOW TABLES LIKE ?");
        $stmt->execute([$table]);
        $exists = $stmt->fetch();
        $tableStatus[$table] = $exists ? true : false;
    }
    
    // Test basic query
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM member_programhdr");
    $stmt->execute();
    $routineCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    echo json_encode([
        'success' => true,
        'message' => 'Routines API test successful',
        'timestamp' => date('Y-m-d H:i:s'),
        'table_status' => $tableStatus,
        'total_routines' => $routineCount,
        'php_version' => phpversion()
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}
?>






