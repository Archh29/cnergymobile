<?php
// Test endpoint for muscle/exercise API
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
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    
    // Test table existence
    $tables = ['target_muscle', 'exercise', 'exercise_target_muscle'];
    $tableStatus = [];
    
    foreach ($tables as $table) {
        $stmt = $pdo->prepare("SHOW TABLES LIKE ?");
        $stmt->execute([$table]);
        $exists = $stmt->fetch();
        $tableStatus[$table] = $exists ? true : false;
    }
    
    // Test basic queries
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM target_muscle");
    $stmt->execute();
    $muscleCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM exercise");
    $stmt->execute();
    $exerciseCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    // Test muscle groups query
    $stmt = $pdo->prepare("
        SELECT id, name, image_url 
        FROM target_muscle 
        WHERE parent_id IS NULL
        ORDER BY name
        LIMIT 5
    ");
    $stmt->execute();
    $muscleGroups = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'message' => 'Muscle/Exercise API test successful',
        'timestamp' => date('Y-m-d H:i:s'),
        'table_status' => $tableStatus,
        'counts' => [
            'muscles' => $muscleCount,
            'exercises' => $exerciseCount
        ],
        'sample_muscle_groups' => $muscleGroups,
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






