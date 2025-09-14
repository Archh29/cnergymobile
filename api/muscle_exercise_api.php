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
} catch(PDOException $e) {
	echo json_encode(['success' => false, 'message' => 'Database connection failed']);
	exit;
}

// Get action from request
$action = '';
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $action = $_GET['action'] ?? '';
} else {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $input['action'] ?? $_POST['action'] ?? '';
}

// Route to appropriate functions
switch($action) {
    // Admin Exercise operations
    case 'get_exercises':
        getExercises($pdo);
        break;
    case 'create_exercise':
        createExercise($pdo);
        break;
    case 'update_exercise':
        updateExercise($pdo);
        break;
    case 'delete_exercise':
        deleteExercise($pdo);
        break;
            
    // Admin Muscle operations
    case 'get_muscles':
        getMuscles($pdo);
        break;
    case 'create_muscle':
        createMuscle($pdo);
        break;
    case 'update_muscle':
        updateMuscle($pdo);
        break;
    case 'delete_muscle':
        deleteMuscle($pdo);
        break;
            
    // User-facing operations for routine creation
    case 'fetchMuscles':
        fetchMusclesForUsers($pdo);
        break;
    case 'fetchExercises':
        fetchExercisesForUsers($pdo);
        break;
            
    // File upload
    case 'upload_file':
        uploadFile();
        break;
        
    case 'get_muscle_groups':
        getMuscleGroups($pdo);
        break;
    case 'get_muscle_parts':
        getMuscleParts($pdo);
        break;
            
    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
        break;
}

