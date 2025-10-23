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
        case 'get_muscles_by_exercise':
            getMusclesByExercise();
            break;
        case 'get_muscles_by_program':
            getMusclesByProgram();
            break;
        case 'get_muscles_by_exercises':
            getMusclesByExercises();
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

function getMusclesByExercise()
{
    global $pdo;

    $exerciseName = $_GET['exercise_name'] ?? '';
    if (!$exerciseName) {
        throw new Exception('Exercise name required');
    }

    // Get exercise by name
    $sql = "SELECT id FROM exercise WHERE name = ? OR name LIKE ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$exerciseName, "%$exerciseName%"]);
    $exercise = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$exercise) {
        echo json_encode([
            'success' => true,
            'muscles' => []
        ]);
        return;
    }

    // Get target muscles for this exercise
    $sql = "SELECT DISTINCT 
                tm.id,
                tm.name,
                tm.image_url,
                etm.role
            FROM target_muscle tm
            INNER JOIN exercise_target_muscle etm ON tm.id = etm.muscle_id
            WHERE etm.exercise_id = ?
            ORDER BY CASE 
                WHEN etm.role = 'primary' THEN 1
                WHEN etm.role = 'secondary' THEN 2
                ELSE 3
            END, tm.name";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$exercise['id']]);
    $muscles = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Replace localhost image URLs with placeholder
    foreach ($muscles as &$muscle) {
        $muscle['image_url'] = getDefaultMuscleImage($muscle['name']);
    }

    echo json_encode([
        'success' => true,
        'muscles' => $muscles
    ]);
}

function getMusclesByProgram()
{
    global $pdo;

    $userId = $_GET['user_id'] ?? null;
    $programId = $_GET['program_id'] ?? null;

    if (!$userId || !$programId) {
        throw new Exception('User ID and program ID required');
    }

    // Get all exercises in the program from workout logs
    $sql = "SELECT DISTINCT e.id, e.name
            FROM member_exercise_log mel
            JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            JOIN exercise e ON mwe.exercise_id = e.id
            LEFT JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
            LEFT JOIN member_programhdr mph ON mpw.member_program_hdr_id = mph.id
            WHERE mel.member_id = ? AND mph.id = ?";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId, $programId]);
    $exercises = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($exercises)) {
        echo json_encode([
            'success' => true,
            'muscles' => []
        ]);
        return;
    }

    $exerciseIds = array_column($exercises, 'id');
    $placeholders = str_repeat('?,', count($exerciseIds) - 1) . '?';

    // Get all muscles targeted by these exercises
    $sql = "SELECT DISTINCT 
                tm.id,
                tm.name,
                tm.image_url,
                etm.role,
                COUNT(DISTINCT etm.exercise_id) as exercise_count
            FROM target_muscle tm
            INNER JOIN exercise_target_muscle etm ON tm.id = etm.muscle_id
            WHERE etm.exercise_id IN ($placeholders)
            GROUP BY tm.id, tm.name, tm.image_url, etm.role
            ORDER BY exercise_count DESC, 
                CASE 
                    WHEN etm.role = 'primary' THEN 1
                    WHEN etm.role = 'secondary' THEN 2
                    ELSE 3
                END, tm.name";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($exerciseIds);
    $muscles = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Replace localhost image URLs with placeholder
    foreach ($muscles as &$muscle) {
        $muscle['image_url'] = getDefaultMuscleImage($muscle['name']);
    }

    echo json_encode([
        'success' => true,
        'muscles' => $muscles
    ]);
}

