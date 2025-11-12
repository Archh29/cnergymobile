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
    $action = trim($_GET['action'] ?? '');
} else {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = trim($input['action'] ?? $_POST['action'] ?? '');
}

// Debug logging
error_log("DEBUG - API Request:");
error_log("  Method: " . $_SERVER['REQUEST_METHOD']);
error_log("  Action: '$action'");
error_log("  Action length: " . strlen($action));
error_log("  Action bytes: " . bin2hex($action));
error_log("  Input: " . json_encode($input ?? []));

// Route to appropriate functions
error_log("DEBUG - About to switch on action: '$action'");
switch($action) {
    case 'fetchMuscles':
        error_log("DEBUG - Matched fetchMuscles");
        fetchMusclesForUsers($pdo);
        break;
    case 'fetchExercises':
        error_log("DEBUG - Matched fetchExercises");
        fetchExercisesForUsers($pdo);
        break;
    case 'createRoutine':
        error_log("DEBUG - Matched createRoutine");
        createRoutineForClient($pdo);
        break;
    case 'createTemplate':
        error_log("DEBUG - Matched createTemplate");
        if (function_exists('createCoachTemplate')) {
            error_log("DEBUG - Function createCoachTemplate exists");
            createCoachTemplate($pdo);
        } else {
            error_log("DEBUG - Function createCoachTemplate does not exist");
            echo json_encode(['success' => false, 'message' => 'Function createCoachTemplate not found']);
        }
        break;
    case 'getTemplates':
        error_log("DEBUG - Matched getTemplates");
        if (function_exists('getCoachTemplates')) {
            error_log("DEBUG - Function getCoachTemplates exists");
            getCoachTemplates($pdo);
        } else {
            error_log("DEBUG - Function getCoachTemplates does not exist");
            echo json_encode(['success' => false, 'message' => 'Function getCoachTemplates not found']);
        }
        break;
    case 'getTemplateDetails':
        if (function_exists('getTemplateDetails')) {
            getTemplateDetails($pdo);
        } else {
            echo json_encode(['success' => false, 'message' => 'Function getTemplateDetails not found']);
        }
        break;
    case 'assignTemplate':
        error_log("DEBUG - Matched assignTemplate");
        assignTemplateToClient($pdo);
        break;
    case 'getClientRoutines':
        error_log("DEBUG - Matched getClientRoutines");
        getClientRoutinesWithExercises($pdo);
        break;
    case 'test':
        error_log("DEBUG - Matched test");
        echo json_encode(['success' => true, 'message' => 'API is working', 'timestamp' => date('Y-m-d H:i:s')]);
        break;
    case 'testDatabase':
        testDatabaseConnection($pdo);
        break;
    case 'checkTemplates':
        checkTemplatesInDatabase($pdo);
        break;
    case 'checkTableStructure':
        checkTableStructure($pdo);
        break;
    case 'getCoachClients':
        getCoachClients($pdo);
        break;
    case 'testAssignment':
        testTemplateAssignment($pdo);
        break;
    default:
        error_log("DEBUG - No match found for action: '$action'");
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

// ============================================
// COACH TEMPLATE FUNCTIONS (Using programhdr table)
// ============================================
function createCoachTemplate($pdo) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        error_log("DEBUG - createCoachTemplate called");
        error_log("DEBUG - Input data: " . json_encode($input));
        
        if (!$input) {
            error_log("ERROR - Invalid JSON input");
            echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
            return;
        }
        
        // Validate required fields
        $createdBy = $input['created_by'] ?? null; // Coach ID
        $templateName = $input['template_name'] ?? null;
        $exercises = $input['exercises'] ?? [];
        
        error_log("DEBUG - Validating fields:");
        error_log("  created_by: $createdBy");
        error_log("  template_name: $templateName");
        error_log("  exercises count: " . count($exercises));
        
        if (!$createdBy || !$templateName || empty($exercises)) {
            error_log("ERROR - Missing required fields");
            echo json_encode([
                'success' => false,
                'message' => 'Missing required fields: created_by, template_name, exercises'
            ]);
            return;
        }
        
        // Validate created_by is integer
        $createdBy = filter_var($createdBy, FILTER_VALIDATE_INT);
        
        if ($createdBy === false) {
            echo json_encode(['success' => false, 'message' => 'Invalid created_by format']);
            return;
        }
        
        // Start transaction
        $pdo->beginTransaction();
        
        try {
            // First, check if programhdr table exists and has the right structure
            $tableCheckStmt = $pdo->prepare("SHOW TABLES LIKE 'programhdr'");
            $tableCheckStmt->execute();
            $tableExists = $tableCheckStmt->fetch();
            
            if (!$tableExists) {
                // Create the table if it doesn't exist
                $createTableSql = "CREATE TABLE programhdr (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    description TEXT,
                    goal VARCHAR(100),
                    difficulty ENUM('Beginner', 'Intermediate', 'Advanced') DEFAULT 'Beginner',
                    duration INT DEFAULT 30,
                    color VARCHAR(20) DEFAULT '0xFF96CEB4',
                    tags JSON,
                    notes TEXT,
                    created_by INT NOT NULL,
                    is_active BOOLEAN DEFAULT TRUE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    INDEX idx_created_by (created_by),
                    INDEX idx_is_active (is_active)
                )";
                $pdo->exec($createTableSql);
                error_log("DEBUG - Created programhdr table");
            } else {
                // Check if the table has the required columns
                $columnCheckStmt = $pdo->prepare("SHOW COLUMNS FROM programhdr LIKE 'name'");
                $columnCheckStmt->execute();
                $nameColumnExists = $columnCheckStmt->fetch();
                
                if (!$nameColumnExists) {
                    // Add missing columns one by one to avoid conflicts
                    $requiredColumns = [
                        'name' => "VARCHAR(255) NOT NULL DEFAULT 'Untitled Template'",
                        'description' => 'TEXT',
                        'goal' => 'VARCHAR(100)',
                        'difficulty' => "ENUM('Beginner', 'Intermediate', 'Advanced') DEFAULT 'Beginner'",
                        'duration' => 'INT DEFAULT 30',
                        'color' => "VARCHAR(20) DEFAULT '0xFF96CEB4'",
                        'tags' => 'JSON',
                        'notes' => 'TEXT',
                        'created_by' => 'INT NOT NULL',
                        'is_active' => 'BOOLEAN DEFAULT TRUE',
                        'created_at' => 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
                        'updated_at' => 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'
                    ];
                    
                    foreach ($requiredColumns as $columnName => $columnDefinition) {
                        $checkColumnStmt = $pdo->prepare("SHOW COLUMNS FROM programhdr LIKE ?");
                        $checkColumnStmt->execute([$columnName]);
                        $columnExists = $checkColumnStmt->fetch();
                        
                        if (!$columnExists) {
                            $alterSql = "ALTER TABLE programhdr ADD COLUMN $columnName $columnDefinition";
                            $pdo->exec($alterSql);
                            error_log("DEBUG - Added column: $columnName");
                        }
                    }
                    
                    // Add indexes if they don't exist
                    try {
                        $pdo->exec("ALTER TABLE programhdr ADD INDEX idx_created_by (created_by)");
                        error_log("DEBUG - Added index: idx_created_by");
                    } catch (PDOException $e) {
                        if (strpos($e->getMessage(), 'Duplicate key name') === false) {
                            throw $e;
                        }
                    }
                    
                    try {
                        $pdo->exec("ALTER TABLE programhdr ADD INDEX idx_is_active (is_active)");
                        error_log("DEBUG - Added index: idx_is_active");
                    } catch (PDOException $e) {
                        if (strpos($e->getMessage(), 'Duplicate key name') === false) {
                            throw $e;
                        }
                    }
                    
                    error_log("DEBUG - Finished adding missing columns to programhdr table");
                }
            }
            
            // Create program_workout table if it doesn't exist
            $createWorkoutTableSql = "CREATE TABLE IF NOT EXISTS program_workout (
                id INT AUTO_INCREMENT PRIMARY KEY,
                program_hdr_id INT NOT NULL,
                workout_details JSON,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (program_hdr_id) REFERENCES programhdr(id) ON DELETE CASCADE,
                INDEX idx_program_hdr_id (program_hdr_id)
            )";
            $pdo->exec($createWorkoutTableSql);
            
            // Create program_workout_exercise table if it doesn't exist
            $createExerciseTableSql = "CREATE TABLE IF NOT EXISTS program_workout_exercise (
                id INT AUTO_INCREMENT PRIMARY KEY,
                program_workout_id INT NOT NULL,
                exercise_id INT NOT NULL,
                sets INT DEFAULT 3,
                reps INT DEFAULT 10,
                weight DECIMAL(8,2) DEFAULT 0.00,
                rest_time INT DEFAULT 60,
                notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (program_workout_id) REFERENCES program_workout(id) ON DELETE CASCADE,
                FOREIGN KEY (exercise_id) REFERENCES exercise(id) ON DELETE CASCADE,
                INDEX idx_program_workout_id (program_workout_id),
                INDEX idx_exercise_id (exercise_id)
            )";
            $pdo->exec($createExerciseTableSql);
            
            // Insert into programhdr table (template)
            $sql = "INSERT INTO programhdr
                (name, description, goal, difficulty, duration, color, tags, notes, created_by)
                VALUES (:name, :description, :goal, :difficulty, :duration, :color, :tags, :notes, :created_by)";
            
            $stmt = $pdo->prepare($sql);
            $stmt->bindValue(':name', $templateName, PDO::PARAM_STR);
            $stmt->bindValue(':description', $input['description'] ?? $input['notes'] ?? '', PDO::PARAM_STR);
            $stmt->bindValue(':goal', $input['goal'] ?? 'General Fitness', PDO::PARAM_STR);
            $stmt->bindValue(':difficulty', $input['difficulty'] ?? 'Beginner', PDO::PARAM_STR);
            $stmt->bindValue(':duration', $input['duration'] ?? 30, PDO::PARAM_INT);
            $stmt->bindValue(':color', $input['color'] ?? '0xFF96CEB4', PDO::PARAM_STR);
            $stmt->bindValue(':tags', json_encode($input['tags'] ?? []), PDO::PARAM_STR);
            $stmt->bindValue(':notes', $input['notes'] ?? '', PDO::PARAM_STR);
            $stmt->bindValue(':created_by', $createdBy, PDO::PARAM_INT);
            
            $result = $stmt->execute();
            
            if (!$result) {
                throw new Exception("Failed to insert template header");
            }
            
            $programHdrId = $pdo->lastInsertId();
            
            // Insert workout details into program_workout
            $workoutSql = "INSERT INTO program_workout (program_hdr_id, workout_details) VALUES (?, ?)";
            $workoutStmt = $pdo->prepare($workoutSql);
            $workoutDetails = json_encode([
                'name' => $templateName,
                'duration' => $input['duration'] ?? 30,
                'created_at' => date('Y-m-d H:i:s'),
                'is_template' => true
            ]);
            $workoutStmt->execute([$programHdrId, $workoutDetails]);
            $programWorkoutId = $pdo->lastInsertId();
            
            // Insert exercises into program_workout_exercise
            if (!empty($exercises) && is_array($exercises)) {
                $exerciseSql = "INSERT INTO program_workout_exercise
                    (program_workout_id, exercise_id, sets, reps, weight, rest_time)
                    VALUES (:program_workout_id, :exercise_id, :sets, :reps, :weight, :rest_time)";
                
                $exerciseStmt = $pdo->prepare($exerciseSql);
                
                foreach ($exercises as $exercise) {
                    $exerciseId = filter_var($exercise['id'] ?? $exercise['exercise_id'], FILTER_VALIDATE_INT);
                    if ($exerciseId === false) {
                        throw new Exception("Invalid exercise ID: " . ($exercise['name'] ?? 'unknown'));
                    }
                    
                    $sets = filter_var($exercise['sets'] ?? $exercise['targetSets'] ?? 3, FILTER_VALIDATE_INT);
                    $reps = filter_var($exercise['reps'] ?? $exercise['targetReps'] ?? 10, FILTER_VALIDATE_INT);
                    $weight = filter_var($exercise['weight'] ?? $exercise['targetWeight'] ?? 0.0, FILTER_VALIDATE_FLOAT);
                    $restTime = filter_var($exercise['rest_time'] ?? $exercise['restTime'] ?? 60, FILTER_VALIDATE_INT);
                    
                    if ($sets === false) $sets = 3;
                    if ($reps === false) $reps = 10;
                    if ($weight === false) $weight = 0.0;
                    if ($restTime === false) $restTime = 60;
                    
                    $exerciseStmt->bindValue(':program_workout_id', $programWorkoutId, PDO::PARAM_INT);
                    $exerciseStmt->bindValue(':exercise_id', $exerciseId, PDO::PARAM_INT);
                    $exerciseStmt->bindValue(':sets', $sets, PDO::PARAM_INT);
                    $exerciseStmt->bindValue(':reps', $reps, PDO::PARAM_INT);
                    $exerciseStmt->bindValue(':weight', $weight, PDO::PARAM_STR);
                    $exerciseStmt->bindValue(':rest_time', $restTime, PDO::PARAM_INT);
                    
                    if (!$exerciseStmt->execute()) {
                        throw new Exception("Failed to insert exercise: " . ($exercise['name'] ?? 'unknown'));
                    }
                }
            }
            
            // Commit transaction
            $pdo->commit();
            
            error_log("SUCCESS - Template created successfully:");
            error_log("  Template ID: $programHdrId");
            error_log("  Created by: $createdBy");
            error_log("  Template name: $templateName");
            error_log("  Exercises count: " . count($exercises));
            
            $response = [
                'success' => true,
                'id' => (int)$programHdrId,
                'message' => 'Template created successfully',
                'created_by' => $createdBy
            ];
            
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

