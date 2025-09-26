<?php
// Complete CORS headers - Fixed for localhost development
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, Origin, X-CSRF-Token, Cache-Control, Pragma");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH");
header("Access-Control-Max-Age: 86400");
header("Access-Control-Allow-Credentials: false");
header("Content-Type: application/json; charset=utf-8");
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

// === DATABASE CONNECTION ===
try {
    $pdo = new PDO("mysql:host=localhost;dbname=u773938685_cnergydb", "u773938685_archh29", "Gwapoko385@");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
    $pdo->setAttribute(PDO::ATTR_STRINGIFY_FETCHES, false);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $e->getMessage()
    ]);
    exit;
}

// === HELPER FUNCTIONS ===
function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function logActivity($pdo, $action, $details, $memberId = null, $coachId = null) {
    try {
        $stmt = $pdo->prepare("
            INSERT INTO admin_activity_log (action, details, member_id, coach_id, created_at) 
            VALUES (?, ?, ?, ?, NOW())
        ");
        $stmt->execute([$action, $details, $memberId, $coachId]);
    } catch (Exception $e) {
        error_log("Failed to log activity: " . $e->getMessage());
    }
}

// === ROUTER ===
$action = $_GET['action'] ?? '';
$method = $_SERVER['REQUEST_METHOD'];

// Add debug logging (to error log only, not response)
error_log("Coach Session Management API - Action: $action, Method: $method");

switch ($action) {
    case 'test':
        sendResponse([
            'success' => true,
            'message' => 'API is working - Fixed member name query',
            'timestamp' => date('Y-m-d H:i:s'),
            'method' => $method,
            'action' => $action,
            'version' => '2.1'
        ]);
        break;
        
    case 'get-session-history':
        if ($method === 'GET' && isset($_GET['member_id'])) {
            getSessionHistory($pdo, (int)$_GET['member_id']);
        } else {
            sendResponse(['success' => false, 'message' => 'Member ID required'], 400);
        }
        break;
        
    case 'undo-session-usage':
        if ($method === 'POST') {
            undoSessionUsage($pdo);
        } else {
            sendResponse(['success' => false, 'message' => 'POST method required'], 405);
        }
        break;
        
    case 'adjust-session-count':
        if ($method === 'POST') {
            adjustSessionCount($pdo);
        } else {
            sendResponse(['success' => false, 'message' => 'POST method required'], 405);
        }
        break;
        
    case 'get-member-session-info':
        if ($method === 'GET' && isset($_GET['member_id'])) {
            getMemberSessionInfo($pdo, (int)$_GET['member_id']);
        } else {
            sendResponse(['success' => false, 'message' => 'Member ID required'], 400);
        }
        break;
        
    case 'add-session-usage':
        if ($method === 'POST') {
            addSessionUsage($pdo);
        } else {
            sendResponse(['success' => false, 'message' => 'POST method required'], 405);
        }
        break;
        
        
    default:
        sendResponse(['success' => false, 'message' => 'Invalid action'], 400);
        break;
}

// === API FUNCTIONS ===

function getSessionHistory($pdo, $memberId) {
    try {
        // First, let's check if the member exists in coach_member_list
        $memberCheckStmt = $pdo->prepare("
            SELECT id, member_id, status, rate_type 
            FROM coach_member_list 
            WHERE member_id = ?
        ");
        $memberCheckStmt->execute([$memberId]);
        $memberData = $memberCheckStmt->fetchAll();
        
        if (empty($memberData)) {
            sendResponse([
                'success' => true,
                'data' => [
                    'history' => [],
                    'current_info' => null,
                    'message' => 'No coach subscription found for this member'
                ]
            ]);
            return;
        }
        
        // Get session usage history for the member
        $stmt = $pdo->prepare("
            SELECT 
                csu.id,
                csu.usage_date,
                csu.created_at,
                cml.remaining_sessions,
                cml.rate_type,
                cml.status as subscription_status,
                CONCAT(u.fname, ' ', u.lname) as member_name,
                u.id as member_id
            FROM coach_session_usage csu
            JOIN coach_member_list cml ON csu.coach_member_id = cml.id
            LEFT JOIN user u ON cml.member_id = u.id
            WHERE cml.member_id = ?
            ORDER BY csu.usage_date DESC, csu.created_at DESC
        ");
        $stmt->execute([$memberId]);
        $history = $stmt->fetchAll();
        
        // Get current session info
        $currentStmt = $pdo->prepare("
            SELECT 
                cml.id,
                cml.remaining_sessions,
                cml.rate_type,
                cml.status,
                cml.expires_at,
                cml.requested_at,
                cml.coach_approval,
                cml.staff_approval
            FROM coach_member_list cml
            WHERE cml.member_id = ? 
            AND cml.status = 'active' 
            AND cml.rate_type = 'package'
            ORDER BY cml.requested_at DESC 
            LIMIT 1
        ");
        $currentStmt->execute([$memberId]);
        $currentInfo = $currentStmt->fetch();
        
        sendResponse([
            'success' => true,
            'data' => [
                'history' => $history,
                'current_info' => $currentInfo
            ]
        ]);
        
    } catch (PDOException $e) {
        error_log("ERROR - Get session history failed: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ], 500);
    } catch (Exception $e) {
        error_log("ERROR - General error: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ], 500);
    }
}

function undoSessionUsage($pdo) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $usageId = $input['usage_id'] ?? null;
        $memberId = $input['member_id'] ?? null;
        
        if (!$usageId || !$memberId) {
            sendResponse([
                'success' => false,
                'message' => 'Usage ID and Member ID are required'
            ], 400);
        }
        
        
        // Start transaction
        $pdo->beginTransaction();
        
        // Check if usage record exists and get coach_member_id
        $checkStmt = $pdo->prepare("
            SELECT csu.id, cml.id as coach_member_id, cml.remaining_sessions, cml.member_id, cml.coach_id
            FROM coach_session_usage csu
            JOIN coach_member_list cml ON csu.coach_member_id = cml.id
            WHERE csu.id = ? AND cml.member_id = ?
        ");
        $checkStmt->execute([$usageId, $memberId]);
        $usage = $checkStmt->fetch();
        
        if (!$usage) {
            $pdo->rollBack();
            sendResponse([
                'success' => false,
                'message' => 'Session usage record not found'
            ], 404);
        }
        
        // Delete the usage record (simple undo approach)
        $deleteStmt = $pdo->prepare("
            DELETE FROM coach_session_usage 
            WHERE id = ?
        ");
        $deleteStmt->execute([$usageId]);
        
        // Add 1 session back to the member's package
        $addSessionStmt = $pdo->prepare("
            UPDATE coach_member_list 
            SET remaining_sessions = remaining_sessions + 1,
                status = CASE 
                    WHEN remaining_sessions + 1 > 0 AND status = 'expired' THEN 'active'
                    ELSE status 
                END
            WHERE id = ?
        ");
        $addSessionStmt->execute([$usage['coach_member_id']]);
        
        // Log the activity
        logActivity($pdo, 'session_undone', "Undid session usage ID: $usageId", $memberId, $usage['coach_id']);
        
        // Commit transaction
        $pdo->commit();
        
        sendResponse([
            'success' => true,
            'message' => 'Session usage undone successfully'
        ]);
        
    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("ERROR - Undo session usage failed: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ], 500);
    }
}

function adjustSessionCount($pdo) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $memberId = $input['member_id'] ?? null;
        $adjustment = $input['adjustment'] ?? null;
        $reason = $input['reason'] ?? 'Manual adjustment by coach';
        
        if (!$memberId || $adjustment === null) {
            sendResponse([
                'success' => false,
                'message' => 'Member ID and adjustment amount are required'
            ], 400);
        }
        
        
        // Start transaction
        $pdo->beginTransaction();
        
        // Get the active coach subscription for the member
        $stmt = $pdo->prepare("
            SELECT id, remaining_sessions, rate_type, status, coach_id
            FROM coach_member_list 
            WHERE member_id = ? 
            AND status = 'active' 
            AND rate_type = 'package'
            ORDER BY requested_at DESC 
            LIMIT 1
        ");
        $stmt->execute([$memberId]);
        $subscription = $stmt->fetch();
        
        if (!$subscription) {
            $pdo->rollBack();
            sendResponse([
                'success' => false,
                'message' => 'No active session package found for this member'
            ], 404);
        }
        
        // Calculate new session count
        $newSessionCount = $subscription['remaining_sessions'] + $adjustment;
        
        // Ensure session count doesn't go below 0
        if ($newSessionCount < 0) {
            $pdo->rollBack();
            sendResponse([
                'success' => false,
                'message' => 'Cannot reduce sessions below 0. Current sessions: ' . $subscription['remaining_sessions']
            ], 400);
        }
        
        // Update the session count
        $updateStmt = $pdo->prepare("
            UPDATE coach_member_list 
            SET remaining_sessions = ?,
                status = CASE 
                    WHEN ? > 0 AND status = 'expired' THEN 'active'
                    WHEN ? = 0 AND status = 'active' THEN 'expired'
                    ELSE status 
                END
            WHERE id = ?
        ");
        $updateStmt->execute([$newSessionCount, $newSessionCount, $newSessionCount, $subscription['id']]);
        
        // Log the activity
        logActivity($pdo, 'session_adjusted', "Adjusted sessions by $adjustment. Reason: $reason", $memberId, $subscription['coach_id']);
        
        // Commit transaction
        $pdo->commit();
        
        sendResponse([
            'success' => true,
            'message' => 'Session count adjusted successfully',
            'data' => [
                'new_session_count' => $newSessionCount,
                'adjustment' => $adjustment,
                'previous_count' => $subscription['remaining_sessions']
            ]
        ]);
        
    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("ERROR - Adjust session count failed: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ], 500);
    }
}

function getMemberSessionInfo($pdo, $memberId) {
    try {
        
        // Get current session package info
        $stmt = $pdo->prepare("
            SELECT 
                cml.id,
                cml.remaining_sessions,
                cml.rate_type,
                cml.status,
                cml.expires_at,
                cml.requested_at,
                cml.coach_approval,
                cml.staff_approval,
                cml.monthly_rate,
                cml.session_package_rate,
                c.name as coach_name,
                CONCAT(u.fname, ' ', u.lname) as member_name
            FROM coach_member_list cml
            LEFT JOIN coaches c ON cml.coach_id = c.id
            LEFT JOIN user u ON cml.member_id = u.id
            WHERE cml.member_id = ? 
            AND cml.status = 'active' 
            AND cml.rate_type = 'package'
            ORDER BY cml.requested_at DESC 
            LIMIT 1
        ");
        $stmt->execute([$memberId]);
        $sessionInfo = $stmt->fetch();
        
        if (!$sessionInfo) {
            sendResponse([
                'success' => false,
                'message' => 'No active session package found for this member'
            ], 404);
        }
        
        // Get usage statistics
        $statsStmt = $pdo->prepare("
            SELECT 
                COUNT(*) as total_usage,
                COUNT(CASE WHEN undone_at IS NULL THEN 1 END) as active_usage,
                COUNT(CASE WHEN undone_at IS NOT NULL THEN 1 END) as undone_usage
            FROM coach_session_usage csu
            JOIN coach_member_list cml ON csu.coach_member_id = cml.id
            WHERE cml.member_id = ?
        ");
        $statsStmt->execute([$memberId]);
        $stats = $statsStmt->fetch();
        
        sendResponse([
            'success' => true,
            'data' => [
                'session_info' => $sessionInfo,
                'usage_stats' => $stats
            ]
        ]);
        
    } catch (PDOException $e) {
        error_log("ERROR - Get member session info failed: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ], 500);
    }
}

function addSessionUsage($pdo) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $memberId = $input['member_id'] ?? null;
        $coachId = $input['coach_id'] ?? null;
        $usageDate = $input['usage_date'] ?? date('Y-m-d');
        $reason = $input['reason'] ?? 'Manual session usage by coach';
        
        if (!$memberId || !$coachId) {
            sendResponse([
                'success' => false,
                'message' => 'Member ID and Coach ID are required'
            ], 400);
        }
        
        
        // Start transaction
        $pdo->beginTransaction();
        
        // Get the active coach subscription
        $stmt = $pdo->prepare("
            SELECT id, remaining_sessions, status
            FROM coach_member_list 
            WHERE member_id = ? 
            AND coach_id = ?
            AND status = 'active' 
            AND rate_type = 'package'
            ORDER BY requested_at DESC 
            LIMIT 1
        ");
        $stmt->execute([$memberId, $coachId]);
        $subscription = $stmt->fetch();
        
        if (!$subscription) {
            $pdo->rollBack();
            sendResponse([
                'success' => false,
                'message' => 'No active session package found for this member-coach pair'
            ], 404);
        }
        
        if ($subscription['remaining_sessions'] <= 0) {
            $pdo->rollBack();
            sendResponse([
                'success' => false,
                'message' => 'No sessions remaining in package'
            ], 400);
        }
        
        // Check if session was already used on this date
        $checkStmt = $pdo->prepare("
            SELECT id FROM coach_session_usage 
            WHERE coach_member_id = ? AND usage_date = ? AND undone_at IS NULL
        ");
        $checkStmt->execute([$subscription['id'], $usageDate]);
        
        if ($checkStmt->fetch()) {
            $pdo->rollBack();
            sendResponse([
                'success' => false,
                'message' => 'Session already used on this date'
            ], 400);
        }
        
        // Deduct 1 session
        $updateStmt = $pdo->prepare("
            UPDATE coach_member_list 
            SET remaining_sessions = remaining_sessions - 1,
                status = CASE 
                    WHEN remaining_sessions - 1 <= 0 THEN 'expired'
                    ELSE status 
                END
            WHERE id = ?
        ");
        $updateStmt->execute([$subscription['id']]);
        
        // Log the usage
        $logStmt = $pdo->prepare("
            INSERT INTO coach_session_usage (coach_member_id, usage_date, created_at, reason)
            VALUES (?, ?, NOW(), ?)
        ");
        $logStmt->execute([$subscription['id'], $usageDate, $reason]);
        
        // Get updated session count
        $remainingStmt = $pdo->prepare("
            SELECT remaining_sessions FROM coach_member_list WHERE id = ?
        ");
        $remainingStmt->execute([$subscription['id']]);
        $newRemainingSessions = $remainingStmt->fetchColumn();
        
        // Log the activity
        logActivity($pdo, 'session_used', "Added session usage. Reason: $reason", $memberId, $coachId);
        
        // Commit transaction
        $pdo->commit();
        
        sendResponse([
            'success' => true,
            'message' => 'Session usage added successfully',
            'data' => [
                'remaining_sessions' => (int)$newRemainingSessions,
                'usage_date' => $usageDate
            ]
        ]);
        
    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("ERROR - Add session usage failed: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ], 500);
    }
}

?>
