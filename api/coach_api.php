<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, Origin");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Max-Age: 86400");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// === DB CONNECTION ===
try {
    $pdo = new PDO("mysql:host=localhost;dbname=u773938685_cnergydb", "u773938685_archh29", "Gwapoko385@");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    // IMPORTANT: Set this to return integers as integers, not strings
    $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
    $pdo->setAttribute(PDO::ATTR_STRINGIFY_FETCHES, false);
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $e->getMessage()
    ]);
    exit;
}

// === HELPER FUNCTIONS ===
function castMemberData($data)
{
    // Cast integer fields
    $intFields = [
        'id',
        'gender_id',
        'coach_id',
        'member_id',
        'request_id',
        'handled_by_coach',
        'handled_by_staff',
        'user_type_id',
        'remaining_sessions'
    ];

    foreach ($intFields as $field) {
        if (isset($data[$field]) && $data[$field] !== null) {
            $data[$field] = (int) $data[$field];
        }
    }

    // Ensure string fields are properly handled
    $stringFields = [
        'fname',
        'mname',
        'lname',
        'email',
        'coach_approval',
        'staff_approval',
        'status',
        'membership_type',
        'rate_type',
        'expires_at'
    ];

    foreach ($stringFields as $field) {
        if (isset($data[$field]) && $data[$field] !== null) {
            $data[$field] = (string) $data[$field];
        }
    }

    // Handle date fields
    $dateFields = [
        'bday',
        'created_at',
        'join_date',
        'requested_at',
        'coach_approved_at',
        'staff_approved_at'
    ];

    foreach ($dateFields as $field) {
        if (isset($data[$field]) && $data[$field] !== null) {
            $data[$field] = (string) $data[$field];
        }
    }

    return $data;
}

// === ROUTER ===
$method = $_SERVER['REQUEST_METHOD'];

// Get action from GET or POST body
$action = $_GET['action'] ?? '';
if (empty($action) && $method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $input['action'] ?? '';
}

// Add debug logging
error_log("Coach API - Action: '$action', Method: '$method', Coach ID: " . ($_GET['coach_id'] ?? 'not set'));

