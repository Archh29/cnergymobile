<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin");
header("Access-Control-Max-Age: 86400");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
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
} catch (PDOException $e) {
    echo json_encode(["success" => false, "error" => "Connection failed: " . $e->getMessage()]);
    exit;
}

$input = json_decode(file_get_contents("php://input"), true);
$routineId = $input['routine_id'] ?? null;
$userId = $input['user_id'] ?? null;
$exerciseId = $input['exercise_id'] ?? null;
$newWeights = $input['weights'] ?? [];

if (!$routineId || !$userId || !$exerciseId || empty($newWeights)) {
    echo json_encode(["success" => false, "error" => "Missing required parameters"]);
    exit;
}

try {
    // Delete existing program weights for this exercise
    $deleteStmt = $pdo->prepare("
        DELETE FROM member_workout_exercise 
        WHERE member_program_workout_id = (
            SELECT id FROM member_program_workout 
            WHERE member_program_hdr_id = :routine_id
        ) AND exercise_id = :exercise_id
    ");
    $deleteStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
    $deleteStmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
    $deleteStmt->execute();
    
    // Insert new weights
    $insertStmt = $pdo->prepare("
        INSERT INTO member_workout_exercise 
        (member_program_workout_id, exercise_id, sets, reps, weight)
        VALUES (
            (SELECT id FROM member_program_workout WHERE member_program_hdr_id = :routine_id),
            :exercise_id, 1, :reps, :weight
        )
    ");
    
    foreach ($newWeights as $weight) {
        $insertStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
        $insertStmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
        $insertStmt->bindParam(':reps', $weight['reps'], PDO::PARAM_INT);
        $insertStmt->bindParam(':weight', $weight['weight'], PDO::PARAM_STR);
        $insertStmt->execute();
    }
    
    echo json_encode([
        "success" => true,
        "message" => "Program weights updated successfully",
        "updated_sets" => count($newWeights)
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        "success" => false,
        "error" => "Database error: " . $e->getMessage()
    ]);
}
?>






