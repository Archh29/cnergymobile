<?php
// Test endpoint for profile management API
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
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    
    // Test table existence
    $tables = ['user', 'gender', 'member_profile_details'];
    $tableStatus = [];
    
    foreach ($tables as $table) {
        $stmt = $pdo->prepare("SHOW TABLES LIKE ?");
        $stmt->execute([$table]);
        $exists = $stmt->fetch();
        $tableStatus[$table] = $exists ? true : false;
    }
    
    // Test basic queries
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM user");
    $stmt->execute();
    $userCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM gender");
    $stmt->execute();
    $genderCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    // Test profile query for user_id = 7
    $stmt = $pdo->prepare("
        SELECT 
            u.id,
            u.email,
            u.fname,
            u.mname,
            u.lname,
            u.bday,
            u.gender_id,
            g.gender_name as gender_type,
            mpd.fitness_level,
            mpd.height_cm,
            mpd.weight_kg,
            mpd.target_weight,
            mpd.body_fat,
            mpd.activity_level,
            mpd.workout_days_per_week,
            mpd.equipment_access
        FROM user u
        LEFT JOIN gender g ON u.gender_id = g.id
        LEFT JOIN member_profile_details mpd ON u.id = mpd.user_id
        WHERE u.id = 7
    ");
    $stmt->execute();
    $profile = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Test genders query
    $stmt = $pdo->prepare("SELECT id, gender_name as type FROM gender ORDER BY id LIMIT 3");
    $stmt->execute();
    $genders = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'message' => 'Profile Management API test successful',
        'timestamp' => date('Y-m-d H:i:s'),
        'table_status' => $tableStatus,
        'counts' => [
            'users' => $userCount,
            'genders' => $genderCount
        ],
        'test_profile_user_7' => $profile,
        'sample_genders' => $genders,
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