// ============================================
// ADMIN FUNCTIONS (existing)
// ============================================
function getExercises($pdo) {
    try {
        // Fixed table names to lowercase
        $stmt = $pdo->prepare("
            SELECT e.id, e.name, e.description, e.image_url, e.video_url, 
                   e.instructions, e.benefits
            FROM exercise e
            ORDER BY e.name
        ");
                
        $stmt->execute();
        $exercises = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
        // Get target muscles for each exercise with roles
        foreach ($exercises as &$exercise) {
            // Convert exercise ID to integer
            $exercise['id'] = (int)$exercise['id'];
            
            // Fixed table names to lowercase
            $muscleStmt = $pdo->prepare("
                SELECT tm.id, tm.name, tm.image_url, tm.parent_id, etm.role
                FROM target_muscle tm
                INNER JOIN exercise_target_muscle etm ON tm.id = etm.muscle_id
                WHERE etm.exercise_id = ?
                ORDER BY etm.role, tm.name
            ");
            $muscleStmt->execute([$exercise['id']]);
            $targetMuscles = $muscleStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Convert muscle IDs to integers
            foreach ($targetMuscles as &$muscle) {
                $muscle['id'] = (int)$muscle['id'];
                if ($muscle['parent_id'] !== null) {
                    $muscle['parent_id'] = (int)$muscle['parent_id'];
                }
            }
            
            $exercise['target_muscles'] = $targetMuscles;
        }
                
        echo json_encode(['success' => true, 'data' => $exercises]);
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching exercises: ' . $e->getMessage()]);
    }
}

function createExercise($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
        
    if (!isset($input['name']) || empty(trim($input['name']))) {
        echo json_encode(['success' => false, 'message' => 'Exercise name is required']);
        return;
    }
        
    try {
        $pdo->beginTransaction();
            
        // Fixed table name to lowercase
        $stmt = $pdo->prepare("
            INSERT INTO exercise (name, description, image_url, video_url, instructions, benefits) 
            VALUES (?, ?, ?, ?, ?, ?)
        ");
                
        $stmt->execute([
            trim($input['name']),
            trim($input['description'] ?? ''),
            $input['image_url'] ?? '',
            $input['video_url'] ?? '',
            trim($input['instructions'] ?? ''),
            trim($input['benefits'] ?? '')
        ]);
                
        $exerciseId = $pdo->lastInsertId();
            
        if (!empty($input['target_muscles']) && is_array($input['target_muscles'])) {
            // Fixed table name to lowercase
            $muscleStmt = $pdo->prepare("
                INSERT INTO exercise_target_muscle (exercise_id, muscle_id, role) 
                VALUES (?, ?, ?)
            ");
                        
            foreach ($input['target_muscles'] as $muscle) {
                if (is_array($muscle) && isset($muscle['id']) && isset($muscle['role'])) {
                    $muscleStmt->execute([$exerciseId, $muscle['id'], $muscle['role']]);
                }
            }
        }
            
        $pdo->commit();
        echo json_encode(['success' => true, 'message' => 'Exercise created successfully', 'id' => $exerciseId]);
            
    } catch(PDOException $e) {
        $pdo->rollBack();
        echo json_encode(['success' => false, 'message' => 'Error creating exercise: ' . $e->getMessage()]);
    }
}

function updateExercise($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
        
    if (!isset($input['id']) || !isset($input['name']) || empty(trim($input['name']))) {
        echo json_encode(['success' => false, 'message' => 'Exercise ID and name are required']);
        return;
    }
        
    try {
        $pdo->beginTransaction();
            
        // Fixed table name to lowercase
        $stmt = $pdo->prepare("
            UPDATE exercise 
            SET name = ?, description = ?, image_url = ?, video_url = ?, instructions = ?, benefits = ?
            WHERE id = ?
        ");
                
        $stmt->execute([
            trim($input['name']),
            trim($input['description'] ?? ''),
            $input['image_url'] ?? '',
            $input['video_url'] ?? '',
            trim($input['instructions'] ?? ''),
            trim($input['benefits'] ?? ''),
            $input['id']
        ]);
            
        // Delete existing target muscles - Fixed table name
        $deleteStmt = $pdo->prepare("DELETE FROM exercise_target_muscle WHERE exercise_id = ?");
        $deleteStmt->execute([$input['id']]);
            
        if (!empty($input['target_muscles']) && is_array($input['target_muscles'])) {
            // Fixed table name to lowercase
            $muscleStmt = $pdo->prepare("
                INSERT INTO exercise_target_muscle (exercise_id, muscle_id, role) 
                VALUES (?, ?, ?)
            ");
                        
            foreach ($input['target_muscles'] as $muscle) {
                if (is_array($muscle) && isset($muscle['id']) && isset($muscle['role'])) {
                    $muscleStmt->execute([$input['id'], $muscle['id'], $muscle['role']]);
                }
            }
        }
            
        $pdo->commit();
        echo json_encode(['success' => true, 'message' => 'Exercise updated successfully']);
            
    } catch(PDOException $e) {
        $pdo->rollBack();
        echo json_encode(['success' => false, 'message' => 'Error updating exercise: ' . $e->getMessage()]);
    }
}

function deleteExercise($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
        
    if (!isset($input['id'])) {
        echo json_encode(['success' => false, 'message' => 'Exercise ID is required']);
        return;
    }
        
    try {
        $pdo->beginTransaction();
            
        // Delete target muscle relationships - Fixed table name
        $stmt = $pdo->prepare("DELETE FROM exercise_target_muscle WHERE exercise_id = ?");
        $stmt->execute([$input['id']]);
            
        // Delete exercise - Fixed table name
        $stmt = $pdo->prepare("DELETE FROM exercise WHERE id = ?");
        $stmt->execute([$input['id']]);
            
        $pdo->commit();
        echo json_encode(['success' => true, 'message' => 'Exercise deleted successfully']);
            
    } catch(PDOException $e) {
        $pdo->rollBack();
        echo json_encode(['success' => false, 'message' => 'Error deleting exercise: ' . $e->getMessage()]);
    }
}

function getMuscles($pdo) {
    try {
        // Fixed table names to lowercase
        $stmt = $pdo->prepare("
            SELECT tm.*, 
                   CASE WHEN tm.parent_id IS NOT NULL THEN parent.name ELSE NULL END as parent_name
            FROM target_muscle tm
            LEFT JOIN target_muscle parent ON tm.parent_id = parent.id
            ORDER BY COALESCE(tm.parent_id, tm.id), tm.parent_id IS NULL DESC, tm.name
        ");
        $stmt->execute();
        $muscles = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Convert IDs to integers for Flutter compatibility
        foreach ($muscles as &$muscle) {
            $muscle['id'] = (int)$muscle['id'];
            if ($muscle['parent_id'] !== null) {
                $muscle['parent_id'] = (int)$muscle['parent_id'];
            }
        }
                
        echo json_encode(['success' => true, 'data' => $muscles]);
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching muscles: ' . $e->getMessage()]);
    }
}

function createMuscle($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
        
    if (!isset($input['name']) || empty(trim($input['name']))) {
        echo json_encode(['success' => false, 'message' => 'Muscle name is required']);
        return;
    }
        
    try {
        // Fixed table name to lowercase
        $stmt = $pdo->prepare("INSERT INTO target_muscle (name, image_url, parent_id) VALUES (?, ?, ?)");
        $stmt->execute([
            trim($input['name']),
            $input['image_url'] ?? '',
            !empty($input['parent_id']) ? $input['parent_id'] : null
        ]);
                
        $muscleId = $pdo->lastInsertId();
        echo json_encode(['success' => true, 'message' => 'Muscle created successfully', 'id' => $muscleId]);
            
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error creating muscle: ' . $e->getMessage()]);
    }
}

function updateMuscle($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
        
    if (!isset($input['id']) || !isset($input['name']) || empty(trim($input['name']))) {
        echo json_encode(['success' => false, 'message' => 'Muscle ID and name are required']);
        return;
    }
        
    try {
        // Fixed table name to lowercase
        $stmt = $pdo->prepare("UPDATE target_muscle SET name = ?, image_url = ?, parent_id = ? WHERE id = ?");
        $stmt->execute([
            trim($input['name']),
            $input['image_url'] ?? '',
            !empty($input['parent_id']) ? $input['parent_id'] : null,
            $input['id']
        ]);
                
        echo json_encode(['success' => true, 'message' => 'Muscle updated successfully']);
            
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error updating muscle: ' . $e->getMessage()]);
    }
}

function deleteMuscle($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
        
    if (!isset($input['id'])) {
        echo json_encode(['success' => false, 'message' => 'Muscle ID is required']);
        return;
    }
        
    try {
        $pdo->beginTransaction();
            
        // Delete exercise-muscle relationships - Fixed table name
        $stmt = $pdo->prepare("DELETE FROM exercise_target_muscle WHERE muscle_id = ?");
        $stmt->execute([$input['id']]);
            
        // Delete muscle - Fixed table name
        $stmt = $pdo->prepare("DELETE FROM target_muscle WHERE id = ?");
        $stmt->execute([$input['id']]);
            
        $pdo->commit();
        echo json_encode(['success' => true, 'message' => 'Muscle deleted successfully']);
            
    } catch(PDOException $e) {
        $pdo->rollBack();
        echo json_encode(['success' => false, 'message' => 'Error deleting muscle: ' . $e->getMessage()]);
    }
}

// ============================================
// USER-FACING FUNCTIONS (new)
// ============================================
function fetchMusclesForUsers($pdo) {
    try {
        // Fixed table name to lowercase
        $stmt = $pdo->prepare("
            SELECT id, name, image_url 
            FROM target_muscle 
            WHERE parent_id IS NULL
            ORDER BY name
        ");
        $stmt->execute();
        $muscles = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Convert ID to integer for Flutter compatibility
        foreach ($muscles as &$muscle) {
            $muscle['id'] = (int)$muscle['id'];
        }
                
        echo json_encode([
            'success' => true, 
            'muscles' => $muscles
        ]);
    } catch(PDOException $e) {
        echo json_encode([
            'success' => false, 
            'error' => 'Error fetching muscle groups: ' . $e->getMessage()
        ]);
    }
}

function fetchExercisesForUsers($pdo) {
    try {
        $muscleId = $_GET['muscle_id'] ?? null;
        
        if ($muscleId && is_numeric($muscleId)) {
            // Get distinct exercises that target the specified muscle - Fixed table names
            $stmt = $pdo->prepare("
                SELECT DISTINCT e.id, e.name, e.description, e.image_url, e.video_url,
                                e.instructions, e.benefits
                FROM exercise e
                INNER JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
                WHERE etm.muscle_id = ?
                ORDER BY e.name
            ");
            $stmt->execute([$muscleId]);
            $exercises = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Get all muscle relationships for these exercises in one query
            if (!empty($exercises)) {
                $exerciseIds = array_column($exercises, 'id');
                $placeholders = str_repeat('?,', count($exerciseIds) - 1) . '?';
                
                // Fixed table names to lowercase
                $muscleStmt = $pdo->prepare("
                    SELECT etm.exercise_id, CONCAT(tm.name, ' (', etm.role, ')') as muscle_role
                    FROM target_muscle tm
                    INNER JOIN exercise_target_muscle etm ON tm.id = etm.muscle_id
                    WHERE etm.exercise_id IN ($placeholders)
                    ORDER BY etm.exercise_id, etm.role, tm.name
                ");
                $muscleStmt->execute($exerciseIds);
                $muscleRoles = $muscleStmt->fetchAll(PDO::FETCH_ASSOC);
                
                // Group muscle roles by exercise_id
                $musclesByExercise = [];
                foreach ($muscleRoles as $role) {
                    $musclesByExercise[$role['exercise_id']][] = $role['muscle_role'];
                }
                
                // Debug: Log muscle roles for first few exercises
                $debugCount = 0;
                foreach ($musclesByExercise as $exerciseId => $muscles) {
                    if ($debugCount < 3) {
                        error_log("[v0] Exercise ID $exerciseId muscles: " . implode(', ', $muscles));
                        $debugCount++;
                    }
                }
                
                // Add muscle roles to exercises
                foreach ($exercises as &$exercise) {
                    $exercise['target_muscle'] = isset($musclesByExercise[$exercise['id']]) 
                        ? implode(', ', $musclesByExercise[$exercise['id']]) 
                        : '';
                }
            }
        } else {
            // Fetch all exercises with their muscle relationships - Fixed table names
            $stmt = $pdo->prepare("
                SELECT e.id, e.name, e.description, e.image_url, e.video_url,
                       e.instructions, e.benefits,
                       COALESCE(GROUP_CONCAT(CONCAT(tm.name, ' (', etm.role, ')') SEPARATOR ', '), '') as target_muscle
                FROM exercise e
                LEFT JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
                LEFT JOIN target_muscle tm ON etm.muscle_id = tm.id
                GROUP BY e.id, e.name, e.description, e.image_url, e.video_url, e.instructions, e.benefits
                ORDER BY e.name
            ");
            $stmt->execute();
            $exercises = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }
        
        // Format exercises for Flutter app - ensure no duplicates
        $formattedExercises = [];
        $seenExerciseIds = [];
        
        foreach ($exercises as $exercise) {
            if (in_array($exercise['id'], $seenExerciseIds)) {
                error_log("[v0] WARNING: Duplicate exercise ID {$exercise['id']} detected and skipped");
                continue;
            }
            
            $seenExerciseIds[] = $exercise['id'];
            
            $formattedExercises[] = [
                'id' => (int)$exercise['id'],
                'name' => $exercise['name'],
                'description' => $exercise['description'] ?? '',
                'instructions' => $exercise['instructions'] ?? '',
                'benefits' => $exercise['benefits'] ?? '',
                'image_url' => $exercise['image_url'] ?? '',
                'video_url' => $exercise['video_url'] ?? '',
                'target_muscle' => $exercise['target_muscle'] ?? '',
                'category' => 'General', // Default category
                'difficulty' => 'Intermediate', // Default difficulty
            ];
        }
        
        error_log("[v0] Returning " . count($formattedExercises) . " unique exercises for muscle_id: " . ($muscleId ?? 'all'));
        
        // Debug: Log first few exercises to see their target_muscle data
        for ($i = 0; $i < min(3, count($formattedExercises)); $i++) {
            $exercise = $formattedExercises[$i];
            error_log("[v0] Exercise {$exercise['id']}: '{$exercise['name']}' - Target Muscle: '{$exercise['target_muscle']}'");
        }
        
        echo json_encode([
            'success' => true, 
            'exercises' => $formattedExercises
        ]);
        
    } catch(PDOException $e) {
        error_log("[v0] Database error in fetchExercisesForUsers: " . $e->getMessage());
        echo json_encode([
            'success' => false, 
            'error' => 'Error fetching exercises: ' . $e->getMessage()
        ]);
    }
}

// ============================================
// NEW ADMIN FUNCTIONS (added)
// ============================================
function getMuscleGroups($pdo) {
    try {
        // Fixed table name to lowercase
        $stmt = $pdo->prepare("
            SELECT tm.id, tm.name, tm.image_url, tm.parent_id
            FROM target_muscle tm
            WHERE tm.parent_id IS NULL
            ORDER BY tm.name
        ");
        $stmt->execute();
        $muscleGroups = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Convert IDs to integers for Flutter compatibility
        foreach ($muscleGroups as &$group) {
            $group['id'] = (int)$group['id'];
            if ($group['parent_id'] !== null) {
                $group['parent_id'] = (int)$group['parent_id'];
            }
        }
                
        echo json_encode(['success' => true, 'data' => $muscleGroups]);
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching muscle groups: ' . $e->getMessage()]);
    }
}

function getMuscleParts($pdo) {
    try {
        $parentId = $_GET['parent_id'] ?? null;
        
        if ($parentId && is_numeric($parentId)) {
            // Get muscle parts for specific parent - Fixed table names
            $stmt = $pdo->prepare("
                SELECT tm.id, tm.name, tm.image_url, tm.parent_id,
                       parent.name as parent_name
                FROM target_muscle tm
                INNER JOIN target_muscle parent ON tm.parent_id = parent.id
                WHERE tm.parent_id = ?
                ORDER BY tm.name
            ");
            $stmt->execute([$parentId]);
        } else {
            // Get all muscle parts (those with parent_id) - Fixed table names
            $stmt = $pdo->prepare("
                SELECT tm.id, tm.name, tm.image_url, tm.parent_id,
                       parent.name as parent_name
                FROM target_muscle tm
                INNER JOIN target_muscle parent ON tm.parent_id = parent.id
                WHERE tm.parent_id IS NOT NULL
                ORDER BY parent.name, tm.name
            ");
            $stmt->execute();
        }
        
        $muscleParts = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Convert IDs to integers for Flutter compatibility
        foreach ($muscleParts as &$part) {
            $part['id'] = (int)$part['id'];
            if ($part['parent_id'] !== null) {
                $part['parent_id'] = (int)$part['parent_id'];
            }
        }
                
        echo json_encode(['success' => true, 'data' => $muscleParts]);
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching muscle parts: ' . $e->getMessage()]);
    }
}

// ============================================
// FILE UPLOAD FUNCTION (existing)
// ============================================
function uploadFile() {
    // Upload configuration
    $uploadDir = 'uploads/';
    $maxImageSize = 10 * 1024 * 1024; // 10MB for images
    $maxVideoSize = 100 * 1024 * 1024; // 100MB for videos
        
    $allowedImageTypes = [
        'image/jpeg', 
        'image/jpg', 
        'image/png', 
        'image/gif', 
        'image/webp'
    ];
        
    $allowedVideoTypes = [
        'video/mp4', 
        'video/mpeg', 
        'video/quicktime',
        'video/x-msvideo', // .avi
        'video/webm',
        'video/ogg',
        'video/3gpp',
        'video/x-ms-wmv' // .wmv
    ];
    // Create upload directory if it doesn't exist
    if (!file_exists($uploadDir)) {
        if (!mkdir($uploadDir, 0777, true)) {
            echo json_encode(['success' => false, 'message' => 'Failed to create upload directory']);
            return;
        }
    }
    if (!isset($_FILES['file']) || !isset($_POST['type'])) {
        echo json_encode(['success' => false, 'message' => 'File and type are required']);
        return;
    }
    $file = $_FILES['file'];
    $type = $_POST['type'];
    // Check for upload errors
    if ($file['error'] !== UPLOAD_ERR_OK) {
        $errorMessages = [
            UPLOAD_ERR_INI_SIZE => 'File exceeds upload_max_filesize directive',
            UPLOAD_ERR_FORM_SIZE => 'File exceeds MAX_FILE_SIZE directive',
            UPLOAD_ERR_PARTIAL => 'File was only partially uploaded',
            UPLOAD_ERR_NO_FILE => 'No file was uploaded',
            UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
            UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
            UPLOAD_ERR_EXTENSION => 'File upload stopped by extension'
        ];
                
        $errorMessage = $errorMessages[$file['error']] ?? 'Unknown upload error';
        echo json_encode(['success' => false, 'message' => $errorMessage]);
        return;
    }
    // Determine file type and size limits
    if ($type === 'image') {
        $allowedTypes = $allowedImageTypes;
        $maxSize = $maxImageSize;
        $typeLabel = 'image';
    } else if ($type === 'video') {
        $allowedTypes = $allowedVideoTypes;
        $maxSize = $maxVideoSize;
        $typeLabel = 'video';
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid file type specified']);
        return;
    }
    // Check file size
    if ($file['size'] > $maxSize) {
        $maxSizeMB = $maxSize / (1024 * 1024);
        echo json_encode(['success' => false, 'message' => "File too large. Maximum size for {$typeLabel} is {$maxSizeMB}MB"]);
        return;
    }
    // Get file info
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    // Check MIME type
    if (!in_array($mimeType, $allowedTypes)) {
        echo json_encode([
            'success' => false, 
            'message' => "Invalid {$typeLabel} type. Detected: {$mimeType}. Allowed types: " . implode(', ', $allowedTypes)
        ]);
        return;
    }
    // Generate unique filename
    $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $filename = uniqid() . '_' . time() . '.' . $extension;
    $filepath = $uploadDir . $filename;
    // Move uploaded file
    if (move_uploaded_file($file['tmp_name'], $filepath)) {
        // THIS IS THE LINE TO CHANGE
        $fileUrl = 'http://localhost/cynergy/image-servers.php?image=' . $filename; // Corrected line for plural 'servers'
        echo json_encode([
            'success' => true, 
            'message' => ucfirst($typeLabel) . ' uploaded successfully',
            'file_url' => $fileUrl,
            'filename' => $filename,
            'file_size' => $file['size'],
            'mime_type' => $mimeType
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to move uploaded file']);
    }
}
?>