function getCoachTemplates($pdo) {
    try {
        $coachId = $_GET['coach_id'] ?? null;
        
        if (!$coachId) {
            echo json_encode(['success' => false, 'message' => 'Coach ID is required']);
            return;
        }
        
        $coachId = filter_var($coachId, FILTER_VALIDATE_INT);
        if ($coachId === false) {
            echo json_encode(['success' => false, 'message' => 'Invalid coach ID format']);
            return;
        }
        
        // Check if programhdr table exists and has the right structure
        $tableCheckStmt = $pdo->prepare("SHOW TABLES LIKE 'programhdr'");
        $tableCheckStmt->execute();
        $tableExists = $tableCheckStmt->fetch();
        
        if (!$tableExists) {
            echo json_encode(['success' => true, 'data' => [], 'message' => 'No templates table found']);
            return;
        }
        
        // Check if the table has the required columns
        $columnCheckStmt = $pdo->prepare("SHOW COLUMNS FROM programhdr LIKE 'name'");
        $columnCheckStmt->execute();
        $nameColumnExists = $columnCheckStmt->fetch();
        
        if (!$nameColumnExists) {
            echo json_encode(['success' => true, 'data' => [], 'message' => 'Templates table needs to be updated']);
            return;
        }
        
        // Get coach templates from programhdr table
        $stmt = $pdo->prepare("
            SELECT 
                ph.id,
                ph.name,
                ph.description,
                ph.goal,
                ph.difficulty,
                ph.duration,
                ph.color,
                ph.tags,
                ph.notes,
                ph.created_by,
                ph.created_at,
                ph.updated_at,
                pw.workout_details,
                COUNT(pwe.id) as exercise_count
            FROM programhdr ph
            LEFT JOIN program_workout pw ON ph.id = pw.program_hdr_id
            LEFT JOIN program_workout_exercise pwe ON pw.id = pwe.program_workout_id
            WHERE ph.created_by = ? AND ph.is_active = TRUE
            GROUP BY ph.id
            ORDER BY ph.created_at DESC
        ");
        $stmt->execute([$coachId]);
        $templates = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Process templates
        foreach ($templates as &$template) {
            $template['id'] = (int)$template['id'];
            $template['created_by'] = (int)$template['created_by'];
            $template['exercise_count'] = (int)$template['exercise_count'];
            $template['duration'] = (int)$template['duration'];
            
            // Parse workout details
            $workoutDetails = json_decode($template['workout_details'], true);
            $template['workout_name'] = $workoutDetails['name'] ?? $template['name'];
            $template['is_template'] = $workoutDetails['is_template'] ?? true;
            
            // Parse tags
            $template['tags'] = json_decode($template['tags'], true) ?? [];
        }
        
        echo json_encode(['success' => true, 'data' => $templates]);
        
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching templates: ' . $e->getMessage()]);
    }
}

function getTemplateDetails($pdo) {
    try {
        $templateId = $_GET['template_id'] ?? null;
        
        if (!$templateId) {
            echo json_encode(['success' => false, 'message' => 'Template ID is required']);
            return;
        }
        
        $templateId = (int)$templateId;
        
        // Get template header
        $stmt = $pdo->prepare("
            SELECT 
                ph.id,
                ph.name,
                ph.description,
                ph.goal,
                ph.difficulty,
                ph.duration,
                ph.color,
                ph.tags,
                ph.notes,
                ph.created_by,
                ph.created_at,
                ph.updated_at,
                pw.workout_details
            FROM programhdr ph
            LEFT JOIN program_workout pw ON ph.id = pw.program_hdr_id
            WHERE ph.id = ? AND ph.is_active = TRUE
            LIMIT 1
        ");
        $stmt->execute([$templateId]);
        $template = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$template) {
            echo json_encode(['success' => false, 'message' => 'Template not found']);
            return;
        }
        
        // Get exercises for this template
        $exerciseStmt = $pdo->prepare("
            SELECT 
                e.id,
                e.name,
                e.description,
                e.image_url,
                e.video_url,
                pwe.reps as target_reps,
                pwe.sets as target_sets,
                pwe.weight as target_weight,
                pwe.rest_time,
                GROUP_CONCAT(DISTINCT tm.name SEPARATOR ', ') as target_muscle
            FROM program_workout_exercise pwe
            INNER JOIN program_workout pw ON pwe.program_workout_id = pw.id
            INNER JOIN exercise e ON pwe.exercise_id = e.id
            LEFT JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
            LEFT JOIN target_muscle tm ON etm.muscle_id = tm.id
            WHERE pw.program_hdr_id = ?
            GROUP BY e.id, e.name, e.description, e.image_url, e.video_url, 
                     pwe.reps, pwe.sets, pwe.weight, pwe.rest_time
            ORDER BY pwe.id ASC
        ");
        $exerciseStmt->execute([$templateId]);
        $exercises = $exerciseStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Process template data
        $template['id'] = (int)$template['id'];
        $template['created_by'] = (int)$template['created_by'];
        $template['duration'] = (int)$template['duration'];
        $template['exercise_count'] = count($exercises);
        $template['tags'] = json_decode($template['tags'], true) ?? [];
        $template['exercises'] = $exercises;
        
        // Parse workout details if exists
        if ($template['workout_details']) {
            $workoutDetails = json_decode($template['workout_details'], true);
            if ($workoutDetails) {
                $template['workout_name'] = $workoutDetails['name'] ?? $template['name'];
            }
        }
        
        echo json_encode(['success' => true, 'data' => $template]);
        
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching template details: ' . $e->getMessage()]);
    }
}

function assignTemplateToClient($pdo) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        error_log("DEBUG - assignTemplateToClient called with input: " . json_encode($input));
        
        if (!$input) {
            error_log("DEBUG - Invalid JSON input");
            echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
            return;
        }
        
        $templateId = $input['template_id'] ?? null;
        $clientId = $input['client_id'] ?? null;
        $coachId = $input['coach_id'] ?? null;
        
        // Customization options
        $customGoal = $input['custom_goal'] ?? null;
        $customDifficulty = $input['custom_difficulty'] ?? null;
        $customDuration = $input['custom_duration'] ?? null;
        $customNotes = $input['custom_notes'] ?? null;
        $exerciseModifications = $input['exercise_modifications'] ?? []; // Array of exercise customizations
        
        if (!$templateId || !$clientId || !$coachId) {
            echo json_encode([
                'success' => false,
                'message' => 'Missing required fields: template_id, client_id, coach_id'
            ]);
            return;
        }
        
        // Validate IDs
        $templateId = filter_var($templateId, FILTER_VALIDATE_INT);
        $clientId = filter_var($clientId, FILTER_VALIDATE_INT);
        $coachId = filter_var($coachId, FILTER_VALIDATE_INT);
        
        if ($templateId === false || $clientId === false || $coachId === false) {
            echo json_encode(['success' => false, 'message' => 'Invalid ID format']);
            return;
        }
        
        // Start transaction
        $pdo->beginTransaction();
        
        try {
            // Ensure member_programhdr table has program_hdr_id column
            $checkColumnStmt = $pdo->prepare("SHOW COLUMNS FROM member_programhdr LIKE 'program_hdr_id'");
            $checkColumnStmt->execute();
            $columnExists = $checkColumnStmt->fetch();
            
            if (!$columnExists) {
                $alterSql = "ALTER TABLE member_programhdr ADD COLUMN program_hdr_id INT NULL COMMENT 'Reference to original template in programhdr table'";
                $pdo->exec($alterSql);
                error_log("DEBUG - Added program_hdr_id column to member_programhdr table");
            }
            // Get template data from programhdr table
            error_log("DEBUG - Looking for template ID: $templateId, Coach ID: $coachId");
            $templateStmt = $pdo->prepare("
                SELECT ph.*, pw.workout_details
                FROM programhdr ph
                LEFT JOIN program_workout pw ON ph.id = pw.program_hdr_id
                WHERE ph.id = ? AND ph.created_by = ? AND ph.is_active = TRUE
            ");
            $templateStmt->execute([$templateId, $coachId]);
            $template = $templateStmt->fetch(PDO::FETCH_ASSOC);
            
            error_log("DEBUG - Template found: " . ($template ? 'YES' : 'NO'));
            if ($template) {
                error_log("DEBUG - Template data: " . json_encode($template));
            }
            
            if (!$template) {
                throw new Exception("Template not found or access denied");
            }
            
            // Apply customizations or use template defaults
            $finalGoal = $customGoal ?? $template['goal'];
            $finalDifficulty = $customDifficulty ?? $template['difficulty'];
            $finalDuration = $customDuration ?? $template['duration'];
            $finalNotes = $customNotes ?? $template['notes'];
            
            // Create new routine for client based on template
            error_log("DEBUG - Creating member_programhdr entry for client: $clientId");
            $sql = "INSERT INTO member_programhdr
                (user_id, program_hdr_id, created_by, color, tags, goal, notes, completion_rate, scheduled_days, difficulty, total_sessions)
                VALUES (:user_id, :program_hdr_id, :created_by, :color, :tags, :goal, :notes, :completion_rate, :scheduled_days, :difficulty, :total_sessions)";
            
            $stmt = $pdo->prepare($sql);
            $stmt->bindValue(':user_id', $clientId, PDO::PARAM_INT);
            $stmt->bindValue(':program_hdr_id', $templateId, PDO::PARAM_INT); // Link to original template
            $stmt->bindValue(':created_by', $coachId, PDO::PARAM_INT);
            $stmt->bindValue(':color', $template['color']);
            $stmt->bindValue(':tags', $template['tags']);
            $stmt->bindValue(':goal', $finalGoal);
            $stmt->bindValue(':notes', $finalNotes);
            $stmt->bindValue(':completion_rate', 0, PDO::PARAM_INT);
            $stmt->bindValue(':scheduled_days', json_encode([])); // Default empty schedule
            $stmt->bindValue(':difficulty', $finalDifficulty);
            $stmt->bindValue(':total_sessions', 0, PDO::PARAM_INT);
            
            $result = $stmt->execute();
            
            if (!$result) {
                $errorInfo = $stmt->errorInfo();
                error_log("DEBUG - Failed to insert into member_programhdr: " . json_encode($errorInfo));
                throw new Exception("Failed to create routine for client: " . ($errorInfo[2] ?? 'Unknown error'));
            }
            
            $newRoutineId = $pdo->lastInsertId();
            error_log("DEBUG - Created member_programhdr with ID: $newRoutineId");
            
            // Copy workout details with customizations
            $workoutSql = "INSERT INTO member_program_workout (member_program_hdr_id, workout_details) VALUES (?, ?)";
            $workoutStmt = $pdo->prepare($workoutSql);
            $workoutDetails = json_decode($template['workout_details'], true);
            $workoutDetails['name'] = $template['name'] . ' - ' . ($finalGoal ?? 'Customized');
            $workoutDetails['duration'] = $finalDuration;
            $workoutDetails['created_at'] = date('Y-m-d H:i:s');
            $workoutDetails['is_template'] = false;
            $workoutDetails['template_id'] = $templateId;
            $workoutStmt->execute([$newRoutineId, json_encode($workoutDetails)]);
            $newWorkoutId = $pdo->lastInsertId();
            
            // Copy exercises with potential customizations
            $exerciseStmt = $pdo->prepare("
                SELECT pwe.*, e.name as exercise_name
                FROM program_workout_exercise pwe
                INNER JOIN program_workout pw ON pwe.program_workout_id = pw.id
                INNER JOIN exercise e ON pwe.exercise_id = e.id
                WHERE pw.program_hdr_id = ?
                ORDER BY pwe.id
            ");
            $exerciseStmt->execute([$templateId]);
            $templateExercises = $exerciseStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Check what columns exist in member_workout_exercise table
            $columnCheckStmt = $pdo->prepare("SHOW COLUMNS FROM member_workout_exercise");
            $columnCheckStmt->execute();
            $columns = $columnCheckStmt->fetchAll(PDO::FETCH_COLUMN);
            error_log("DEBUG - member_workout_exercise columns: " . json_encode($columns));
            
            // Build dynamic INSERT statement based on available columns
            $availableColumns = [];
            $placeholders = [];
            
            if (in_array('member_program_workout_id', $columns)) $availableColumns[] = 'member_program_workout_id';
            if (in_array('exercise_id', $columns)) $availableColumns[] = 'exercise_id';
            if (in_array('sets', $columns)) $availableColumns[] = 'sets';
            if (in_array('reps', $columns)) $availableColumns[] = 'reps';
            if (in_array('weight', $columns)) $availableColumns[] = 'weight';
            if (in_array('rest_time', $columns)) $availableColumns[] = 'rest_time';
            if (in_array('notes', $columns)) $availableColumns[] = 'notes';
            
            $placeholders = array_fill(0, count($availableColumns), '?');
            
            $insertSql = "INSERT INTO member_workout_exercise (" . implode(', ', $availableColumns) . ") VALUES (" . implode(', ', $placeholders) . ")";
            error_log("DEBUG - Dynamic INSERT SQL: $insertSql");
            
            $insertExerciseStmt = $pdo->prepare($insertSql);
            
            foreach ($templateExercises as $exercise) {
                // Check if this exercise has custom modifications
                $exerciseMod = null;
                foreach ($exerciseModifications as $mod) {
                    if ($mod['exercise_id'] == $exercise['exercise_id']) {
                        $exerciseMod = $mod;
                        break;
                    }
                }
                
                // Apply customizations or use template defaults
                $sets = $exerciseMod['sets'] ?? $exercise['sets'];
                $reps = $exerciseMod['reps'] ?? $exercise['reps'];
                $weight = $exerciseMod['weight'] ?? $exercise['weight'];
                $restTime = $exerciseMod['rest_time'] ?? $exercise['rest_time'] ?? 60;
                $notes = $exerciseMod['notes'] ?? $exercise['notes'] ?? '';
                
                // Build values array dynamically based on available columns
                $values = [];
                if (in_array('member_program_workout_id', $availableColumns)) $values[] = $newWorkoutId;
                if (in_array('exercise_id', $availableColumns)) $values[] = $exercise['exercise_id'];
                if (in_array('sets', $availableColumns)) $values[] = $sets;
                if (in_array('reps', $availableColumns)) $values[] = $reps;
                if (in_array('weight', $availableColumns)) $values[] = $weight;
                if (in_array('rest_time', $availableColumns)) $values[] = $restTime;
                if (in_array('notes', $availableColumns)) $values[] = $notes;
                
                error_log("DEBUG - Inserting exercise with values: " . json_encode($values));
                $insertExerciseStmt->execute($values);
            }
            
            // Commit transaction
            $pdo->commit();
            
            $response = [
                'success' => true,
                'id' => (int)$newRoutineId,
                'message' => 'Template assigned to client successfully',
                'client_id' => $clientId,
                'template_id' => $templateId,
                'customizations_applied' => [
                    'goal' => $finalGoal,
                    'difficulty' => $finalDifficulty,
                    'duration' => $finalDuration,
                    'exercise_modifications' => count($exerciseModifications)
                ]
            ];
            
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

function getClientRoutinesWithExercises($pdo) {
    try {
        $clientId = $_GET['client_id'] ?? null;
        
        if (!$clientId) {
            echo json_encode(['success' => false, 'message' => 'Client ID is required']);
            return;
        }
        
        $clientId = filter_var($clientId, FILTER_VALIDATE_INT);
        if ($clientId === false) {
            echo json_encode(['success' => false, 'message' => 'Invalid client ID format']);
            return;
        }
        
        // Get client routines with exercise details
        $stmt = $pdo->prepare("
            SELECT 
                mph.id,
                mph.created_by,
                mph.color,
                mph.tags,
                mph.goal,
                mph.notes,
                mph.difficulty,
                mph.created_at,
                mph.completion_rate,
                mph.total_sessions,
                mpw.workout_details,
                COUNT(mwe.id) as exercise_count,
                GROUP_CONCAT(
                    CONCAT(e.name, ' (', mwe.sets, 'x', mwe.reps, ')') 
                    ORDER BY mwe.id 
                    SEPARATOR ', '
                ) as exercise_list
            FROM member_programhdr mph
            LEFT JOIN member_program_workout mpw ON mph.id = mpw.member_program_hdr_id
            LEFT JOIN member_workout_exercise mwe ON mpw.id = mwe.member_program_workout_id
            LEFT JOIN exercise e ON mwe.exercise_id = e.id
            WHERE mph.user_id = ?
            GROUP BY mph.id
            ORDER BY mph.created_at DESC
        ");
        $stmt->execute([$clientId]);
        $routines = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Process routines
        foreach ($routines as &$routine) {
            $routine['id'] = (int)$routine['id'];
            $routine['created_by'] = (int)$routine['created_by'];
            $routine['exercise_count'] = (int)$routine['exercise_count'];
            $routine['completion_rate'] = (int)$routine['completion_rate'];
            $routine['total_sessions'] = (int)$routine['total_sessions'];
            
            // Parse workout details
            $workoutDetails = json_decode($routine['workout_details'], true);
            $routine['name'] = $workoutDetails['name'] ?? 'Untitled Routine';
            $routine['duration'] = $workoutDetails['duration'] ?? '30';
            
            // Parse tags
            $routine['tags'] = json_decode($routine['tags'], true) ?? [];
            
            // Format exercise list
            $routine['exercise_list'] = $routine['exercise_list'] ?? 'No exercises';
        }
        
        echo json_encode(['success' => true, 'data' => $routines]);
        
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching client routines: ' . $e->getMessage()]);
    }
}

// ============================================
// DEBUG FUNCTIONS
// ============================================
function testDatabaseConnection($pdo) {
    try {
        $stmt = $pdo->query("SELECT 1 as test");
        $result = $stmt->fetch();
        echo json_encode([
            'success' => true, 
            'message' => 'Database connection successful',
            'test_result' => $result
        ]);
    } catch (PDOException $e) {
        echo json_encode([
            'success' => false, 
            'message' => 'Database connection failed: ' . $e->getMessage()
        ]);
    }
}

function checkTemplatesInDatabase($pdo) {
    try {
        $coachId = $_GET['coach_id'] ?? 59; // Default to coach 59 for testing
        
        // Check if programhdr table exists
        $tableCheckStmt = $pdo->prepare("SHOW TABLES LIKE 'programhdr'");
        $tableCheckStmt->execute();
        $tableExists = $tableCheckStmt->fetch();
        
        if (!$tableExists) {
            echo json_encode([
                'success' => false,
                'message' => 'programhdr table does not exist yet. Create a template first to create the table.',
                'coach_id' => $coachId
            ]);
            return;
        }
        
        // Check all templates in programhdr table
        $stmt = $pdo->prepare("
            SELECT 
                ph.id,
                ph.name,
                ph.description,
                ph.goal,
                ph.difficulty,
                ph.duration,
                ph.created_by,
                ph.created_at,
                ph.updated_at,
                ph.is_active,
                pw.workout_details,
                COUNT(pwe.id) as exercise_count
            FROM programhdr ph
            LEFT JOIN program_workout pw ON ph.id = pw.program_hdr_id
            LEFT JOIN program_workout_exercise pwe ON pw.id = pwe.program_workout_id
            WHERE ph.is_active = TRUE
            GROUP BY ph.id
            ORDER BY ph.created_at DESC
        ");
        $stmt->execute();
        $templates = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Also check for coach-specific templates
        $coachStmt = $pdo->prepare("
            SELECT 
                ph.id,
                ph.name,
                ph.description,
                ph.goal,
                ph.difficulty,
                ph.duration,
                ph.created_by,
                ph.created_at,
                ph.updated_at,
                ph.is_active,
                pw.workout_details,
                COUNT(pwe.id) as exercise_count
            FROM programhdr ph
            LEFT JOIN program_workout pw ON ph.id = pw.program_hdr_id
            LEFT JOIN program_workout_exercise pwe ON pw.id = pwe.program_workout_id
            WHERE ph.created_by = ? AND ph.is_active = TRUE
            GROUP BY ph.id
            ORDER BY ph.created_at DESC
        ");
        $coachStmt->execute([$coachId]);
        $coachTemplates = $coachStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Also check member_programhdr for any old templates
        $oldTemplatesStmt = $pdo->prepare("
            SELECT 
                mph.id,
                mph.user_id,
                mph.created_by,
                mph.goal,
                mph.difficulty,
                mph.created_at,
                mpw.workout_details,
                COUNT(mwe.id) as exercise_count
            FROM member_programhdr mph
            LEFT JOIN member_program_workout mpw ON mph.id = mpw.member_program_hdr_id
            LEFT JOIN member_workout_exercise mwe ON mpw.id = mwe.member_program_workout_id
            WHERE mph.user_id IS NULL
            GROUP BY mph.id
            ORDER BY mph.created_at DESC
        ");
        $oldTemplatesStmt->execute();
        $oldTemplates = $oldTemplatesStmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'message' => 'Database check completed',
            'table_exists' => true,
            'total_templates' => count($templates),
            'coach_templates' => count($coachTemplates),
            'old_templates' => count($oldTemplates),
            'coach_id' => $coachId,
            'all_templates' => $templates,
            'coach_specific_templates' => $coachTemplates,
            'old_member_templates' => $oldTemplates
        ]);
        
    } catch (PDOException $e) {
        echo json_encode([
            'success' => false, 
            'message' => 'Database check failed: ' . $e->getMessage()
        ]);
    }
}

function checkTableStructure($pdo) {
    try {
        // Check if programhdr table exists
        $tableCheckStmt = $pdo->prepare("SHOW TABLES LIKE 'programhdr'");
        $tableCheckStmt->execute();
        $tableExists = $tableCheckStmt->fetch();
        
        if (!$tableExists) {
            echo json_encode([
                'success' => false,
                'message' => 'programhdr table does not exist',
                'table_exists' => false
            ]);
            return;
        }
        
        // Get table structure
        $structureStmt = $pdo->prepare("DESCRIBE programhdr");
        $structureStmt->execute();
        $columns = $structureStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Check for required columns
        $requiredColumns = ['id', 'name', 'description', 'goal', 'difficulty', 'duration', 'color', 'tags', 'notes', 'created_by', 'is_active', 'created_at', 'updated_at'];
        $existingColumns = array_column($columns, 'Field');
        $missingColumns = array_diff($requiredColumns, $existingColumns);
        
        echo json_encode([
            'success' => true,
            'message' => 'Table structure check completed',
            'table_exists' => true,
            'columns' => $columns,
            'existing_columns' => $existingColumns,
            'required_columns' => $requiredColumns,
            'missing_columns' => array_values($missingColumns),
            'needs_update' => !empty($missingColumns)
        ]);
        
    } catch (PDOException $e) {
        echo json_encode([
            'success' => false, 
            'message' => 'Table structure check failed: ' . $e->getMessage()
        ]);
    }
}

function getCoachClients($pdo) {
    try {
        $coachId = $_GET['coach_id'] ?? null;
        
        if (!$coachId) {
            echo json_encode(['success' => false, 'message' => 'Coach ID is required']);
            return;
        }
        
        $coachId = filter_var($coachId, FILTER_VALIDATE_INT);
        if ($coachId === false) {
            echo json_encode(['success' => false, 'message' => 'Invalid coach ID format']);
            return;
        }
        
        // Get coach's assigned clients from coach_member_list
        $stmt = $pdo->prepare("
            SELECT 
                cml.id as request_id,
                cml.status,
                cml.coach_approval,
                cml.staff_approval,
                cml.requested_at,
                cml.coach_approved_at,
                cml.staff_approved_at,
                cml.remaining_sessions,
                cml.rate_type,
                u.id,
                u.fname,
                u.mname,
                u.lname,
                u.email,
                u.bday,
                u.created_at as join_date,
                u.profile_image,
                u.gender_id
            FROM coach_member_list cml
            JOIN user u ON cml.member_id = u.id
            WHERE cml.coach_id = ? 
            AND cml.status = 'active'
            AND cml.coach_approval = 'approved'
            AND cml.staff_approval = 'approved'
            ORDER BY cml.coach_approved_at DESC
        ");
        $stmt->execute([$coachId]);
        $clients = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Process client data
        foreach ($clients as &$client) {
            $client['id'] = (int)$client['id'];
            $client['request_id'] = (int)$client['request_id'];
            $client['gender_id'] = (int)$client['gender_id'];
            $client['remaining_sessions'] = $client['remaining_sessions'] ? (int)$client['remaining_sessions'] : null;
            
            // Create full name
            $client['full_name'] = trim($client['fname'] . ' ' . ($client['mname'] ?? '') . ' ' . $client['lname']);
            $client['full_name'] = preg_replace('/\s+/', ' ', $client['full_name']); // Remove extra spaces
            
            // Create initials
            $initials = '';
            if (!empty($client['fname'])) $initials .= strtoupper(substr($client['fname'], 0, 1));
            if (!empty($client['lname'])) $initials .= strtoupper(substr($client['lname'], 0, 1));
            $client['initials'] = $initials;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $clients,
            'count' => count($clients)
        ]);
        
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching coach clients: ' . $e->getMessage()]);
    }
}

function testTemplateAssignment($pdo) {
    try {
        // Test with sample data
        $testData = [
            'template_id' => 1,
            'client_id' => 1,
            'coach_id' => 59,
            'custom_goal' => 'Test Goal',
            'custom_difficulty' => 'Beginner',
            'custom_duration' => 30,
            'custom_notes' => 'Test assignment',
            'exercise_modifications' => []
        ];
        
        error_log("DEBUG - Testing template assignment with data: " . json_encode($testData));
        
        // Simulate the assignment process
        $templateId = $testData['template_id'];
        $clientId = $testData['client_id'];
        $coachId = $testData['coach_id'];
        
        // Check if template exists
        $templateStmt = $pdo->prepare("
            SELECT ph.*, pw.workout_details
            FROM programhdr ph
            LEFT JOIN program_workout pw ON ph.id = pw.program_hdr_id
            WHERE ph.id = ? AND ph.created_by = ? AND ph.is_active = TRUE
        ");
        $templateStmt->execute([$templateId, $coachId]);
        $template = $templateStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$template) {
            echo json_encode([
                'success' => false,
                'message' => 'Template not found',
                'template_id' => $templateId,
                'coach_id' => $coachId,
                'test_data' => $testData
            ]);
            return;
        }
        
        // Check if member_programhdr table has required columns
        $checkColumnStmt = $pdo->prepare("SHOW COLUMNS FROM member_programhdr LIKE 'program_hdr_id'");
        $checkColumnStmt->execute();
        $columnExists = $checkColumnStmt->fetch();
        
        echo json_encode([
            'success' => true,
            'message' => 'Test completed successfully',
            'template_found' => true,
            'template_data' => $template,
            'program_hdr_id_column_exists' => $columnExists ? true : false,
            'test_data' => $testData
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Test failed: ' . $e->getMessage(),
            'test_data' => $testData ?? []
        ]);
    }
}
?>