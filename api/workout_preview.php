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

$input = json_decode(file_get_contents("php://input"), true);
$action = $_GET['action'] ?? $input['action'] ?? '';

function respond($data) {
    echo json_encode($data);
    exit;
}

function validateUserId($userId) {
    if (!$userId || !is_numeric($userId) || $userId <= 0) {
        respond(["error" => "Invalid or missing user ID"]);
    }
    return intval($userId);
}

function validateRoutineId($routineId) {
    if (!$routineId) {
        respond(["error" => "Invalid or missing routine ID"]);
    }
    
    // Check if it's an admin template program (starts with 'template_')
    if (strpos($routineId, 'template_') === 0) {
        return $routineId; // Return as string for template programs
    }
    
    // For regular routines, validate as numeric
    if (!is_numeric($routineId) || $routineId <= 0) {
        respond(["error" => "Invalid or missing routine ID"]);
    }
    return intval($routineId);
}

// Helper function to get member_workout_exercise_id from exercise_id and routine_id
function getMemberWorkoutExerciseId($pdo, $routineId, $exerciseId, $userId) {
    // Fixed table names to lowercase
    $stmt = $pdo->prepare("
        SELECT mwe.id as member_workout_exercise_id
        FROM member_workout_exercise mwe
        JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
        JOIN member_programhdr mph ON mpw.member_program_hdr_id = mph.id
        WHERE mph.id = :routine_id 
        AND mwe.exercise_id = :exercise_id 
        AND mph.user_id = :user_id
        LIMIT 1
    ");
    $stmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
    $stmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    return $result ? intval($result['member_workout_exercise_id']) : null;
}

switch ($action) {
    case 'getWorkoutPreview':
        try {
            $routineId = validateRoutineId($_GET['routine_id'] ?? null);
            $userId = validateUserId($_GET['user_id'] ?? null);
            
            error_log("Fetching workout preview for routine ID: $routineId, user ID: $userId");
            
            $routine = null;
            $workoutDetails = null;
            $routineName = null;
            
            // Check if this is an admin template program
            if (strpos($routineId, 'template_') === 0) {
                $templateId = str_replace('template_', '', $routineId);
                error_log("Fetching admin template program with ID: $templateId");
                
                // Debug: Check what templates exist in programhdr
                $debugStmt = $pdo->prepare("SELECT id, name, type, created_by FROM programhdr WHERE type = 'template'");
                $debugStmt->execute();
                $allTemplates = $debugStmt->fetchAll(PDO::FETCH_ASSOC);
                error_log("All templates in programhdr: " . json_encode($allTemplates));
                
                // Get admin template program from programs table (matching routines.php logic)
                $templateStmt = $pdo->prepare("
                    SELECT 
                        p.id,
                        p.name,
                        p.description,
                        ph.difficulty,
                        ph.goal,
                        ph.notes,
                        ph.duration,
                        p.name as program_name
                    FROM programs p
                    LEFT JOIN programhdr ph ON p.id = ph.program_id AND ph.type = 'template'
                    WHERE p.id = :template_id
                ");
                $templateStmt->bindParam(':template_id', $templateId, PDO::PARAM_INT);
                $templateStmt->execute();
                $template = $templateStmt->fetch(PDO::FETCH_ASSOC);
                
                error_log("Template lookup result: " . json_encode($template));
                
                if ($template) {
                    // Create routine data for template
                    $routine = [
                        'id' => $routineId,
                        'user_id' => $userId
                    ];
                    $routineName = $template['name'] ?: $template['program_name'];
                    $workoutDetails = json_encode([
                        'name' => $routineName,
                        'description' => $template['description'],
                        'difficulty' => $template['difficulty'],
                        'goal' => $template['goal'],
                        'duration' => $template['duration'] . ' days',
                        'created_at' => date('Y-m-d H:i:s')
                    ]);
                }
            } else {
                // For regular routines, verify the routine belongs to the user
                $routineStmt = $pdo->prepare("
                    SELECT 
                        m.id,
                        mpw.workout_details
                    FROM member_programhdr m
                    LEFT JOIN member_program_workout mpw ON m.id = mpw.member_program_hdr_id
                    WHERE m.id = :routine_id AND m.user_id = :user_id
                    LIMIT 1
                ");
                $routineStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
                $routineStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $routineStmt->execute();
                $routine = $routineStmt->fetch(PDO::FETCH_ASSOC);
                
                if ($routine) {
                    $workoutDetails = $routine['workout_details'];
                    $workoutDetailsArray = json_decode($workoutDetails ?? '{}', true);
                    $routineName = $workoutDetailsArray['name'] ?? "Routine #$routineId";
                }
            }
            
            if (!$routine) {
                respond([
                    "success" => false,
                    "error" => "Routine not found or access denied"
                ]);
            }
            
            // Fetch exercises for this routine
            $exercises = [];
            
            if (strpos($routineId, 'template_') === 0) {
                // For admin template programs, fetch actual workout data from program_workout tables
                error_log("Fetching actual workout data for admin template program");
                
                $exerciseStmt = $pdo->prepare("
                    SELECT 
                        e.id as exercise_id,
                        e.name,
                        e.description,
                        e.image_url,
                        e.video_url,
                        pwe.id as program_workout_exercise_id,
                        pwe.sets,
                        pwe.reps,
                        pwe.weight,
                        GROUP_CONCAT(DISTINCT tm.name SEPARATOR ', ') as target_muscle,
                        60 as rest_time
                    FROM program_workout_exercise pwe
                    JOIN exercise e ON pwe.exercise_id = e.id
                    JOIN program_workout pw ON pwe.program_workout_id = pw.id
                    JOIN programhdr ph ON pw.program_hdr_id = ph.id
                    LEFT JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
                    LEFT JOIN target_muscle tm ON etm.muscle_id = tm.id
                    WHERE ph.program_id = :template_id AND ph.type = 'template'
                    GROUP BY e.id, e.name, e.description, e.image_url, e.video_url, 
                             pwe.id, pwe.sets, pwe.reps, pwe.weight
                    ORDER BY pwe.id ASC
                ");
                $exerciseStmt->bindParam(':template_id', $templateId, PDO::PARAM_INT);
                $exerciseStmt->execute();
                $exercises = $exerciseStmt->fetchAll(PDO::FETCH_ASSOC);
                
                // If no exercises found, provide default data
                if (empty($exercises)) {
                    error_log("No exercises found for template, providing default data");
                    $exercises = [
                        [
                            'exercise_id' => 1,
                            'name' => 'Chest Exercise',
                            'description' => 'Basic chest exercise for the ' . $routineName . ' program',
                            'image_url' => '',
                            'video_url' => '',
                            'program_workout_exercise_id' => 0,
                            'sets' => 3,
                            'reps' => 10,
                            'weight' => 0.0,
                            'target_muscle' => 'Chest',
                            'rest_time' => 60
                        ]
                    ];
                }
            } else {
                // For regular routines, fetch from database
                $exerciseStmt = $pdo->prepare("
                    SELECT 
                        e.id as exercise_id,
                        e.name,
                        e.description,
                        e.image_url,
                        e.video_url,
                        mwe.id as member_workout_exercise_id,
                        mwe.sets,
                        mwe.reps,
                        mwe.weight,
                        GROUP_CONCAT(DISTINCT tm.name SEPARATOR ', ') as target_muscle,
                        60 as rest_time
                    FROM member_workout_exercise mwe
                    JOIN exercise e ON mwe.exercise_id = e.id
                    JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
                    LEFT JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
                    LEFT JOIN target_muscle tm ON etm.muscle_id = tm.id
                    WHERE mpw.member_program_hdr_id = :routine_id
                    GROUP BY e.id, e.name, e.description, e.image_url, e.video_url, 
                             mwe.id, mwe.sets, mwe.reps, mwe.weight
                    ORDER BY mwe.id ASC
                ");
                $exerciseStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
                $exerciseStmt->execute();
                $exercises = $exerciseStmt->fetchAll(PDO::FETCH_ASSOC);
            }
            
            error_log("Found " . count($exercises) . " exercises for routine $routineId");

            // Calculate workout stats
            $totalExercises = count($exercises);
            $totalSets = array_sum(array_column($exercises, 'sets'));
            $estimatedVolume = 0;
            $estimatedDuration = 0;
            
            foreach ($exercises as $exercise) {
                // Calculate estimated volume (weight * sets * average reps)
                $avgReps = is_numeric($exercise['reps']) ? intval($exercise['reps']) : 10;
                $estimatedVolume += ($exercise['weight'] * $exercise['sets'] * $avgReps);
                
                // Calculate estimated duration (2-3 minutes per set + rest time)
                $setTime = $exercise['sets'] * 2; // 2 minutes per set
                $restTime = $exercise['sets'] * (intval($exercise['rest_time']) / 60); // rest time in minutes
                $estimatedDuration += ($setTime + $restTime);
            }
            
            // Estimate calories (roughly 6 calories per minute)
            $estimatedCalories = round($estimatedDuration * 6);
            
            $stats = [
                'estimated_duration' => (int)$estimatedDuration,
                'estimated_calories' => (int)$estimatedCalories,
                'estimated_volume' => round($estimatedVolume, 2),
                'total_exercises' => (int)$totalExercises,
                'total_sets' => (int)$totalSets
            ];
            
            // Format exercises for response
            $formattedExercises = array_map(function($exercise) use ($workoutDetails) {
                $exerciseId = $exercise['exercise_id'];
                $targetSets = [];
                
                // Check if we have individual set configurations stored in workout_details
                if (isset($workoutDetails['exercise_set_configs'][$exerciseId])) {
                    // Use the stored individual set configurations
                    $setConfigs = $workoutDetails['exercise_set_configs'][$exerciseId];
                    foreach ($setConfigs as $setConfig) {
                        $targetSets[] = [
                            'reps' => (int)$setConfig['reps'],
                            'weight' => (float)$setConfig['weight'],
                            'timestamp' => $setConfig['timestamp'] ?? date('c'),
                            'isCompleted' => false,
                        ];
                    }
                    error_log("Using individual set configurations for exercise ID $exerciseId: " . json_encode($setConfigs));
                } else {
                    // Fallback to creating sets with default values
                    $setCount = (int)$exercise['sets'];
                    for ($i = 0; $i < $setCount; $i++) {
                        $targetSets[] = [
                            'reps' => (int)$exercise['reps'],
                            'weight' => (float)$exercise['weight'],
                            'timestamp' => date('c'),
                            'isCompleted' => false,
                        ];
                    }
                    error_log("Using default set configuration for exercise ID $exerciseId");
                }
                
                return [
                    'id' => (int)$exercise['exercise_id'],
                    'exercise_id' => (int)$exercise['exercise_id'],
                    'member_workout_exercise_id' => (int)($exercise['member_workout_exercise_id'] ?? $exercise['program_workout_exercise_id'] ?? 0),
                    'name' => $exercise['name'],
                    'target_muscle' => $exercise['target_muscle'] ?? 'General',
                    'description' => $exercise['description'] ?? '',
                    'image_url' => $exercise['image_url'] ?? '',
                    'video_url' => $exercise['video_url'] ?? '',
                    'target_sets' => $targetSets, // Array of individual set configurations
                    'sets' => (int)$exercise['sets'],
                    'target_reps' => $exercise['reps'],
                    'reps' => $exercise['reps'],
                    'target_weight' => (float)$exercise['weight'],
                    'weight' => (float)$exercise['weight'],
                    'rest_time' => (int)$exercise['rest_time'],
                    'category' => 'Strength', // Default since not in your schema
                    'difficulty' => 'Intermediate', // Default since not in your schema
                    'completed_sets' => 0,
                    'is_completed' => false,
                    'logged_sets' => []
                ];
            }, $exercises);
            
            respond([
                "success" => true,
                "data" => [
                    "routine_id" => is_numeric($routineId) ? (int)$routineId : $routineId,
                    "routine_name" => $routineName,
                    "exercises" => $formattedExercises,
                    "stats" => $stats
                ]
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in getWorkoutPreview: " . $e->getMessage());
            respond([
                "success" => false,
                "error" => "Database error: " . $e->getMessage()
            ]);
        }
        break;
        
    case 'logExerciseSet':
        try {
            $userId = validateUserId($input['user_id'] ?? null);
            $memberWorkoutExerciseId = intval($input['member_workout_exercise_id'] ?? 0);
            $setNumber = intval($input['set_number'] ?? 0);
            $reps = intval($input['reps'] ?? 0);
            $weight = floatval($input['weight'] ?? 0.0);
            
            error_log("REAL-TIME LOG - Logging single exercise set: user=$userId, member_workout_exercise_id=$memberWorkoutExerciseId, set=$setNumber, reps=$reps, weight=$weight");
            
            // CRITICAL FIX: Verify the member_workout_exercise exists and belongs to the user - Fixed table names
            $verifyStmt = $pdo->prepare("
                SELECT mwe.id 
                FROM member_workout_exercise mwe
                JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
                JOIN member_programhdr mph ON mpw.member_program_hdr_id = mph.id
                WHERE mwe.id = :member_workout_exercise_id AND mph.user_id = :user_id
            ");
            $verifyStmt->bindParam(':member_workout_exercise_id', $memberWorkoutExerciseId, PDO::PARAM_INT);
            $verifyStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $verifyStmt->execute();
            
            if (!$verifyStmt->fetch()) {
                respond([
                    "success" => false,
                    "error" => "Exercise not found or access denied. member_workout_exercise_id: $memberWorkoutExerciseId does not exist or doesn't belong to user: $userId"
                ]);
            }
            
            // Check if there's already an exercise log for today - Fixed table names
            $exerciseLogStmt = $pdo->prepare("
                SELECT id FROM member_exercise_log 
                WHERE member_id = :member_id 
                AND member_workout_exercise_id = :member_workout_exercise_id 
                AND log_date = CURDATE()
            ");
            $exerciseLogStmt->bindParam(':member_id', $userId, PDO::PARAM_INT);
            $exerciseLogStmt->bindParam(':member_workout_exercise_id', $memberWorkoutExerciseId, PDO::PARAM_INT);
            $exerciseLogStmt->execute();
            $exerciseLog = $exerciseLogStmt->fetch(PDO::FETCH_ASSOC);
            
            $exerciseLogId = null;
            if ($exerciseLog) {
                $exerciseLogId = (int)$exerciseLog['id'];
            } else {
                // Create new exercise log entry - Fixed table names
                $createLogStmt = $pdo->prepare("
                    INSERT INTO member_exercise_log 
                    (member_id, member_workout_exercise_id, actual_sets, actual_reps, total_kg, log_date)
                    VALUES (:member_id, :member_workout_exercise_id, 0, 0, 0, CURDATE())
                ");
                $createLogStmt->bindParam(':member_id', $userId, PDO::PARAM_INT);
                $createLogStmt->bindParam(':member_workout_exercise_id', $memberWorkoutExerciseId, PDO::PARAM_INT);
                $createLogStmt->execute();
                $exerciseLogId = (int)$pdo->lastInsertId();
            }
            
            // Insert or update the specific set - Fixed table names
            $setLogStmt = $pdo->prepare("
                INSERT INTO member_exercise_set_log 
                (exercise_log_id, set_number, reps, weight)
                VALUES (:exercise_log_id, :set_number, :reps, :weight)
                ON DUPLICATE KEY UPDATE
                reps = VALUES(reps),
                weight = VALUES(weight)
            ");
            $setLogStmt->bindParam(':exercise_log_id', $exerciseLogId, PDO::PARAM_INT);
            $setLogStmt->bindParam(':set_number', $setNumber, PDO::PARAM_INT);
            $setLogStmt->bindParam(':reps', $reps, PDO::PARAM_INT);
            $setLogStmt->bindParam(':weight', $weight, PDO::PARAM_STR);
            $setLogStmt->execute();
            
            // Update the exercise log summary - Fixed table names
            $updateSummaryStmt = $pdo->prepare("
                UPDATE member_exercise_log mel
                SET 
                    actual_sets = (
                        SELECT COUNT(*) 
                        FROM member_exercise_set_log mesl 
                        WHERE mesl.exercise_log_id = mel.id
                    ),
                    actual_reps = (
                        SELECT SUM(reps) 
                        FROM member_exercise_set_log mesl 
                        WHERE mesl.exercise_log_id = mel.id
                    ),
                    total_kg = (
                        SELECT SUM(reps * weight) 
                        FROM member_exercise_set_log mesl 
                        WHERE mesl.exercise_log_id = mel.id
                    )
                WHERE mel.id = :exercise_log_id
            ");
            $updateSummaryStmt->bindParam(':exercise_log_id', $exerciseLogId, PDO::PARAM_INT);
            $updateSummaryStmt->execute();
            
            respond([
                "success" => true,
                "message" => "Exercise set logged successfully",
                "exercise_log_id" => (int)$exerciseLogId,
                "set_log_id" => (int)$pdo->lastInsertId()
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in logExerciseSet: " . $e->getMessage());
            respond([
                "success" => false,
                "error" => "Database error: " . $e->getMessage()
            ]);
        }
        break;
        
    case 'completeWorkout':
        try {
            $routineId = validateRoutineId($input['routine_id'] ?? null);
            $userId = validateUserId($input['user_id'] ?? null);
            $duration = intval($input['duration'] ?? 0);
            $totalVolume = floatval($input['total_volume'] ?? 0);
            $completedExercises = intval($input['completed_exercises'] ?? 0);
            $totalExercises = intval($input['total_exercises'] ?? 0);
            $totalSets = intval($input['total_sets'] ?? 0);
            $exercises = $input['exercises'] ?? [];
            
            error_log("Completing workout: routine=$routineId, user=$userId, duration=$duration");
            error_log("Exercises data: " . json_encode($exercises));
            
            // Verify routine ownership - Fixed table names
            $checkStmt = $pdo->prepare("SELECT id FROM member_programhdr WHERE id = :routine_id AND user_id = :user_id");
            $checkStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
            $checkStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $checkStmt->execute();
            
            if (!$checkStmt->fetch()) {
                respond([
                    "success" => false,
                    "error" => "Routine not found or access denied"
                ]);
            }
            
            // Start transaction for data consistency
            $pdo->beginTransaction();
            
            try {
                $processedExercises = 0;
                
                // Log each exercise's completed sets to member_exercise_log and member_exercise_set_log
                foreach ($exercises as $exercise) {
                    $exerciseId = intval($exercise['exercise_id'] ?? 0);
                    $memberWorkoutExerciseId = $exercise['member_workout_exercise_id'] ?? null;
                    $completedSets = intval($exercise['completed_sets'] ?? 0);
                    $loggedSets = $exercise['logged_sets'] ?? [];
                    
                    error_log("Processing exercise: exercise_id=$exerciseId, member_workout_exercise_id=$memberWorkoutExerciseId, completed_sets=$completedSets");
                    
                    // CRITICAL FIX: If member_workout_exercise_id is null, get it from exercise_id and routine_id
                    if ($memberWorkoutExerciseId === null || $memberWorkoutExerciseId === 0) {
                        $memberWorkoutExerciseId = getMemberWorkoutExerciseId($pdo, $routineId, $exerciseId, $userId);
                        error_log("Retrieved member_workout_exercise_id: $memberWorkoutExerciseId for exercise_id: $exerciseId");
                    }
                    
                    if ($memberWorkoutExerciseId === null) {
                        error_log("Skipping exercise_id $exerciseId - no member_workout_exercise_id found");
                        continue;
                    }
                    
                    if ($completedSets > 0 && !empty($loggedSets)) {
                        // Verify member_workout_exercise_id exists before logging - Fixed table names
                        $verifyExerciseStmt = $pdo->prepare("
                            SELECT mwe.id 
                            FROM member_workout_exercise mwe
                            JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
                            JOIN member_programhdr mph ON mpw.member_program_hdr_id = mph.id
                            WHERE mwe.id = :member_workout_exercise_id AND mph.user_id = :user_id
                        ");
                        $verifyExerciseStmt->bindParam(':member_workout_exercise_id', $memberWorkoutExerciseId, PDO::PARAM_INT);
                        $verifyExerciseStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                        $verifyExerciseStmt->execute();
                        
                        if (!$verifyExerciseStmt->fetch()) {
                            error_log("Skipping invalid member_workout_exercise_id: $memberWorkoutExerciseId for user: $userId");
                            continue;
                        }
                        
                        // Create or get exercise log entry - Fixed table names
                        $exerciseLogStmt = $pdo->prepare("
                            SELECT id FROM member_exercise_log 
                            WHERE member_id = :member_id 
                            AND member_workout_exercise_id = :member_workout_exercise_id 
                            AND log_date = CURDATE()
                        ");
                        $exerciseLogStmt->bindParam(':member_id', $userId, PDO::PARAM_INT);
                        $exerciseLogStmt->bindParam(':member_workout_exercise_id', $memberWorkoutExerciseId, PDO::PARAM_INT);
                        $exerciseLogStmt->execute();
                        $exerciseLog = $exerciseLogStmt->fetch(PDO::FETCH_ASSOC);
                        
                        $exerciseLogId = null;
                        if ($exerciseLog) {
                            $exerciseLogId = (int)$exerciseLog['id'];
                            error_log("Found existing exercise log: $exerciseLogId");
                        } else {
                            // Create new exercise log entry - Fixed table names
                            $createLogStmt = $pdo->prepare("
                                INSERT INTO member_exercise_log 
                                (member_id, member_workout_exercise_id, actual_sets, actual_reps, total_kg, log_date)
                                VALUES (:member_id, :member_workout_exercise_id, :actual_sets, 0, 0, CURDATE())
                            ");
                            $createLogStmt->bindParam(':member_id', $userId, PDO::PARAM_INT);
                            $createLogStmt->bindParam(':member_workout_exercise_id', $memberWorkoutExerciseId, PDO::PARAM_INT);
                            $createLogStmt->bindParam(':actual_sets', $completedSets, PDO::PARAM_INT);
                            $createLogStmt->execute();
                            $exerciseLogId = (int)$pdo->lastInsertId();
                            error_log("Created new exercise log: $exerciseLogId");
                        }
                        
                        // Log each individual set - Fixed table names
                        $setNumber = 1;
                        foreach ($loggedSets as $set) {
                            $setReps = intval($set['reps'] ?? 0);
                            $setWeight = floatval($set['weight'] ?? 0);
                            $setRpe = intval($set['rpe'] ?? 0);
                            $setNotes = $set['notes'] ?? '';
                            
                            error_log("COMPLETE WORKOUT - Logging set $setNumber: reps=$setReps, weight=$setWeight, rpe=$setRpe");
                            error_log("COMPLETE WORKOUT - Raw set data: " . json_encode($set));
                            
                            $setLogStmt = $pdo->prepare("
                                INSERT INTO member_exercise_set_log 
                                (exercise_log_id, set_number, reps, weight, rpe, notes)
                                VALUES (:exercise_log_id, :set_number, :reps, :weight, :rpe, :notes)
                                ON DUPLICATE KEY UPDATE
                                reps = VALUES(reps),
                                weight = VALUES(weight),
                                rpe = VALUES(rpe),
                                notes = VALUES(notes)
                            ");
                            $setLogStmt->bindParam(':exercise_log_id', $exerciseLogId, PDO::PARAM_INT);
                            $setLogStmt->bindParam(':set_number', $setNumber, PDO::PARAM_INT);
                            $setLogStmt->bindParam(':reps', $setReps, PDO::PARAM_INT);
                            $setLogStmt->bindParam(':weight', $setWeight, PDO::PARAM_STR);
                            $setLogStmt->bindParam(':rpe', $setRpe, PDO::PARAM_INT);
                            $setLogStmt->bindParam(':notes', $setNotes, PDO::PARAM_STR);
                            $setLogStmt->execute();
                            
                            $setNumber++;
                        }
                        
                        // Update exercise log summary - Fixed table names
                        $updateSummaryStmt = $pdo->prepare("
                            UPDATE member_exercise_log mel
                            SET 
                                actual_sets = (
                                    SELECT COUNT(*) 
                                    FROM member_exercise_set_log mesl 
                                    WHERE mesl.exercise_log_id = mel.id
                                ),
                                actual_reps = (
                                    SELECT SUM(reps) 
                                    FROM member_exercise_set_log mesl 
                                    WHERE mesl.exercise_log_id = mel.id
                                ),
                                total_kg = (
                                    SELECT SUM(reps * weight) 
                                    FROM member_exercise_set_log mesl 
                                    WHERE mesl.exercise_log_id = mel.id
                                )
                            WHERE mel.id = :exercise_log_id
                        ");
                        $updateSummaryStmt->bindParam(':exercise_log_id', $exerciseLogId, PDO::PARAM_INT);
                        $updateSummaryStmt->execute();
                        
                        $processedExercises++;
                        error_log("Successfully processed exercise with log ID: $exerciseLogId");
                    }
                }
                
                // Update routine progress - Fixed table names
                $completionRate = $totalExercises > 0 ? round(($completedExercises / $totalExercises) * 100) : 0;
                
                $updateStmt = $pdo->prepare("
                    UPDATE member_programhdr 
                    SET 
                        completion_rate = :completion_rate,
                        total_sessions = total_sessions + 1,
                        updated_at = NOW()
                    WHERE id = :routine_id AND user_id = :user_id
                ");
                $updateStmt->bindParam(':completion_rate', $completionRate, PDO::PARAM_INT);
                $updateStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
                $updateStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $updateStmt->execute();
                
                // Commit transaction
                $pdo->commit();
                
                error_log("Workout completed successfully. Processed $processedExercises exercises.");
                
                respond([
                    "success" => true,
                    "message" => "Workout completed and logged successfully",
                    "completion_rate" => (int)$completionRate,
                    "processed_exercises" => (int)$processedExercises
                ]);
                
            } catch (Exception $e) {
                // Rollback transaction on error
                $pdo->rollback();
                error_log("Transaction rolled back due to error: " . $e->getMessage());
                throw $e;
            }
            
        } catch (PDOException $e) {
            error_log("Database error in completeWorkout: " . $e->getMessage());
            respond([
                "success" => false,
                "error" => "Database error: " . $e->getMessage()
            ]);
        }
        break;
        
    case 'getWorkoutHistory':
        try {
            $routineId = validateRoutineId($_GET['routine_id'] ?? null);
            $userId = validateUserId($_GET['user_id'] ?? null);
            
            error_log("Fetching workout history: routine=$routineId, user=$userId");
            
            // Get detailed workout history with individual sets - Fixed table names
            $historyStmt = $pdo->prepare("
                SELECT 
                    mel.log_date,
                    e.name as exercise_name,
                    mel.actual_sets,
                    mel.actual_reps,
                    mel.total_kg,
                    mesl.set_number,
                    mesl.reps as set_reps,
                    mesl.weight as set_weight,
                    mesl.rpe,
                    mesl.notes
                FROM member_exercise_log mel
                JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
                JOIN exercise e ON mwe.exercise_id = e.id
                JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
                LEFT JOIN member_exercise_set_log mesl ON mel.id = mesl.exercise_log_id
                WHERE mpw.member_program_hdr_id = :routine_id AND mel.member_id = :user_id
                ORDER BY mel.log_date DESC, mel.id DESC, mesl.set_number ASC
            ");
            $historyStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
            $historyStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $historyStmt->execute();
            $history = $historyStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Convert numeric fields to integers
            foreach ($history as &$record) {
                if (isset($record['actual_sets'])) {
                    $record['actual_sets'] = (int)$record['actual_sets'];
                }
                if (isset($record['actual_reps'])) {
                    $record['actual_reps'] = (int)$record['actual_reps'];
                }
                if (isset($record['total_kg'])) {
                    $record['total_kg'] = (float)$record['total_kg'];
                }
                if (isset($record['set_number'])) {
                    $record['set_number'] = (int)$record['set_number'];
                }
                if (isset($record['set_reps'])) {
                    $record['set_reps'] = (int)$record['set_reps'];
                }
                if (isset($record['set_weight'])) {
                    $record['set_weight'] = (float)$record['set_weight'];
                }
                if (isset($record['rpe'])) {
                    $record['rpe'] = (int)$record['rpe'];
                }
            }
            
            respond([
                "success" => true,
                "history" => $history
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in getWorkoutHistory: " . $e->getMessage());
            respond([
                "success" => false,
                "error" => "Database error: " . $e->getMessage()
            ]);
        }
        break;
        
    case 'getExerciseAnalytics':
        try {
            $exerciseId = intval($_GET['exercise_id'] ?? 0);
            $userId = validateUserId($_GET['user_id'] ?? null);
            $days = intval($_GET['days'] ?? 30); // Default to last 30 days
            
            error_log("Fetching exercise analytics: exercise=$exerciseId, user=$userId, days=$days");
            
            // Get detailed analytics for a specific exercise - Fixed table names
            $analyticsStmt = $pdo->prepare("
                SELECT 
                    mel.log_date,
                    mesl.set_number,
                    mesl.reps,
                    mesl.weight,
                    mesl.rpe,
                    (mesl.reps * mesl.weight) as volume
                FROM member_exercise_log mel
                JOIN member_exercise_set_log mesl ON mel.id = mesl.exercise_log_id
                JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
                WHERE mwe.exercise_id = :exercise_id 
                AND mel.member_id = :user_id
                AND mel.log_date >= DATE_SUB(CURDATE(), INTERVAL :days DAY)
                ORDER BY mel.log_date DESC, mesl.set_number ASC
            ");
            $analyticsStmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
            $analyticsStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $analyticsStmt->bindParam(':days', $days, PDO::PARAM_INT);
            $analyticsStmt->execute();
            $analytics = $analyticsStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Convert numeric fields to integers
            foreach ($analytics as &$record) {
                if (isset($record['set_number'])) {
                    $record['set_number'] = (int)$record['set_number'];
                }
                if (isset($record['reps'])) {
                    $record['reps'] = (int)$record['reps'];
                }
                if (isset($record['weight'])) {
                    $record['weight'] = (float)$record['weight'];
                }
                if (isset($record['rpe'])) {
                    $record['rpe'] = (int)$record['rpe'];
                }
                if (isset($record['volume'])) {
                    $record['volume'] = (float)$record['volume'];
                }
            }
            
            respond([
                "success" => true,
                "analytics" => $analytics
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in getExerciseAnalytics: " . $e->getMessage());
            respond([
                "success" => false,
                "error" => "Database error: " . $e->getMessage()
            ]);
        }
        break;
        
    case 'copyTemplateToUser':
        try {
            $templateId = validateRoutineId($_GET['template_id'] ?? null);
            $userId = validateUserId($_GET['user_id'] ?? null);
            
            error_log("Copying template program $templateId to user $userId");
            
            // Check if this is a template ID
            if (strpos($templateId, 'template_') === 0) {
                $actualTemplateId = str_replace('template_', '', $templateId);
            } else {
                $actualTemplateId = $templateId;
            }
            
            // Get template program details from programs table (matching routines.php logic)
            $templateStmt = $pdo->prepare("
                SELECT 
                    p.id,
                    p.name,
                    p.description,
                    ph.difficulty,
                    ph.goal,
                    ph.notes,
                    ph.duration,
                    ph.color,
                    ph.tags,
                    p.name as program_name
                FROM programs p
                LEFT JOIN programhdr ph ON p.id = ph.program_id AND ph.type = 'template'
                WHERE p.id = :template_id
            ");
            $templateStmt->bindParam(':template_id', $actualTemplateId, PDO::PARAM_INT);
            $templateStmt->execute();
            $template = $templateStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$template) {
                respond([
                    "success" => false,
                    "error" => "Template program not found"
                ]);
            }
            
            // Get the programhdr_id that corresponds to this programs.id
            $programHdrStmt = $pdo->prepare("
                SELECT id FROM programhdr 
                WHERE program_id = :template_id AND type = 'template'
            ");
            $programHdrStmt->bindParam(':template_id', $actualTemplateId, PDO::PARAM_INT);
            $programHdrStmt->execute();
            $programHdr = $programHdrStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$programHdr) {
                respond([
                    "success" => false,
                    "error" => "Template program structure not found"
                ]);
            }
            
            $programHdrId = $programHdr['id'];
            
            // Check if user already has a copy of this template
            $existingStmt = $pdo->prepare("
                SELECT id FROM member_programhdr 
                WHERE user_id = :user_id AND program_hdr_id = :program_hdr_id
            ");
            $existingStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $existingStmt->bindParam(':program_hdr_id', $programHdrId, PDO::PARAM_INT);
            $existingStmt->execute();
            $existing = $existingStmt->fetch(PDO::FETCH_ASSOC);
            
            if ($existing) {
                respond([
                    "success" => true,
                    "message" => "Template already copied to user",
                    "routine_id" => (int)$existing['id']
                ]);
            }
            
            // Start transaction
            $pdo->beginTransaction();
            
            try {
                // Create new member_programhdr entry
                $insertStmt = $pdo->prepare("
                    INSERT INTO member_programhdr 
                    (user_id, program_hdr_id, created_by, color, tags, goal, notes, completion_rate, scheduled_days, difficulty, total_sessions)
                    VALUES (:user_id, :program_hdr_id, :created_by, :color, :tags, :goal, :notes, :completion_rate, :scheduled_days, :difficulty, :total_sessions)
                ");
                $insertStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $insertStmt->bindParam(':program_hdr_id', $actualTemplateId, PDO::PARAM_INT);
                $insertStmt->bindParam(':created_by', 1, PDO::PARAM_INT); // Admin
                $insertStmt->bindParam(':color', $template['color'] ?: '0xFF4ECDC4');
                $insertStmt->bindParam(':tags', $template['tags'] ?: '[]');
                $insertStmt->bindParam(':goal', $template['goal'] ?: $template['name']);
                $insertStmt->bindParam(':notes', $template['notes'] ?: '');
                $insertStmt->bindParam(':completion_rate', 0, PDO::PARAM_INT);
                $insertStmt->bindParam(':scheduled_days', '[]');
                $insertStmt->bindParam(':difficulty', $template['difficulty'] ?: 'Beginner');
                $insertStmt->bindParam(':total_sessions', 0, PDO::PARAM_INT);
                $insertStmt->execute();
                
                $newRoutineId = $pdo->lastInsertId();
                error_log("Created member_programhdr with ID: $newRoutineId");
                
                // Create member_program_workout entry
                $workoutStmt = $pdo->prepare("
                    INSERT INTO member_program_workout (member_program_hdr_id, workout_details)
                    VALUES (:member_program_hdr_id, :workout_details)
                ");
                $workoutDetails = json_encode([
                    'name' => $template['name'] ?: $template['program_name'],
                    'description' => $template['description'],
                    'difficulty' => $template['difficulty'],
                    'goal' => $template['goal'],
                    'duration' => $template['duration'] . ' days',
                    'created_at' => date('Y-m-d H:i:s'),
                    'is_template' => false,
                    'template_id' => $actualTemplateId
                ]);
                $workoutStmt->bindParam(':member_program_hdr_id', $newRoutineId, PDO::PARAM_INT);
                $workoutStmt->bindParam(':workout_details', $workoutDetails);
                $workoutStmt->execute();
                
                $newWorkoutId = $pdo->lastInsertId();
                error_log("Created member_program_workout with ID: $newWorkoutId");
                
                // Copy exercises from template
                $exerciseStmt = $pdo->prepare("
                    SELECT pwe.exercise_id, pwe.sets, pwe.reps, pwe.weight
                    FROM program_workout_exercise pwe
                    JOIN program_workout pw ON pwe.program_workout_id = pw.id
                    WHERE pw.program_hdr_id = :template_id
                ");
                $exerciseStmt->bindParam(':template_id', $actualTemplateId, PDO::PARAM_INT);
                $exerciseStmt->execute();
                $templateExercises = $exerciseStmt->fetchAll(PDO::FETCH_ASSOC);
                
                if (!empty($templateExercises)) {
                    $memberExerciseStmt = $pdo->prepare("
                        INSERT INTO member_workout_exercise 
                        (member_program_workout_id, exercise_id, sets, reps, weight)
                        VALUES (:member_program_workout_id, :exercise_id, :sets, :reps, :weight)
                    ");
                    
                    foreach ($templateExercises as $exercise) {
                        $memberExerciseStmt->bindParam(':member_program_workout_id', $newWorkoutId, PDO::PARAM_INT);
                        $memberExerciseStmt->bindParam(':exercise_id', $exercise['exercise_id'], PDO::PARAM_INT);
                        $memberExerciseStmt->bindParam(':sets', $exercise['sets'], PDO::PARAM_INT);
                        $memberExerciseStmt->bindParam(':reps', $exercise['reps'], PDO::PARAM_INT);
                        $memberExerciseStmt->bindParam(':weight', $exercise['weight'], PDO::PARAM_STR);
                        $memberExerciseStmt->execute();
                    }
                    
                    error_log("Copied " . count($templateExercises) . " exercises to user program");
                }
                
                // Commit transaction
                $pdo->commit();
                
                respond([
                    "success" => true,
                    "message" => "Template program copied successfully",
                    "routine_id" => (int)$newRoutineId
                ]);
                
            } catch (Exception $e) {
                // Rollback transaction on error
                $pdo->rollback();
                error_log("Transaction rolled back due to error: " . $e->getMessage());
                throw $e;
            }
            
        } catch (PDOException $e) {
            error_log("Database error in copyTemplateToUser: " . $e->getMessage());
            respond([
                "success" => false,
                "error" => "Database error: " . $e->getMessage()
            ]);
        }
        break;
        
    default:
        respond(["error" => "Invalid action: " . $action]);
}
?>
