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
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
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

// Enhanced membership status check function - HARDCODED for ID 1 only
function checkMembershipStatus($pdo, $userId) {
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
                error_log("DEBUG: Checking subscription - Plan ID: {$result['plan_id']}, Is Plan 1: " . ((int)$result['plan_id'] === 1 ? 'YES' : 'NO'));
                if ((int)$result['plan_id'] === 1) {
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
                    $routine['exercises'] = (int)$workoutData['exercise_count'];
                    
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
            
            // Apply membership restriction ONLY to user's own routines
            if (!$isPremium && count($myRoutines) > 1) {
                $myRoutines = array_slice($myRoutines, 0, 1);
                error_log("Limited My Routines to 1 for basic user; coach/template remain unrestricted");
            }
            
            error_log("DEBUG: After membership restriction - myRoutines: " . count($myRoutines) . ", coachAssigned: " . count($coachAssigned) . ", templateRoutines: " . count($templateRoutines));

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
            
            // ONLY get user-created routines (created_by IS NULL) - NO coach logic
            $stmt = $pdo->prepare("SELECT m.id, m.user_id, m.program_hdr_id, m.created_by, CONCAT(u.fname, ' ', u.mname, ' ', u.lname) AS createdByName, u.user_type_id AS createdByTypeId, m.color, m.tags, m.goal, m.notes, m.completion_rate AS completionRate, m.scheduled_days AS scheduledDays, m.difficulty, m.total_sessions AS totalSessions, m.created_at, m.updated_at FROM member_programhdr m LEFT JOIN user u ON u.id = m.created_by WHERE m.user_id = :user_id AND (m.created_by IS NULL OR m.created_by = '') ORDER BY m.created_at DESC");
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
                    $routine['exercises'] = (int)$workoutData['exercise_count'];
                    
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

            // IMPORTANT: This endpoint ONLY returns user-created routines (NO coach logic)
            respond([
                'success' => true,
                'routines' => $processedRoutines,
                'my_routines' => $processedRoutines,
                'coach_assigned' => [], // Empty - coach routines handled separately
                'template_routines' => [], // Empty - template routines handled separately
                'total_routines' => count($processedRoutines),
                'is_premium' => $isPremium,
                'membership_status' => [
                    'is_premium' => $isPremium,
                    'subscription_details' => $membershipData['subscription_details']
                ],
                'debug_info' => $membershipData['debug_info'] ?? null,
                'user_id' => $userId,
                'fetched_at' => date('Y-m-d H:i:s'),
                'note' => 'This endpoint only returns user-created routines. Use coach_routines action for coach routines.'
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
                AND u.user_type_id IN (1, 3)
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
                    $coachId = (int)$routine['created_by'];
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
                    $routine['exercises'] = (int)$workoutData['exercise_count'];
                    
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
                            // Handle individual set configurations
                            if (isset($exercise['sets']) && is_array($exercise['sets'])) {
                                // Process each set individually
                                foreach ($exercise['sets'] as $setIndex => $set) {
                                    $reps = $set['reps'] ?? $exercise['reps'] ?? $exercise['target_reps'] ?? '10';
                                    $weight = $set['weight'] ?? $exercise['weight'] ?? $exercise['target_weight'] ?? 0;
                                    
                                    $exerciseStmt->execute([
                                        $workoutId,
                                        $exerciseId,
                                        is_numeric($reps) ? $reps : 10,
                                        1, // Each set is inserted as a separate row
                                        is_numeric($weight) ? $weight : 0
                                    ]);
                                }
                                error_log("Added " . count($exercise['sets']) . " sets for exercise ID $exerciseId with individual weights");
                            } else {
                                // Fallback to old format
                                $sets = $exercise['target_sets'] ?? 3;
                                $reps = $exercise['target_reps'] ?? '10';
                                $weight = $exercise['target_weight'] ?? 0;
                                
                                $exerciseStmt->execute([
                                    $workoutId,
                                    $exerciseId,
                                    is_numeric($reps) ? $reps : 10,
                                    $sets,
                                    is_numeric($weight) ? $weight : 0
                                ]);
                                error_log("Added exercise ID $exerciseId with fallback format");
                            }
                            
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

            $stmt = $pdo->prepare("DELETE FROM member_programhdr WHERE id = :id AND user_id = :user_id");
            $result = $stmt->execute([
                ':id' => $routineId,
                ':user_id' => $userId
            ]);

            if ($result) {
                respond(["success" => true, "message" => "Routine deleted successfully"]);
            } else {
                respond(["error" => "Failed to delete routine"]);
            }

        } catch (PDOException $e) {
            error_log("Database error in delete: " . $e->getMessage());
            respond(["error" => "Database error: " . $e->getMessage()]);
        }
        break;

    default:
        respond(["error" => "Invalid action: " . $action]);
}
?>
