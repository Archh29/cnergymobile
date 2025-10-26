<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, DELETE");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$host = "localhost";
$db_name = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db_name;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $username, $password, $options);
} catch (PDOException $e) {
    echo json_encode(["error" => "Connection failed: " . $e->getMessage()]);
    exit;
}

$input = json_decode(file_get_contents("php://input"), true);
$action = $_GET['action'] ?? $input['action'] ?? '';

function respond($data)
{
    echo json_encode($data);
    exit;
}

function validateUserId($userId)
{
    if (!$userId || !is_numeric($userId) || $userId <= 0) {
        respond(["error" => "Invalid or missing user ID"]);
    }
    return intval($userId);
}

// Enhanced membership status check function - HARDCODED for ID 1 only
function checkMembershipStatus($pdo, $userId)
{
    try {
        error_log("=== CHECKING MEMBERSHIP STATUS FOR USER $userId ===");
        error_log("Checking membership status for user ID: " . $userId);

        // Get ALL active subscriptions for this user
        $stmt = $pdo->prepare("SELECT s.id AS subscription_id, s.plan_id, s.start_date, s.end_date, ss.status_name, msp.plan_name, msp.price FROM subscription s LEFT JOIN subscription_status ss ON s.status_id = ss.id LEFT JOIN member_subscription_plan msp ON s.plan_id = msp.id WHERE s.user_id = :user_id AND s.end_date >= CURDATE() AND ss.status_name = 'approved' ORDER BY s.end_date DESC, s.id DESC");

        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->execute();

        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // DEBUG: Log all results from database
        error_log("DEBUG: Database returned " . count($results) . " subscriptions for user $userId");
        foreach ($results as $result) {
            error_log("DEBUG: Subscription - ID: {$result['subscription_id']}, Plan ID: {$result['plan_id']}, Plan Name: {$result['plan_name']}, Status: {$result['status_name']}, End Date: {$result['end_date']}");
        }

        if ($results) {
            // HARDCODED: Check if user has subscription ID 1 (Member Fee)
            $hasMemberFee = false;
            $latestSubscription = null;

            foreach ($results as $result) {
                error_log("DEBUG: Checking subscription - Plan ID: {$result['plan_id']}, Is Plan 1: " . ((int) $result['plan_id'] === 1 ? 'YES' : 'NO'));
                if ((int) $result['plan_id'] === 1) {
                    $hasMemberFee = true;
                    $latestSubscription = $result;
                    error_log("DEBUG: Found Plan ID 1 subscription - setting hasMemberFee = true");
                    break;
                }
                // Keep track of the latest subscription for details
                if ($latestSubscription === null) {
                    $latestSubscription = $result;
                }
            }

            // HARDCODED: ONLY subscription ID 1 gives premium access
            // All other plans (2, 3, 4, etc.) are BASIC
            $isPremium = false; // Default to BASIC

            // CRITICAL FIX: Only set premium if we actually found Plan ID 1
            if ($hasMemberFee) {
                $isPremium = true; // ONLY Plan ID 1 gets premium
                error_log("DEBUG: Setting isPremium = true because hasMemberFee = true");
            } else {
                $isPremium = false; // All other plans are BASIC
                error_log("DEBUG: Setting isPremium = false because hasMemberFee = false");
            }

            error_log("User $userId has " . count($results) . " active subscriptions");
            error_log("User $userId has Member Fee (ID 1): " . ($hasMemberFee ? 'YES' : 'NO'));
            error_log("User $userId membership status: " . ($isPremium ? 'PREMIUM' : 'BASIC'));

            $returnData = [
                'is_premium' => $isPremium,
                'subscription_details' => [
                    'subscription_id' => $latestSubscription['subscription_id'],
                    'plan_id' => $latestSubscription['plan_id'],
                    'plan_name' => $latestSubscription['plan_name'],
                    'status' => $latestSubscription['status_name'],
                    'start_date' => $latestSubscription['start_date'],
                    'end_date' => $latestSubscription['end_date'],
                    'price' => $latestSubscription['price']
                ],
                'debug_info' => [
                    'has_plan_1' => $hasMemberFee ? 'YES' : 'NO',
                    'total_subscriptions' => count($results),
                    'latest_plan_id' => $latestSubscription['plan_id'],
                    'is_premium_result' => $isPremium ? 'TRUE' : 'FALSE',
                    'logic_explanation' => $isPremium ? 'User has Plan ID 1 (Member Fee)' : 'User does NOT have Plan ID 1 (Member Fee)'
                ]
            ];

            error_log("DEBUG: Returning data - is_premium: " . ($isPremium ? 'true' : 'false') . ", plan_id: {$latestSubscription['plan_id']}, plan_name: {$latestSubscription['plan_name']}");

            return $returnData;
        } else {
            error_log("User $userId has no active subscriptions - defaulting to BASIC");
            return [
                'is_premium' => false,
                'subscription_details' => null
            ];
        }
    } catch (PDOException $e) {
        error_log("Error checking membership status: " . $e->getMessage());
        return [
            'is_premium' => false,
            'subscription_details' => null,
            'error' => $e->getMessage()
        ];
    }
}

