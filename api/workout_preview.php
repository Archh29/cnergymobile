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

// Debug: Log all requests
error_log("=== API REQUEST RECEIVED ===");
error_log("Request method: " . $_SERVER['REQUEST_METHOD']);
error_log("Request URI: " . $_SERVER['REQUEST_URI']);
error_log("Request body: " . file_get_contents('php://input'));
error_log("=== API FILE LOADED SUCCESSFULLY ===");

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
    if (!$routineId || !is_numeric($routineId) || $routineId <= 0) {
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
        error_log("=== GETWORKOUTPREVIEW CASE STARTED ===");
        try {
            $routineId = validateRoutineId($_GET['routine_id'] ?? null);
            $userId = validateUserId($_GET['user_id'] ?? null);
            
            error_log("Fetching workout preview for routine ID: $routineId, user ID: $userId");
            
            // First, verify the routine belongs to the user - Fixed table names to lowercase
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
            
            if (!$routine) {
                respond([
                    "success" => false,
                    "error" => "Routine not found or access denied"
                ]);
            }
            
            // Get routine name from workout details
            $workoutDetails = json_decode($routine['workout_details'] ?? '{}', true);
            $routineName = $workoutDetails['name'] ?? "Routine #$routineId";
            
            // Fetch exercises for this routine - get all individual sets
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
                ORDER BY e.id, mwe.id ASC
            ");
            $exerciseStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
            $exerciseStmt->execute();
            $exercises = $exerciseStmt->fetchAll(PDO::FETCH_ASSOC);
            
            error_log("Found " . count($exercises) . " exercise sets for routine $routineId");
            error_log("=== TESTING WEIGHT UPDATE LOGIC ===");

            // Group exercises by exercise_id and process individual sets
            $groupedExercises = [];
            foreach ($exercises as $exerciseSet) {
                $exerciseId = $exerciseSet['exercise_id'];
                
                if (!isset($groupedExercises[$exerciseId])) {
                    $groupedExercises[$exerciseId] = [
                        'exercise_id' => $exerciseId,
                        'name' => $exerciseSet['name'],
                        'description' => $exerciseSet['description'],
                        'image_url' => $exerciseSet['image_url'],
                        'video_url' => $exerciseSet['video_url'],
                        'target_muscle' => $exerciseSet['target_muscle'],
                        'rest_time' => $exerciseSet['rest_time'],
                        'sets' => [],
                        'total_sets' => 0,
                        'member_workout_exercise_id' => $exerciseSet['member_workout_exercise_id']
                    ];
                }
                
                // Add this set to the exercise
                $groupedExercises[$exerciseId]['sets'][] = [
                    'reps' => (int)$exerciseSet['reps'],
                    'weight' => (float)$exerciseSet['weight'],
                    'timestamp' => date('c'),
                    'isCompleted' => false,
                ];
                $groupedExercises[$exerciseId]['total_sets']++;
            }

            // Convert to array and calculate stats
            $exercises = array_values($groupedExercises);
            $totalExercises = count($exercises);
            $totalSets = array_sum(array_column($exercises, 'total_sets'));
            
            // Update exercises with latest logged weights
            foreach ($exercises as &$exercise) {
                $exerciseId = $exercise['exercise_id'];
                $memberWorkoutExerciseId = $exercise['member_workout_exercise_id'];
                
                error_log("=== DEBUGGING WEIGHT FETCH ===");
                error_log("Exercise ID: $exerciseId");
                error_log("Member Workout Exercise ID: $memberWorkoutExerciseId");
                error_log("User ID: $userId");
                
                // Get latest logged sets for this exercise - try multiple approaches
                $latestSets = [];
                
                // Approach 1: Try with member_workout_exercise_id
                $latestSetsStmt = $pdo->prepare("
                    SELECT 
                        mesl.reps,
                        mesl.weight,
                        mel.log_date,
                        mel.member_workout_exercise_id
                    FROM member_exercise_set_log mesl
                    JOIN member_exercise_log mel ON mesl.exercise_log_id = mel.id
                    WHERE mel.member_workout_exercise_id = :member_workout_exercise_id
                    AND mel.member_id = :user_id
                    ORDER BY mel.log_date DESC, mesl.set_number ASC
                    LIMIT 10
                ");
                $latestSetsStmt->bindParam(':member_workout_exercise_id', $memberWorkoutExerciseId, PDO::PARAM_INT);
                $latestSetsStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $latestSetsStmt->execute();
                $latestSets = $latestSetsStmt->fetchAll(PDO::FETCH_ASSOC);
                
                error_log("Approach 1 - Found " . count($latestSets) . " sets with member_workout_exercise_id: $memberWorkoutExerciseId");
                
                // Approach 2: If no results, try finding by exercise_id and user_id
                if (empty($latestSets)) {
                    error_log("Trying approach 2 - searching by exercise_id and user_id");
                    
                    $latestSetsStmt2 = $pdo->prepare("
                        SELECT 
                            mesl.reps,
                            mesl.weight,
                            mel.log_date,
                            mel.member_workout_exercise_id
                        FROM member_exercise_set_log mesl
                        JOIN member_exercise_log mel ON mesl.exercise_log_id = mel.id
                        JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
                        WHERE mwe.exercise_id = :exercise_id
                        AND mel.member_id = :user_id
                        ORDER BY mel.log_date DESC, mesl.set_number ASC
                        LIMIT 10
                    ");
                    $latestSetsStmt2->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
                    $latestSetsStmt2->bindParam(':user_id', $userId, PDO::PARAM_INT);
                    $latestSetsStmt2->execute();
                    $latestSets = $latestSetsStmt2->fetchAll(PDO::FETCH_ASSOC);
                    
                    error_log("Approach 2 - Found " . count($latestSets) . " sets with exercise_id: $exerciseId");
                }
                
                // Approach 3: If still no results, try finding any logged sets for this user and exercise
                if (empty($latestSets)) {
                    error_log("Trying approach 3 - searching for any logged sets for this user and exercise");
                    
                    $latestSetsStmt3 = $pdo->prepare("
                        SELECT 
                            mesl.reps,
                            mesl.weight,
                            mel.log_date,
                            mel.member_workout_exercise_id
                        FROM member_exercise_set_log mesl
                        JOIN member_exercise_log mel ON mesl.exercise_log_id = mel.id
                        JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
                        JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
                        WHERE mwe.exercise_id = :exercise_id
                        AND mel.member_id = :user_id
                        AND mpw.member_program_hdr_id = :routine_id
                        ORDER BY mel.log_date DESC, mesl.set_number ASC
                        LIMIT 10
                    ");
                    $latestSetsStmt3->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
                    $latestSetsStmt3->bindParam(':user_id', $userId, PDO::PARAM_INT);
                    $latestSetsStmt3->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
                    $latestSetsStmt3->execute();
                    $latestSets = $latestSetsStmt3->fetchAll(PDO::FETCH_ASSOC);
                    
                    error_log("Approach 3 - Found " . count($latestSets) . " sets with exercise_id: $exerciseId and routine_id: $routineId");
                }
                
                if (!empty($latestSets)) {
                    error_log("SUCCESS: Found " . count($latestSets) . " latest sets for exercise $exerciseId");
                    error_log("Latest sets data: " . json_encode($latestSets));
                    
                    // Replace the sets with latest logged weights
                    $exercise['sets'] = [];
                    foreach ($latestSets as $set) {
                        $exercise['sets'][] = [
                            'reps' => (int)$set['reps'],
                            'weight' => (float)$set['weight'],
                            'timestamp' => date('c'),
                            'isCompleted' => false,
                        ];
                    }
                    $exercise['total_sets'] = count($latestSets);
                    
                    error_log("Updated exercise $exerciseId with latest weights: " . json_encode($exercise['sets']));
                } else {
                    error_log("FAILED: No latest sets found for exercise $exerciseId with any approach, using program weights");
                }
            }
            $estimatedVolume = 0;
            $estimatedDuration = 0;
            
            foreach ($exercises as $exercise) {
                // Calculate estimated volume (sum of all sets)
                foreach ($exercise['sets'] as $set) {
                    $estimatedVolume += ($set['weight'] * $set['reps']);
                }
                
                // Calculate estimated duration (2-3 minutes per set + rest time)
                $setTime = $exercise['total_sets'] * 2; // 2 minutes per set
                $restTime = $exercise['total_sets'] * (intval($exercise['rest_time']) / 60); // rest time in minutes
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
            $formattedExercises = array_map(function($exercise) use ($workoutDetails, $pdo, $userId) {
                $exerciseId = $exercise['exercise_id'];
                $memberWorkoutExerciseId = $exercise['member_workout_exercise_id'];
                
                // Use the sets we already processed from the database
                $targetSets = $exercise['sets'];
                
                // Fetch previous lifts for this exercise
                $previousLifts = [];
                try {
                    $previousLiftsStmt = $pdo->prepare("
                        SELECT 
                            mesl.set_number,
                            mesl.reps,
                            mesl.weight,
                            mesl.rpe,
                            mesl.notes,
                            mel.log_date
                        FROM member_exercise_set_log mesl
                        JOIN member_exercise_log mel ON mesl.exercise_log_id = mel.id
                        WHERE mel.member_workout_exercise_id = :member_workout_exercise_id
                        AND mel.member_id = :user_id
                        ORDER BY mel.log_date DESC, mesl.set_number ASC
                        LIMIT 20
                    ");
                    $previousLiftsStmt->bindParam(':member_workout_exercise_id', $memberWorkoutExerciseId, PDO::PARAM_INT);
                    $previousLiftsStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                    $previousLiftsStmt->execute();
                    $previousLifts = $previousLiftsStmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    error_log("Found " . count($previousLifts) . " previous lifts for exercise ID $exerciseId");
                } catch (Exception $e) {
                    error_log("Error fetching previous lifts: " . $e->getMessage());
                }
                
                error_log("Using database sets for exercise ID $exerciseId: " . count($targetSets) . " sets");
                
                return [
                    'id' => (int)$exercise['exercise_id'],
                    'exercise_id' => (int)$exercise['exercise_id'],
                    'member_workout_exercise_id' => (int)$exercise['member_workout_exercise_id'],
                    'name' => $exercise['name'],
                    'target_muscle' => $exercise['target_muscle'] ?? 'General',
                    'description' => $exercise['description'] ?? '',
                    'image_url' => $exercise['image_url'] ?? '',
                    'video_url' => $exercise['video_url'] ?? '',
                    'target_sets' => $targetSets, // Array of individual set configurations from database
                    'previous_lifts' => $previousLifts, // Previous performance data
                    'sets' => $exercise['total_sets'],
                    'target_reps' => $exercise['sets'][0]['reps'] ?? 10, // Use first set's reps as default
                    'reps' => $exercise['sets'][0]['reps'] ?? 10,
                    'target_weight' => $exercise['sets'][0]['weight'] ?? 0.0, // Use first set's weight as default
                    'weight' => $exercise['sets'][0]['weight'] ?? 0.0,
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
                    "routine_id" => (int)$routineId,
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
            
            error_log("Logging single exercise set: user=$userId, member_workout_exercise_id=$memberWorkoutExerciseId, set=$setNumber, reps=$reps, weight=$weight");
            
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
        error_log("=== COMPLETEWORKOUT CASE STARTED ===");
        error_log("=== API IS BEING CALLED ===");
        error_log("=== INPUT DATA: " . json_encode($input) . " ===");
        error_log("=== ROUTINE ID: " . ($input['routine_id'] ?? 'NULL') . " ===");
        error_log("=== USER ID: " . ($input['user_id'] ?? 'NULL') . " ===");
        error_log("=== EXERCISES COUNT: " . count($input['exercises'] ?? []) . " ===");
        error_log("=== COMPLETEWORKOUT CASE IS DEFINITELY BEING EXECUTED ===");
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
                            
                            error_log("Logging set $setNumber: reps=$setReps, weight=$setWeight, rpe=$setRpe");
                            
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
                error_log("=== REACHED WEIGHT UPDATE SECTION ===");
                error_log("=== ABOUT TO UPDATE WEIGHTS ===");
                error_log("=== ROUTINE ID FOR UPDATE: $routineId ===");
                error_log("=== USER ID FOR UPDATE: $userId ===");
                error_log("=== EXERCISES COUNT FOR UPDATE: " . count($exercises) . " ===");
                
                // Update program weights with the weights user actually used (before respond)
                error_log("=== UPDATING PROGRAM WEIGHTS ===");
                error_log("Total exercises to process: " . count($exercises));
                error_log("Exercises data: " . json_encode($exercises));
                error_log("WEIGHT UPDATE SECTION IS BEING EXECUTED!");
                
                foreach ($exercises as $exercise) {
                    $exerciseId = $exercise['exercise_id'] ?? $exercise['id'] ?? null;
                    $loggedSets = $exercise['logged_sets'] ?? [];
                    
                    error_log("Processing exercise ID: $exerciseId");
                    error_log("Logged sets count: " . count($loggedSets));
                    error_log("Logged sets data: " . json_encode($loggedSets));
                    
                    if ($exerciseId && !empty($loggedSets)) {
                        error_log("EXERCISE HAS LOGGED SETS - PROCEEDING WITH UPDATE");
                        try {
                            error_log("ATTEMPTING TO UPDATE WEIGHTS FOR EXERCISE $exerciseId");
                            
                            // Delete existing sets for this exercise
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
                            
                            error_log("Deleted existing sets for exercise $exerciseId");
                            
                            // Insert new sets with updated weights
                            $insertStmt = $pdo->prepare("
                                INSERT INTO member_workout_exercise 
                                (member_program_workout_id, exercise_id, sets, reps, weight)
                                VALUES (
                                    (SELECT id FROM member_program_workout WHERE member_program_hdr_id = :routine_id),
                                    :exercise_id, 1, :reps, :weight
                                )
                            ");
                            
                            foreach ($loggedSets as $setIndex => $set) {
                                $reps = intval($set['reps'] ?? 0);
                                $weight = floatval($set['weight'] ?? 0);
                                
                                error_log("Inserting set " . ($setIndex + 1) . ": reps=$reps, weight=$weight");
                                
                                $insertStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
                                $insertStmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
                                $insertStmt->bindParam(':reps', $reps, PDO::PARAM_INT);
                                $insertStmt->bindParam(':weight', $weight, PDO::PARAM_STR);
                                $insertStmt->execute();
                                
                                error_log("Successfully inserted set " . ($setIndex + 1) . " for exercise $exerciseId");
                            }
                            
                            error_log("✅ COMPLETED: Updated program weights for exercise ID $exerciseId with " . count($loggedSets) . " sets");
                        } catch (Exception $e) {
                            error_log("❌ Error updating weights for exercise $exerciseId: " . $e->getMessage());
                        }
                    }
                }
                
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
        
    case 'deleteProgramWeights':
        try {
            $routineId = validateRoutineId($input['routine_id'] ?? null);
            $userId = validateUserId($input['user_id'] ?? null);
            $exerciseId = validateRoutineId($input['exercise_id'] ?? null);
            
            error_log("Deleting program weights for routine: $routineId, exercise: $exerciseId, user: $userId");
            
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
            
            $deletedRows = $deleteStmt->rowCount();
            error_log("Deleted $deletedRows program weight rows for exercise $exerciseId");
            
            respond([
                "success" => true,
                "message" => "Program weights deleted successfully",
                "deleted_rows" => $deletedRows
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in deleteProgramWeights: " . $e->getMessage());
            respond([
                "success" => false,
                "error" => "Database error: " . $e->getMessage()
            ]);
        }
        break;
        
    case 'insertProgramWeight':
        try {
            $routineId = validateRoutineId($input['routine_id'] ?? null);
            $userId = validateUserId($input['user_id'] ?? null);
            $exerciseId = validateRoutineId($input['exercise_id'] ?? null);
            $reps = intval($input['reps'] ?? 0);
            $weight = floatval($input['weight'] ?? 0.0);
            $workoutDate = $input['workout_date'] ?? date('Y-m-d'); // Default to today if not provided
            
            error_log("Inserting program weight: routine=$routineId, exercise=$exerciseId, reps=$reps, weight=$weight, date=$workoutDate");
            
            // Insert new program weight with workout date
            $insertStmt = $pdo->prepare("
                INSERT INTO member_workout_exercise 
                (member_program_workout_id, exercise_id, sets, reps, weight, workout_date)
                VALUES (
                    (SELECT id FROM member_program_workout WHERE member_program_hdr_id = :routine_id),
                    :exercise_id, 1, :reps, :weight, :workout_date
                )
            ");
            $insertStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
            $insertStmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
            $insertStmt->bindParam(':reps', $reps, PDO::PARAM_INT);
            $insertStmt->bindParam(':weight', $weight, PDO::PARAM_STR);
            $insertStmt->bindParam(':workout_date', $workoutDate, PDO::PARAM_STR);
            $insertStmt->execute();
            
            $insertId = $pdo->lastInsertId();
            error_log("Inserted program weight with ID: $insertId and date: $workoutDate");
            
            respond([
                "success" => true,
                "message" => "Program weight inserted successfully",
                "insert_id" => $insertId,
                "workout_date" => $workoutDate
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in insertProgramWeight: " . $e->getMessage());
            respond([
                "success" => false,
                "error" => "Database error: " . $e->getMessage()
            ]);
        }
        break;
        
    case 'getWorkoutHistory':
        try {
            $routineId = validateRoutineId($input['routine_id'] ?? null);
            $userId = validateUserId($input['user_id'] ?? null);
            $exerciseId = validateRoutineId($input['exercise_id'] ?? null);
            
            error_log("Getting workout history for routine: $routineId, exercise: $exerciseId, user: $userId");
            
            // Get workout history for this exercise
            $historyStmt = $pdo->prepare("
                SELECT 
                    mwe.workout_date,
                    mwe.reps,
                    mwe.weight,
                    mwe.sets,
                    e.exercise_name
                FROM member_workout_exercise mwe
                JOIN exercise e ON mwe.exercise_id = e.id
                WHERE mwe.member_program_workout_id = (
                    SELECT id FROM member_program_workout 
                    WHERE member_program_hdr_id = :routine_id
                ) AND mwe.exercise_id = :exercise_id
                AND mwe.workout_date IS NOT NULL
                ORDER BY mwe.workout_date DESC, mwe.id DESC
            ");
            $historyStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
            $historyStmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
            $historyStmt->execute();
            
            $history = $historyStmt->fetchAll(PDO::FETCH_ASSOC);
            error_log("Found " . count($history) . " workout history records");
            
            respond([
                "success" => true,
                "workout_history" => $history,
                "exercise_name" => $history[0]['exercise_name'] ?? 'Unknown Exercise'
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in getWorkoutHistory: " . $e->getMessage());
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
