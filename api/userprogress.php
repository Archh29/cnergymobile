<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');

// Add debugging (remove in production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$dbname = "u773938685_cnergydb";      
$username = "u773938685_archh29";  
$password = "Gwapoko385@"; 

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? null;

// Extract user_id from GET parameters or POST body
$user_id = null;
if ($method === 'GET') {
    $user_id = $_GET['user_id'] ?? null;
} else if ($method === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);
    $user_id = $input['user_id'] ?? $_GET['user_id'] ?? null;
}

// Function to check if table exists
function tableExists($pdo, $tableName) {
    try {
        $stmt = $pdo->prepare("SHOW TABLES LIKE ?");
        $stmt->execute([$tableName]);
        return $stmt->rowCount() > 0;
    } catch (PDOException $e) {
        return false;
    }
}

// Function to check if column exists in table
function columnExists($pdo, $tableName, $columnName) {
    try {
        $stmt = $pdo->prepare("SHOW COLUMNS FROM `$tableName` LIKE ?");
        $stmt->execute([$columnName]);
        return $stmt->rowCount() > 0;
    } catch (PDOException $e) {
        return false;
    }
}

switch ($action) {
    case 'fetch_goals':
        if ($method === 'GET') {
            // Validate user_id for this specific action
            if (!$user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }
            
            try {
                if (!tableExists($pdo, 'member_goals')) {
                    echo json_encode([]);
                    break;
                }
                                
                $stmt = $pdo->prepare("SELECT
                    id,
                    user_id,
                    goal_type,
                    target_value,
                    current_value,
                    target_date,
                    status,
                    created_at,
                    updated_at
                FROM member_goals 
                WHERE user_id = ?
                ORDER BY created_at DESC");
                $stmt->execute([$user_id]);
                $goals = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                // Convert IDs to integers
                foreach ($goals as &$goal) {
                    $goal['id'] = (int)$goal['id'];
                }
                
                echo json_encode($goals);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in fetch_goals: " . $e->getMessage()]);
            }
        }
        break;

    case 'fetch_progress':
        if ($method === 'GET') {
            // Validate user_id for this specific action
            if (!$user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }
            
            try {
                if (!tableExists($pdo, 'progress_tracking')) {
                    echo json_encode([]);
                    break;
                }
                                
                $stmt = $pdo->prepare("SELECT
                    id,
                    user_id,
                    weight,
                    bmi,
                    chest_cm,
                    waist_cm,
                    hips_cm,
                    date_recorded
                FROM progress_tracking 
                WHERE user_id = ?
                ORDER BY date_recorded DESC");
                $stmt->execute([$user_id]);
                $progress = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                // Convert IDs to integers
                foreach ($progress as &$record) {
                    $record['id'] = (int)$record['id'];
                }
                
                echo json_encode($progress);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in fetch_progress: " . $e->getMessage()]);
            }
        }
        break;

    case 'fetch_attendance':
        if ($method === 'GET') {
            // Validate user_id for this specific action
            if (!$user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }
            
            try {
                if (!tableExists($pdo, 'attendance')) {
                    echo json_encode([]);
                    break;
                }
                                
                $stmt = $pdo->prepare("SELECT
                    id,
                    user_id,
                    check_in,
                    check_out,
                    CASE 
                        WHEN check_out IS NULL THEN 'checked_in'
                        ELSE 'checked_out'
                    END as status,
                    TIMESTAMPDIFF(MINUTE, check_in, COALESCE(check_out, NOW())) as duration_minutes
                FROM attendance 
                WHERE user_id = ?
                ORDER BY check_in DESC
                LIMIT 30");
                $stmt->execute([$user_id]);
                $attendance = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                // Convert IDs to integers
                foreach ($attendance as &$record) {
                    $record['id'] = (int)$record['id'];
                    $record['user_id'] = (int)$record['user_id'];
                    if ($record['duration_minutes'] !== null) {
                        $record['duration_minutes'] = (int)$record['duration_minutes'];
                    }
                }
                
                echo json_encode($attendance);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in fetch_attendance: " . $e->getMessage()]);
            }
        }
        break;

    case 'fetch_sessions':
        if ($method === 'GET') {
            // Validate user_id for this specific action
            if (!$user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required for fetch_sessions"]);
                exit();
            }
            
            try {
                // Check if required tables exist - try different possible table names
                $tableName = null;
                $possibleTables = ['member_programhdr', 'member_program_hdr', 'member_program_header'];
                foreach ($possibleTables as $table) {
                    if (tableExists($pdo, $table)) {
                        $tableName = $table;
                        break;
                    }
                }
                
                if (!$tableName) {
                    echo json_encode([]);
                    break;
                }

                // First, let's see what tables we have and their structure
                $tablesStmt = $pdo->query("SHOW TABLES");
                $tables = $tablesStmt->fetchAll(PDO::FETCH_COLUMN);
                                
                // Check if member_program_workout exists
                $hasWorkoutTable = in_array('member_program_workout', $tables);
                                
                if ($hasWorkoutTable) {
                    // Use the full join query - updated to match actual schema with proper workout type mapping
                    $stmt = $pdo->prepare("SELECT
                        mph.id,
                        mph.id AS member_program_hdr_id,
                        mph.created_at AS session_date,
                        COALESCE(mph.notes, '') AS notes,
                        CASE WHEN mph.completion_rate >= 100 THEN 1 ELSE 0 END AS completed,
                        COALESCE(JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.name')), CONCAT('Workout ', mph.id)) AS program_name,
                        COALESCE(mph.goal, 'General Fitness') AS program_goal,
                        COALESCE(JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.name')), CONCAT('Workout ', mph.id)) AS workout_title,
                        'Monday' AS scheduled_day,
                        CASE 
                            WHEN LOWER(COALESCE(mph.goal, 'General Fitness')) = 'muscle building' THEN 'Strength Training'
                            WHEN LOWER(COALESCE(mph.goal, 'General Fitness')) = 'strength' THEN 'Strength Training'
                            WHEN LOWER(COALESCE(mph.goal, 'General Fitness')) = 'fat loss' THEN 'Cardio & Strength'
                            WHEN LOWER(COALESCE(mph.goal, 'General Fitness')) = 'endurance' THEN 'Cardio Training'
                            WHEN LOWER(COALESCE(mph.goal, 'General Fitness')) = 'general fitness' THEN 'Full Body'
                            ELSE 'Workout'
                        END AS focus,
                        'Monday' AS next_workout_day
                    FROM `$tableName` mph
                    LEFT JOIN member_program_workout mpw ON mph.id = mpw.member_program_hdr_id
                    WHERE mph.user_id = ?
                    ORDER BY mph.created_at DESC");
                } else {
                    // Fallback query without the workout table - updated to match actual schema with proper workout type mapping
                    $stmt = $pdo->prepare("SELECT
                        mph.id,
                        mph.id AS member_program_hdr_id,
                        mph.created_at AS session_date,
                        COALESCE(mph.notes, '') AS notes,
                        CASE WHEN mph.completion_rate >= 100 THEN 1 ELSE 0 END AS completed,
                        CONCAT('Workout ', mph.id) AS program_name,
                        COALESCE(mph.goal, 'General Fitness') AS program_goal,
                        CONCAT('Workout ', mph.id) AS workout_title,
                        'Monday' AS scheduled_day,
                        CASE 
                            WHEN LOWER(COALESCE(mph.goal, 'General Fitness')) = 'muscle building' THEN 'Strength Training'
                            WHEN LOWER(COALESCE(mph.goal, 'General Fitness')) = 'strength' THEN 'Strength Training'
                            WHEN LOWER(COALESCE(mph.goal, 'General Fitness')) = 'fat loss' THEN 'Cardio & Strength'
                            WHEN LOWER(COALESCE(mph.goal, 'General Fitness')) = 'endurance' THEN 'Cardio Training'
                            WHEN LOWER(COALESCE(mph.goal, 'General Fitness')) = 'general fitness' THEN 'Full Body'
                            ELSE 'Workout'
                        END AS focus,
                        'Monday' AS next_workout_day
                    FROM `$tableName` mph
                    WHERE mph.user_id = ?
                    ORDER BY mph.created_at DESC");
                }
                                
                $stmt->execute([$user_id]);
                $sessions = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                // Convert IDs to integers
                foreach ($sessions as &$session) {
                    $session['id'] = (int)$session['id'];
                    $session['member_program_hdr_id'] = (int)$session['member_program_hdr_id'];
                    $session['completed'] = (int)$session['completed'];
                }
                                
                // Debug information
                error_log("User ID: " . $user_id);
                error_log("Tables found: " . implode(', ', $tables));
                error_log("Sessions found: " . count($sessions));
                                
                echo json_encode($sessions);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in fetch_sessions: " . $e->getMessage(), "sql_state" => $e->getCode()]);
            }
        }
        break;

    case 'create_session':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);
            
            // Debug: Log the received data
            error_log("create_session - Received data: " . json_encode($data));
            
            // Use user_id from POST data or fallback to GET parameter
            $session_user_id = $data['user_id'] ?? $user_id;
            
            if (!$session_user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }
            
            error_log("create_session - Using user_id: " . $session_user_id);
            
            try {
                // Check if required tables exist - try different possible table names
                $tableName = null;
                $possibleTables = ['member_programhdr', 'member_program_hdr', 'member_program_header'];
                
                error_log("create_session - Checking for tables: " . implode(', ', $possibleTables));
                
                foreach ($possibleTables as $table) {
                    if (tableExists($pdo, $table)) {
                        $tableName = $table;
                        error_log("create_session - Found table: " . $table);
                        break;
                    }
                }
                
                if (!$tableName) {
                    // Get all available tables for debugging
                    $tablesStmt = $pdo->query("SHOW TABLES");
                    $allTables = $tablesStmt->fetchAll(PDO::FETCH_COLUMN);
                    error_log("create_session - Available tables: " . implode(', ', $allTables));
                    echo json_encode(["error" => "No member program table found. Available tables: " . implode(', ', $allTables)]);
                    break;
                }

                // Start transaction
                $pdo->beginTransaction();
                                
                // Create a new member_programhdr entry for the scheduled workout
                // Based on the actual database schema, the table has these columns:
                // id, user_id, program_hdr_id, created_by, color, tags, goal, notes, 
                // completion_rate, scheduled_days, created_at, updated_at, difficulty, total_sessions
                
                $sql = "INSERT INTO `$tableName`
                    (user_id, program_hdr_id, created_by, goal, notes, completion_rate, difficulty, total_sessions)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
                
                error_log("create_session - SQL: " . $sql);
                
                $stmt = $pdo->prepare($sql);
                                
                // Fix date handling - use current date for weekly split, not the provided date
                $notes = $data['notes'] ?? 'Scheduled workout';
                $program_goal = $data['program_goal'] ?? 'General Fitness';
                $completion_rate = 0; // New scheduled workout
                $difficulty = 'Beginner'; // Default difficulty
                $total_sessions = 0; // New workout
                                
                // Use a default program_hdr_id of NULL (as per schema)
                $program_hdr_id = $data['member_program_hdr_id'] ?? null;
                $created_by = $session_user_id; // User creates their own workout
                
                $params = [
                    $session_user_id,
                    $program_hdr_id,
                    $created_by,
                    $program_goal,
                    $notes,
                    $completion_rate,
                    $difficulty,
                    $total_sessions
                ];
                
                error_log("create_session - Parameters: " . json_encode($params));
                                
                $stmt->execute($params);
                                
                $session_id = $pdo->lastInsertId();
                                
                // Only create workout entry if table exists
                if (tableExists($pdo, 'member_program_workout')) {
                    $workoutStmt = $pdo->prepare("INSERT INTO member_program_workout
                        (member_program_hdr_id, workout_details)
                        VALUES (?, ?)");
                                        
                    $workout_name = $data['program_name'] ?? 'Custom Workout';
                    $scheduled_day = $data['scheduled_day'] ?? 'Monday';
                    $focus = $data['focus'] ?? $workout_name;
                    $duration = $data['duration'] ?? '30';
                    
                    $workout_details = json_encode([
                        'name' => $workout_name,
                        'duration' => $duration,
                        'created_at' => date('Y-m-d H:i:s')
                    ]);
                                        
                    $workoutStmt->execute([
                        $session_id,
                        $workout_details
                    ]);
                }
                                
                // Commit transaction
                $pdo->commit();
                                
                echo json_encode(["success" => true, "id" => (int)$session_id]);
            } catch (PDOException $e) {
                // Rollback transaction on error
                $pdo->rollback();
                error_log("create_session - PDO Error: " . $e->getMessage());
                error_log("create_session - Error Code: " . $e->getCode());
                error_log("create_session - SQL State: " . $e->errorInfo[0]);
                http_response_code(500);
                echo json_encode([
                    "error" => "Database error in create_session: " . $e->getMessage(),
                    "code" => $e->getCode(),
                    "sql_state" => $e->errorInfo[0]
                ]);
            } catch (Exception $e) {
                // Rollback transaction on error
                $pdo->rollback();
                error_log("create_session - General Error: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(["error" => "General error in create_session: " . $e->getMessage()]);
            }
        }
        break;

    case 'debug_tables':
        if ($method === 'GET') {
            try {
                // Get all tables
                $tablesStmt = $pdo->query("SHOW TABLES");
                $tables = $tablesStmt->fetchAll(PDO::FETCH_COLUMN);
                                
                $tableInfo = [];
                foreach ($tables as $table) {
                    $columnsStmt = $pdo->query("DESCRIBE `$table`");
                    $columns = $columnsStmt->fetchAll(PDO::FETCH_ASSOC);
                    $tableInfo[$table] = $columns;
                }
                                
                echo json_encode([
                    "tables" => $tables,
                    "table_structures" => $tableInfo,
                    "user_id_received" => $user_id
                ]);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in debug_tables: " . $e->getMessage()]);
            }
        }
        break;

    case 'test_connection':
        if ($method === 'GET') {
            try {
                // Simple test to check database connection and basic table info
                $tablesStmt = $pdo->query("SHOW TABLES");
                $tables = $tablesStmt->fetchAll(PDO::FETCH_COLUMN);
                
                // Check for member program related tables
                $memberTables = array_filter($tables, function($table) {
                    return strpos(strtolower($table), 'member') !== false || 
                           strpos(strtolower($table), 'program') !== false;
                });
                
                echo json_encode([
                    "status" => "connected",
                    "all_tables" => $tables,
                    "member_program_tables" => array_values($memberTables),
                    "database" => $dbname
                ]);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode([
                    "status" => "error",
                    "error" => $e->getMessage(),
                    "database" => $dbname
                ]);
            }
        }
        break;

    // ... (rest of your existing cases remain the same)
    case 'fetch_program_details':
        if ($method === 'GET') {
            try {
                $program_hdr_id = $_GET['program_hdr_id'] ?? null;
                
                // Check if required tables exist - try different possible table names
                $tableName = null;
                $possibleTables = ['member_programhdr', 'member_program_hdr', 'member_program_header'];
                foreach ($possibleTables as $table) {
                    if (tableExists($pdo, $table)) {
                        $tableName = $table;
                        break;
                    }
                }
                
                if (!$tableName) {
                    echo json_encode(["error" => "No member program table found"]);
                    break;
                }
                                
                if (!tableExists($pdo, 'member_program_workout')) {
                    echo json_encode([]);
                    break;
                }
                                
                if ($program_hdr_id) {
                    // Fetch specific program details from member_program_workout
                    $stmt = $pdo->prepare("SELECT
                        mpw.id,
                        mpw.member_program_hdr_id as program_hdr_id,
                        JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.name')) as workout_name,
                        'Monday' as scheduled_day,
                        mph.goal as focus,
                        mph.user_id
                    FROM member_program_workout mpw
                    JOIN `$tableName` mph ON mpw.member_program_hdr_id = mph.id
                    WHERE mpw.member_program_hdr_id = ?
                    ORDER BY mpw.id");
                    $stmt->execute([$program_hdr_id]);
                } else {
                    // Fetch all program details
                    $stmt = $pdo->prepare("SELECT
                        mpw.id,
                        mpw.member_program_hdr_id as program_hdr_id,
                        JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.name')) as workout_name,
                        'Monday' as scheduled_day,
                        mph.goal as focus,
                        mph.user_id,
                        mph.goal as program_goal
                    FROM member_program_workout mpw
                    JOIN `$tableName` mph ON mpw.member_program_hdr_id = mph.id
                    ORDER BY mpw.id, mph.created_at");
                    $stmt->execute();
                }
                $details = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                // Convert IDs to integers
                foreach ($details as &$detail) {
                    $detail['id'] = (int)$detail['id'];
                    $detail['program_hdr_id'] = (int)$detail['program_hdr_id'];
                    $detail['user_id'] = (int)$detail['user_id'];
                }
                
                echo json_encode($details);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in fetch_program_details: " . $e->getMessage()]);
            }
        }
        break;

    case 'fetch_personal_records':
        if ($method === 'GET') {
            // Validate user_id for this specific action
            if (!$user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }
            
            try {
                if (!tableExists($pdo, 'personal_records') || !tableExists($pdo, 'exercise')) {
                    echo json_encode([]);
                    break;
                }
                                
                $stmt = $pdo->prepare("SELECT
                    pr.id,
                    pr.user_id,
                    pr.exercise_id,
                    pr.max_weight,
                    pr.achieved_on,
                    e.name as exercise_name,
                    e.description as exercise_description
                FROM personal_records pr
                JOIN exercise e ON pr.exercise_id = e.id
                WHERE pr.user_id = ?
                ORDER BY pr.achieved_on DESC");
                $stmt->execute([$user_id]);
                $records = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                // Convert IDs to integers
                foreach ($records as &$record) {
                    $record['id'] = (int)$record['id'];
                    $record['user_id'] = (int)$record['user_id'];
                    $record['exercise_id'] = (int)$record['exercise_id'];
                    $record['max_weight'] = (float)$record['max_weight'];
                }
                
                echo json_encode($records);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in fetch_personal_records: " . $e->getMessage()]);
            }
        }
        break;

    case 'fetch_exercises':
        if ($method === 'GET') {
            try {
                if (!tableExists($pdo, 'exercise')) {
                    echo json_encode([]);
                    break;
                }
                                
                $stmt = $pdo->prepare("SELECT
                    e.id,
                    e.name,
                    e.description,
                    e.image_url,
                    e.video_url,
                    GROUP_CONCAT(tm.name) as target_muscles
                FROM exercise e
                LEFT JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
                LEFT JOIN target_muscle tm ON etm.muscle_id = tm.id
                GROUP BY e.id
                ORDER BY e.name");
                $stmt->execute();
                $exercises = $stmt->fetchAll(PDO::FETCH_ASSOC);
                                
                // Process target_muscles into array and convert IDs
                foreach ($exercises as &$exercise) {
                    $exercise['id'] = (int)$exercise['id'];
                    $exercise['target_muscles'] = $exercise['target_muscles']
                        ? explode(',', $exercise['target_muscles'])
                        : [];
                }
                                
                echo json_encode($exercises);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in fetch_exercises: " . $e->getMessage()]);
            }
        }
        break;

    case 'create_goal':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);
            
            $goal_user_id = $data['user_id'] ?? $user_id;
            if (!$goal_user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }
            
            try {
                if (!tableExists($pdo, 'member_goals')) {
                    echo json_encode(["error" => "Table 'member_goals' does not exist"]);
                    break;
                }
                                
                $stmt = $pdo->prepare("INSERT INTO member_goals (user_id, goal_type, target_value, target_date) VALUES (?, ?, ?, ?)");
                $stmt->execute([
                    $goal_user_id,
                    $data['goal_type'] ?? 'general',
                    $data['target_value'] ?? '',
                    $data['target_date'] ?? null
                ]);
                echo json_encode(["success" => true, "id" => (int)$pdo->lastInsertId()]);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in create_goal: " . $e->getMessage()]);
            }
        }
        break;

    case 'update_goal_status':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);
            try {
                if (!tableExists($pdo, 'member_goals')) {
                    echo json_encode(["error" => "Table 'member_goals' does not exist"]);
                    break;
                }
                                
                $stmt = $pdo->prepare("UPDATE member_goals SET status = ?, updated_at = NOW() WHERE id = ?");
                $stmt->execute([
                    $data['status'],
                    $data['id']
                ]);
                echo json_encode(["success" => true]);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in update_goal_status: " . $e->getMessage()]);
            }
        }
        break;

    case 'create_progress':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);
            
            $progress_user_id = $data['user_id'] ?? $user_id;
            if (!$progress_user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }
            
            try {
                if (!tableExists($pdo, 'progress_tracking')) {
                    echo json_encode(["error" => "Table 'progress_tracking' does not exist"]);
                    break;
                }
                                
                $stmt = $pdo->prepare("INSERT INTO progress_tracking (user_id, weight, bmi, chest_cm, waist_cm, hips_cm, date_recorded) VALUES (?, ?, ?, ?, ?, ?, ?)");
                $stmt->execute([
                    $progress_user_id,
                    $data['weight'] ?? $data['weight_kg'] ?? null,
                    $data['bmi'] ?? null,
                    $data['chest_cm'] ?? null,
                    $data['waist_cm'] ?? null,
                    $data['hips_cm'] ?? null,
                    $data['date_recorded'] ?? date('Y-m-d')
                ]);
                echo json_encode(["success" => true, "id" => (int)$pdo->lastInsertId()]);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in create_progress: " . $e->getMessage()]);
            }
        }
        break;

    case 'create_personal_record':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);
            
            $record_user_id = $data['user_id'] ?? $user_id;
            if (!$record_user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }
            
            try {
                if (!tableExists($pdo, 'personal_records')) {
                    echo json_encode(["error" => "Table 'personal_records' does not exist"]);
                    break;
                }
                                
                // Check if record exists for this user and exercise
                $checkStmt = $pdo->prepare("SELECT id, max_weight FROM personal_records WHERE user_id = ? AND exercise_id = ?");
                $checkStmt->execute([$record_user_id, $data['exercise_id']]);
                $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);
                                
                if ($existing) {
                    // Update if new weight is higher
                    if ($data['max_weight'] > $existing['max_weight']) {
                        $stmt = $pdo->prepare("UPDATE personal_records SET max_weight = ?, achieved_on = ? WHERE id = ?");
                        $stmt->execute([
                            $data['max_weight'],
                            $data['achieved_on'] ?? date('Y-m-d'),
                            $existing['id']
                        ]);
                        echo json_encode(["success" => true, "updated" => true]);
                    } else {
                        echo json_encode(["success" => false, "message" => "Weight not higher than current PR"]);
                    }
                } else {
                    // Create new record
                    $stmt = $pdo->prepare("INSERT INTO personal_records (user_id, exercise_id, max_weight, achieved_on) VALUES (?, ?, ?, ?)");
                    $stmt->execute([
                        $record_user_id,
                        $data['exercise_id'],
                        $data['max_weight'],
                        $data['achieved_on'] ?? date('Y-m-d')
                    ]);
                    echo json_encode(["success" => true, "id" => (int)$pdo->lastInsertId()]);
                }
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in create_personal_record: " . $e->getMessage()]);
            }
        }
        break;

    case 'create_program_detail':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);
            try {
                if (!tableExists($pdo, 'member_program_workout')) {
                    echo json_encode(["error" => "Table 'member_program_workout' does not exist"]);
                    break;
                }
                                
                $workout_details = json_encode([
                    'name' => $data['workout_name'] ?? 'Custom Workout',
                    'duration' => $data['duration'] ?? '30',
                    'created_at' => date('Y-m-d H:i:s')
                ]);
                
                $stmt = $pdo->prepare("INSERT INTO member_program_workout (member_program_hdr_id, workout_details) VALUES (?, ?)");
                $stmt->execute([
                    $data['member_program_hdr_id'],
                    $workout_details
                ]);
                echo json_encode(["success" => true, "id" => $pdo->lastInsertId()]);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in create_program_detail: " . $e->getMessage()]);
            }
        }
        break;

    case 'check_in':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);
            
            $checkin_user_id = $data['user_id'] ?? $user_id;
            if (!$checkin_user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }
            
            try {
                if (!tableExists($pdo, 'attendance')) {
                    echo json_encode(["error" => "Table 'attendance' does not exist"]);
                    break;
                }
                                
                // Check if user already checked in today
                $checkStmt = $pdo->prepare("SELECT id FROM attendance WHERE user_id = ? AND DATE(check_in) = CURDATE() AND check_out IS NULL");
                $checkStmt->execute([$checkin_user_id]);
                                
                if ($checkStmt->rowCount() > 0) {
                    echo json_encode(["error" => "Already checked in today"]);
                } else {
                    $stmt = $pdo->prepare("INSERT INTO attendance (user_id, check_in) VALUES (?, NOW())");
                    $stmt->execute([$checkin_user_id]);
                    echo json_encode(["success" => true, "id" => (int)$pdo->lastInsertId()]);
                }
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in check_in: " . $e->getMessage()]);
            }
        }
        break;

    case 'check_out':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);
            
            $checkout_user_id = $data['user_id'] ?? $user_id;
            if (!$checkout_user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }
            
            try {
                if (!tableExists($pdo, 'attendance')) {
                    echo json_encode(["error" => "Table 'attendance' does not exist"]);
                    break;
                }
                                
                $stmt = $pdo->prepare("UPDATE attendance SET check_out = NOW() WHERE user_id = ? AND DATE(check_in) = CURDATE() AND check_out IS NULL");
                $stmt->execute([$checkout_user_id]);
                                
                if ($stmt->rowCount() > 0) {
                    echo json_encode(["success" => true]);
                } else {
                    echo json_encode(["error" => "No active check-in found for today"]);
                }
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error in check_out: " . $e->getMessage()]);
            }
        }
        break;

    // Add weekly stats endpoint
    case 'get_weekly_stats':
        if ($method === 'GET') {
            try {
                $userId = $_GET['user_id'] ?? '';
                
                if (empty($userId)) {
                    echo json_encode(['success' => false, 'error' => 'User ID is required']);
                    return;
                }
                
                // Get current week period
                $startOfWeek = date('Y-m-d', strtotime('monday this week'));
                $endOfWeek = date('Y-m-d', strtotime('sunday this week'));
                
                // Get workout sessions for this week
                $stmt = $pdo->prepare("
                    SELECT COUNT(*) as total_workouts, 
                           SUM(duration_minutes) as total_duration,
                           SUM(calories_burned) as total_calories
                    FROM workout_sessions 
                    WHERE user_id = ? AND DATE(session_date) BETWEEN ? AND ?
                ");
                $stmt->execute([$userId, $startOfWeek, $endOfWeek]);
                $workoutStats = $stmt->fetch(PDO::FETCH_ASSOC);
                
                // Get muscle groups worked this week
                $muscleStmt = $pdo->prepare("
                    SELECT DISTINCT tm.name as muscle_group
                    FROM workout_sessions ws
                    JOIN workout_exercises we ON ws.id = we.workout_session_id
                    JOIN exercise e ON we.exercise_id = e.id
                    JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
                    JOIN target_muscle tm ON etm.muscle_id = tm.id
                    WHERE ws.user_id = ? AND DATE(ws.session_date) BETWEEN ? AND ?
                ");
                $muscleStmt->execute([$userId, $startOfWeek, $endOfWeek]);
                $muscleGroups = $muscleStmt->fetchAll(PDO::FETCH_ASSOC);
                
                echo json_encode([
                    'success' => true,
                    'data' => [
                        'week_period' => [
                            'start' => $startOfWeek,
                            'end' => $endOfWeek
                        ],
                        'total_workouts' => (int)$workoutStats['total_workouts'],
                        'total_duration' => (int)$workoutStats['total_duration'],
                        'total_calories' => (int)$workoutStats['total_calories'],
                        'muscle_groups' => array_column($muscleGroups, 'muscle_group')
                    ]
                ]);
                
            } catch(PDOException $e) {
                echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
            }
        }
        break;

    default:
        http_response_code(400);
        echo json_encode(["error" => "Invalid action: $action"]);
        break;
}
?>