function getMusclesByExercises()
{
    global $pdo;

    $input = json_decode(file_get_contents('php://input'), true);
    $exerciseNames = $input['exercise_names'] ?? [];

    if (empty($exerciseNames)) {
        echo json_encode([
            'success' => true,
            'muscles' => []
        ]);
        return;
    }

    // Get exercise IDs from names
    $placeholders = str_repeat('?,', count($exerciseNames) - 1) . '?';
    $sql = "SELECT id FROM exercise WHERE name IN ($placeholders)";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($exerciseNames);
    $exercises = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($exercises)) {
        echo json_encode([
            'success' => true,
            'muscles' => []
        ]);
        return;
    }

    $exerciseIds = array_column($exercises, 'id');
    $placeholders = str_repeat('?,', count($exerciseIds) - 1) . '?';

    // Get all muscles targeted by these exercises
    $sql = "SELECT DISTINCT 
                tm.id,
                tm.name,
                tm.image_url,
                etm.role,
                COUNT(DISTINCT etm.exercise_id) as exercise_count
            FROM target_muscle tm
            INNER JOIN exercise_target_muscle etm ON tm.id = etm.muscle_id
            WHERE etm.exercise_id IN ($placeholders)
            GROUP BY tm.id, tm.name, tm.image_url, etm.role
            ORDER BY exercise_count DESC, 
                CASE 
                    WHEN etm.role = 'primary' THEN 1
                    WHEN etm.role = 'secondary' THEN 2
                    ELSE 3
                END, tm.name";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($exerciseIds);
    $muscles = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Replace localhost image URLs with placeholder
    foreach ($muscles as &$muscle) {
        $muscle['image_url'] = getDefaultMuscleImage($muscle['name']);
    }

    echo json_encode([
        'success' => true,
        'muscles' => $muscles
    ]);
}

// Helper function to provide default muscle images
function getDefaultMuscleImage($muscleName) {
    // Static image mapping from database (same as weekly muscle analytics)
    $imageMap = [
        'Chest' => 'https://api.cnergy.site/image-servers.php?image=68e4bdc995d2a_1759821257.jpg',
        'Back' => 'https://api.cnergy.site/image-servers.php?image=68e3601c90c68_1759731740.jpg',
        'Shoulder' => 'https://api.cnergy.site/image-servers.php?image=68e35ff3c80bf_1759731699.jpg',
        'Shoulders' => 'https://api.cnergy.site/image-servers.php?image=68e35ff3c80bf_1759731699.jpg',
        'Core' => 'https://api.cnergy.site/image-servers.php?image=68e4bdbf3044e_1759821247.jpg',
        'Arms' => 'https://api.cnergy.site/image-servers.php?image=68e4bdaac1683_1759821226.jpg',
        'Legs' => 'https://api.cnergy.site/image-servers.php?image=68e4bdb72737e_1759821239.jpg',
        'Biceps' => 'https://api.cnergy.site/image-servers.php?image=68e35fc7a61a1_1759731655.jpg',
        'Upper Chest' => 'https://api.cnergy.site/image-servers.php?image=68f64dd7e8266_1760972247.jpg',
        'Middle Chest' => 'https://api.cnergy.site/image-servers.php?image=68f64de00c60e_1760972256.jpg',
        'Lower Chest' => 'https://api.cnergy.site/image-servers.php?image=68f64dcc3d660_1760972236.jpg',
        'Lats' => 'https://api.cnergy.site/image-servers.php?image=68f64d9478f41_1760972180.jpg',
        'Triceps' => 'https://api.cnergy.site/image-servers.php?image=68f64ea977586_1760972457.jpg',
        'Forearms' => 'https://api.cnergy.site/image-servers.php?image=68f64eb18b226_1760972465.jpg',
        'Quads' => 'https://api.cnergy.site/image-servers.php?image=68f64dad93d06_1760972205.jpg',
        'Quadriceps' => 'https://api.cnergy.site/image-servers.php?image=68f64dad93d06_1760972205.jpg',
        'Hamstring' => 'https://api.cnergy.site/image-servers.php?image=68f64db61bead_1760972214.jpg',
        'Hamstrings' => 'https://api.cnergy.site/image-servers.php?image=68f64db61bead_1760972214.jpg',
        'Calves' => 'https://api.cnergy.site/image-servers.php?image=68f64d9e5c757_1760972190.jpg',
        'Obliques' => 'https://api.cnergy.site/image-servers.php?image=68f64e10591ac_1760972304.jpg',
        'Abs' => 'https://api.cnergy.site/image-servers.php?image=68e4bdbf3044e_1759821247.jpg',
        'Glutes' => 'https://api.cnergy.site/image-servers.php?image=68e4bdb72737e_1759821239.jpg',
        'Traps' => 'https://api.cnergy.site/image-servers.php?image=68e3601c90c68_1759731740.jpg',
        'Delts' => 'https://api.cnergy.site/image-servers.php?image=68e35ff3c80bf_1759731699.jpg',
        'Lower Back' => 'https://api.cnergy.site/image-servers.php?image=68e3601c90c68_1759731740.jpg',
    ];

    // Return the mapped image URL or empty string
    return $imageMap[$muscleName] ?? '';
}
?>

