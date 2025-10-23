<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, Origin");
header("Access-Control-Max-Age: 86400");
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
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed', 'error' => $e->getMessage()]);
    exit;
}

// API Endpoints:
// GET  ?action=get_preferences&user_id=X
// POST ?action=save_preferences (body: {user_id, training_focus, custom_muscle_groups})
// POST ?action=dismiss_warning (body: {user_id, muscle_group_id, warning_type, is_permanent, notes})
// POST ?action=reset_dismissals (body: {user_id, muscle_group_id?})
// GET  ?action=get_dismissals&user_id=X
// GET  ?action=get_muscle_groups (returns all available muscle groups for custom selection)

try {
    $action = $_GET['action'] ?? 'get_preferences';

    switch ($action) {
        case 'get_preferences':
            getPreferences($pdo);
            break;
        
        case 'save_preferences':
            savePreferences($pdo);
            break;
        
        case 'dismiss_warning':
            dismissWarning($pdo);
            break;
        
        case 'reset_dismissals':
            resetDismissals($pdo);
            break;
        
        case 'get_dismissals':
            getDismissals($pdo);
            break;
        
        case 'get_muscle_groups':
            getMuscleGroups($pdo);
            break;
        
        default:
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
            break;
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Server error', 'error' => $e->getMessage()]);
}

function getPreferences($pdo) {
    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    if ($userId <= 0) {
        echo json_encode(['success' => false, 'message' => 'Invalid user_id']);
        return;
    }

    $stmt = $pdo->prepare("
        SELECT 
            id,
            user_id,
            training_focus,
            custom_muscle_groups,
            created_at,
            updated_at
        FROM user_training_preferences 
        WHERE user_id = :userId
    ");
    $stmt->execute([':userId' => $userId]);
    $prefs = $stmt->fetch();

    if (!$prefs) {
        // Create default preference if doesn't exist
        $insertStmt = $pdo->prepare("
            INSERT INTO user_training_preferences (user_id, training_focus) 
            VALUES (:userId, 'full_body')
        ");
        $insertStmt->execute([':userId' => $userId]);
        
        $prefs = [
            'id' => (int)$pdo->lastInsertId(),
            'user_id' => (int)$userId,
            'training_focus' => 'full_body',
            'custom_muscle_groups' => null,
            'created_at' => date('Y-m-d H:i:s'),
            'updated_at' => date('Y-m-d H:i:s'),
        ];
    }

    // Decode JSON if present and ensure all IDs are integers
    if ($prefs['custom_muscle_groups']) {
        $decoded = json_decode($prefs['custom_muscle_groups'], true);
        $prefs['custom_muscle_groups'] = is_array($decoded) ? array_map('intval', $decoded) : null;
    }
    
    // Ensure all numeric fields are proper types
    $prefs['id'] = (int)$prefs['id'];
    $prefs['user_id'] = (int)$prefs['user_id'];

    echo json_encode([
        'success' => true,
        'data' => $prefs
    ], JSON_NUMERIC_CHECK);
}

function savePreferences($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    error_log("🔍 PHP SAVE - Received input: " . json_encode($input));
    
    $userId = isset($input['user_id']) ? intval($input['user_id']) : 0;
    $trainingFocus = $input['training_focus'] ?? 'full_body';
    $customMuscleGroups = $input['custom_muscle_groups'] ?? null;

    error_log("🔍 PHP SAVE - User ID: " . $userId);
    error_log("🔍 PHP SAVE - Training Focus: " . $trainingFocus);
    error_log("🔍 PHP SAVE - Custom Muscle Groups: " . json_encode($customMuscleGroups));

    if ($userId <= 0) {
        echo json_encode(['success' => false, 'message' => 'Invalid user_id']);
        return;
    }

    // Validate training_focus
    $validFocus = ['full_body', 'upper_body', 'lower_body', 'custom'];
    if (!in_array($trainingFocus, $validFocus)) {
        echo json_encode(['success' => false, 'message' => 'Invalid training_focus value']);
        return;
    }

    // Encode custom muscle groups as JSON
    $customMuscleGroupsJson = null;
    if ($customMuscleGroups !== null) {
        $customMuscleGroupsJson = json_encode($customMuscleGroups);
    }

    error_log("🔍 PHP SAVE - Will save to DB - customMuscleGroupsJson: " . $customMuscleGroupsJson);

    // Insert or update
    $stmt = $pdo->prepare("
        INSERT INTO user_training_preferences (user_id, training_focus, custom_muscle_groups)
        VALUES (:userId, :trainingFocus, :customMuscleGroups)
        ON DUPLICATE KEY UPDATE 
            training_focus = :trainingFocus,
            custom_muscle_groups = :customMuscleGroups,
            updated_at = CURRENT_TIMESTAMP
    ");

    $stmt->execute([
        ':userId' => $userId,
        ':trainingFocus' => $trainingFocus,
        ':customMuscleGroups' => $customMuscleGroupsJson,
    ]);
    
    error_log("🔍 PHP SAVE - Successfully saved to database");

    echo json_encode([
        'success' => true,
        'message' => 'Preferences saved successfully'
    ], JSON_NUMERIC_CHECK);
}

function dismissWarning($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $userId = isset($input['user_id']) ? intval($input['user_id']) : 0;
    $muscleGroupId = isset($input['muscle_group_id']) ? intval($input['muscle_group_id']) : 0;
    $warningType = $input['warning_type'] ?? 'neglected';
    $isPermanent = isset($input['is_permanent']) ? (bool)$input['is_permanent'] : false;
    $notes = $input['notes'] ?? null;

    if ($userId <= 0 || $muscleGroupId <= 0) {
        echo json_encode(['success' => false, 'message' => 'Invalid user_id or muscle_group_id']);
        return;
    }

    // Insert or update dismissal
    $stmt = $pdo->prepare("
        INSERT INTO user_warning_dismissals 
            (user_id, muscle_group_id, warning_type, dismiss_count, is_permanent, notes)
        VALUES 
            (:userId, :muscleGroupId, :warningType, 1, :isPermanent, :notes)
        ON DUPLICATE KEY UPDATE 
            dismiss_count = dismiss_count + 1,
            is_permanent = :isPermanent,
            notes = :notes,
            last_seen_at = CURRENT_TIMESTAMP
    ");

    $stmt->execute([
        ':userId' => $userId,
        ':muscleGroupId' => $muscleGroupId,
        ':warningType' => $warningType,
        ':isPermanent' => $isPermanent ? 1 : 0,
        ':notes' => $notes,
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Warning dismissed successfully'
    ]);
}

function resetDismissals($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $userId = isset($input['user_id']) ? intval($input['user_id']) : 0;
    $muscleGroupId = isset($input['muscle_group_id']) ? intval($input['muscle_group_id']) : null;

    if ($userId <= 0) {
        echo json_encode(['success' => false, 'message' => 'Invalid user_id']);
        return;
    }

    if ($muscleGroupId) {
        // Reset specific muscle group
        $stmt = $pdo->prepare("
            DELETE FROM user_warning_dismissals 
            WHERE user_id = :userId AND muscle_group_id = :muscleGroupId
        ");
        $stmt->execute([':userId' => $userId, ':muscleGroupId' => $muscleGroupId]);
    } else {
        // Reset all dismissals
        $stmt = $pdo->prepare("
            DELETE FROM user_warning_dismissals 
            WHERE user_id = :userId
        ");
        $stmt->execute([':userId' => $userId]);
    }

    echo json_encode([
        'success' => true,
        'message' => 'Dismissals reset successfully'
    ]);
}

function getDismissals($pdo) {
    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    if ($userId <= 0) {
        echo json_encode(['success' => false, 'message' => 'Invalid user_id']);
        return;
    }

    $stmt = $pdo->prepare("
        SELECT 
            uwd.*,
            tm.name as muscle_group_name
        FROM user_warning_dismissals uwd
        JOIN target_muscle tm ON tm.id = uwd.muscle_group_id
        WHERE uwd.user_id = :userId
        ORDER BY uwd.last_seen_at DESC
    ");
    $stmt->execute([':userId' => $userId]);
    $dismissals = $stmt->fetchAll();

    echo json_encode([
        'success' => true,
        'data' => $dismissals
    ], JSON_NUMERIC_CHECK);
}

function getMuscleGroups($pdo) {
    // Get all parent muscle groups (groups with no parent_id)
    $stmt = $pdo->query("
        SELECT 
            id,
            name
        FROM target_muscle 
        WHERE parent_id IS NULL
        ORDER BY name ASC
    ");
    $groups = $stmt->fetchAll();
    
    // Ensure all IDs are integers
    $groups = array_map(function($group) {
        return [
            'id' => (int)$group['id'],
            'name' => (string)$group['name'],
        ];
    }, $groups);

    echo json_encode([
        'success' => true,
        'data' => array_values($groups)
    ], JSON_NUMERIC_CHECK);
}

?>