switch ($action) {
    case 'checkMembership':
        try {
            $userId = $_GET['user_id'] ?? $input['user_id'] ?? null;
            $userId = validateUserId($userId);

            $membershipData = checkMembershipStatus($pdo, $userId);

            respond([
                'success' => true,
                'user_id' => $userId,
                'is_premium' => $membershipData['is_premium'],
                'subscription_details' => $membershipData['subscription_details'],
                'checked_at' => date('Y-m-d H:i:s')
            ]);

        } catch (Exception $e) {
            error_log("Error in checkMembership: " . $e->getMessage());
            respond([
                'success' => false,
                'error' => $e->getMessage(),
                'is_premium' => false
            ]);
        }
        break;

    case 'fetch':
        try {
            $userId = $_GET['user_id'] ?? null;
            $userId = validateUserId($userId);

            error_log("Fetching routines for user ID: " . $userId);
            // ALWAYS check membership status first
            $membershipData = checkMembershipStatus($pdo, $userId);
            $isPremium = $membershipData['is_premium'];

            error_log("User $userId is " . ($isPremium ? 'PREMIUM' : 'BASIC') . " - fetching routines accordingly");

            // Get ALL routines for this user (user-created, coach-created, admin-created)
            $stmt = $pdo->prepare("SELECT m.id, m.user_id, m.program_hdr_id, m.created_by, CONCAT(u.fname, ' ', u.mname, ' ', u.lname) AS createdByName, u.user_type_id AS createdByTypeId, m.color, m.tags, m.goal, m.notes, m.completion_rate AS completionRate, m.scheduled_days AS scheduledDays, m.difficulty, m.total_sessions AS totalSessions, m.created_at, m.updated_at FROM member_programhdr m LEFT JOIN user u ON u.id = m.created_by WHERE m.user_id = :user_id ORDER BY m.created_at DESC");
            $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $stmt->execute();
            $allRoutines = $stmt->fetchAll(PDO::FETCH_ASSOC);

            error_log("Found " . count($allRoutines) . " total routines for user " . $userId);

            // Debug: Log each routine found
            foreach ($allRoutines as $routine) {
                error_log("DEBUG: Routine ID {$routine['id']} - user_id: {$routine['user_id']}, created_by: " . ($routine['created_by'] ?? 'NULL') . ", createdByTypeId: " . ($routine['createdByTypeId'] ?? 'NULL'));
            }

            // Process and categorize all routines
            $myRoutines = [];
            $coachAssigned = [];
            $templateRoutines = [];

            foreach ($allRoutines as &$routine) {
                $routine['tags'] = json_decode($routine['tags'] ?? '[]', true);
                $routine['scheduledDays'] = json_decode($routine['scheduledDays'] ?? '[]', true);
                $routine['lastPerformed'] = $routine['updated_at'] ?? 'Never';
                $routine['exerciseList'] = ''; // Will be populated below
                $routine['version'] = 1.0;
                $routine['createdBy'] = $routine['createdByName'] ?? 'Unknown';
                $routine['createdById'] = intval($routine['created_by'] ?? 0);
                $routine['createdByTypeId'] = intval($routine['createdByTypeId'] ?? 0);

                // Get workout details and exercise count
                $workoutStmt = $pdo->prepare("SELECT mpw.workout_details, COUNT(mwe.id) as exercise_count FROM member_program_workout mpw LEFT JOIN member_workout_exercise mwe ON mpw.id = mwe.member_program_workout_id WHERE mpw.member_program_hdr_id = :routine_id GROUP BY mpw.id ORDER BY mpw.id DESC LIMIT 1");
                $workoutStmt->bindParam(':routine_id', $routine['id'], PDO::PARAM_INT);
                $workoutStmt->execute();
                $workoutData = $workoutStmt->fetch(PDO::FETCH_ASSOC);

                if ($workoutData && !empty($workoutData['workout_details'])) {
                    // Set exercise count
                    $routine['exercises'] = (int) $workoutData['exercise_count'];

                    // Get routine name from workout_details with better error handling
                    $workoutDetails = json_decode($workoutData['workout_details'], true);
                    error_log("DEBUG: Main Fetch Routine ID {$routine['id']} - workout_details: " . $workoutData['workout_details']);
                    error_log("DEBUG: Main Fetch Routine ID {$routine['id']} - parsed workout_details: " . print_r($workoutDetails, true));

                    if ($workoutDetails && isset($workoutDetails['name']) && !empty($workoutDetails['name'])) {
                        $routine['name'] = $workoutDetails['name'];
                        $routine['duration'] = $workoutDetails['duration'] ?? '30-45 min';
                        error_log("DEBUG: Main Fetch Routine ID {$routine['id']} - using name from workout_details: " . $workoutDetails['name']);
                    } else {
                        // Fallback: use goal field from member_programhdr if available
                        $routine['name'] = !empty($routine['goal']) ? $routine['goal'] : 'Routine #' . $routine['id'];
                        $routine['duration'] = '30-45 min';
                        error_log("DEBUG: Main Fetch Routine ID {$routine['id']} - using fallback name: " . $routine['name']);
                    }

                    // Get exercise names for exercise list
                    if ($routine['exercises'] > 0) {
                        $exerciseListStmt = $pdo->prepare("SELECT e.name FROM member_workout_exercise mwe JOIN exercise e ON mwe.exercise_id = e.id JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id WHERE mpw.member_program_hdr_id = :routine_id ORDER BY mwe.id LIMIT 3");
                        $exerciseListStmt->bindParam(':routine_id', $routine['id'], PDO::PARAM_INT);
                        $exerciseListStmt->execute();
                        $exercises = $exerciseListStmt->fetchAll(PDO::FETCH_COLUMN);

                        if (!empty($exercises)) {
                            $routine['exerciseList'] = implode(', ', $exercises);
                            if ($routine['exercises'] > 3) {
                                $routine['exerciseList'] .= '...';
                            }
                        }
                    }
                } else {
                    // No workout found, set defaults
                    $routine['exercises'] = 0;
                    $routine['name'] = 'Routine #' . $routine['id'];
                    $routine['duration'] = '30-45 min';
                    $routine['exerciseList'] = 'No exercises added';
                }

                // Categorize by creator - SEPARATE LOGIC FOR EACH TYPE
                $category = 'self';
                if ($routine['created_by'] === null || $routine['created_by'] === '') {
                    // User-created routine (created_by is NULL)
                    $category = 'self';
                } elseif (intval($routine['createdByTypeId']) === 3) { // coach
                    $category = 'coach';
                } elseif (intval($routine['createdByTypeId']) === 1) { // admin
                    $category = 'admin';
                }
                $routine['category'] = $category;

                error_log("DEBUG: Categorizing routine ID {$routine['id']} - category: $category, created_by: " . ($routine['created_by'] ?? 'NULL') . ", userId: $userId");

                if ($category === 'self') {
                    $myRoutines[] = $routine;
                    error_log("DEBUG: Added routine ID {$routine['id']} to myRoutines");
                } elseif ($category === 'coach') {
                    $coachAssigned[] = $routine;
                    error_log("DEBUG: Added routine ID {$routine['id']} to coachAssigned");
                } elseif ($category === 'admin') {
                    $templateRoutines[] = $routine;
                    error_log("DEBUG: Added routine ID {$routine['id']} to templateRoutines");
                }

                unset($routine['createdByName']);
            }

            error_log("DEBUG: Before membership restriction - myRoutines: " . count($myRoutines) . ", coachAssigned: " . count($coachAssigned) . ", templateRoutines: " . count($templateRoutines));

            // Fetch admin-created programs from programs table for EXPLORE tab
            try {
                error_log("Fetching admin programs from programs/programhdr tables for EXPLORE tab");
                
                // First, check if programhdr table exists
                $tableCheckStmt = $pdo->prepare("SHOW TABLES LIKE 'programhdr'");
                $tableCheckStmt->execute();
                $tableExists = $tableCheckStmt->fetch();
                
                $adminPrograms = [];
                
                // First check if programs table exists (this is where admin creates free programs)
                $programsTableCheck = $pdo->prepare("SHOW TABLES LIKE 'programs'");
                $programsTableCheck->execute();
                $programsTableExists = $programsTableCheck->fetch();
                
                if ($programsTableExists) {
                    error_log("programs table exists - checking for admin-created programs");
                    
                    // Check how many programs exist
                    $programsCountStmt = $pdo->prepare("SELECT COUNT(*) as count FROM programs");
                    $programsCountStmt->execute();
                    $programsCount = $programsCountStmt->fetch(PDO::FETCH_ASSOC)['count'];
                    error_log("Found $programsCount total programs in programs table");
                    
                    // Get ALL programs from programhdr table - NO FILTER
                    $adminStmt = $pdo->prepare("
                        SELECT 
                            ph.id as id,
                            ph.name,
                            ph.header_name,
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
                            COUNT(pwe.id) as exercise_count,
                            COALESCE(u.user_type_id, 1) AS createdByTypeId,
                            p.id as program_id
                        FROM programhdr ph
                        LEFT JOIN programs p ON ph.program_id = p.id
                        LEFT JOIN program_workout pw ON ph.id = pw.program_hdr_id
                        LEFT JOIN program_workout_exercise pwe ON pw.id = pwe.program_workout_id
                        LEFT JOIN user u ON ph.created_by = u.id
                        WHERE ph.is_active = 1
                        GROUP BY ph.id
                        ORDER BY ph.created_at DESC
                    ");
                    $adminStmt->execute();
                    $adminPrograms = $adminStmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    error_log("Found " . count($adminPrograms) . " programs from programhdr table (ALL programs for explore)");
                }
                
                // Process each admin program
                if (count($adminPrograms) > 0) {
                foreach ($adminPrograms as &$adminProgram) {
                    $adminProgram['tags'] = json_decode($adminProgram['tags'] ?? '[]', true);
                    $adminProgram['exerciseList'] = '';
                    $adminProgram['version'] = 1.0;
                    $adminProgram['createdByTypeId'] = intval($adminProgram['createdByTypeId'] ?? 1);
                    $adminProgram['category'] = 'admin';
                    $adminProgram['user_id'] = null; // Admin programs don't belong to any specific user
                    $adminProgram['createdBy'] = ''; // Empty for admin programs to prevent session status widget
                    $adminProgram['createdById'] = 0; // Set to 0 for Explore programs (admin templates)
                    $adminProgram['completionRate'] = 0;
                    $adminProgram['totalSessions'] = 0;
                    $adminProgram['lastPerformed'] = 'Never';
                    $adminProgram['scheduledDays'] = [];
                    $adminProgram['notes'] = $adminProgram['notes'] ?? '';
                    $adminProgram['difficulty'] = $adminProgram['difficulty'] ?? 'Beginner';
                    $adminProgram['color'] = $adminProgram['color'] ?? '0xFF96CEB4';
                    
                    // Get workout details
                    if ($adminProgram['workout_details']) {
                        $workoutDetails = json_decode($adminProgram['workout_details'], true);
                        $adminProgram['name'] = $workoutDetails['name'] ?? $adminProgram['name'] ?? 'Program #' . $adminProgram['id'];
                        $adminProgram['duration'] = $workoutDetails['duration'] ?? ($adminProgram['duration'] ?? '30-45 min');
                    } else {
                        $adminProgram['name'] = $adminProgram['name'] ?? 'Program #' . $adminProgram['id'];
                        $adminProgram['duration'] = $adminProgram['duration'] ?? '30-45 min';
                    }
                    
                    // Get exercise names for exercise list
                    if ($adminProgram['exercise_count'] > 0) {
                        $exerciseListStmt = $pdo->prepare("
                            SELECT e.name 
                            FROM program_workout_exercise pwe 
                            JOIN exercise e ON pwe.exercise_id = e.id 
                            JOIN program_workout pw ON pwe.program_workout_id = pw.id 
                            WHERE pw.program_hdr_id = :program_hdr_id 
                            ORDER BY pwe.id LIMIT 3
                        ");
                        $exerciseListStmt->bindParam(':program_hdr_id', $adminProgram['id'], PDO::PARAM_INT);
                        $exerciseListStmt->execute();
                        $exercises = $exerciseListStmt->fetchAll(PDO::FETCH_COLUMN);
                        
                        if (!empty($exercises)) {
                            $adminProgram['exerciseList'] = implode(', ', $exercises);
                            if ($adminProgram['exercise_count'] > 3) {
                                $adminProgram['exerciseList'] .= '...';
                            }
                        }
                    }
                    
                    // Set exercise count
                    $adminProgram['exercises'] = (int)$adminProgram['exercise_count'];
                    
                    // Add to templateRoutines
                    $templateRoutines[] = $adminProgram;
                    error_log("Added admin program ID {$adminProgram['id']} to templateRoutines");
                }
                } else {
                    error_log("No admin programs found to process");
                }
            } catch (Exception $e) {
                error_log("Error fetching admin programs: " . $e->getMessage());
                error_log("Stack trace: " . $e->getTraceAsString());
            }

            error_log("DEBUG: After fetching admin programs - templateRoutines: " . count($templateRoutines));
            
            // Log details of templateRoutines
            foreach ($templateRoutines as $idx => $tr) {
                error_log("Template Routine #{$idx}: ID={$tr['id']}, Name={$tr['name']}, Exercises={$tr['exercises']}, category={$tr['category']}");
            }

            // Apply membership restriction ONLY to user's own routines
            if (!$isPremium && count($myRoutines) > 1) {
                $myRoutines = array_slice($myRoutines, 0, 1);
                error_log("Limited My Routines to 1 for basic user; coach/template remain unrestricted");
            }

            error_log("DEBUG: After membership restriction - myRoutines: " . count($myRoutines) . ", coachAssigned: " . count($coachAssigned) . ", templateRoutines: " . count($templateRoutines));
            
            // Final response summary
            error_log("=== FINAL RESPONSE SUMMARY ===");
            error_log("myRoutines: " . count($myRoutines));
            error_log("coachAssigned: " . count($coachAssigned));
            error_log("templateRoutines: " . count($templateRoutines));
            error_log("Total template routines being sent to frontend: " . count($templateRoutines));

            // For backward compatibility, set combined routines to just myRoutines
            $routines = $myRoutines;

            // IMPORTANT: Returns all routines with proper categorization
            respond([
                'success' => true,
                'routines' => $routines,
                'my_routines' => $myRoutines,
                'coach_assigned' => $coachAssigned,
                'template_routines' => $templateRoutines,
                'total_routines' => count($allRoutines),
                'is_premium' => $isPremium,
                'membership_status' => [
                    'is_premium' => $isPremium,
                    'subscription_details' => $membershipData['subscription_details']
                ],
                'debug_info' => $membershipData['debug_info'] ?? null,
                'user_id' => $userId,
                'fetched_at' => date('Y-m-d H:i:s')
            ]);

        } catch (PDOException $e) {
            error_log("Database error in fetch: " . $e->getMessage());
            respond([
                "error" => "Database error: " . $e->getMessage(),
                "is_premium" => false
            ]);
        }
        break;

    case 'user_routines':
        try {
            $userId = $_GET['user_id'] ?? null;
            $userId = validateUserId($userId);

            error_log("Fetching USER-ONLY routines for user ID: " . $userId);
            // ALWAYS check membership status first
            $membershipData = checkMembershipStatus($pdo, $userId);
            $isPremium = $membershipData['is_premium'];

            error_log("User $userId is " . ($isPremium ? 'PREMIUM' : 'BASIC') . " - fetching USER routines only");

            // Get ALL routines belonging to this user (both user-created AND cloned)
            // Filter: only routines where user_id matches (regardless of created_by)
            $stmt = $pdo->prepare("SELECT m.id, m.user_id, m.program_hdr_id, m.created_by, CONCAT(u.fname, ' ', u.mname, ' ', u.lname) AS createdByName, u.user_type_id AS createdByTypeId, m.color, m.tags, m.goal, m.notes, m.completion_rate AS completionRate, m.scheduled_days AS scheduledDays, m.difficulty, m.total_sessions AS totalSessions, m.created_at, m.updated_at FROM member_programhdr m LEFT JOIN user u ON u.id = m.created_by WHERE m.user_id = :user_id ORDER BY m.created_at DESC");
            $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $stmt->execute();
            $userRoutines = $stmt->fetchAll(PDO::FETCH_ASSOC);

            error_log("Found " . count($userRoutines) . " user-created routines for user " . $userId);

            // Process user-created routines only (NO coach logic)
            $processedRoutines = [];

            foreach ($userRoutines as &$routine) {
                $routine['tags'] = json_decode($routine['tags'] ?? '[]', true);
                $routine['scheduledDays'] = json_decode($routine['scheduledDays'] ?? '[]', true);
                $routine['lastPerformed'] = $routine['updated_at'] ?? 'Never';
                $routine['exerciseList'] = ''; // Will be populated below
                $routine['version'] = 1.0;
                $routine['createdBy'] = 'Self'; // User-created routines
                $routine['createdById'] = 0; // No creator ID for user-created
                $routine['createdByTypeId'] = 0; // No creator type for user-created
                $routine['category'] = 'self'; // All routines here are user-created

                // Get workout details and exercise count
                $workoutStmt = $pdo->prepare("SELECT mpw.workout_details, COUNT(mwe.id) as exercise_count FROM member_program_workout mpw LEFT JOIN member_workout_exercise mwe ON mpw.id = mwe.member_program_workout_id WHERE mpw.member_program_hdr_id = :routine_id GROUP BY mpw.id ORDER BY mpw.id DESC LIMIT 1");
                $workoutStmt->bindParam(':routine_id', $routine['id'], PDO::PARAM_INT);
                $workoutStmt->execute();
                $workoutData = $workoutStmt->fetch(PDO::FETCH_ASSOC);

                if ($workoutData && !empty($workoutData['workout_details'])) {
                    // Set exercise count
                    $routine['exercises'] = (int) $workoutData['exercise_count'];

                    // Get routine name from workout_details with better error handling
                    $workoutDetails = json_decode($workoutData['workout_details'], true);
                    error_log("DEBUG: User Routine ID {$routine['id']} - workout_details: " . $workoutData['workout_details']);
                    error_log("DEBUG: User Routine ID {$routine['id']} - parsed workout_details: " . print_r($workoutDetails, true));

                    if ($workoutDetails && isset($workoutDetails['name']) && !empty($workoutDetails['name'])) {
                        $routine['name'] = $workoutDetails['name'];
                        $routine['duration'] = $workoutDetails['duration'] ?? '30-45 min';
                        error_log("DEBUG: User Routine ID {$routine['id']} - using name from workout_details: " . $workoutDetails['name']);
                    } else {
                        // Fallback: use goal field from member_programhdr if available
                        $routine['name'] = !empty($routine['goal']) ? $routine['goal'] : 'Routine #' . $routine['id'];
                        $routine['duration'] = '30-45 min';
                        error_log("DEBUG: User Routine ID {$routine['id']} - using fallback name: " . $routine['name']);
                    }

                    // Get exercise names for exercise list
                    if ($routine['exercises'] > 0) {
                        $exerciseListStmt = $pdo->prepare("SELECT e.name FROM member_workout_exercise mwe JOIN exercise e ON mwe.exercise_id = e.id JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id WHERE mpw.member_program_hdr_id = :routine_id ORDER BY mwe.id LIMIT 3");
                        $exerciseListStmt->bindParam(':routine_id', $routine['id'], PDO::PARAM_INT);
                        $exerciseListStmt->execute();
                        $exercises = $exerciseListStmt->fetchAll(PDO::FETCH_COLUMN);

                        if (!empty($exercises)) {
                            $routine['exerciseList'] = implode(', ', $exercises);
                            if ($routine['exercises'] > 3) {
                                $routine['exerciseList'] .= '...';
                            }
                        }
                    }
                } else {
                    // No workout found, set defaults
                    $routine['exercises'] = 0;
                    $routine['name'] = 'Routine #' . $routine['id'];
                    $routine['duration'] = '30-45 min';
                    $routine['exerciseList'] = 'No exercises added';
                }

                $processedRoutines[] = $routine;
                error_log("DEBUG: Added user-created routine ID {$routine['id']} to processedRoutines");

                unset($routine['createdByName']);
            }

            // Apply membership restriction
            if (!$isPremium && count($processedRoutines) > 1) {
                $processedRoutines = array_slice($processedRoutines, 0, 1);
                error_log("Limited user routines to 1 for basic user");
            }

            // Fetch ALL programs from programhdr table for EXPLORE tab
            $templateRoutines = [];
            try {
                error_log("Fetching programs for explore tab from programhdr table");
                
                // Simple check first
                $simpleStmt = $pdo->prepare("SELECT id, name, header_name, is_active FROM programhdr WHERE is_active = 1 LIMIT 10");
                $simpleStmt->execute();
                $simplePrograms = $simpleStmt->fetchAll(PDO::FETCH_ASSOC);
                error_log("DEBUG: Found " . count($simplePrograms) . " programs in programhdr: " . json_encode($simplePrograms));
                
                // Get ALL programs from programhdr table
                // Exclude test programs by filtering out common test names
                $adminStmt = $pdo->prepare("
                    SELECT 
                        ph.id as id,
                        ph.name,
                        ph.header_name,
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
                        COUNT(pwe.id) as exercise_count,
                        COALESCE(u.user_type_id, 1) AS createdByTypeId,
                        p.id as program_id
                    FROM programhdr ph
                    LEFT JOIN programs p ON ph.program_id = p.id
                    LEFT JOIN program_workout pw ON ph.id = pw.program_hdr_id
                    LEFT JOIN program_workout_exercise pwe ON pw.id = pwe.program_workout_id
                    LEFT JOIN user u ON ph.created_by = u.id
                    WHERE ph.is_active = 1
                    AND (COALESCE(ph.name, '') NOT LIKE '%Test%' 
                         AND COALESCE(ph.name, '') NOT LIKE '%Template%'
                         AND COALESCE(ph.header_name, '') NOT LIKE '%Test%'
                         AND COALESCE(ph.header_name, '') NOT LIKE '%Template%')
                    GROUP BY ph.id
                    ORDER BY ph.created_at DESC
                ");
                $adminStmt->execute();
                $adminPrograms = $adminStmt->fetchAll(PDO::FETCH_ASSOC);
                error_log("DEBUG: Query returned " . count($adminPrograms) . " programs from programhdr (after filtering test programs)");
                
                // Process admin programs
                foreach ($adminPrograms as &$adminProgram) {
                    $adminProgram['tags'] = json_decode($adminProgram['tags'] ?? '[]', true);
                    $adminProgram['exerciseList'] = '';
                    $adminProgram['version'] = 1.0;
                    $adminProgram['createdByTypeId'] = intval($adminProgram['createdByTypeId'] ?? 1);
                    $adminProgram['category'] = 'admin';
                    $adminProgram['user_id'] = null;
                    $adminProgram['createdBy'] = '';
                    $adminProgram['createdById'] = 0; // Set to 0 for Explore programs (admin templates)
                    $adminProgram['completionRate'] = 0;
                    $adminProgram['totalSessions'] = 0;
                    $adminProgram['lastPerformed'] = 'Never';
                    $adminProgram['scheduledDays'] = [];
                    $adminProgram['notes'] = $adminProgram['notes'] ?? '';
                    $adminProgram['difficulty'] = $adminProgram['difficulty'] ?? 'Beginner';
                    $adminProgram['color'] = $adminProgram['color'] ?? '0xFF96CEB4';
                    
                    // Use header_name if available, otherwise use name
                    $programName = !empty($adminProgram['header_name']) ? $adminProgram['header_name'] : $adminProgram['name'];
                    
                    // Get workout details
                    if ($adminProgram['workout_details']) {
                        $workoutDetails = json_decode($adminProgram['workout_details'], true);
                        $adminProgram['name'] = $workoutDetails['name'] ?? $programName ?? 'Program #' . $adminProgram['id'];
                        $adminProgram['duration'] = $workoutDetails['duration'] ?? ($adminProgram['duration'] ?? '30-45 min');
                    } else {
                        $adminProgram['name'] = $programName ?? 'Program #' . $adminProgram['id'];
                        $adminProgram['duration'] = $adminProgram['duration'] ?? '30-45 min';
                    }
                    
                    // Get exercise names for exercise list
                    if ($adminProgram['exercise_count'] > 0) {
                        $exerciseListStmt = $pdo->prepare("
                            SELECT e.name 
                            FROM program_workout_exercise pwe 
                            JOIN exercise e ON pwe.exercise_id = e.id 
                            JOIN program_workout pw ON pwe.program_workout_id = pw.id 
                            WHERE pw.program_hdr_id = :program_hdr_id 
                            ORDER BY pwe.id LIMIT 3
                        ");
                        $exerciseListStmt->bindParam(':program_hdr_id', $adminProgram['id'], PDO::PARAM_INT);
                        $exerciseListStmt->execute();
                        $exercises = $exerciseListStmt->fetchAll(PDO::FETCH_COLUMN);
                        
                        if (!empty($exercises)) {
                            $adminProgram['exerciseList'] = implode(', ', $exercises);
                            if ($adminProgram['exercise_count'] > 3) {
                                $adminProgram['exerciseList'] .= '...';
                            }
                        }
                    }
                    
                    // Set exercise count
                    $adminProgram['exercises'] = (int)$adminProgram['exercise_count'];
                    
                    // Add to templateRoutines
                    $templateRoutines[] = $adminProgram;
                }
                error_log("Added " . count($templateRoutines) . " admin programs to template_routines");
            } catch (Exception $e) {
                error_log("Error fetching admin programs in user_routines: " . $e->getMessage());
            }
            
            // IMPORTANT: This endpoint returns user-created routines AND admin programs
            respond([
                'success' => true,
                'routines' => $processedRoutines,
                'my_routines' => $processedRoutines,
                'coach_assigned' => [], // Empty - coach routines handled separately
                'template_routines' => $templateRoutines, // Now includes admin programs
                'total_routines' => count($processedRoutines),
                'is_premium' => $isPremium,
                'membership_status' => [
                    'is_premium' => $isPremium,
                    'subscription_details' => $membershipData['subscription_details']
                ],
                'debug_info' => $membershipData['debug_info'] ?? null,
                'user_id' => $userId,
                'fetched_at' => date('Y-m-d H:i:s'),
                'note' => 'Returns user-created routines and admin programs for explore tab.'
            ]);

        } catch (PDOException $e) {
            error_log("Database error in user_routines: " . $e->getMessage());
            respond([
                "error" => "Database error: " . $e->getMessage(),
                "is_premium" => false
            ]);
        }
        break;

    case 'coach_routines':
        try {
            $userId = $_GET['user_id'] ?? null;
            $userId = validateUserId($userId);

            error_log("Fetching COACH-ONLY routines for user ID: " . $userId);

            // Get coach-created routines with coach connection validation using new status field
            $stmt = $pdo->prepare("
                SELECT 
                    m.id, m.user_id, m.program_hdr_id, m.created_by, 
                    CONCAT(u.fname, ' ', u.mname, ' ', u.lname) AS createdByName, 
                    u.user_type_id AS createdByTypeId, 
                    m.color, m.tags, m.goal, m.notes, 
                    m.completion_rate AS completionRate, 
                    m.scheduled_days AS scheduledDays, 
                    m.difficulty, m.total_sessions AS totalSessions, 
                    m.created_at, m.updated_at,
                    cml.status,
                    cml.coach_approval,
                    cml.staff_approval,
                    cml.expires_at,
                    cml.remaining_sessions,
                    cml.rate_type,
                    c.session_package_rate,
                    c.session_package_count,
                    c.monthly_rate
                FROM member_programhdr m 
                LEFT JOIN user u ON u.id = m.created_by 
                LEFT JOIN coach_member_list cml ON m.created_by = cml.coach_id AND cml.member_id = m.user_id
                LEFT JOIN coaches c ON m.created_by = c.user_id
                WHERE m.user_id = :user_id 
                AND m.created_by IS NOT NULL 
                AND m.created_by != m.user_id
                AND u.user_type_id = 3
                ORDER BY m.created_at DESC
            ");
            $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $stmt->execute();
            $allCoachRoutines = $stmt->fetchAll(PDO::FETCH_ASSOC);

            error_log("Found " . count($allCoachRoutines) . " coach/admin-created routines for user " . $userId);

            $accessibleRoutines = [];

            // Filter routines based on coach connection and subscription status using new status field
            foreach ($allCoachRoutines as $routine) {
                $isAccessible = false;
                $accessReason = '';

                // Check if it's an admin-created routine (always accessible)
                if (intval($routine['createdByTypeId']) === 1) {
                    $isAccessible = true;
                    $accessReason = 'Admin template routine';
                }
                // Check if it's a coach-created routine
                else if (intval($routine['createdByTypeId']) === 3) {
                    $coachId = (int) $routine['created_by'];
                    $status = $routine['status'] ?? '';
                    $coachApproval = $routine['coach_approval'] ?? '';
                    $staffApproval = $routine['staff_approval'] ?? '';

                    // Check if user has active connection with this coach using new status field
                    if ($status === 'active' && $coachApproval === 'approved' && $staffApproval === 'approved') {
                        $expiresAt = $routine['expires_at'];
                        $remainingSessions = $routine['remaining_sessions'];
                        $rateType = $routine['rate_type'] ?? '';
                        $monthlyRate = $routine['monthly_rate'];

                        // Check if subscription is expired
                        if ($expiresAt) {
                            $expirationDate = new DateTime($expiresAt);
                            $now = new DateTime();

                            if ($now <= $expirationDate) {
                                // Subscription is active
                                if ($rateType === 'monthly' || $monthlyRate) {
                                    // Monthly subscription - unlimited access
                                    $isAccessible = true;
                                    $daysLeft = $now->diff($expirationDate)->days;
                                    $accessReason = "Monthly subscription active ($daysLeft days left)";
                                } else if ($rateType === 'package' && $remainingSessions && $remainingSessions > 0) {
                                    // Session package - check remaining sessions
                                    $isAccessible = true;
                                    $accessReason = "Session package active ($remainingSessions sessions remaining)";
                                } else if ($rateType === 'hourly') {
                                    // Hourly rate - unlimited access until expiration
                                    $isAccessible = true;
                                    $daysLeft = $now->diff($expirationDate)->days;
                                    $accessReason = "Hourly rate active ($daysLeft days left)";
                                } else {
                                    // Default case - assume it's active
                                    $isAccessible = true;
                                    $accessReason = 'Coach connection active';
                                }
                            } else {
                                $accessReason = 'Coach subscription expired';
                            }
                        } else {
                            // No expiration date - assume it's active
                            $isAccessible = true;
                            $accessReason = 'Coach connection active (no expiration)';
                        }
                    } else if ($status === 'expired') {
                        $accessReason = 'Coach connection expired - please renew';
                    } else if ($status === 'disconnected') {
                        $accessReason = 'Coach connection disconnected';
                    } else {
                        $accessReason = 'No active coach connection';
                    }
                }

                if ($isAccessible) {
                    $accessibleRoutines[] = $routine;
                    error_log("Routine {$routine['id']} is accessible: $accessReason");
                } else {
                    error_log("Routine {$routine['id']} is not accessible: $accessReason");
                }
            }

            error_log("Found " . count($accessibleRoutines) . " accessible coach-created routines for user " . $userId);

            // Process accessible routines
            $processedRoutines = [];

            foreach ($accessibleRoutines as &$routine) {
                $routine['tags'] = json_decode($routine['tags'] ?? '[]', true);
                $routine['scheduledDays'] = json_decode($routine['scheduledDays'] ?? '[]', true);
                $routine['lastPerformed'] = $routine['updated_at'] ?? 'Never';
                $routine['exerciseList'] = ''; // Will be populated below
                $routine['version'] = 1.0;
                $routine['createdBy'] = $routine['createdByName'] ?? 'Unknown';
                $routine['createdById'] = intval($routine['created_by'] ?? 0);
                $routine['createdByTypeId'] = intval($routine['createdByTypeId'] ?? 0);
                $routine['category'] = intval($routine['createdByTypeId']) === 3 ? 'coach' : 'admin';

                // Get workout details and exercise count
                $workoutStmt = $pdo->prepare("SELECT mpw.workout_details, COUNT(mwe.id) as exercise_count FROM member_program_workout mpw LEFT JOIN member_workout_exercise mwe ON mpw.id = mwe.member_program_workout_id WHERE mpw.member_program_hdr_id = :routine_id GROUP BY mpw.id ORDER BY mpw.id DESC LIMIT 1");
                $workoutStmt->bindParam(':routine_id', $routine['id'], PDO::PARAM_INT);
                $workoutStmt->execute();
                $workoutData = $workoutStmt->fetch(PDO::FETCH_ASSOC);

                if ($workoutData && !empty($workoutData['workout_details'])) {
                    // Set exercise count
                    $routine['exercises'] = (int) $workoutData['exercise_count'];

                    // Get routine name from workout_details with better error handling
                    $workoutDetails = json_decode($workoutData['workout_details'], true);
                    error_log("DEBUG: Coach Routine ID {$routine['id']} - workout_details: " . $workoutData['workout_details']);
                    error_log("DEBUG: Coach Routine ID {$routine['id']} - parsed workout_details: " . print_r($workoutDetails, true));

                    if ($workoutDetails && isset($workoutDetails['name']) && !empty($workoutDetails['name'])) {
                        $routine['name'] = $workoutDetails['name'];
                        $routine['duration'] = $workoutDetails['duration'] ?? '30-45 min';
                        error_log("DEBUG: Coach Routine ID {$routine['id']} - using name from workout_details: " . $workoutDetails['name']);
                    } else {
                        // Fallback: use goal field from member_programhdr if available
                        $routine['name'] = !empty($routine['goal']) ? $routine['goal'] : 'Routine #' . $routine['id'];
                        $routine['duration'] = '30-45 min';
                        error_log("DEBUG: Coach Routine ID {$routine['id']} - using fallback name: " . $routine['name']);
                    }

                    // Get exercise names for exercise list
                    if ($routine['exercises'] > 0) {
                        $exerciseListStmt = $pdo->prepare("SELECT e.name FROM member_workout_exercise mwe JOIN exercise e ON mwe.exercise_id = e.id JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id WHERE mpw.member_program_hdr_id = :routine_id ORDER BY mwe.id LIMIT 3");
                        $exerciseListStmt->bindParam(':routine_id', $routine['id'], PDO::PARAM_INT);
                        $exerciseListStmt->execute();
                        $exercises = $exerciseListStmt->fetchAll(PDO::FETCH_COLUMN);

                        if (!empty($exercises)) {
                            $routine['exerciseList'] = implode(', ', $exercises);
                            if ($routine['exercises'] > 3) {
                                $routine['exerciseList'] .= '...';
                            }
                        }
                    }
                } else {
                    // No workout found, set defaults
                    $routine['exercises'] = 0;
                    $routine['name'] = 'Routine #' . $routine['id'];
                    $routine['duration'] = '30-45 min';
                    $routine['exerciseList'] = 'No exercises added';
                }

                $processedRoutines[] = $routine;
                error_log("DEBUG: Added accessible routine ID {$routine['id']} to processedRoutines");

                unset($routine['createdByName']);
            }

            // IMPORTANT: This endpoint ONLY returns accessible coach-created routines
            respond([
                'success' => true,
                'routines' => $processedRoutines,
                'my_routines' => [], // Empty - user routines handled separately
                'coach_assigned' => $processedRoutines,
                'template_routines' => [], // Admin routines included in coach_assigned
                'total_routines' => count($processedRoutines),
                'is_premium' => true, // Coach routines don't have membership restrictions
                'membership_status' => [
                    'is_premium' => true,
                    'subscription_details' => null
                ],
                'user_id' => $userId,
                'fetched_at' => date('Y-m-d H:i:s'),
                'note' => 'This endpoint only returns accessible coach-created routines. Use user_routines action for user routines.'
            ]);

        } catch (PDOException $e) {
            error_log("Database error in coach_routines: " . $e->getMessage());
            respond([
                "error" => "Database error: " . $e->getMessage(),
                "is_premium" => false
            ]);
        }
        break;

    case 'create':
    case 'createRoutine': // Add support for both action names
        try {
            // Handle both Flutter data format and original format
            $userId = validateUserId($input['user_id'] ?? $input['userId'] ?? null);
            $createdBy = null; // User creates their own routine - set created_by to NULL

            error_log("Creating routine for user ID: " . $userId);
            error_log("Input data: " . json_encode($input));

            // Check membership status before allowing creation
            $membershipData = checkMembershipStatus($pdo, $userId);
            $isPremium = $membershipData['is_premium'];

            // Count existing routines for this user
            $countStmt = $pdo->prepare("SELECT COUNT(*) as routine_count FROM member_programhdr WHERE user_id = :user_id");
            $countStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $countStmt->execute();
            $routineCount = $countStmt->fetch(PDO::FETCH_ASSOC)['routine_count'];

            error_log("User $userId has $routineCount routines, is_premium: " . ($isPremium ? 'true' : 'false'));

            // Apply membership restrictions
            if (!$isPremium && $routineCount >= 1) {
                error_log("Blocking routine creation - basic user at limit");
                respond([
                    "success" => false,
                    "error" => "Basic users can only have 1 routine. Upgrade to premium for unlimited routines.",
                    "membership_required" => true,
                    "current_routine_count" => $routineCount,
                    "is_premium" => false
                ]);
            }

            // Handle nullable program_hdr_id
            $programHdrId = $input['programHdrId'] ?? $input['program_hdr_id'] ?? null;
            $programHdrId = (is_numeric($programHdrId) && $programHdrId > 0) ? intval($programHdrId) : null;

            // Start transaction for routine creation
            $pdo->beginTransaction();

            try {
                // Insert into Member_ProgramHdr
                $sql = "INSERT INTO member_programhdr (user_id, program_hdr_id, created_by, color, tags, goal, notes, completion_rate, scheduled_days, difficulty, total_sessions) VALUES (:user_id, :program_hdr_id, :created_by, :color, :tags, :goal, :notes, :completion_rate, :scheduled_days, :difficulty, :total_sessions)";

                $stmt = $pdo->prepare($sql);
                $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
                $stmt->bindValue(':program_hdr_id', $programHdrId, $programHdrId === null ? PDO::PARAM_NULL : PDO::PARAM_INT);
                $stmt->bindValue(':created_by', $createdBy, $createdBy === null ? PDO::PARAM_NULL : PDO::PARAM_INT);
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
                    throw new Exception("Failed to insert routine header");
                }

                $memberProgramHdrId = $pdo->lastInsertId();
                error_log("Created Member_ProgramHdr with ID: " . $memberProgramHdrId);

                // Handle exercises if provided
                if (!empty($input['exercises']) && is_array($input['exercises'])) {
                    error_log("Processing " . count($input['exercises']) . " exercises");

                    // Create a workout entry with the routine name
                    $workoutSql = "INSERT INTO member_program_workout (member_program_hdr_id, workout_details) VALUES (?, ?)";
                    $workoutStmt = $pdo->prepare($workoutSql);
                    $workoutDetails = json_encode([
                        'name' => $input['name'] ?? 'Custom Workout',
                        'duration' => $input['duration'] ?? '30-45 min',
                        'created_at' => date('Y-m-d H:i:s')
                    ]);
                    $workoutStmt->execute([$memberProgramHdrId, $workoutDetails]);
                    $workoutId = $pdo->lastInsertId();

                    $addedExerciseIds = []; // Track which exercises have been added

                    // Add exercises to the workout
                    $exerciseSql = "INSERT INTO member_workout_exercise (member_program_workout_id, exercise_id, reps, sets, weight) VALUES (?, ?, ?, ?, ?)";
                    $exerciseStmt = $pdo->prepare($exerciseSql);

                    foreach ($input['exercises'] as $exercise) {
                        $exerciseId = $exercise['exercise_id'] ?? $exercise['id'] ?? null;

                        if ($exerciseId && !in_array($exerciseId, $addedExerciseIds)) {
                            // Use target_sets if available, otherwise count sets array
                            $totalSets = 0;
                            $avgReps = 0;
                            $avgWeight = 0;
                            
                            // Priority 1: Use target_sets if available
                            if (isset($exercise['target_sets']) && is_numeric($exercise['target_sets'])) {
                                $totalSets = (int)$exercise['target_sets'];
                                $avgReps = $exercise['target_reps'] ?? 10;
                                $avgWeight = $exercise['target_weight'] ?? 0;
                                
                                error_log("Added exercise ID $exerciseId using target_sets: $totalSets, reps: $avgReps, weight: $avgWeight");
                            }
                            // Priority 2: Count sets array if target_sets not available
                            else if (isset($exercise['sets']) && is_array($exercise['sets'])) {
                                $totalSets = count($exercise['sets']);
                                $totalReps = 0;
                                $totalWeight = 0;
                                
                                foreach ($exercise['sets'] as $set) {
                                    $reps = $set['reps'] ?? $exercise['reps'] ?? $exercise['target_reps'] ?? 10;
                                    $weight = $set['weight'] ?? $exercise['weight'] ?? $exercise['target_weight'] ?? 0;
                                    $totalReps += is_numeric($reps) ? $reps : 10;
                                    $totalWeight += is_numeric($weight) ? $weight : 0;
                                }
                                
                                $avgReps = $totalSets > 0 ? round($totalReps / $totalSets) : 10;
                                $avgWeight = $totalSets > 0 ? round($totalWeight / $totalSets, 1) : 0;
                                
                                error_log("Added exercise ID $exerciseId counting sets array: $totalSets, avg reps: $avgReps, avg weight: $avgWeight");
                            }
                            // Priority 3: Fallback to default
                            else {
                                $totalSets = 3;
                                $avgReps = 10;
                                $avgWeight = 0;
                                
                                error_log("Added exercise ID $exerciseId with default values - sets: $totalSets, reps: $avgReps, weight: $avgWeight");
                            }

                            // Insert ONE row per exercise with total sets
                            $exerciseStmt->execute([
                                $workoutId,
                                $exerciseId,
                                is_numeric($avgReps) ? $avgReps : 10,
                                $totalSets,
                                is_numeric($avgWeight) ? $avgWeight : 0
                            ]);

                            $addedExerciseIds[] = $exerciseId; // Mark as added
                        } elseif ($exerciseId && in_array($exerciseId, $addedExerciseIds)) {
                            error_log("Skipped duplicate exercise ID $exerciseId");
                        }
                    }

                    error_log("Total unique exercises added: " . count($addedExerciseIds));
                }

                $pdo->commit();

                error_log("Routine created successfully with ID: " . $memberProgramHdrId);
                respond([
                    "success" => true,
                    "id" => $memberProgramHdrId,
                    "message" => "Routine created successfully",
                    "is_premium" => $isPremium,
                    "membership_status" => [
                        "is_premium" => $isPremium,
                        "routines_remaining" => $isPremium ? "unlimited" : (1 - ($routineCount + 1))
                    ]
                ]);

            } catch (Exception $e) {
                $pdo->rollBack();
                error_log("Error in routine creation transaction: " . $e->getMessage());
                throw $e;
            }

        } catch (PDOException $e) {
            error_log("Database error in create: " . $e->getMessage());
            respond(["success" => false, "error" => "Database error: " . $e->getMessage()]);
        } catch (Exception $e) {
            error_log("General error in create: " . $e->getMessage());
            respond(["success" => false, "error" => $e->getMessage()]);
        }
        break;

    case 'updateProgress':
        try {
            $routineId = $input['id'] ?? null;
            $userId = validateUserId($input['userId'] ?? null);

            if (!$routineId) {
                respond(["error" => "Missing routine ID"]);
            }

            $checkStmt = $pdo->prepare("SELECT user_id FROM member_programhdr WHERE id = :id");
            $checkStmt->bindParam(':id', $routineId);
            $checkStmt->execute();
            $routine = $checkStmt->fetch(PDO::FETCH_ASSOC);

            if (!$routine) {
                respond(["error" => "Routine not found"]);
            }

            if ($routine['user_id'] != $userId) {
                respond(["error" => "Unauthorized: Cannot update another user's routine"]);
            }

            $sql = "UPDATE member_programhdr SET completion_rate = :completion_rate, total_sessions = :total_sessions, updated_at = NOW() WHERE id = :id AND user_id = :user_id";

            $stmt = $pdo->prepare($sql);
            $result = $stmt->execute([
                ':completion_rate' => intval($input['completionRate'] ?? 0),
                ':total_sessions' => intval($input['totalSessions'] ?? 0),
                ':id' => $routineId,
                ':user_id' => $userId
            ]);

            if ($result) {
                respond(["success" => true, "message" => "Progress updated"]);
            } else {
                respond(["error" => "Failed to update progress"]);
            }

        } catch (PDOException $e) {
            error_log("Database error in updateProgress: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        }
        break;

    case 'delete':
        try {
            $routineId = $input['id'] ?? null;
            $userId = validateUserId($input['userId'] ?? null);

            if (!$routineId) {
                respond(["error" => "Missing routine ID"]);
            }

            $checkStmt = $pdo->prepare("SELECT user_id FROM member_programhdr WHERE id = :id");
            $checkStmt->bindParam(':id', $routineId);
            $checkStmt->execute();
            $routine = $checkStmt->fetch(PDO::FETCH_ASSOC);

            if (!$routine) {
                respond(["error" => "Routine not found"]);
            }

            if ($routine['user_id'] != $userId) {
                respond(["error" => "Unauthorized: Cannot delete another user's routine"]);
            }

            // Start transaction to ensure all related data is deleted properly
            $pdo->beginTransaction();

            try {
                // First, delete all workout exercises related to this routine
                $deleteExercisesStmt = $pdo->prepare("
                    DELETE mwe FROM member_workout_exercise mwe
                    INNER JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
                    WHERE mpw.member_program_hdr_id = :routine_id
                ");
                $deleteExercisesStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
                $deleteExercisesStmt->execute();
                error_log("Deleted " . $deleteExercisesStmt->rowCount() . " workout exercises for routine $routineId");

                // Then, delete all workouts related to this routine
                $deleteWorkoutsStmt = $pdo->prepare("
                    DELETE FROM member_program_workout 
                    WHERE member_program_hdr_id = :routine_id
                ");
                $deleteWorkoutsStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
                $deleteWorkoutsStmt->execute();
                error_log("Deleted " . $deleteWorkoutsStmt->rowCount() . " workouts for routine $routineId");

                // Finally, delete the routine header
                $deleteRoutineStmt = $pdo->prepare("
                    DELETE FROM member_programhdr 
                    WHERE id = :routine_id AND user_id = :user_id
                ");
                $deleteRoutineStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
                $deleteRoutineStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $deleteRoutineStmt->execute();

                if ($deleteRoutineStmt->rowCount() > 0) {
                    $pdo->commit();
                    error_log("Successfully deleted routine $routineId and all related data");
                    respond(["success" => true, "message" => "Routine deleted successfully"]);
                } else {
                    $pdo->rollBack();
                    error_log("Failed to delete routine $routineId - no rows affected");
                    respond(["error" => "Failed to delete routine"]);
                }

            } catch (Exception $e) {
                $pdo->rollBack();
                error_log("Error in delete transaction: " . $e->getMessage());
                throw $e;
            }

        } catch (PDOException $e) {
            error_log("Database error in delete: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        }
        break;

    case 'get_programs_for_scheduling':
        try {
            $userId = validateUserId($_GET['user_id'] ?? null);
            
            error_log("Fetching programs for scheduling for user ID: " . $userId);
            
            // Get ALL programs for this user (same logic as 'fetch' action)
            $stmt = $pdo->prepare("
                SELECT 
                    mph.id as program_id,
                    mph.goal,
                    mph.difficulty,
                    mph.created_at,
                    mph.created_by,
                    u.user_type_id as created_by_type_id,
                    CONCAT(u.fname, ' ', u.lname) as created_by_name,
                    COUNT(mpw.id) as total_workouts
                FROM member_programhdr mph
                LEFT JOIN member_program_workout mpw ON mph.id = mpw.member_program_hdr_id
                LEFT JOIN user u ON mph.created_by = u.id
                WHERE mph.user_id = :user_id
                GROUP BY mph.id, mph.goal, mph.difficulty, mph.created_at, mph.created_by, u.user_type_id, u.fname, u.lname
                ORDER BY mph.created_at DESC
            ");
            $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $stmt->execute();
            $programs = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $programsForScheduling = [];
            
            foreach ($programs as $program) {
                // Apply same filtering logic as coach_routines action
                $isAccessible = false; // Default to false, then check access
                $createdByTypeId = (int)($program['created_by_type_id'] ?? 0);
                
                // Check if it's an admin-created program (type 1) - always accessible
                if ($createdByTypeId === 1) {
                    $isAccessible = true;
                }
                // Check if it's a coach-created program (type 3) - validate connection
                else if ($createdByTypeId === 3) {
                    // If the program was created by the current user, treat it as a user program
                    if ((int)$program['created_by'] === (int)$userId) {
                        $isAccessible = true;
                    } else {
                        // Check coach connection status for programs created by other coaches
                        $coachCheckStmt = $pdo->prepare("
                            SELECT coach_approval, staff_approval, expires_at, session_package_count, monthly_rate
                            FROM coach_member_list cml
                            LEFT JOIN coaches c ON cml.coach_id = c.user_id
                            WHERE cml.coach_id = :coach_id AND cml.member_id = :user_id
                            ORDER BY cml.requested_at DESC LIMIT 1
                        ");
                        $coachCheckStmt->execute([
                            ':coach_id' => $program['created_by'],
                            ':user_id' => $userId
                        ]);
                        $coachConnection = $coachCheckStmt->fetch(PDO::FETCH_ASSOC);
                        
                        if ($coachConnection && 
                            $coachConnection['coach_approval'] === 'approved' && 
                            $coachConnection['staff_approval'] === 'approved') {
                            
                            $expiresAt = $coachConnection['expires_at'];
                            if ($expiresAt) {
                                $expirationDate = new DateTime($expiresAt);
                                $now = new DateTime();
                                
                                if ($now <= $expirationDate) {
                                    $isAccessible = true;
                                }
                            } else {
                                // No expiration date - assume active
                                $isAccessible = true;
                            }
                        }
                    }
                }
                // Check if it's a user-created program (no created_by or null type_id)
                else if (!$program['created_by'] || $createdByTypeId === 0 || $createdByTypeId === null) {
                    $isAccessible = true;
                }
                
                // Only include accessible programs
                if ($isAccessible) {
                    // Get workouts for this program
                    $workoutStmt = $pdo->prepare("
                        SELECT 
                            mpw.id as workout_id,
                            JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.name')) as name,
                            JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.duration')) as duration
                        FROM member_program_workout mpw
                        WHERE mpw.member_program_hdr_id = :program_id
                        ORDER BY mpw.id
                    ");
                    $workoutStmt->bindParam(':program_id', $program['program_id'], PDO::PARAM_INT);
                    $workoutStmt->execute();
                    $workouts = $workoutStmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    // Clean up workout data
                    foreach ($workouts as &$workout) {
                        $workout['workout_id'] = (int)$workout['workout_id'];
                        $workout['name'] = $workout['name'] ?: 'Workout ' . $workout['workout_id'];
                        $workout['duration'] = $workout['duration'] ?: '30';
                    }
                    
                    $programsForScheduling[] = [
                        'program_id' => (int)$program['program_id'],
                        'goal' => $program['goal'] ?: 'General Fitness',
                        'difficulty' => $program['difficulty'] ?: 'Beginner',
                        'total_workouts' => (int)$program['total_workouts'],
                        'workouts' => $workouts,
                        'created_at' => $program['created_at'],
                        'created_by' => $program['created_by'],
                        'created_by_type_id' => $program['created_by_type_id'],
                        'created_by_name' => $program['created_by_name']
                    ];
                }
            }
            
            error_log("Found " . count($programsForScheduling) . " programs for scheduling");
            
            respond([
                'success' => true,
                'programs' => $programsForScheduling
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in get_programs_for_scheduling: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        } catch (Exception $e) {
            error_log("General error in get_programs_for_scheduling: " . $e->getMessage());
            respond(["success" => false, "error" => $e->getMessage()]);
        }
        break;

    case 'get_schedule':
        try {
            $userId = validateUserId($_GET['user_id'] ?? null);
            $memberProgramId = $_GET['member_program_id'] ?? null;
            
            if (!$memberProgramId) {
                respond(["error" => "Missing member_program_id"]);
            }
            
            error_log("Fetching schedule for program: $memberProgramId, user: $userId");
            
            // Verify the program belongs to the user
            $checkStmt = $pdo->prepare("SELECT user_id FROM member_programhdr WHERE id = :id");
            $checkStmt->bindParam(':id', $memberProgramId);
            $checkStmt->execute();
            $program = $checkStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$program || $program['user_id'] != $userId) {
                respond(["error" => "Program not found or unauthorized"]);
            }
            
            // Get the weekly schedule for this program
            $stmt = $pdo->prepare("
                SELECT 
                    mps.id as schedule_id,
                    mps.day_of_week,
                    mps.workout_id,
                    mps.scheduled_time,
                    mps.is_rest_day,
                    mps.notes,
                    mps.is_active,
                    JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.name')) as workout_name,
                    JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.duration')) as workout_duration
                FROM member_program_schedule mps
                LEFT JOIN member_program_workout mpw ON mps.workout_id = mpw.id
                WHERE mps.member_program_hdr_id = :program_id
                AND mps.is_active = 1
                ORDER BY 
                    CASE mps.day_of_week
                        WHEN 'Monday' THEN 1
                        WHEN 'Tuesday' THEN 2
                        WHEN 'Wednesday' THEN 3
                        WHEN 'Thursday' THEN 4
                        WHEN 'Friday' THEN 5
                        WHEN 'Saturday' THEN 6
                        WHEN 'Sunday' THEN 7
                    END
            ");
            $stmt->bindParam(':program_id', $memberProgramId, PDO::PARAM_INT);
            $stmt->execute();
            $scheduleItems = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Format the weekly schedule
            $weeklySchedule = [];
            foreach ($scheduleItems as $item) {
                $weeklySchedule[$item['day_of_week']] = [
                    'schedule_id' => (int)$item['schedule_id'],
                    'day_of_week' => $item['day_of_week'],
                    'workout_id' => $item['workout_id'] ? (int)$item['workout_id'] : null,
                    'workout_name' => $item['workout_name'],
                    'workout_duration' => $item['workout_duration'],
                    'scheduled_time' => $item['scheduled_time'],
                    'is_rest_day' => (bool)$item['is_rest_day'],
                    'notes' => $item['notes'],
                    'is_active' => (bool)$item['is_active']
                ];
            }
            
            respond([
                'success' => true,
                'weekly_schedule' => $weeklySchedule
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in get_schedule: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        } catch (Exception $e) {
            error_log("General error in get_schedule: " . $e->getMessage());
            respond(["success" => false, "error" => $e->getMessage()]);
        }
        break;

    case 'create_schedule':
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            $userId = validateUserId($input['user_id'] ?? null);
            $memberProgramId = $input['member_program_id'] ?? null;
            $schedule = $input['schedule'] ?? null;
            
            if (!$memberProgramId || !$schedule) {
                respond(["error" => "Missing member_program_id or schedule data"]);
            }
            
            // Verify the program belongs to the user
            $checkStmt = $pdo->prepare("SELECT user_id FROM member_programhdr WHERE id = :id");
            $checkStmt->bindParam(':id', $memberProgramId);
            $checkStmt->execute();
            $program = $checkStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$program || $program['user_id'] != $userId) {
                respond(["error" => "Program not found or unauthorized"]);
            }
            
            $pdo->beginTransaction();
            
            try {
                // Delete existing schedule for this program
                $deleteStmt = $pdo->prepare("DELETE FROM member_program_schedule WHERE member_program_hdr_id = :program_id");
                $deleteStmt->execute([':program_id' => $memberProgramId]);
                
                // Insert new schedule
                $insertStmt = $pdo->prepare("
                    INSERT INTO member_program_schedule 
                    (member_program_hdr_id, day_of_week, workout_id, scheduled_time, is_rest_day, notes) 
                    VALUES (:program_id, :day_of_week, :workout_id, :scheduled_time, :is_rest_day, :notes)
                ");
                
                foreach ($schedule as $day => $dayData) {
                    $workoutId = $dayData['workout_id'] ?? null;
                    $scheduledTime = $dayData['scheduled_time'] ?? '09:00:00';
                    $isRestDay = $dayData['is_rest_day'] ?? false;
                    $notes = $dayData['notes'] ?? null;
                    
                    $insertStmt->execute([
                        ':program_id' => $memberProgramId,
                        ':day_of_week' => $day,
                        ':workout_id' => $workoutId,
                        ':scheduled_time' => $isRestDay ? null : $scheduledTime,
                        ':is_rest_day' => $isRestDay ? 1 : 0,
                        ':notes' => $notes
                    ]);
                }
                
                $pdo->commit();
                respond([
                    "success" => true,
                    "message" => "Schedule created successfully"
                ]);
                
            } catch (Exception $e) {
                $pdo->rollBack();
                error_log("Error in create_schedule transaction: " . $e->getMessage());
                throw $e;
            }
            
        } catch (PDOException $e) {
            error_log("Database error in create_schedule: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        } catch (Exception $e) {
            error_log("General error in create_schedule: " . $e->getMessage());
            respond(["success" => false, "error" => $e->getMessage()]);
        }
        break;

    case 'get_member_schedule':
        try {
            $userId = validateUserId($_GET['user_id'] ?? null);
            $coachId = validateUserId($_GET['coach_id'] ?? null);
            
            // Verify coach has access to this member
            $coachCheckStmt = $pdo->prepare("
                SELECT 1 FROM coach_member_list 
                WHERE coach_id = :coach_id AND member_id = :user_id 
                AND coach_approval = 'approved' AND staff_approval = 'approved'
                AND (expires_at IS NULL OR expires_at > NOW())
            ");
            $coachCheckStmt->execute([
                ':coach_id' => $coachId,
                ':user_id' => $userId
            ]);
            
            if (!$coachCheckStmt->fetch()) {
                respond(["success" => false, "error" => "Access denied: Coach not authorized to view this member's schedule"]);
            }
            
            // Get member's weekly schedule
            $scheduleStmt = $pdo->prepare("
                SELECT 
                    mps.id as schedule_id,
                    mps.day_of_week,
                    mps.workout_id,
                    mps.scheduled_time,
                    mps.is_rest_day,
                    mps.notes,
                    mps.is_active,
                    JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.name')) as workout_name,
                    JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.duration')) as workout_duration,
                    mph.goal as program_goal,
                    mph.id as program_id
                FROM member_program_schedule mps
                LEFT JOIN member_program_workout mpw ON mps.workout_id = mpw.id
                LEFT JOIN member_programhdr mph ON mps.member_program_hdr_id = mph.id
                WHERE mph.user_id = :user_id 
                AND mps.is_active = 1
                ORDER BY 
                    CASE mps.day_of_week
                        WHEN 'Monday' THEN 1
                        WHEN 'Tuesday' THEN 2
                        WHEN 'Wednesday' THEN 3
                        WHEN 'Thursday' THEN 4
                        WHEN 'Friday' THEN 5
                        WHEN 'Saturday' THEN 6
                        WHEN 'Sunday' THEN 7
                    END,
                    mps.scheduled_time ASC
            ");
            $scheduleStmt->execute([':user_id' => $userId]);
            $scheduleData = $scheduleStmt->fetchAll();
            
            $schedule = array_map(function($day) {
                return [
                    'schedule_id' => (int)$day['schedule_id'],
                    'day_of_week' => $day['day_of_week'],
                    'workout_id' => $day['workout_id'] ? (int)$day['workout_id'] : null,
                    'workout_name' => $day['workout_name'] ?: 'Workout',
                    'workout_duration' => $day['workout_duration'] ?: '30',
                    'scheduled_time' => $day['scheduled_time'],
                    'is_rest_day' => (bool)$day['is_rest_day'],
                    'notes' => $day['notes'],
                    'is_active' => (bool)$day['is_active'],
                    'program_goal' => $day['program_goal'] ?: 'General Fitness',
                    'program_id' => (int)$day['program_id']
                ];
            }, $scheduleData);
            
            respond([
                'success' => true,
                'schedule' => $schedule
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in get_member_schedule: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        } catch (Exception $e) {
            error_log("General error in get_member_schedule: " . $e->getMessage());
            respond(["success" => false, "error" => $e->getMessage()]);
        }
        break;

    case 'fetch_routine_details':
        try {
            $routineId = $_GET['routine_id'] ?? $input['routine_id'] ?? null;
            $userId = validateUserId($_GET['user_id'] ?? $input['user_id'] ?? null);
            
            if (!$routineId) {
                respond(["error" => "Missing routine ID"]);
            }
            
            $routineId = is_numeric($routineId) ? intval($routineId) : $routineId;
            
            error_log("Fetching routine details for routine ID: $routineId, user ID: $userId");
            
            // Fetch routine header
            $routineStmt = $pdo->prepare("
                SELECT 
                    m.id,
                    m.user_id,
                    m.program_hdr_id,
                    m.created_by,
                    m.color,
                    m.tags,
                    m.goal,
                    m.notes,
                    m.completion_rate AS completionRate,
                    m.scheduled_days AS scheduledDays,
                    m.difficulty,
                    m.total_sessions AS totalSessions,
                    m.created_at,
                    m.updated_at,
                    CONCAT(u.fname, ' ', u.mname, ' ', u.lname) AS createdByName,
                    u.user_type_id AS createdByTypeId
                FROM member_programhdr m 
                LEFT JOIN user u ON u.id = m.created_by 
                WHERE m.id = :routine_id
            ");
            $routineStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
            $routineStmt->execute();
            $routineData = $routineStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$routineData) {
                respond(["error" => "Routine not found"]);
            }
            
            // Verify the routine belongs to the user
            if ($routineData['user_id'] != $userId) {
                respond(["error" => "Unauthorized: Cannot access another user's routine"]);
            }
            
            // Get workout details
            $workoutStmt = $pdo->prepare("
                SELECT workout_details 
                FROM member_program_workout 
                WHERE member_program_hdr_id = :routine_id 
                ORDER BY id DESC 
                LIMIT 1
            ");
            $workoutStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
            $workoutStmt->execute();
            $workoutData = $workoutStmt->fetch(PDO::FETCH_ASSOC);
            
            $workoutDetails = [];
            if ($workoutData && !empty($workoutData['workout_details'])) {
                $workoutDetails = json_decode($workoutData['workout_details'], true);
            }
            
            // Fetch all exercises with details
            // Note: GROUP_CONCAT for target_muscle requires GROUP BY
            $exerciseStmt = $pdo->prepare("
                SELECT 
                    e.id as exercise_id,
                    e.name,
                    e.description,
                    e.image_url,
                    e.video_url,
                    mwe.id as member_workout_exercise_id,
                    mwe.reps as target_reps,
                    mwe.sets as target_sets,
                    mwe.weight as target_weight,
                    GROUP_CONCAT(DISTINCT tm.name SEPARATOR ', ') as target_muscle
                FROM member_workout_exercise mwe
                JOIN exercise e ON mwe.exercise_id = e.id
                JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
                LEFT JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
                LEFT JOIN target_muscle tm ON etm.muscle_id = tm.id
                WHERE mpw.member_program_hdr_id = :routine_id
                GROUP BY mwe.id
                ORDER BY mwe.id ASC
            ");
            $exerciseStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
            $exerciseStmt->execute();
            $exercises = $exerciseStmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Build detailed exercises array
            $detailedExercises = [];
            foreach ($exercises as $exercise) {
                // Create empty sets array for editing
                $sets = [];
                $targetSets = (int)$exercise['target_sets'];
                $targetReps = (string)$exercise['target_reps'];
                $targetWeight = (string)$exercise['target_weight'];
                
                // Create sets array based on target sets
                for ($i = 0; $i < $targetSets; $i++) {
                    $sets[] = [
                        'reps' => $targetReps,
                        'weight' => $targetWeight,
                        'rpe' => 0,
                        'duration' => '',
                        'timestamp' => date('c')
                    ];
                }
                
                $detailedExercises[] = [
                    'id' => (int)$exercise['exercise_id'],
                    'name' => $exercise['name'],
                    'target_sets' => $targetSets,
                    'target_reps' => $targetReps,
                    'target_weight' => $targetWeight,
                    'completed_sets' => 0,
                    'sets' => $sets,
                    'completed' => false,
                    'category' => '', // Not in database
                    'difficulty' => $routineData['difficulty'] ?? 'Beginner', // Use routine difficulty
                    'color' => $routineData['color'],
                    'rest_time' => 60, // Default 60 seconds
                    'notes' => '',
                    'target_muscle' => $exercise['target_muscle'] ?? '',
                    'description' => $exercise['description'] ?? '',
                    'image_url' => $exercise['image_url'] ?? '',
                    'video_url' => $exercise['video_url'] ?? ''
                ];
            }
            
            // Build routine name from workout_details
            $routineName = $workoutDetails['name'] ?? $routineData['goal'] ?? 'Routine #' . $routineId;
            $routineDuration = $workoutDetails['duration'] ?? '30-45 min';
            
            // Build exercise list string
            $exerciseNames = array_column($exercises, 'name');
            $exerciseList = !empty($exerciseNames) ? implode(', ', array_slice($exerciseNames, 0, 3)) : 'No exercises';
            
            // Format response
            $formattedRoutine = [
                'id' => (string)$routineData['id'],
                'name' => $routineName,
                'exercises' => count($detailedExercises),
                'duration' => $routineDuration,
                'difficulty' => $routineData['difficulty'] ?? 'Beginner',
                'createdById' => $routineData['created_by'] ? (string)$routineData['created_by'] : '',
                'createdByTypeId' => (int)($routineData['createdByTypeId'] ?? 0),
                'exerciseList' => $exerciseList,
                'color' => $routineData['color'] ?? '0xFF96CEB4',
                'lastPerformed' => $routineData['updated_at'] ?? 'Never',
                'tags' => json_decode($routineData['tags'] ?? '[]', true),
                'goal' => $routineData['goal'] ?? '',
                'completionRate' => (int)$routineData['completionRate'],
                'totalSessions' => (int)$routineData['totalSessions'],
                'notes' => $routineData['notes'] ?? '',
                'scheduledDays' => json_decode($routineData['scheduledDays'] ?? '[]', true),
                'version' => 1.0,
                'detailedExercises' => $detailedExercises
            ];
            
            respond([
                'success' => true,
                'routine' => $formattedRoutine
            ]);
            
        } catch (PDOException $e) {
            error_log("Database error in fetch_routine_details: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        } catch (Exception $e) {
            error_log("General error in fetch_routine_details: " . $e->getMessage());
            respond(["success" => false, "error" => $e->getMessage()]);
        }
        break;

    case 'add_exercise_to_routine':
        try {
            $routineId = $input['routine_id'] ?? $input['routineId'] ?? null;
            $userId = validateUserId($input['user_id'] ?? $input['userId'] ?? null);
            $exerciseId = $input['exercise_id'] ?? $input['exerciseId'] ?? null;
            $sets = intval($input['sets'] ?? 3);
            $reps = intval($input['reps'] ?? 10);
            $weight = floatval($input['weight'] ?? 0);
            
            if (!$routineId || !$exerciseId) {
                respond(["error" => "Missing routine ID or exercise ID"]);
            }
            
            $routineId = is_numeric($routineId) ? intval($routineId) : null;
            $exerciseId = is_numeric($exerciseId) ? intval($exerciseId) : null;
            
            if (!$routineId || !$exerciseId) {
                error_log("DEBUG: Invalid routine_id=$routineId or exercise_id=$exerciseId");
                respond(["error" => "Invalid routine ID or exercise ID"]);
            }
            
            error_log("Adding exercise to routine: routine_id=$routineId, exercise_id=$exerciseId, user_id=$userId");
            
            // Verify the routine belongs to the user - also get created_by
            $checkStmt = $pdo->prepare("SELECT user_id, id, created_by FROM member_programhdr WHERE id = :routine_id");
            $checkStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
            $checkStmt->execute();
            $routine = $checkStmt->fetch(PDO::FETCH_ASSOC);
            
            error_log("DEBUG: Routine query result: " . json_encode($routine));
            
            if ($routine) {
                error_log("DEBUG: user_id from DB: " . $routine['user_id'] . " (assigned to)");
                error_log("DEBUG: created_by from DB: " . ($routine['created_by'] ?? 'NULL') . " (created by)");
            } else {
                error_log("DEBUG: Routine with ID $routineId NOT FOUND in database");
            }
            
            error_log("DEBUG: user_id from request: $userId (who is trying to add exercise)");
            
            // Get info about both users (after we find out the routine owner)
            // We'll log this info later when we know who owns the routine
            
            // Additional debug: Check if any routines exist for this user
            $checkAllRoutinesStmt = $pdo->prepare("SELECT id, user_id FROM member_programhdr WHERE user_id = :user_id LIMIT 5");
            $checkAllRoutinesStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
            $checkAllRoutinesStmt->execute();
            $allRoutines = $checkAllRoutinesStmt->fetchAll(PDO::FETCH_ASSOC);
            error_log("DEBUG: User $userId has these routines: " . json_encode($allRoutines));
            
            if (!$routine) {
                error_log("DEBUG: Routine not found in database");
                respond([
                    "success" => false,
                    "error" => "Routine not found",
                    "debug_info" => [
                        "routine_id" => $routineId,
                        "user_id" => $userId,
                        "message" => "Routine ID $routineId does not exist in the database"
                    ]
                ]);
            }
            
            // Allow access if routine belongs to user OR if it's assigned to this user (coach-created)
            $routineUserId = (int)$routine['user_id'];
            $requestUserId = (int)$userId;
            
            // Check if user has access to this routine (either owns it, or it's assigned to them)
            $hasAccess = false;
            
            // If user owns the routine (user_id matches), allow access
            if ($routineUserId == $requestUserId) {
                $hasAccess = true;
                error_log("DEBUG: User $requestUserId owns routine $routineId");
            } else {
                // User doesn't own it, deny access
                // The user might be logged in as the wrong account
                error_log("DEBUG: User $requestUserId trying to modify routine $routineId which belongs to user $routineUserId");
                $hasAccess = false;
            }
            
            if (!$hasAccess) {
                error_log("DEBUG: Access denied - Routine owner: $routineUserId, Request user: $requestUserId");
                
                // Get user names for better error message
                $ownerInfoStmt = $pdo->prepare("SELECT email, fname, lname FROM user WHERE id = :user_id");
                $ownerInfoStmt->bindParam(':user_id', $routineUserId, PDO::PARAM_INT);
                $ownerInfoStmt->execute();
                $ownerInfo = $ownerInfoStmt->fetch(PDO::FETCH_ASSOC);
                
                $requestInfoStmt = $pdo->prepare("SELECT email, fname, lname FROM user WHERE id = :user_id");
                $requestInfoStmt->bindParam(':user_id', $requestUserId, PDO::PARAM_INT);
                $requestInfoStmt->execute();
                $requestInfo = $requestInfoStmt->fetch(PDO::FETCH_ASSOC);
                
                respond([
                    "success" => false,
                    "error" => "Unauthorized",
                    "debug_info" => [
                        "routine_id" => $routineId,
                        "routine_user_id" => $routineUserId,
                        "request_user_id" => $requestUserId,
                        "message" => "Routine belongs to user $routineUserId but request is from user $requestUserId",
                        "routine_owner" => $ownerInfo ? ($ownerInfo['fname'] . ' ' . $ownerInfo['lname'] . ' (' . $ownerInfo['email'] . ')') : 'Unknown',
                        "request_user" => $requestInfo ? ($requestInfo['fname'] . ' ' . $requestInfo['lname'] . ' (' . $requestInfo['email'] . ')') : 'Unknown'
                    ]
                ]);
            }
            
            // Get the workout ID for this routine
            $workoutStmt = $pdo->prepare("SELECT id FROM member_program_workout WHERE member_program_hdr_id = :routine_id ORDER BY id DESC LIMIT 1");
            $workoutStmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
            $workoutStmt->execute();
            $workoutData = $workoutStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$workoutData) {
                respond(["error" => "No workout found for this routine"]);
            }
            
            $workoutId = $workoutData['id'];
            
            // Check if this exercise already exists in this workout
            $checkStmt = $pdo->prepare("SELECT id FROM member_workout_exercise WHERE member_program_workout_id = :workout_id AND exercise_id = :exercise_id");
            $checkStmt->bindParam(':workout_id', $workoutId, PDO::PARAM_INT);
            $checkStmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
            $checkStmt->execute();
            $existingExercise = $checkStmt->fetch(PDO::FETCH_ASSOC);
            
            if ($existingExercise) {
                error_log("Exercise $exerciseId already exists in routine $routineId");
                respond([
                    "success" => false,
                    "message" => "Exercise already exists in routine",
                    "error" => "This exercise is already in the routine"
                ]);
            }
            
            // Insert the exercise into member_workout_exercise
            $insertStmt = $pdo->prepare("INSERT INTO member_workout_exercise (member_program_workout_id, exercise_id, sets, reps, weight) VALUES (:workout_id, :exercise_id, :sets, :reps, :weight)");
            $insertStmt->bindParam(':workout_id', $workoutId, PDO::PARAM_INT);
            $insertStmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
            $insertStmt->bindParam(':sets', $sets, PDO::PARAM_INT);
            $insertStmt->bindParam(':reps', $reps, PDO::PARAM_INT);
            $insertStmt->bindParam(':weight', $weight, PDO::PARAM_STR);
            
            if ($insertStmt->execute()) {
                $newExerciseId = $pdo->lastInsertId();
                error_log("Successfully added exercise $exerciseId to routine $routineId with new ID: $newExerciseId");
                
                // Get exercise name for response
                $exerciseNameStmt = $pdo->prepare("SELECT name FROM exercise WHERE id = :exercise_id");
                $exerciseNameStmt->bindParam(':exercise_id', $exerciseId, PDO::PARAM_INT);
                $exerciseNameStmt->execute();
                $exerciseData = $exerciseNameStmt->fetch(PDO::FETCH_ASSOC);
                
                respond([
                    "success" => true,
                    "message" => "Exercise added to routine successfully",
                    "exercise_id" => $exerciseId,
                    "exercise_name" => $exerciseData['name'] ?? '',
                    "member_workout_exercise_id" => $newExerciseId
                ]);
            } else {
                respond(["error" => "Failed to add exercise to routine"]);
            }
            
        } catch (PDOException $e) {
            error_log("Database error in add_exercise_to_routine: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        } catch (Exception $e) {
            error_log("General error in add_exercise_to_routine: " . $e->getMessage());
            respond(["success" => false, "error" => $e->getMessage()]);
        }
        break;

    case 'get_today_workout':
        try {
            $userId = validateUserId($_GET['user_id'] ?? null);
            $memberProgramId = $_GET['member_program_id'] ?? null;
            
            if (!$memberProgramId) {
                respond(["error" => "Missing member program ID"]);
            }
            
            // Get today's day name (e.g., 'Monday', 'Tuesday', etc.)
            $today = date('l'); // Returns full day name like 'Wednesday'
            
            // Get the program details and check the actual schedule table
            $stmt = $pdo->prepare("
                SELECT 
                    mph.id,
                    mph.goal,
                    mph.notes,
                    mph.difficulty,
                    mph.total_sessions,
                    mph.completion_rate,
                    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.name')), 'Workout') as workout_name,
                    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.duration')), '60') as workout_duration,
                    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.scheduled_time')), '') as scheduled_time
                FROM member_programhdr mph
                LEFT JOIN member_program_workout mpw ON mph.id = mpw.member_program_hdr_id
                WHERE mph.id = ? AND mph.user_id = ?
                LIMIT 1
            ");
            
            $stmt->execute([$memberProgramId, $userId]);
            $program = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$program) {
                respond(["error" => "Program not found"]);
            }
            
            // Check if today is scheduled in the member_program_schedule table
            $scheduleStmt = $pdo->prepare("
                SELECT 
                    mps.id as schedule_id,
                    mps.day_of_week,
                    mps.workout_id,
                    mps.scheduled_time,
                    mps.is_rest_day,
                    mps.notes,
                    JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.name')) as workout_name,
                    JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.duration')) as workout_duration
                FROM member_program_schedule mps
                LEFT JOIN member_program_workout mpw ON mps.workout_id = mpw.id
                WHERE mps.member_program_hdr_id = ? AND mps.day_of_week = ? AND mps.is_active = 1
                LIMIT 1
            ");
            
            $scheduleStmt->execute([$memberProgramId, $today]);
            $scheduleItem = $scheduleStmt->fetch(PDO::FETCH_ASSOC);
            
            // Check if today is a scheduled day
            $isScheduledDay = ($scheduleItem !== false);
            
            if (!$isScheduledDay) {
                // No schedule found for today - show rest day
                respond([
                    "success" => true,
                    "today_workout" => [
                        "isRestDay" => true,
                        "programGoal" => $program['goal'] ?: 'General Fitness',
                        "programId" => intval($program['id']),
                        "scheduledTime" => null,
                        "workoutName" => null,
                        "workoutDuration" => null
                    ]
                ]);
            }
            
            // Today is scheduled - check if it's a rest day or workout
            if ($scheduleItem['is_rest_day']) {
                // Today is explicitly scheduled as a rest day
                respond([
                    "success" => true,
                    "today_workout" => [
                        "isRestDay" => true,
                        "programGoal" => $program['goal'] ?: 'General Fitness',
                        "programId" => intval($program['id']),
                        "scheduledTime" => null,
                        "workoutName" => null,
                        "workoutDuration" => null
                    ]
                ]);
            } else {
                // Today is a workout day
                respond([
                    "success" => true,
                    "today_workout" => [
                        "isRestDay" => false,
                        "programGoal" => $program['goal'] ?: 'General Fitness',
                        "programId" => intval($program['id']),
                        "scheduledTime" => $scheduleItem['scheduled_time'] ?: null,
                        "workoutName" => $scheduleItem['workout_name'] ?: $program['workout_name'],
                        "workoutDuration" => $scheduleItem['workout_duration'] ?: $program['workout_duration'],
                        "difficulty" => $program['difficulty'],
                        "completionRate" => intval($program['completion_rate']),
                        "totalSessions" => intval($program['total_sessions'])
                    ]
                ]);
            }
            
        } catch (PDOException $e) {
            error_log("Database error in get_today_workout: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        } catch (Exception $e) {
            error_log("Error in get_today_workout: " . $e->getMessage());
            respond(["error" => $e->getMessage()]);
        }
        break;

    case 'clone_program':
        try {
            error_log("=== CLONE PROGRAM REQUEST ===");
            $userId = $_GET['user_id'] ?? $input['user_id'] ?? null;
            $userId = validateUserId($userId);
            $programId = $_GET['program_id'] ?? $input['program_id'] ?? null;
            
            if (!$programId || !is_numeric($programId)) {
                respond(["error" => "Invalid or missing program ID"]);
            }
            
            $programId = intval($programId);
            error_log("Cloning program ID: $programId for user ID: $userId");
            
            // Start transaction
            $pdo->beginTransaction();
            
            try {
                // Get the original program from programhdr
                $getProgramStmt = $pdo->prepare("
                    SELECT * FROM programhdr WHERE id = :program_id
                ");
                $getProgramStmt->bindParam(':program_id', $programId, PDO::PARAM_INT);
                $getProgramStmt->execute();
                $originalProgram = $getProgramStmt->fetch(PDO::FETCH_ASSOC);
                
                if (!$originalProgram) {
                    throw new Exception("Program not found");
                }
                
                error_log("Original program found: " . json_encode($originalProgram));
                
                // Check if this program is already cloned for this user
                error_log("DEBUG: Checking if program_hdr_id=$programId already exists for user_id=$userId");
                
                // Check if there's an existing clone (with or without complete data)
                $checkCloneStmt = $pdo->prepare("
                    SELECT id, program_hdr_id, user_id 
                    FROM member_programhdr 
                    WHERE user_id = :user_id AND program_hdr_id = :program_id
                ");
                $checkCloneStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $checkCloneStmt->bindParam(':program_id', $programId, PDO::PARAM_INT);
                $checkCloneStmt->execute();
                $existingClone = $checkCloneStmt->fetch(PDO::FETCH_ASSOC);
                
                error_log("DEBUG: Duplicate check result: " . json_encode($existingClone));
                
                if ($existingClone) {
                    error_log("DEBUG: Program already exists as member_programhdr ID: {$existingClone['id']}");
                    $pdo->rollBack();
                    respond([
                        "error" => "You already have this program in your library", 
                        "already_exists" => true,
                        "debug_info" => $existingClone
                    ]);
                }
                
                error_log("DEBUG: No existing clone found, proceeding with clone");
                
                // Delete any incomplete clones (without workouts) before cloning
                $deleteIncompleteStmt = $pdo->prepare("
                    DELETE FROM member_programhdr 
                    WHERE user_id = :user_id AND program_hdr_id = :program_id
                    AND NOT EXISTS (
                        SELECT 1 FROM member_program_workout WHERE member_program_hdr_id = member_programhdr.id
                    )
                ");
                $deleteIncompleteStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
                $deleteIncompleteStmt->bindParam(':program_id', $programId, PDO::PARAM_INT);
                $deleteIncompleteStmt->execute();
                $deletedCount = $deleteIncompleteStmt->rowCount();
                if ($deletedCount > 0) {
                    error_log("Deleted $deletedCount incomplete clone(s)");
                }
                
                // Insert into member_programhdr
                // IMPORTANT: Set program_hdr_id to track which template was cloned
                $insertStmt = $pdo->prepare("
                    INSERT INTO member_programhdr (
                        user_id, program_hdr_id, created_by, color, tags, goal, notes, 
                        completion_rate, scheduled_days, difficulty, total_sessions
                    ) VALUES (
                        :user_id, :program_hdr_id, :created_by, :color, :tags, :goal, :notes,
                        :completion_rate, :scheduled_days, :difficulty, :total_sessions
                    )
                ");
                
                // Extract name from programhdr for the goal field
                $programName = $originalProgram['header_name'] ?? $originalProgram['name'] ?? 'Workout Program';
                
                $insertStmt->execute([
                    ':user_id' => $userId,
                    ':program_hdr_id' => $programId, // Set to track which template was cloned (prevents duplicates)
                    ':created_by' => $originalProgram['created_by'] ?? 0,
                    ':color' => $originalProgram['color'] ?? '0xFF96CEB4',
                    ':tags' => $originalProgram['tags'] ?? '[]',
                    ':goal' => '', // Leave goal empty - program name comes from workout_details
                    ':notes' => $originalProgram['notes'] ?? '',
                    ':completion_rate' => 0,
                    ':scheduled_days' => json_encode([]),
                    ':difficulty' => $originalProgram['difficulty'] ?? 'Beginner',
                    ':total_sessions' => 0
                ]);
                
                $newMemberProgramId = $pdo->lastInsertId();
                error_log("Created member_programhdr with ID: $newMemberProgramId");
                
                // Get workouts from program_workout
                $getWorkoutsStmt = $pdo->prepare("
                    SELECT * FROM program_workout WHERE program_hdr_id = :program_id
                ");
                $getWorkoutsStmt->bindParam(':program_id', $programId, PDO::PARAM_INT);
                $getWorkoutsStmt->execute();
                $workouts = $getWorkoutsStmt->fetchAll(PDO::FETCH_ASSOC);
                
                error_log("Found " . count($workouts) . " workouts to clone");
                
                // If no workouts found, create a default one
                if (count($workouts) == 0) {
                    error_log("No workouts found, creating default workout");
                    $workouts = [[
                        'workout_details' => json_encode([
                            'name' => $programName,
                            'duration' => $originalProgram['duration'] ?? '30-45 min',
                            'created_at' => date('Y-m-d H:i:s')
                        ])
                    ]];
                }
                
                foreach ($workouts as $workout) {
                    // Insert into member_program_workout
                    $insertWorkoutStmt = $pdo->prepare("
                        INSERT INTO member_program_workout (member_program_hdr_id, workout_details)
                        VALUES (:member_program_hdr_id, :workout_details)
                    ");
                    $insertWorkoutStmt->execute([
                        ':member_program_hdr_id' => $newMemberProgramId,
                        ':workout_details' => $workout['workout_details']
                    ]);
                    
                    $newWorkoutId = $pdo->lastInsertId();
                    error_log("Created member_program_workout with ID: $newWorkoutId");
                    
                    // Get exercises from program_workout_exercise
                    $getExercisesStmt = $pdo->prepare("
                        SELECT * FROM program_workout_exercise WHERE program_workout_id = :program_workout_id
                    ");
                    $getExercisesStmt->bindParam(':program_workout_id', $workout['id'], PDO::PARAM_INT);
                    $getExercisesStmt->execute();
                    $exercises = $getExercisesStmt->fetchAll(PDO::FETCH_ASSOC);
                    
                    error_log("Found " . count($exercises) . " exercises to clone for workout ID: {$workout['id']}");
                    
                    // Check what columns exist in member_workout_exercise table
                    $columnCheckStmt = $pdo->prepare("SHOW COLUMNS FROM member_workout_exercise");
                    $columnCheckStmt->execute();
                    $columns = $columnCheckStmt->fetchAll(PDO::FETCH_COLUMN);
                    error_log("DEBUG - member_workout_exercise columns: " . json_encode($columns));
                    
                    foreach ($exercises as $exercise) {
                        // Build INSERT statement based on available columns
                        $insertData = [];
                        $insertFields = [];
                        $insertValues = [];
                        
                        if (in_array('member_program_workout_id', $columns)) {
                            $insertFields[] = 'member_program_workout_id';
                            $insertValues[] = '?';
                            $insertData[] = $newWorkoutId;
                        }
                        
                        if (in_array('exercise_id', $columns)) {
                            $insertFields[] = 'exercise_id';
                            $insertValues[] = '?';
                            $insertData[] = $exercise['exercise_id'];
                        }
                        
                        if (in_array('sets', $columns)) {
                            $insertFields[] = 'sets';
                            $insertValues[] = '?';
                            $insertData[] = $exercise['sets'] ?? 3;
                        }
                        
                        if (in_array('reps', $columns)) {
                            $insertFields[] = 'reps';
                            $insertValues[] = '?';
                            $insertData[] = $exercise['reps'] ?? 10;
                        }
                        
                        if (in_array('weight', $columns)) {
                            $insertFields[] = 'weight';
                            $insertValues[] = '?';
                            $insertData[] = $exercise['weight'] ?? 0.0;
                        }
                        
                        if (in_array('rest_time', $columns)) {
                            $insertFields[] = 'rest_time';
                            $insertValues[] = '?';
                            // Default to 60 seconds (1 minute) if no rest_time specified
                            $insertData[] = $exercise['rest_time'] ?? 60;
                        }
                        
                        if (in_array('notes', $columns)) {
                            $insertFields[] = 'notes';
                            $insertValues[] = '?';
                            $insertData[] = $exercise['notes'] ?? '';
                        }
                        
                        if (!empty($insertFields)) {
                            $insertSql = "INSERT INTO member_workout_exercise (" . implode(', ', $insertFields) . ") VALUES (" . implode(', ', $insertValues) . ")";
                            $insertExerciseStmt = $pdo->prepare($insertSql);
                            $insertExerciseStmt->execute($insertData);
                            error_log("Cloned exercise ID: {$exercise['exercise_id']}");
                        }
                    }
                }
                
                // Commit transaction
                $pdo->commit();
                
                respond([
                    "success" => true,
                    "message" => "Program added to your library successfully",
                    "member_program_hdr_id" => $newMemberProgramId,
                    "cloned_from_program_id" => $programId,
                    "note" => "If this shows duplicate error, delete member_programhdr record with program_hdr_id=$programId"
                ]);
                
            } catch (Exception $e) {
                $pdo->rollBack();
                error_log("Error cloning program: " . $e->getMessage());
                throw $e;
            }
            
        } catch (PDOException $e) {
            error_log("Database error in clone_program: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        } catch (Exception $e) {
            error_log("Error in clone_program: " . $e->getMessage());
            respond(["error" => $e->getMessage()]);
        }
        break;

    default:
        respond(["error" => "Invalid action: " . $action]);
}
?>