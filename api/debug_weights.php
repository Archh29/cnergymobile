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

$userId = $_GET['user_id'] ?? null;
$exerciseId = $_GET['exercise_id'] ?? null;

if (!$userId || !$exerciseId) {
    echo json_encode(["error" => "Missing user_id or exercise_id"]);
    exit;
}

try {
    // Check what's in the exercise logs for this user and exercise
    $stmt = $pdo->prepare("
        SELECT 
            mel.id as log_id,
            mel.member_workout_exercise_id,
            mel.log_date,
            mel.actual_sets,
            mel.actual_reps,
            mel.total_kg,
            mesl.set_number,
            mesl.reps,
            mesl.weight,
            mwe.exercise_id,
            e.name as exercise_name
        FROM member_exercise_log mel
        JOIN member_exercise_set_log mesl ON mel.id = mesl.exercise_log_id
        JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
        JOIN exercise e ON mwe.exercise_id = e.id
        WHERE mel.member_id = :user_id 
        AND mwe.exercise_id = :exercise_id
        ORDER BY mel.log_date DESC, mesl.set_number ASC
        LIMIT 20
    ");
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
    $stmt->execute();
    $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Also check what member_workout_exercise_ids exist for this exercise
    $stmt2 = $pdo->prepare("
        SELECT 
            mwe.id as member_workout_exercise_id,
            mwe.exercise_id,
            mwe.reps,
            mwe.weight,
            e.name as exercise_name,
            mpw.member_program_hdr_id as routine_id
        FROM member_workout_exercise mwe
        JOIN exercise e ON mwe.exercise_id = e.id
        JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
        WHERE mwe.exercise_id = :exercise_id
        ORDER BY mwe.id DESC
        LIMIT 10
    ");
    $stmt2->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
    $stmt2->execute();
    $programWeights = $stmt2->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        "success" => true,
        "user_id" => $userId,
        "exercise_id" => $exerciseId,
        "logged_sets" => $logs,
        "program_weights" => $programWeights,
        "logged_sets_count" => count($logs),
        "program_weights_count" => count($programWeights)
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        "success" => false,
        "error" => "Database error: " . $e->getMessage()
    ]);
}
?>





