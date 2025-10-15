<?php
// CORS and JSON headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin");
header("Access-Control-Max-Age: 86400");
header('Content-Type: application/json');

// Preflight
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$host = "localhost";
$dbname = "u773938685_cnergydb";      
$username = "u773938685_archh29";  
$password = "Gwapoko385@"; 

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    echo json_encode(["error" => "Connection failed: " . $e->getMessage()]);
    exit;
}

$routineId = $_GET['routine_id'] ?? null;
$userId = $_GET['user_id'] ?? null;

if (!$routineId || !$userId) {
    echo json_encode(["error" => "Missing routine_id or user_id"]);
    exit;
}

try {
    // Get the latest logged weights for each exercise in this routine
    $stmt = $pdo->prepare("
        SELECT 
            e.id as exercise_id,
            e.name as exercise_name,
            mwe.id as member_workout_exercise_id,
            -- Get the latest logged sets for this exercise
            GROUP_CONCAT(
                CONCAT(mesl.reps, ':', mesl.weight) 
                ORDER BY mel.log_date DESC, mesl.set_number ASC 
                SEPARATOR ','
            ) as latest_sets
        FROM member_workout_exercise mwe
        JOIN exercise e ON mwe.exercise_id = e.id
        JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
        LEFT JOIN member_exercise_log mel ON mwe.id = mel.member_workout_exercise_id AND mel.member_id = :user_id
        LEFT JOIN member_exercise_set_log mesl ON mel.id = mesl.exercise_log_id
        WHERE mpw.member_program_hdr_id = :routine_id
        GROUP BY e.id, e.name, mwe.id
        ORDER BY e.id
    ");
    
    $stmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $updatedWeights = [];
    
    foreach ($results as $row) {
        $exerciseId = $row['exercise_id'];
        $latestSets = $row['latest_sets'];
        
        if ($latestSets) {
            // Parse the latest sets (format: "reps:weight,reps:weight,...")
            $sets = explode(',', $latestSets);
            $parsedSets = [];
            
            foreach ($sets as $set) {
                if (strpos($set, ':') !== false) {
                    list($reps, $weight) = explode(':', $set);
                    $parsedSets[] = [
                        'reps' => (int)$reps,
                        'weight' => (float)$weight,
                        'timestamp' => date('c'),
                        'isCompleted' => false
                    ];
                }
            }
            
            if (!empty($parsedSets)) {
                $updatedWeights[$exerciseId] = $parsedSets;
            }
        }
    }
    
    echo json_encode([
        "success" => true,
        "updated_weights" => $updatedWeights
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        "success" => false,
        "error" => "Database error: " . $e->getMessage()
    ]);
}
?>





