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

// Debug logging
error_log("DEBUG - API Request:");
error_log("  Method: " . $_SERVER['REQUEST_METHOD']);
error_log("  Action: '$action'");
error_log("  Input: " . json_encode($input ?? []));

// Route to appropriate functions
switch($action) {
    case 'fetchMuscles':
        fetchMusclesForUsers($pdo);
        break;
    case 'fetchExercises':
        fetchExercisesForUsers($pdo);
        break;
    case 'createRoutine':
        createRoutineForClient($pdo);
        break;
    case 'test':
        echo json_encode(['success' => true, 'message' => 'API is working', 'timestamp' => date('Y-m-d H:i:s')]);
        break;
    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action', 'received_action' => $action]);
        break;
}

// ============================================
// MUSCLE GROUP FUNCTIONS (same as user routine creation)
// ============================================
function fetchMusclesForUsers($pdo) {
    try {
        // Get muscle groups (parent muscles)
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

// ============================================
// EXERCISE FUNCTIONS (same as user routine creation)
// ============================================
function fetchExercisesForUsers($pdo) {
    try {
        $muscleGroupId = $_GET['muscle_group_id'] ?? null;
        
        if ($muscleGroupId) {
            // Get exercises for specific muscle group
            $stmt = $pdo->prepare("
                SELECT DISTINCT e.id, e.name, e.description, e.image_url, e.video_url
                FROM exercise e
                INNER JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
                INNER JOIN target_muscle tm ON etm.muscle_id = tm.id
                WHERE tm.id = ? OR tm.parent_id = ?
                ORDER BY e.name
            ");
            $stmt->execute([$muscleGroupId, $muscleGroupId]);
        } else {
            // Get all exercises
            $stmt = $pdo->prepare("
                SELECT e.id, e.name, e.description, e.image_url, e.video_url
                FROM exercise e
                ORDER BY e.name
            ");
            $stmt->execute();
        }
        
        $exercises = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Convert IDs to integers for Flutter compatibility
        foreach ($exercises as &$exercise) {
            $exercise['id'] = (int)$exercise['id'];
        }
        
        echo json_encode(['success' => true, 'data' => $exercises]);
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching exercises: ' . $e->getMessage()]);
    }
}

// ============================================
// ROUTINE CREATION FUNCTION (same as user routine creation)
// ============================================
function createRoutineForClient($pdo) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
            return;
        }
        
        // Validate required fields
        $userId = $input['user_id'] ?? null;
        $createdBy = $input['created_by'] ?? null; // Coach ID
        $workoutName = $input['workout_name'] ?? null;
        $exercises = $input['exercises'] ?? [];
        
        // Debug logging
        error_log("DEBUG - Coach Routine Creation:");
        error_log("  user_id (client): $userId");
        error_log("  created_by (coach): $createdBy");
        error_log("  workout_name: $workoutName");
        error_log("  exercises count: " . count($exercises));
        
        if (!$userId || !$createdBy || !$workoutName || empty($exercises)) {
            echo json_encode([
                'success' => false,
                'message' => 'Missing required fields: user_id, created_by, workout_name, exercises'
            ]);
            return;
        }
        
        // Validate user_id and created_by are integers
        $userId = filter_var($userId, FILTER_VALIDATE_INT);
        $createdBy = filter_var($createdBy, FILTER_VALIDATE_INT);
        
        if ($userId === false || $createdBy === false) {
            echo json_encode(['success' => false, 'message' => 'Invalid user_id or created_by format']);
            return;
        }
        
        // Start transaction
        $pdo->beginTransaction();
        
        try {
            // Insert into member_programhdr (same as user routine creation)
            $sql = "INSERT INTO member_programhdr
                (user_id, program_hdr_id, created_by, color, tags, goal, notes, completion_rate, scheduled_days, difficulty, total_sessions)
                VALUES (:user_id, :program_hdr_id, :created_by, :color, :tags, :goal, :notes, :completion_rate, :scheduled_days, :difficulty, :total_sessions)";
            
            $stmt = $pdo->prepare($sql);
            $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
            $stmt->bindValue(':program_hdr_id', null, PDO::PARAM_NULL);
            $stmt->bindValue(':created_by', $createdBy, PDO::PARAM_INT); // Coach ID
            
            // Debug logging for database insertion
            error_log("DEBUG - Inserting into member_programhdr:");
            error_log("  user_id (client): $userId");
            error_log("  created_by (coach): $createdBy");
            $stmt->bindValue(':color', $input['color'] ?? '0xFF96CEB4');
            $stmt->bindValue(':tags', json_encode($input['tags'] ?? []));
            $stmt->bindValue(':goal', $input['goal'] ?? '');
            $stmt->bindValue(':notes', $input['notes'] ?? '');
            $stmt->bindValue(':completion_rate', $input['completionRate'] ?? $input['completion_rate'] ?? 0, PDO::PARAM_INT);
            $stmt->bindValue(':scheduled_days', json_encode($input['scheduledDays'] ?? $input['scheduled_days'] ?? []));
            $stmt->bindValue(':difficulty', $input['difficulty'] ?? 'Beginner');
            $stmt->bindValue(':total_sessions', $input['totalSessions'] ?? $input['total_sessions'] ?? 0, PDO::PARAM_INT);
            
            $result = $stmt->execute();
            
            if (!$result) {
                error_log("ERROR - Failed to execute member_programhdr insert");
                throw new Exception("Failed to insert routine header");
            }
            
            $memberProgramHdrId = $pdo->lastInsertId();
            error_log("SUCCESS - Inserted member_programhdr with ID: $memberProgramHdrId");
            
            // Insert workout details into member_program_workout
            $workoutSql = "INSERT INTO member_program_workout (member_program_hdr_id, workout_details) VALUES (?, ?)";
            $workoutStmt = $pdo->prepare($workoutSql);
            $workoutDetails = json_encode([
                'name' => $workoutName,
                'duration' => $input['duration'] ?? '30',
                'created_at' => date('Y-m-d H:i:s')
            ]);
            $workoutStmt->execute([$memberProgramHdrId, $workoutDetails]);
            $memberProgramWorkoutId = $pdo->lastInsertId();
            
            // Insert exercises into member_workout_exercise
            if (!empty($exercises) && is_array($exercises)) {
                $exerciseSql = "INSERT INTO member_workout_exercise
                    (member_program_workout_id, exercise_id, sets, reps, weight)
                    VALUES (:member_program_workout_id, :exercise_id, :sets, :reps, :weight)";
                
                $exerciseStmt = $pdo->prepare($exerciseSql);
                
                foreach ($exercises as $exercise) {
                    $exerciseId = filter_var($exercise['id'] ?? $exercise['exercise_id'], FILTER_VALIDATE_INT);
                    if ($exerciseId === false) {
                        throw new Exception("Invalid exercise ID: " . ($exercise['name'] ?? 'unknown'));
                    }
                    
                    $sets = filter_var($exercise['sets'] ?? $exercise['targetSets'] ?? 3, FILTER_VALIDATE_INT);
                    $reps = filter_var($exercise['reps'] ?? $exercise['targetReps'] ?? 10, FILTER_VALIDATE_INT);
                    $weight = filter_var($exercise['weight'] ?? $exercise['targetWeight'] ?? 0.0, FILTER_VALIDATE_FLOAT);
                    
                    if ($sets === false) $sets = 3;
                    if ($reps === false) $reps = 10;
                    if ($weight === false) $weight = 0.0;
                    
                    $exerciseStmt->bindValue(':member_program_workout_id', $memberProgramWorkoutId, PDO::PARAM_INT);
                    $exerciseStmt->bindValue(':exercise_id', $exerciseId, PDO::PARAM_INT);
                    $exerciseStmt->bindValue(':sets', $sets, PDO::PARAM_INT);
                    $exerciseStmt->bindValue(':reps', $reps, PDO::PARAM_INT);
                    $exerciseStmt->bindValue(':weight', $weight, PDO::PARAM_STR);
                    
                    if (!$exerciseStmt->execute()) {
                        throw new Exception("Failed to insert exercise: " . ($exercise['name'] ?? 'unknown'));
                    }
                }
            }
            
            // Commit transaction
            $pdo->commit();
            
            $response = [
                'success' => true,
                'id' => (int)$memberProgramHdrId,
                'message' => 'Routine created successfully for client',
                'created_by' => $createdBy
            ];
            
            error_log("SUCCESS - Routine created successfully:");
            error_log("  member_programhdr_id: $memberProgramHdrId");
            error_log("  user_id (client): $userId");
            error_log("  created_by (coach): $createdBy");
            
            echo json_encode($response);
            
        } catch (Exception $e) {
            $pdo->rollBack();
            throw $e;
        }
        
    } catch (PDOException $e) {
        error_log("PDO ERROR - Database error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    } catch (Exception $e) {
        error_log("GENERAL ERROR - " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}
?>