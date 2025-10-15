<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database connection
$host = "localhost";
$db_name = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    throw new Exception("Connection failed: " . $e->getMessage());
}

$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    switch ($action) {
        case 'save_lift':
            saveLift();
            break;
        case 'get_all_progress':
            getAllProgress();
            break;
        case 'get_exercise_progress':
            getExerciseProgress();
            break;
        case 'get_recent_lifts':
            getRecentLifts();
            break;
        case 'get_progress_by_program':
            getProgressByProgram();
            break;
        default:
            throw new Exception('Invalid action');
    }
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

function saveLift()
{
    global $pdo;

    $input = json_decode(file_get_contents('php://input'), true);
    $data = $input['data'] ?? [];

    $userId = $data['user_id'] ?? null;
    $exerciseName = $data['exercise_name'] ?? '';
    $muscleGroup = $data['muscle_group'] ?? '';
    $weight = $data['weight'] ?? 0;
    $reps = $data['reps'] ?? 0;
    $sets = $data['sets'] ?? 0;
    $notes = $data['notes'] ?? null;
    $programName = $data['program_name'] ?? null;
    $programId = $data['program_id'] ?? null;

    if (!$userId || !$exerciseName) {
        throw new Exception('Missing required fields');
    }

    // Calculate volume and 1RM
    $volume = $weight * $reps * $sets;
    $oneRepMax = $reps == 1 ? $weight : $weight * (1 + ($reps / 30.0));

    $sql = "INSERT INTO progress_tracker 
            (user_id, exercise_name, muscle_group, weight, reps, sets, volume, one_rep_max, notes, program_name, program_id, created_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    // Handle custom date if provided
    $customDate = $data['date'] ?? null;
    $createdAt = $customDate ? date('Y-m-d H:i:s', strtotime($customDate)) : date('Y-m-d H:i:s');

    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute([
        $userId,
        $exerciseName,
        $muscleGroup,
        $weight,
        $reps,
        $sets,
        $volume,
        $oneRepMax,
        $notes,
        $programName,
        $programId,
        $createdAt
    ]);

    if ($result) {
        echo json_encode([
            'success' => true,
            'message' => 'Lift saved successfully',
            'lift_id' => $pdo->lastInsertId()
        ]);
    } else {
        throw new Exception('Failed to save lift');
    }
}

function getAllProgress()
{
    global $pdo;

    $userId = $_GET['user_id'] ?? null;
    if (!$userId) {
        throw new Exception('User ID required');
    }

    $sql = "SELECT id, user_id, exercise_name, muscle_group, weight, reps, sets, 
                   volume, one_rep_max, notes, program_name, program_id, 
                   created_at as date
            FROM progress_tracker 
            WHERE user_id = ? 
            ORDER BY exercise_name, created_at DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId]);
    $lifts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Group by exercise name
    $grouped = [];
    foreach ($lifts as $lift) {
        $exerciseName = $lift['exercise_name'];
        if (!isset($grouped[$exerciseName])) {
            $grouped[$exerciseName] = [];
        }
        $grouped[$exerciseName][] = $lift;
    }

    echo json_encode([
        'success' => true,
        'data' => $grouped
    ]);
}

function getExerciseProgress()
{
    global $pdo;

    $userId = $_GET['user_id'] ?? null;
    $exerciseName = $_GET['exercise_name'] ?? '';
    $muscleGroup = $_GET['muscle_group'] ?? null;
    $limit = $_GET['limit'] ?? null;

    if (!$userId || !$exerciseName) {
        throw new Exception('User ID and exercise name required');
    }

    $sql = "SELECT id, user_id, exercise_name, muscle_group, weight, reps, sets, 
                   volume, one_rep_max, notes, program_name, program_id, 
                   created_at as date
            FROM progress_tracker 
            WHERE user_id = ? AND exercise_name = ?";
    $params = [$userId, $exerciseName];

    if ($muscleGroup) {
        $sql .= " AND muscle_group = ?";
        $params[] = $muscleGroup;
    }

    $sql .= " ORDER BY created_at DESC";

    // Fix: Use direct string concatenation for LIMIT instead of parameter binding
    if ($limit && is_numeric($limit)) {
        $sql .= " LIMIT " . (int) $limit;
    }

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $lifts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $lifts
    ]);
}

function getRecentLifts()
{
    global $pdo;

    $userId = $_GET['user_id'] ?? null;
    $days = $_GET['days'] ?? 30;

    if (!$userId) {
        throw new Exception('User ID required');
    }

    $sql = "SELECT id, user_id, exercise_name, muscle_group, weight, reps, sets, 
                   volume, one_rep_max, notes, program_name, program_id, 
                   created_at as date
            FROM progress_tracker 
            WHERE user_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
            ORDER BY created_at DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId, $days]);
    $lifts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $lifts
    ]);
}

function getProgressByProgram()
{
    global $pdo;

    $userId = $_GET['user_id'] ?? null;
    $programId = $_GET['program_id'] ?? null;

    if (!$userId || !$programId) {
        throw new Exception('User ID and program ID required');
    }

    $sql = "SELECT id, user_id, exercise_name, muscle_group, weight, reps, sets, 
                   volume, one_rep_max, notes, program_name, program_id, 
                   created_at as date
            FROM progress_tracker 
            WHERE user_id = ? AND program_id = ?
            ORDER BY exercise_name, created_at DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId, $programId]);
    $lifts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $lifts
    ]);
}
?>