switch ($action) {
    case 'coaches':
        if ($method === 'GET')
            fetchCoaches($pdo);
        break;

    case 'hire-coach':
        if ($method === 'POST')
            hireCoach($pdo);
        break;

    case 'coach-pending-requests':
        if ($method === 'GET' && isset($_GET['coach_id'])) {
            getCoachPendingRequests($pdo, (int) $_GET['coach_id']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Coach ID required']);
        }
        break;

    case 'coach-assigned-members':
        if ($method === 'GET' && isset($_GET['coach_id'])) {
            getCoachAssignedMembers($pdo, (int) $_GET['coach_id']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Coach ID required']);
        }
        break;

    case 'member-routines':
        if ($method === 'GET' && isset($_GET['member_id'])) {
            getMemberRoutines($pdo, (int) $_GET['member_id'], (int) ($_GET['coach_id'] ?? 0));
        } else {
            echo json_encode(['success' => false, 'message' => 'Member ID required']);
        }
        break;

    case 'coach-created-routines':
        if ($method === 'GET' && isset($_GET['member_id'])) {
            getCoachCreatedRoutines($pdo, (int) $_GET['member_id']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Member ID required']);
        }
        break;

    case 'approve-member-request':
        if ($method === 'POST')
            approveMemberRequest($pdo);
        break;

    case 'approve-member-request-staff':
        if ($method === 'POST')
            approveMemberRequestByStaff($pdo);
        break;

    case 'reject-member-request':
        if ($method === 'POST')
            rejectMemberRequest($pdo);
        break;

    case 'member-request-status':
        if ($method === 'GET' && isset($_GET['member_id'])) {
            getMemberRequestStatus($pdo, (int) $_GET['member_id']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Member ID required']);
        }
        break;

    case 'user-coach-status':
        if ($method === 'GET' && isset($_GET['user_id'])) {
            getUserCoachStatus($pdo, (int) $_GET['user_id']);
        } else {
            echo json_encode(['success' => false, 'message' => 'User ID required']);
        }
        break;

    // Debug endpoint
    case 'debug-coach':
        if ($method === 'GET' && isset($_GET['coach_id'])) {
            debugCoachRequests($pdo, (int) $_GET['coach_id']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Coach ID required for debug']);
        }
        break;


    // Legacy endpoints for backward compatibility
    case 'coach-requests':
        if ($method === 'POST')
            hireCoach($pdo);
        break;

    case 'user-request':
        if ($method === 'GET' && isset($_GET['user_id'])) {
            getUserCoachStatus($pdo, (int) $_GET['user_id']);
        } else {
            echo json_encode(['success' => false, 'message' => 'User ID required']);
        }
        break;

    case 'check-session-availability':
        if ($method === 'GET' && isset($_GET['user_id']) && isset($_GET['coach_id'])) {
            checkSessionAvailability($pdo, (int) $_GET['user_id'], (int) $_GET['coach_id']);
        } else {
            echo json_encode(['success' => false, 'message' => 'User ID and Coach ID required']);
        }
        break;

    case 'deduct-session':
        if ($method === 'POST') {
            deductSession($pdo);
        } else {
            echo json_encode(['success' => false, 'message' => 'POST method required']);
        }
        break;

    case 'get-remaining-sessions':
        if ($method === 'GET' && isset($_GET['user_id']) && isset($_GET['coach_id'])) {
            getRemainingSessions($pdo, (int) $_GET['user_id'], (int) $_GET['coach_id']);
        } else {
            echo json_encode(['success' => false, 'message' => 'User ID and Coach ID required']);
        }
        break;

    case 'get-user-coach-request':
        if ($method === 'GET' && isset($_GET['user_id'])) {
            getUserCoachRequest($pdo, (int) $_GET['user_id']);
        } else {
            echo json_encode(['success' => false, 'message' => 'User ID required']);
        }
        break;

    case 'update-program-order':
        if ($method === 'POST') {
            updateProgramOrder($pdo);
        } else {
            echo json_encode(['success' => false, 'message' => 'POST method required']);
        }
        break;

    case 'getRoutineExercises':
        if ($method === 'GET') {
            getRoutineExercises($pdo);
        } else {
            echo json_encode(['success' => false, 'message' => 'GET method required']);
        }
        break;

    default:
        echo json_encode(['success' => false, 'message' => 'Invalid endpoint']);
        break;
}

// === FUNCTIONS ===
function fetchCoaches($pdo)
{
    try {
        $stmt = $pdo->prepare("
            SELECT 
                u.id AS id,
                CONCAT(u.fname, ' ', u.lname) AS name,
                u.email,
                u.gender_id,
                u.bday,
                u.created_at,
                c.id AS coach_id,
                c.specialty,
                c.bio,
                c.per_session_rate as hourly_rate,
                c.monthly_rate,
                c.session_package_rate,
                c.session_package_count,
                c.rating,
                c.total_clients,
                c.is_available,
                c.experience,
                c.image_url,
                c.certifications
            FROM user u
            INNER JOIN coaches c ON u.id = c.user_id
            WHERE u.user_type_id = 3
            ORDER BY u.id DESC
        ");
        $stmt->execute();
        $coaches = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($coaches as &$coach) {
            // Cast numeric fields
            $coach['id'] = (int) $coach['id'];
            $coach['gender_id'] = (int) $coach['gender_id'];
            $coach['coach_id'] = (int) $coach['coach_id'];
            $coach['total_clients'] = (int) ($coach['total_clients'] ?? 0);
            $coach['rating'] = (float) ($coach['rating'] ?? 0.0);
            $coach['hourly_rate'] = (float) ($coach['hourly_rate'] ?? 0.0);
            $coach['monthly_rate'] = $coach['monthly_rate'] !== null ? (float) $coach['monthly_rate'] : null;
            $coach['session_package_rate'] = $coach['session_package_rate'] !== null ? (float) $coach['session_package_rate'] : null;
            $coach['session_package_count'] = $coach['session_package_count'] !== null ? (int) $coach['session_package_count'] : null;
            $coach['is_available'] = (bool) ($coach['is_available'] ?? true);

            // Handle certifications - convert from string to array if needed
            if (isset($coach['certifications']) && is_string($coach['certifications'])) {
                $coach['certifications'] = json_decode($coach['certifications'], true) ?? ['CPT', 'Fitness Trainer'];
            } else {
                $coach['certifications'] = $coach['certifications'] ?? ['CPT', 'Fitness Trainer'];
            }

            // Ensure required fields have values
            $coach['specialty'] = $coach['specialty'] ?? 'General Fitness';
            $coach['bio'] = $coach['bio'] ?? 'Experienced fitness coach dedicated to helping clients achieve their goals.';
            $coach['experience'] = $coach['experience'] ?? '3+ years';
            $coach['image_url'] = $coach['image_url'] ?? '';
        }

        // Debug logging
        error_log("Fetched coaches with pricing data: " . json_encode($coaches));

        echo json_encode([
            'success' => true,
            'coaches' => $coaches
        ]);
    } catch (PDOException $e) {
        error_log("Error in fetchCoaches: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Error fetching coaches: ' . $e->getMessage()
        ]);
    }
}

function hireCoach($pdo)
{
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        error_log("Coach hire request - Input: " . json_encode($input));

        if (!$input) {
            error_log("Coach hire request - Invalid JSON input");
            echo json_encode([
                'success' => false,
                'message' => 'Invalid JSON input'
            ]);
            return;
        }

        $memberId = isset($input['member_id']) ? (int) $input['member_id'] : (isset($input['user_id']) ? (int) $input['user_id'] : null);
        $coachId = isset($input['coach_id']) ? (int) $input['coach_id'] : null;
        $rateType = $input['rate_type'] ?? 'hourly';
        $rate = isset($input['rate']) ? (float) $input['rate'] : 0.0;
        $sessionCount = isset($input['session_count']) ? (int) $input['session_count'] : null;

        error_log("Coach hire request - Member ID: $memberId, Coach ID: $coachId, Rate Type: $rateType, Rate: $rate, Session Count: $sessionCount");

        if (!$memberId || !$coachId) {
            error_log("Coach hire request - Missing required IDs");
            echo json_encode([
                'success' => false,
                'message' => 'Member ID and Coach ID are required'
            ]);
            return;
        }

        // Verify coach exists
        $coachCheckStmt = $pdo->prepare("
            SELECT id FROM user 
            WHERE id = ? AND user_type_id = 3
        ");
        $coachCheckStmt->execute([$coachId]);
        $coachExists = $coachCheckStmt->fetch();

        if (!$coachExists) {
            error_log("Coach hire request - Coach not found with ID: $coachId");
            echo json_encode([
                'success' => false,
                'message' => 'Coach not found'
            ]);
            return;
        }
        error_log("Coach hire request - Coach verified: " . json_encode($coachExists));

        // Verify member exists
        $memberCheckStmt = $pdo->prepare("
            SELECT id FROM user 
            WHERE id = ? AND user_type_id = 4
        ");
        $memberCheckStmt->execute([$memberId]);
        $member = $memberCheckStmt->fetch();

        if (!$member) {
            error_log("Coach hire request - Member not found with ID: $memberId");
            echo json_encode([
                'success' => false,
                'message' => 'Member not found'
            ]);
            return;
        }
        error_log("Coach hire request - Member verified: " . json_encode($member));

        // Check if member has premium subscription (plan_id = 1)
        $premiumCheckStmt = $pdo->prepare("
            SELECT s.plan_id
            FROM subscription s
            JOIN subscription_status ss ON s.status_id = ss.id
            WHERE s.user_id = ?
              AND ss.status_name = 'approved'
              AND s.start_date <= CURDATE()
              AND s.end_date >= CURDATE()
              AND s.plan_id = 1
        ");
        $premiumCheckStmt->execute([$memberId]);
        $premiumSubscription = $premiumCheckStmt->fetch();

        if (!$premiumSubscription) {
            error_log("Coach hire request - Member does not have premium subscription (plan_id = 1)");
            echo json_encode([
                'success' => false,
                'message' => 'Premium membership required to hire coaches'
            ]);
            return;
        }
        error_log("Coach hire request - Premium subscription verified: " . json_encode($premiumSubscription));

        // Check for existing requests
        $checkStmt = $pdo->prepare("
            SELECT id, status FROM coach_member_list 
            WHERE member_id = ? AND coach_id = ?
            AND status IN ('pending', 'approved')
        ");
        $checkStmt->execute([$memberId, $coachId]);
        $existingRequest = $checkStmt->fetch();

        if ($existingRequest) {
            error_log("Coach hire request - Existing request found: " . json_encode($existingRequest));
            echo json_encode([
                'success' => false,
                'message' => 'You already have a ' . $existingRequest['status'] . ' request with this coach'
            ]);
            return;
        }

        // Calculate expiration based on rate type
        $expiresAt = null;
        $remainingSessions = null;

        switch ($rateType) {
            case 'hourly':
                // Hourly rate - expires in 30 days (no session limit)
                $expiresAt = date('Y-m-d', strtotime('+30 days'));
                $remainingSessions = null;
                break;
            case 'monthly':
                // Monthly package - expires in 1 month (no session limit)
                $expiresAt = date('Y-m-d', strtotime('+1 month'));
                $remainingSessions = null;
                break;
            case 'package':
                // Session package - expires in 3 months and has session limit
                $expiresAt = date('Y-m-d', strtotime('+3 months'));
                $remainingSessions = $sessionCount;
                // Keep rate_type as 'package' for session packages
                break;
            default:
                $expiresAt = date('Y-m-d', strtotime('+30 days'));
                $remainingSessions = null;
                break;
        }

        error_log("Coach hire request - Rate type: $rateType, Expires at: $expiresAt, Remaining sessions: $remainingSessions");

        // Insert new request with appropriate expiration data and new status field
        $stmt = $pdo->prepare("
            INSERT INTO coach_member_list 
            (coach_id, member_id, status, coach_approval, staff_approval, requested_at, expires_at, remaining_sessions, rate_type)
            VALUES (?, ?, 'expired', 'pending', 'pending', NOW(), ?, ?, ?)
        ");

        error_log("Coach hire request - Attempting to insert request for member $memberId and coach $coachId");
        $result = $stmt->execute([$coachId, $memberId, $expiresAt, $remainingSessions, $rateType]);

        if ($result) {
            $requestId = (int) $pdo->lastInsertId();
            error_log("Coach hire request - Successfully inserted with ID: $requestId");

            $packageInfo = '';
            switch ($rateType) {
                case 'hourly':
                    $packageInfo = "Hourly rate (₱{$rate}/hr)";
                    break;
                case 'monthly':
                    $packageInfo = "Monthly package (₱{$rate}/mo)";
                    break;
                case 'package':
                    $packageInfo = "Session package (₱{$rate}/{$sessionCount} sessions)";
                    break;
            }

            echo json_encode([
                'success' => true,
                'message' => 'Coach hire request submitted successfully',
                'request_id' => $requestId,
                'package_info' => $packageInfo,
                'expires_at' => $expiresAt,
                'remaining_sessions' => $remainingSessions,
                'rate_type' => $rateType,
                'rate' => $rate,
                'session_count' => $sessionCount
            ]);
        } else {
            error_log("Coach hire request - Failed to insert request");
            echo json_encode([
                'success' => false,
                'message' => 'Failed to submit coach hire request'
            ]);
        }

    } catch (PDOException $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
}

function getCoachPendingRequests($pdo, $coachId)
{
    try {
        error_log("Getting pending requests for coach ID: $coachId");

        // First verify the coach exists
        $coachVerifyStmt = $pdo->prepare("
            SELECT id, CONCAT(fname, ' ', lname) as coach_name
            FROM user 
            WHERE id = ? AND user_type_id = 3
        ");
        $coachVerifyStmt->execute([$coachId]);
        $coachExists = $coachVerifyStmt->fetch();

        if (!$coachExists) {
            error_log("Coach not found with ID: $coachId");
            echo json_encode([
                'success' => false,
                'message' => 'Coach not found'
            ]);
            return;
        }

        error_log("Coach verified: " . json_encode($coachExists));

        // Get pending requests for this coach
        $stmt = $pdo->prepare("
            SELECT 
                cml.id as request_id,
                cml.status,
                cml.coach_approval,
                cml.staff_approval,
                cml.requested_at,
                u.id,
                u.fname,
                u.mname,
                u.lname,
                u.email,
                u.bday,
                u.created_at as join_date,
                'Basic' as membership_type,
                'Active' as status
            FROM coach_member_list cml
            JOIN user u ON cml.member_id = u.id
            WHERE cml.coach_id = ? 
            AND cml.coach_approval = 'pending'
            ORDER BY cml.requested_at DESC
        ");
        $stmt->execute([$coachId]);
        $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);

        error_log("Found " . count($requests) . " pending requests for coach $coachId");
        error_log("Raw requests data: " . json_encode($requests));

        // FIXED: Properly cast the data types
        foreach ($requests as &$request) {
            $request = castMemberData($request);
            $request['coach_id'] = $coachId; // Add coach_id as integer
        }

        echo json_encode([
            'success' => true,
            'requests' => $requests,
            'coach_info' => $coachExists
        ]);
    } catch (PDOException $e) {
        error_log("Error in getCoachPendingRequests: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Error fetching pending requests: ' . $e->getMessage()
        ]);
    }
}

function getCoachAssignedMembers($pdo, $coachId)
{
    try {
        error_log("Getting assigned members for coach ID: $coachId");

        $stmt = $pdo->prepare("
            SELECT 
                cml.id as request_id,
                cml.status,
                cml.coach_approval,
                cml.staff_approval,
                cml.requested_at,
                cml.coach_approved_at,
                cml.staff_approved_at,
                cml.expires_at,
                cml.remaining_sessions,
                cml.rate_type,
                u.id,
                u.fname,
                u.mname,
                u.lname,
                u.email,
                u.bday,
                u.created_at as join_date,
                'Basic' as membership_type
            FROM coach_member_list cml
            JOIN user u ON cml.member_id = u.id
            WHERE cml.coach_id = ? 
            AND cml.status = 'active'
            AND cml.coach_approval = 'approved'
            AND cml.staff_approval = 'approved'
            ORDER BY cml.coach_approved_at DESC
        ");
        $stmt->execute([$coachId]);
        $members = $stmt->fetchAll(PDO::FETCH_ASSOC);

        error_log("Found " . count($members) . " assigned members for coach $coachId");

        // FIXED: Properly cast the data types
        foreach ($members as &$member) {
            $member = castMemberData($member);
            $member['coach_id'] = $coachId; // Add coach_id as integer
        }

        echo json_encode([
            'success' => true,
            'members' => $members
        ]);
    } catch (PDOException $e) {
        error_log("Error in getCoachAssignedMembers: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Error fetching assigned members: ' . $e->getMessage()
        ]);
    }
}

function getMemberRoutines($pdo, $memberId, $coachId = 0)
{
    try {
        error_log("Getting routines for member ID: $memberId, coach ID: $coachId");

        $sql = "
            SELECT 
                mph.id as routine_id,
                mpw.workout_details,
                mph.goal,
                mph.notes as description,
                mph.created_by,
                mph.user_id as member_id,
                mph.created_at,
                mph.updated_at,
                mph.color,
                mph.tags,
                mph.completion_rate,
                mph.difficulty,
                mph.total_sessions,
                'coach' as created_by_type,
                CONCAT(u.fname, ' ', u.lname) as creator_name,
                COALESCE(exercise_count.total_exercises, 0) as exercises
            FROM member_programhdr mph
            LEFT JOIN user u ON mph.created_by = u.id
            LEFT JOIN member_program_workout mpw ON mph.id = mpw.member_program_hdr_id
            LEFT JOIN (
                SELECT 
                    mpw_inner.member_program_hdr_id,
                    COUNT(mwe.id) as total_exercises
                FROM member_program_workout mpw_inner
                LEFT JOIN member_workout_exercise mwe ON mpw_inner.id = mwe.member_program_workout_id
                GROUP BY mpw_inner.member_program_hdr_id
            ) exercise_count ON mph.id = exercise_count.member_program_hdr_id
            WHERE mph.user_id = ? AND mph.created_by = ?
            ORDER BY mph.created_at DESC
        ";

        $params = [$memberId, $coachId];

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $routines = $stmt->fetchAll(PDO::FETCH_ASSOC);

        error_log("Found " . count($routines) . " coach-created routines for member $memberId");

        // Cast data types properly
        foreach ($routines as &$routine) {
            $routine['routine_id'] = (int) $routine['routine_id'];
            $routine['created_by'] = (int) $routine['created_by'];
            $routine['member_id'] = (int) $routine['member_id'];
            $routine['exercises'] = (int) ($routine['exercises'] ?? 0);

            $routineName = 'Untitled Routine';
            $duration = '30';

            if (!empty($routine['workout_details'])) {
                $workoutDetails = json_decode($routine['workout_details'], true);
                if (json_last_error() === JSON_ERROR_NONE && is_array($workoutDetails)) {
                    $routineName = $workoutDetails['name'] ?? $routine['goal'] ?? 'Untitled Routine';
                    $duration = $workoutDetails['duration'] ?? '30';
                    $routine['workout_details'] = $workoutDetails;
                } else {
                    $routine['workout_details'] = null;
                }
            } else {
                $routine['workout_details'] = null;
            }

            $routine['routine_name'] = (string) $routineName;
            $routine['duration'] = (string) $duration;
            $routine['goal'] = (string) ($routine['goal'] ?? '');
            $routine['description'] = (string) ($routine['description'] ?? '');
            $routine['created_by_type'] = (string) $routine['created_by_type'];
            $routine['creator_name'] = (string) $routine['creator_name'] ?? 'Unknown';
            $routine['color'] = (string) $routine['color'] ?? '';
            $routine['completion_rate'] = (int) ($routine['completion_rate'] ?? 0);
            $routine['difficulty'] = (string) $routine['difficulty'] ?? 'Beginner';
            $routine['total_sessions'] = (int) ($routine['total_sessions'] ?? 0);

            // Handle tags JSON
            if (!empty($routine['tags'])) {
                $tags = json_decode($routine['tags'], true);
                if (json_last_error() === JSON_ERROR_NONE && is_array($tags)) {
                    $routine['tags'] = $tags;
                } else {
                    $routine['tags'] = [];
                }
            } else {
                $routine['tags'] = [];
            }
        }

        echo json_encode([
            'success' => true,
            'routines' => $routines,
            'member_id' => $memberId,
            'coach_id' => $coachId
        ]);

    } catch (PDOException $e) {
        error_log("Error in getMemberRoutines: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Error fetching member routines: ' . $e->getMessage()
        ]);
    }
}

function getCoachCreatedRoutines($pdo, $memberId)
{
    try {
        error_log("Getting coach-created routines for member ID: $memberId");

        // First, get all coach-created routines for this member using new status field
        $sql = "
            SELECT 
                mph.id as routine_id,
                mpw.workout_details,
                mph.goal,
                mph.notes as description,
                mph.created_by,
                mph.user_id as member_id,
                mph.created_at,
                mph.updated_at,
                mph.color,
                mph.tags,
                mph.completion_rate,
                mph.difficulty,
                mph.total_sessions,
                CASE 
                    WHEN u.user_type_id = 3 THEN 'coach'
                    WHEN u.user_type_id = 1 THEN 'admin'
                    ELSE 'unknown'
                END as created_by_type,
                CONCAT(u.fname, ' ', u.lname) as creator_name,
                COALESCE(exercise_count.total_exercises, 0) as exercises,
                cml.status,
                cml.coach_approval,
                cml.staff_approval,
                cml.expires_at,
                cml.remaining_sessions,
                cml.rate_type,
                c.session_package_rate,
                c.session_package_count,
                c.monthly_rate
            FROM member_programhdr mph
            LEFT JOIN user u ON mph.created_by = u.id
            LEFT JOIN member_program_workout mpw ON mph.id = mpw.member_program_hdr_id
            LEFT JOIN (
                SELECT 
                    mpw_inner.member_program_hdr_id,
                    COUNT(mwe.id) as total_exercises
                FROM member_program_workout mpw_inner
                LEFT JOIN member_workout_exercise mwe ON mpw_inner.id = mwe.member_program_workout_id
                GROUP BY mpw_inner.member_program_hdr_id
            ) exercise_count ON mph.id = exercise_count.member_program_hdr_id
            LEFT JOIN coach_member_list cml ON mph.created_by = cml.coach_id AND cml.member_id = mph.user_id
            LEFT JOIN coaches c ON mph.created_by = c.user_id
            WHERE mph.user_id = ? 
            AND mph.created_by IS NOT NULL 
            AND mph.created_by != mph.user_id
            AND u.user_type_id IN (1, 3)
            ORDER BY mph.created_at ASC
        ";

        $stmt = $pdo->prepare($sql);
        $stmt->execute([$memberId]);
        $allRoutines = $stmt->fetchAll(PDO::FETCH_ASSOC);

        error_log("SQL Query for member $memberId: " . $sql);
        error_log("Found " . count($allRoutines) . " routines, first few created_at values:");
        foreach (array_slice($allRoutines, 0, 3) as $i => $routine) {
            error_log("Routine $i (ID: {$routine['routine_id']}): created_at = {$routine['created_at']}");
        }

        error_log("Found " . count($allRoutines) . " total coach/admin-created routines for member $memberId");

        $accessibleRoutines = [];

        // Filter routines based on coach connection and subscription status using new status field
        foreach ($allRoutines as $routine) {
            $isAccessible = false;
            $accessReason = '';

            // Check if it's an admin-created routine (always accessible)
            if ($routine['created_by_type'] === 'admin') {
                $isAccessible = true;
                $accessReason = 'Admin template routine';
            }
            // Check if it's a coach-created routine
            else if ($routine['created_by_type'] === 'coach') {
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
                error_log("Routine {$routine['routine_id']} is accessible: $accessReason");
            } else {
                error_log("Routine {$routine['routine_id']} is not accessible: $accessReason");
            }
        }

        error_log("Found " . count($accessibleRoutines) . " accessible coach-created routines for member $memberId");

        // Cast data types properly
        foreach ($accessibleRoutines as &$routine) {
            $routine['routine_id'] = (int) $routine['routine_id'];
            $routine['created_by'] = (int) $routine['created_by'];
            $routine['member_id'] = (int) $routine['member_id'];
            $routine['exercises'] = (int) ($routine['exercises'] ?? 0);

            $routineName = 'Untitled Routine';
            $duration = '30';

            if (!empty($routine['workout_details'])) {
                $workoutDetails = json_decode($routine['workout_details'], true);
                if (json_last_error() === JSON_ERROR_NONE && is_array($workoutDetails)) {
                    $routineName = $workoutDetails['name'] ?? $routine['goal'] ?? 'Untitled Routine';
                    $duration = $workoutDetails['duration'] ?? '30';
                    $routine['workout_details'] = $workoutDetails;
                } else {
                    $routine['workout_details'] = null;
                }
            } else {
                $routine['workout_details'] = null;
            }

            $routine['routine_name'] = (string) $routineName;
            $routine['duration'] = (string) $duration;
            $routine['goal'] = (string) ($routine['goal'] ?? '');
            $routine['description'] = (string) ($routine['description'] ?? '');
            $routine['created_by_type'] = (string) $routine['created_by_type'];
            $routine['creator_name'] = (string) $routine['creator_name'] ?? 'Unknown';
            $routine['color'] = (string) $routine['color'] ?? '';
            $routine['completion_rate'] = (int) ($routine['completion_rate'] ?? 0);
            $routine['difficulty'] = (string) $routine['difficulty'] ?? 'Beginner';
            $routine['total_sessions'] = (int) ($routine['total_sessions'] ?? 0);

            // Handle tags JSON
            if (!empty($routine['tags'])) {
                $tags = json_decode($routine['tags'], true);
                if (json_last_error() === JSON_ERROR_NONE && is_array($tags)) {
                    $routine['tags'] = $tags;
                } else {
                    $routine['tags'] = [];
                }
            } else {
                $routine['tags'] = [];
            }
        }

        echo json_encode([
            'success' => true,
            'routines' => $accessibleRoutines,
            'member_id' => $memberId,
            'total_found' => count($allRoutines),
            'accessible_count' => count($accessibleRoutines)
        ]);

    } catch (PDOException $e) {
        error_log("Error in getCoachCreatedRoutines: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Error fetching coach-created routines: ' . $e->getMessage()
        ]);
    }
}

function approveMemberRequest($pdo)
{
    try {
        $input = json_decode(file_get_contents('php://input'), true);

        $requestId = $input['request_id'] ?? null;
        $coachId = $input['coach_id'] ?? null;

        error_log("Approving request - Request ID: $requestId, Coach ID: $coachId");

        if (!$requestId || !$coachId) {
            echo json_encode([
                'success' => false,
                'message' => 'Request ID and Coach ID are required'
            ]);
            return;
        }

        // Update the request and set status to 'active' when both coach and staff approve
        $stmt = $pdo->prepare("
            UPDATE coach_member_list 
            SET coach_approval = 'approved',
                coach_approved_at = NOW(),
                handled_by_coach = ?,
                status = CASE 
                    WHEN staff_approval = 'approved' THEN 'active'
                    ELSE 'expired'
                END
            WHERE id = ? AND coach_id = ? AND coach_approval = 'pending'
        ");

        $result = $stmt->execute([$coachId, $requestId, $coachId]);

        if ($result && $stmt->rowCount() > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'Member request approved successfully'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to approve request or request not found'
            ]);
        }

    } catch (PDOException $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
}

function rejectMemberRequest($pdo)
{
    try {
        $input = json_decode(file_get_contents('php://input'), true);

        $requestId = $input['request_id'] ?? null;
        $coachId = $input['coach_id'] ?? null;
        $reason = $input['reason'] ?? 'Not available';

        if (!$requestId || !$coachId) {
            echo json_encode([
                'success' => false,
                'message' => 'Request ID and Coach ID are required'
            ]);
            return;
        }

        // Update the request and set status to 'disconnected' when rejected
        $stmt = $pdo->prepare("
            UPDATE coach_member_list 
            SET coach_approval = 'rejected',
                status = 'disconnected',
                coach_approved_at = NOW(),
                handled_by_coach = ?
            WHERE id = ? AND coach_id = ? AND coach_approval = 'pending'
        ");

        $result = $stmt->execute([$coachId, $requestId, $coachId]);

        if ($result && $stmt->rowCount() > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'Member request rejected'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to reject request or request not found'
            ]);
        }

    } catch (PDOException $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
}

function approveMemberRequestByStaff($pdo)
{
    try {
        $input = json_decode(file_get_contents('php://input'), true);

        $requestId = $input['request_id'] ?? null;
        $staffId = $input['staff_id'] ?? null;

        error_log("Staff approving request - Request ID: $requestId, Staff ID: $staffId");

        if (!$requestId || !$staffId) {
            echo json_encode([
                'success' => false,
                'message' => 'Request ID and Staff ID are required'
            ]);
            return;
        }

        // Update the request and set status to 'active' when both coach and staff approve
        $stmt = $pdo->prepare("
            UPDATE coach_member_list 
            SET staff_approval = 'approved',
                staff_approved_at = NOW(),
                handled_by_staff = ?,
                status = CASE 
                    WHEN coach_approval = 'approved' THEN 'active'
                    ELSE 'expired'
                END
            WHERE id = ? AND staff_approval = 'pending'
        ");

        $result = $stmt->execute([$staffId, $requestId]);

        if ($result && $stmt->rowCount() > 0) {
            error_log("Staff approved request successfully - Request ID: $requestId");
            echo json_encode([
                'success' => true,
                'message' => 'Request approved by staff successfully'
            ]);
        } else {
            error_log("Failed to approve request by staff - Request ID: $requestId");
            echo json_encode([
                'success' => false,
                'message' => 'Request not found or already processed'
            ]);
        }

    } catch (PDOException $e) {
        error_log("ERROR - Staff approval failed: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Failed to approve request'
        ]);
    }
}

function getMemberRequestStatus($pdo, $memberId)
{
    try {
        // First check if user has premium subscription (plan_id = 1)
        $premiumCheckStmt = $pdo->prepare("
            SELECT s.plan_id
            FROM subscription s
            JOIN subscription_status ss ON s.status_id = ss.id
            WHERE s.user_id = ?
              AND ss.status_name = 'approved'
              AND s.start_date <= CURDATE()
              AND s.end_date >= CURDATE()
              AND s.plan_id = 1
        ");
        $premiumCheckStmt->execute([$memberId]);
        $premiumSubscription = $premiumCheckStmt->fetch();

        if (!$premiumSubscription) {
            echo json_encode([
                'success' => false,
                'message' => 'Premium membership required to access coach features'
            ]);
            return;
        }

        $stmt = $pdo->prepare("
            SELECT 
                cml.*,
                CONCAT(u.fname, ' ', u.lname) AS coach_name,
                COALESCE(c.specialty, 'General Fitness') AS specialty,
                COALESCE(c.per_session_rate, 50.0) AS hourly_rate,
                cml.remaining_sessions,
                cml.rate_type
            FROM coach_member_list cml
            JOIN user u ON cml.coach_id = u.id
            LEFT JOIN coaches c ON u.id = c.user_id
            WHERE cml.member_id = ?
            ORDER BY cml.requested_at DESC
            LIMIT 1
        ");
        $stmt->execute([$memberId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($result) {
            // Cast numeric fields
            $result['id'] = (int) $result['id'];
            $result['coach_id'] = (int) $result['coach_id'];
            $result['member_id'] = (int) $result['member_id'];
            $result['handled_by_coach'] = $result['handled_by_coach'] ? (int) $result['handled_by_coach'] : null;
            $result['handled_by_staff'] = $result['handled_by_staff'] ? (int) $result['handled_by_staff'] : null;
            $result['hourly_rate'] = (float) ($result['hourly_rate'] ?? 0);
            $result['remaining_sessions'] = $result['remaining_sessions'] !== null ? (int) $result['remaining_sessions'] : null;
            $result['rate_type'] = $result['rate_type'] ?? 'hourly';
        }

        echo json_encode([
            'success' => true,
            'request' => $result
        ]);
    } catch (PDOException $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Error fetching request status: ' . $e->getMessage()
        ]);
    }
}

function getUserCoachStatus($pdo, $userId)
{
    getMemberRequestStatus($pdo, $userId);
}

// === DEBUG FUNCTION ===
function debugCoachRequests($pdo, $coachId)
{
    try {
        error_log("=== DEBUG: Coach Requests for ID: $coachId ===");

        // Check if coach exists in user table
        $userCheck = $pdo->prepare("SELECT * FROM user WHERE id = ? AND user_type_id = 3");
        $userCheck->execute([$coachId]);
        $user = $userCheck->fetch();
        error_log("User data: " . json_encode($user));

        // Check if coach exists in coaches table
        $coachCheck = $pdo->prepare("SELECT * FROM coaches WHERE user_id = ?");
        $coachCheck->execute([$coachId]);
        $coach = $coachCheck->fetch();
        error_log("Coach data: " . json_encode($coach));

        // Check all requests for this coach
        $allRequests = $pdo->prepare("SELECT * FROM coach_member_list WHERE coach_id = ?");
        $allRequests->execute([$coachId]);
        $requests = $allRequests->fetchAll();
        error_log("All requests for coach $coachId: " . json_encode($requests));

        // Check pending requests specifically
        $pendingRequests = $pdo->prepare("
            SELECT cml.*, u.fname, u.lname 
            FROM coach_member_list cml
            LEFT JOIN user u ON cml.member_id = u.id
            WHERE cml.coach_id = ? AND cml.coach_approval = 'pending'
        ");
        $pendingRequests->execute([$coachId]);
        $pending = $pendingRequests->fetchAll();
        error_log("Pending requests for coach $coachId: " . json_encode($pending));

        // Cast data properly for debug response
        foreach ($requests as &$request) {
            $request = castMemberData($request);
        }
        foreach ($pending as &$pendingRequest) {
            $pendingRequest = castMemberData($pendingRequest);
        }

        // Return debug info
        echo json_encode([
            'success' => true,
            'debug_info' => [
                'coach_id' => (int) $coachId,
                'user_exists' => $user ? true : false,
                'coach_exists' => $coach ? true : false,
                'total_requests' => count($requests),
                'pending_requests' => count($pending),
                'user_data' => $user,
                'coach_data' => $coach,
                'all_requests' => $requests,
                'pending_requests_data' => $pending
            ]
        ]);

    } catch (Exception $e) {
        error_log("Debug error: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Debug error: ' . $e->getMessage()
        ]);
    }
}


// === SESSION TRACKING FUNCTIONS ===

function checkSessionAvailability($pdo, $userId, $coachId)
{
    try {
        error_log("DEBUG - Checking session availability for user $userId and coach $coachId");

        // First, let's check what records exist for this user-coach pair
        $debugStmt = $pdo->prepare("
            SELECT * FROM coach_member_list 
            WHERE member_id = ? AND coach_id = ?
            ORDER BY requested_at DESC
        ");
        $debugStmt->execute([$userId, $coachId]);
        $allRecords = $debugStmt->fetchAll(PDO::FETCH_ASSOC);

        error_log("DEBUG - All records for user $userId and coach $coachId: " . json_encode($allRecords));

        // Also check what records exist for this user with any coach
        $userRecordsStmt = $pdo->prepare("
            SELECT * FROM coach_member_list 
            WHERE member_id = ?
            ORDER BY requested_at DESC
        ");
        $userRecordsStmt->execute([$userId]);
        $userRecords = $userRecordsStmt->fetchAll(PDO::FETCH_ASSOC);
        error_log("DEBUG - All records for user $userId with any coach: " . json_encode($userRecords));

        // Check what records exist for this coach with any user
        $coachRecordsStmt = $pdo->prepare("
            SELECT * FROM coach_member_list 
            WHERE coach_id = ?
            ORDER BY requested_at DESC
        ");
        $coachRecordsStmt->execute([$coachId]);
        $coachRecords = $coachRecordsStmt->fetchAll(PDO::FETCH_ASSOC);
        error_log("DEBUG - All records for coach $coachId with any user: " . json_encode($coachRecords));

        // Get the active subscription between user and coach with coach session package info
        // Check based on new status field being 'active' and approvals being 'approved'
        $stmt = $pdo->prepare("
            SELECT 
                cml.id,
                cml.status,
                cml.coach_approval,
                cml.staff_approval,
                cml.expires_at,
                cml.requested_at,
                cml.remaining_sessions,
                cml.rate_type,
                c.session_package_rate,
                c.session_package_count,
                c.monthly_rate
            FROM coach_member_list cml
            LEFT JOIN coaches c ON c.user_id = cml.coach_id
            WHERE cml.member_id = ? 
            AND cml.coach_id = ? 
            AND cml.status = 'active'
            AND cml.coach_approval = 'approved'
            AND cml.staff_approval = 'approved'
            ORDER BY cml.requested_at DESC
            LIMIT 1
        ");
        $stmt->execute([$userId, $coachId]);
        $subscription = $stmt->fetch(PDO::FETCH_ASSOC);

        error_log("DEBUG - Found subscription: " . json_encode($subscription));

        // If no approved subscription found, try to find any subscription with any approval status
        if (!$subscription) {
            $fallbackStmt = $pdo->prepare("
                SELECT 
                    cml.id,
                    cml.status,
                    cml.coach_approval,
                    cml.staff_approval,
                    cml.expires_at,
                    cml.requested_at,
                    c.session_package_rate,
                    c.session_package_count,
                    c.monthly_rate
                FROM coach_member_list cml
                LEFT JOIN coaches c ON c.user_id = cml.coach_id
                WHERE cml.member_id = ? 
                AND cml.coach_id = ? 
                ORDER BY cml.requested_at DESC
                LIMIT 1
            ");
            $fallbackStmt->execute([$userId, $coachId]);
            $fallbackSubscription = $fallbackStmt->fetch(PDO::FETCH_ASSOC);

            error_log("DEBUG - Fallback subscription (any approval): " . json_encode($fallbackSubscription));

            if ($fallbackSubscription) {
                error_log("DEBUG - Found subscription with coach_approval: " . $fallbackSubscription['coach_approval'] . ", staff_approval: " . $fallbackSubscription['staff_approval']);
                // Use the fallback subscription but note the approval status
                $subscription = $fallbackSubscription;
            }
        }

        if (!$subscription) {
            echo json_encode([
                'success' => true,
                'data' => [
                    'can_start_workout' => false,
                    'reason' => 'No active subscription with this coach',
                    'remaining_sessions' => 0,
                    'subscription_type' => 'none',
                    'expires_at' => null
                ]
            ]);
            return;
        }

        $canStartWorkout = false;
        $reason = '';
        $expiresAt = $subscription['expires_at'];
        $remainingSessions = $subscription['remaining_sessions'];
        $rateType = $subscription['rate_type'] ?? '';
        $sessionPackageRate = $subscription['session_package_rate'];
        $sessionPackageCount = $subscription['session_package_count'];
        $monthlyRate = $subscription['monthly_rate'];

        // Determine subscription type based on rate_type and expiration
        $expirationDate = null;
        if ($expiresAt) {
            $expirationDate = new DateTime($expiresAt);
            $now = new DateTime();
        }

        // Check if subscription is expired
        if ($expirationDate && $now > $expirationDate) {
            $canStartWorkout = false;
            $reason = 'Subscription expired';
            $subscriptionType = 'expired';
            $remainingSessions = 0;
        } else {
            // Subscription is active - determine type based on rate_type
            if ($rateType === 'package' && $remainingSessions && $remainingSessions > 0) {
                // Session package
                $subscriptionType = 'package';
                $canStartWorkout = true;
                if ($expirationDate) {
                    $daysLeft = $now->diff($expirationDate)->days;
                    $reason = "Session package active ($remainingSessions sessions, $daysLeft days left)";
                } else {
                    $reason = "Session package active ($remainingSessions sessions)";
                }
            } elseif ($rateType === 'monthly' || $monthlyRate) {
                // Monthly subscription
                $subscriptionType = 'monthly';
                $remainingSessions = 999; // Unlimited
                $canStartWorkout = true;
                if ($expirationDate) {
                    $daysLeft = $now->diff($expirationDate)->days;
                    $reason = "Monthly subscription active ($daysLeft days left)";
                } else {
                    $reason = "Monthly subscription active";
                }
            } elseif ($rateType === 'hourly') {
                // Hourly rate
                $subscriptionType = 'hourly';
                $remainingSessions = 999; // Unlimited until expiration
                $canStartWorkout = true;
                if ($expirationDate) {
                    $daysLeft = $now->diff($expirationDate)->days;
                    $reason = "Hourly rate active ($daysLeft days left)";
                } else {
                    $reason = "Hourly rate active";
                }
            } else {
                // Default case - assume it's active
                $subscriptionType = 'monthly';
                $canStartWorkout = true;
                $reason = 'Subscription active';
                $remainingSessions = 999;
            }
        }

        echo json_encode([
            'success' => true,
            'data' => [
                'can_start_workout' => $canStartWorkout,
                'reason' => $reason,
                'remaining_sessions' => $remainingSessions,
                'subscription_type' => $subscriptionType,
                'expires_at' => $expiresAt
            ]
        ]);

    } catch (PDOException $e) {
        error_log("ERROR - Session availability check failed: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
}

function deductSession($pdo)
{
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $memberId = $input['member_id'] ?? null;
        $coachId = $input['coach_id'] ?? null;

        if (!$memberId || !$coachId) {
            echo json_encode([
                'success' => false,
                'message' => 'Member ID and Coach ID are required'
            ]);
            return;
        }

        error_log("DEBUG - Deducting session for member $memberId and coach $coachId");

        // Get the active subscription with coach session package info
        // Check based on new status field being 'active' and approvals being 'approved'
        $stmt = $pdo->prepare("
            SELECT 
                cml.id,
                cml.status,
                cml.coach_approval,
                cml.staff_approval,
                cml.expires_at,
                cml.requested_at,
                cml.remaining_sessions,
                cml.rate_type,
                c.session_package_rate,
                c.session_package_count,
                c.monthly_rate
            FROM coach_member_list cml
            LEFT JOIN coaches c ON c.user_id = cml.coach_id
            WHERE cml.member_id = ? 
            AND cml.coach_id = ? 
            AND cml.status = 'active'
            AND cml.coach_approval = 'approved'
            AND cml.staff_approval = 'approved'
            ORDER BY cml.requested_at DESC
            LIMIT 1
        ");
        $stmt->execute([$memberId, $coachId]);
        $subscription = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$subscription) {
            echo json_encode([
                'success' => false,
                'message' => 'No active subscription found'
            ]);
            return;
        }

        $expiresAt = $subscription['expires_at'];
        $remainingSessions = $subscription['remaining_sessions'];
        $rateType = $subscription['rate_type'] ?? '';
        $sessionPackageRate = $subscription['session_package_rate'];
        $sessionPackageCount = $subscription['session_package_count'];
        $monthlyRate = $subscription['monthly_rate'];

        // Check if subscription is expired
        if ($expiresAt) {
            $expirationDate = new DateTime($expiresAt);
            $now = new DateTime();

            if ($now > $expirationDate) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Subscription expired'
                ]);
                return;
            }
        }

        // Determine subscription type and handle session deduction using new rate_type field
        if ($rateType === 'package' && $remainingSessions && $remainingSessions > 0) {
            // Session package - check if we can deduct a session
            // Check if session was already used today (prevent double deduction)
            $today = date('Y-m-d');
            $usageCheckStmt = $pdo->prepare("
                SELECT id FROM coach_session_usage 
                WHERE coach_member_id = ? AND usage_date = ?
            ");
            $usageCheckStmt->execute([$subscription['id'], $today]);

            if ($usageCheckStmt->fetch()) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Session already used today',
                    'remaining_sessions' => $remainingSessions,
                    'already_used_today' => true
                ]);
                return;
            }

            // Deduct 1 session from the remaining_sessions in coach_member_list
            $updateStmt = $pdo->prepare("
                UPDATE coach_member_list 
                SET remaining_sessions = remaining_sessions - 1 
                WHERE id = ? AND remaining_sessions > 0
            ");
            $updateStmt->execute([$subscription['id']]);

            if ($updateStmt->rowCount() > 0) {
                // Record today's usage in the coach_session_usage table
                $usageStmt = $pdo->prepare("
                    INSERT INTO coach_session_usage (coach_member_id, usage_date, created_at)
                    VALUES (?, ?, NOW())
                    ON DUPLICATE KEY UPDATE created_at = NOW()
                ");
                $usageStmt->execute([$subscription['id'], $today]);

                // Get updated remaining sessions
                $remainingStmt = $pdo->prepare("
                    SELECT remaining_sessions FROM coach_member_list WHERE id = ?
                ");
                $remainingStmt->execute([$subscription['id']]);
                $newRemainingSessions = $remainingStmt->fetchColumn();

                // If no sessions left, update status to 'expired'
                if ($newRemainingSessions <= 0) {
                    $statusUpdateStmt = $pdo->prepare("
                        UPDATE coach_member_list 
                        SET status = 'expired' 
                        WHERE id = ?
                    ");
                    $statusUpdateStmt->execute([$subscription['id']]);
                }

                echo json_encode([
                    'success' => true,
                    'message' => 'Session deducted successfully',
                    'remaining_sessions' => (int) $newRemainingSessions,
                    'already_used_today' => false
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'No sessions remaining in package'
                ]);
            }

        } elseif ($rateType === 'monthly' || $monthlyRate) {
            // Monthly subscription - no session deduction needed
            echo json_encode([
                'success' => true,
                'message' => 'Monthly subscription - no session deduction needed',
                'remaining_sessions' => 999
            ]);

        } elseif ($rateType === 'hourly') {
            // Hourly rate - no session deduction needed
            echo json_encode([
                'success' => true,
                'message' => 'Hourly rate - no session deduction needed',
                'remaining_sessions' => 999
            ]);

        } else {
            // Default case - assume it's active
            echo json_encode([
                'success' => true,
                'message' => 'Subscription active - no session deduction needed',
                'remaining_sessions' => 999
            ]);
        }

    } catch (PDOException $e) {
        error_log("ERROR - Session deduction failed: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
}

function getRemainingSessions($pdo, $userId, $coachId)
{
    try {
        error_log("DEBUG - Getting remaining sessions for user $userId and coach $coachId");

        $stmt = $pdo->prepare("
            SELECT 
                cml.status,
                cml.coach_approval,
                cml.staff_approval,
                cml.expires_at,
                cml.remaining_sessions,
                cml.rate_type,
                c.session_package_rate,
                c.session_package_count,
                c.monthly_rate
            FROM coach_member_list cml
            LEFT JOIN coaches c ON c.user_id = cml.coach_id
            WHERE cml.member_id = ? 
            AND cml.coach_id = ? 
            AND cml.status = 'active'
            ORDER BY cml.requested_at DESC
            LIMIT 1
        ");
        $stmt->execute([$userId, $coachId]);
        $subscription = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$subscription) {
            echo json_encode([
                'success' => true,
                'remaining_sessions' => 0
            ]);
            return;
        }

        $expiresAt = $subscription['expires_at'];
        $remainingSessions = $subscription['remaining_sessions'];
        $rateType = $subscription['rate_type'] ?? '';
        $sessionPackageRate = $subscription['session_package_rate'];
        $sessionPackageCount = $subscription['session_package_count'];
        $monthlyRate = $subscription['monthly_rate'];

        // Check if subscription is expired
        if ($expiresAt) {
            $expirationDate = new DateTime($expiresAt);
            $now = new DateTime();

            if ($now > $expirationDate) {
                $remainingSessions = 0; // Expired
            } else {
                // Determine remaining sessions based on rate_type
                if ($rateType === 'package' && $remainingSessions !== null) {
                    $remainingSessions = $remainingSessions; // Use from coach_member_list
                } elseif ($rateType === 'monthly' || $monthlyRate) {
                    $remainingSessions = 999; // Unlimited
                } elseif ($rateType === 'hourly') {
                    $remainingSessions = 999; // Unlimited
                } else {
                    $remainingSessions = 999; // Default unlimited
                }
            }
        } else {
            // No expiration date - determine based on rate_type
            if ($rateType === 'package' && $remainingSessions !== null) {
                $remainingSessions = $remainingSessions; // Use from coach_member_list
            } elseif ($rateType === 'monthly' || $monthlyRate) {
                $remainingSessions = 999; // Unlimited
            } elseif ($rateType === 'hourly') {
                $remainingSessions = 999; // Unlimited
            } else {
                $remainingSessions = 999; // Default unlimited
            }
        }

        echo json_encode([
            'success' => true,
            'remaining_sessions' => $remainingSessions
        ]);

    } catch (PDOException $e) {
        error_log("ERROR - Get remaining sessions failed: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
}

function getUserCoachRequest($pdo, $userId)
{
    try {
        error_log("Getting user coach request for user ID: $userId");

        // Get the latest coach request for this user
        $stmt = $pdo->prepare("
            SELECT 
                cml.id,
                cml.coach_id,
                cml.member_id,
                cml.status,
                cml.coach_approval,
                cml.staff_approval,
                cml.requested_at,
                cml.coach_approved_at,
                cml.staff_approved_at,
                cml.expires_at,
                cml.remaining_sessions,
                cml.rate_type,
                CONCAT(u.fname, ' ', u.lname) AS coach_name,
                COALESCE(c.specialty, 'General Fitness') AS specialty,
                COALESCE(c.per_session_rate, 50.0) AS hourly_rate,
                COALESCE(c.monthly_rate, 0.0) AS monthly_rate,
                COALESCE(c.session_package_rate, 0.0) AS session_package_rate,
                COALESCE(c.session_package_count, 0) AS session_package_count
            FROM coach_member_list cml
            JOIN user u ON cml.coach_id = u.id
            LEFT JOIN coaches c ON u.id = c.user_id
            WHERE cml.member_id = ?
            ORDER BY cml.requested_at DESC
            LIMIT 1
        ");
        $stmt->execute([$userId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($result) {
            // Cast numeric fields to proper types
            $result['id'] = (int) $result['id'];
            $result['coach_id'] = (int) $result['coach_id'];
            $result['member_id'] = (int) $result['member_id'];
            $result['hourly_rate'] = (float) $result['hourly_rate'];
            $result['monthly_rate'] = (float) $result['monthly_rate'];
            $result['session_package_rate'] = (float) $result['session_package_rate'];
            $result['session_package_count'] = (int) $result['session_package_count'];
            $result['remaining_sessions'] = $result['remaining_sessions'] !== null ? (int) $result['remaining_sessions'] : null;

            // Ensure string fields are properly handled
            $result['status'] = (string) $result['status'];
            $result['coach_approval'] = (string) $result['coach_approval'];
            $result['staff_approval'] = (string) $result['staff_approval'];
            $result['coach_name'] = (string) $result['coach_name'];
            $result['specialty'] = (string) $result['specialty'];
            $result['rate_type'] = (string) ($result['rate_type'] ?? 'hourly');

            // Handle date fields
            $result['requested_at'] = $result['requested_at'] ? (string) $result['requested_at'] : null;
            $result['coach_approved_at'] = $result['coach_approved_at'] ? (string) $result['coach_approved_at'] : null;
            $result['staff_approved_at'] = $result['staff_approved_at'] ? (string) $result['staff_approved_at'] : null;
            $result['expires_at'] = $result['expires_at'] ? (string) $result['expires_at'] : null;
        }

        echo json_encode([
            'success' => true,
            'request' => $result
        ]);

    } catch (PDOException $e) {
        error_log("Error in getUserCoachRequest: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Error fetching user coach request: ' . $e->getMessage()
        ]);
    }
}

function updateProgramOrder($pdo)
{
    try {
        $input = json_decode(file_get_contents('php://input'), true);

        $memberId = $input['member_id'] ?? null;
        $orderData = $input['order_data'] ?? [];

        if (!$memberId || empty($orderData)) {
            echo json_encode([
                'success' => false,
                'message' => 'Member ID and order data required'
            ]);
            return;
        }

        error_log("Updating program order for member $memberId with " . count($orderData) . " programs");
        error_log("Order data: " . json_encode($orderData));

        // Start transaction
        $pdo->beginTransaction();

        // Update each program's created_at timestamp to maintain order
        // We'll use created_at field to sort programs (newer = higher priority)
        $stmt = $pdo->prepare("UPDATE member_programhdr SET created_at = DATE_ADD(NOW(), INTERVAL :order SECOND) WHERE id = :routine_id AND user_id = :member_id");

        foreach ($orderData as $item) {
            $routineId = $item['routine_id'] ?? null;
            $order = $item['order'] ?? null;

            if ($routineId && $order) {
                // Set updated_at to current time + order seconds to maintain sequence
                $result = $stmt->execute([
                    ':order' => $order,
                    ':routine_id' => $routineId,
                    ':member_id' => $memberId
                ]);

                $affectedRows = $stmt->rowCount();
                error_log("Updated routine $routineId to order $order for member $memberId - Result: $result, Affected rows: $affectedRows");
            }
        }

        // Commit transaction
        $pdo->commit();

        echo json_encode([
            'success' => true,
            'message' => 'Program order updated successfully'
        ]);

    } catch (PDOException $e) {
        // Rollback transaction on error
        if ($pdo->inTransaction()) {
            $pdo->rollback();
        }

        error_log("Error in updateProgramOrder: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Error updating program order: ' . $e->getMessage()
        ]);
    }
}

function getRoutineExercises($pdo)
{
    try {
        $routineId = $_GET['routine_id'] ?? null;
        $memberId = $_GET['member_id'] ?? null;

        if (!$routineId || !$memberId) {
            echo json_encode(['success' => false, 'message' => 'Routine ID and Member ID are required']);
            return;
        }

        error_log("Getting exercises for routine ID: $routineId, member ID: $memberId");

        // Get exercises for the specific routine with workout details
        $stmt = $pdo->prepare("
            SELECT 
                e.id as exercise_id,
                e.name,
                e.description,
                e.image_url,
                e.video_url,
                mwe.id as member_workout_exercise_id,
                mwe.sets as target_sets,
                mwe.reps as target_reps,
                mwe.weight as target_weight,
                60 as rest_time,
                GROUP_CONCAT(DISTINCT tm.name SEPARATOR ', ') as target_muscle,
                mpw.workout_details
            FROM member_workout_exercise mwe
            JOIN exercise e ON mwe.exercise_id = e.id
            JOIN member_program_workout mpw ON mwe.member_program_workout_id = mpw.id
            JOIN member_programhdr mph ON mpw.member_program_hdr_id = mph.id
            LEFT JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
            LEFT JOIN target_muscle tm ON etm.muscle_id = tm.id
            WHERE mph.id = :routine_id AND mph.user_id = :member_id
            GROUP BY e.id, mwe.id
            ORDER BY mwe.id ASC
        ");

        $stmt->bindParam(':routine_id', $routineId, PDO::PARAM_INT);
        $stmt->bindParam(':member_id', $memberId, PDO::PARAM_INT);
        $stmt->execute();
        $exercises = $stmt->fetchAll(PDO::FETCH_ASSOC);

        error_log("Found " . count($exercises) . " exercises for routine $routineId");

        // Format exercises for Flutter
        $formattedExercises = [];
        foreach ($exercises as $exercise) {
            // Try to get weight from workout_details JSON
            $workoutDetails = json_decode($exercise['workout_details'], true);
            $actualWeight = (float) $exercise['target_weight'];
            
            // If weight is 0, try to get it from workout_details
            if ($actualWeight == 0 && isset($workoutDetails['exercise_set_configs'])) {
                $exerciseId = $exercise['exercise_id'];
                error_log("DEBUG: Looking for weight in workout_details for exercise ID: $exerciseId");
                error_log("DEBUG: workout_details: " . $exercise['workout_details']);
                if (isset($workoutDetails['exercise_set_configs'][$exerciseId])) {
                    $setConfigs = $workoutDetails['exercise_set_configs'][$exerciseId];
                    error_log("DEBUG: Found set configs: " . json_encode($setConfigs));
                    if (!empty($setConfigs) && isset($setConfigs[0]['weight'])) {
                        $actualWeight = (float) $setConfigs[0]['weight'];
                        error_log("DEBUG: Found weight in workout_details: $actualWeight");
                    }
                }
            }
            error_log("DEBUG: Final weight for exercise {$exercise['name']}: $actualWeight");
            
            $formattedExercises[] = [
                'id' => (int) $exercise['exercise_id'],
                'exercise_id' => (int) $exercise['exercise_id'],
                'member_workout_exercise_id' => (int) $exercise['member_workout_exercise_id'],
                'name' => $exercise['name'],
                'description' => $exercise['description'] ?? '',
                'image_url' => $exercise['image_url'] ?? '',
                'video_url' => $exercise['video_url'] ?? '',
                'target_sets' => (int) $exercise['target_sets'],
                'target_reps' => (int) $exercise['target_reps'],
                'target_weight' => $actualWeight,
                'rest_time' => (int) $exercise['rest_time'],
                'target_muscle' => $exercise['target_muscle'] ?? 'General',
                'sets' => [(int) $exercise['target_sets']], // Array format for compatibility
                'reps' => (int) $exercise['target_reps'],
                'weight' => $actualWeight,
                'category' => 'Strength',
                'difficulty' => 'Intermediate',
                'completed_sets' => 0,
                'is_completed' => false,
                'logged_sets' => []
            ];
        }

        echo json_encode([
            'success' => true,
            'data' => [
                'routine_id' => (int) $routineId,
                'exercises' => $formattedExercises
            ]
        ]);

    } catch (PDOException $e) {
        error_log("Error in getRoutineExercises: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Error fetching routine exercises: ' . $e->getMessage()
        ]);
    }
}
?>