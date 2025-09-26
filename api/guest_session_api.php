<?php
// Database configuration
$host = "127.0.0.1:3306";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    error_log('Database connection failed: ' . $e->getMessage());
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'error' => 'Database connection failed. Please check your database configuration.',
        'details' => $e->getMessage()
    ]);
    exit();
}

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $method = $_SERVER['REQUEST_METHOD'];
    
    switch ($method) {
        case 'GET':
            $action = $_GET['action'] ?? '';
            handleGetRequest($pdo, $action);
            break;
        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            $action = $input['action'] ?? '';
            handlePostRequest($pdo, $action, $input);
            break;
        default:
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

function handleGetRequest($pdo, $action) {
    switch ($action) {
        case 'check_status':
            checkGuestSessionStatus($pdo);
            break;
        case 'get_session':
            getGuestSession($pdo);
            break;
        case 'get_all_sessions':
            getAllGuestSessions($pdo);
            break;
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
            break;
    }
}

function handlePostRequest($pdo, $action, $input) {
    // Check if JSON decode was successful
    if (json_last_error() !== JSON_ERROR_NONE) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid JSON: ' . json_last_error_msg()]);
        return;
    }
    
    switch ($action) {
        case 'create_guest_session':
            createGuestSession($pdo, $input);
            break;
        case 'approve_session':
            approveGuestSession($pdo, $input);
            break;
        case 'reject_session':
            rejectGuestSession($pdo, $input);
            break;
        case 'mark_paid':
            markGuestSessionPaid($pdo, $input);
            break;
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
            break;
    }
}

function createGuestSession($pdo, $data) {
    try {
        // Validate input data
        if (!is_array($data)) {
            throw new Exception('Invalid data format');
        }
        
        // Validate required fields
        if (!isset($data['guest_name']) || !isset($data['guest_type']) || !isset($data['amount_paid'])) {
            throw new Exception('Missing required fields: guest_name, guest_type, amount_paid');
        }
        
        $guestName = trim($data['guest_name']);
        $guestType = $data['guest_type'];
        $amountPaid = floatval($data['amount_paid']);
        
        // Validate guest name
        if (empty($guestName)) {
            throw new Exception('Guest name cannot be empty');
        }
        
        // Validate guest type
        $validTypes = ['walkin', 'trial', 'guest'];
        if (!in_array($guestType, $validTypes)) {
            throw new Exception('Invalid guest type. Must be one of: ' . implode(', ', $validTypes));
        }
        
        // Validate amount
        if ($amountPaid < 0) {
            throw new Exception('Amount cannot be negative');
        }
        
        // Generate unique QR token
        $qrToken = generateUniqueQRToken($pdo);
        
        // Calculate valid until (24 hours from now)
        $validUntil = date('Y-m-d H:i:s', strtotime('+24 hours'));
        
        // Insert guest session
        $stmt = $pdo->prepare("
            INSERT INTO guest_session (guest_name, guest_type, amount_paid, qr_token, valid_until, paid, status, created_at)
            VALUES (?, ?, ?, ?, ?, 0, 'pending', NOW())
        ");
        
        $stmt->execute([$guestName, $guestType, $amountPaid, $qrToken, $validUntil]);
        
        $sessionId = $pdo->lastInsertId();
        
        // Get the created session
        $stmt = $pdo->prepare("
            SELECT * FROM guest_session WHERE id = ?
        ");
        $stmt->execute([$sessionId]);
        $session = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Log activity
        logActivity($pdo, null, "Guest session created: $guestName ($guestType) - Amount: ₱$amountPaid");
        
        echo json_encode([
            'success' => true,
            'message' => 'Guest session created successfully',
            'data' => $session
        ]);
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function checkGuestSessionStatus($pdo) {
    try {
        $qrToken = $_GET['qr_token'] ?? '';
        
        if (empty($qrToken)) {
            throw new Exception('QR token is required');
        }
        
        $stmt = $pdo->prepare("
            SELECT * FROM guest_session 
            WHERE qr_token = ? AND valid_until > NOW()
        ");
        $stmt->execute([$qrToken]);
        $session = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$session) {
            echo json_encode([
                'success' => false,
                'message' => 'Session not found or expired'
            ]);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $session
        ]);
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function getGuestSession($pdo) {
    try {
        $sessionId = $_GET['session_id'] ?? '';
        
        // Debug logging
        error_log("getGuestSession called with session_id: $sessionId");
        
        if (empty($sessionId)) {
            throw new Exception('Session ID is required');
        }
        
        // Validate session ID is numeric
        if (!is_numeric($sessionId)) {
            throw new Exception('Session ID must be numeric');
        }
        
        $stmt = $pdo->prepare("
            SELECT * FROM guest_session WHERE id = ?
        ");
        
        if (!$stmt) {
            throw new Exception('Failed to prepare statement: ' . implode(', ', $pdo->errorInfo()));
        }
        
        $result = $stmt->execute([$sessionId]);
        
        if (!$result) {
            throw new Exception('Failed to execute statement: ' . implode(', ', $stmt->errorInfo()));
        }
        
        $session = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$session) {
            echo json_encode([
                'success' => false,
                'message' => 'Session not found'
            ]);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $session
        ]);
        
    } catch (Exception $e) {
        error_log("getGuestSession error: " . $e->getMessage());
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function getAllGuestSessions($pdo) {
    try {
        $stmt = $pdo->prepare("
            SELECT * FROM guest_session 
            ORDER BY created_at DESC
        ");
        $stmt->execute();
        $sessions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $sessions,
            'count' => count($sessions)
        ]);
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function approveGuestSession($pdo, $data) {
    try {
        $sessionId = $data['session_id'] ?? '';
        
        if (empty($sessionId)) {
            throw new Exception('Session ID is required');
        }
        
        $stmt = $pdo->prepare("
            UPDATE guest_session 
            SET status = 'approved' 
            WHERE id = ?
        ");
        $stmt->execute([$sessionId]);
        
        if ($stmt->rowCount() === 0) {
            throw new Exception('Session not found');
        }
        
        // Get updated session
        $stmt = $pdo->prepare("SELECT * FROM guest_session WHERE id = ?");
        $stmt->execute([$sessionId]);
        $session = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Log activity
        logActivity($pdo, null, "Guest session approved: {$session['guest_name']} (ID: $sessionId)");
        
        echo json_encode([
            'success' => true,
            'message' => 'Guest session approved successfully',
            'data' => $session
        ]);
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function rejectGuestSession($pdo, $data) {
    try {
        $sessionId = $data['session_id'] ?? '';
        
        if (empty($sessionId)) {
            throw new Exception('Session ID is required');
        }
        
        $stmt = $pdo->prepare("
            UPDATE guest_session 
            SET status = 'rejected' 
            WHERE id = ?
        ");
        $stmt->execute([$sessionId]);
        
        if ($stmt->rowCount() === 0) {
            throw new Exception('Session not found');
        }
        
        // Get updated session
        $stmt = $pdo->prepare("SELECT * FROM guest_session WHERE id = ?");
        $stmt->execute([$sessionId]);
        $session = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Log activity
        logActivity($pdo, null, "Guest session rejected: {$session['guest_name']} (ID: $sessionId)");
        
        echo json_encode([
            'success' => true,
            'message' => 'Guest session rejected successfully',
            'data' => $session
        ]);
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function markGuestSessionPaid($pdo, $data) {
    try {
        $sessionId = $data['session_id'] ?? '';
        
        if (empty($sessionId)) {
            throw new Exception('Session ID is required');
        }
        
        $stmt = $pdo->prepare("
            UPDATE guest_session 
            SET paid = 1, status = 'approved' 
            WHERE id = ?
        ");
        $stmt->execute([$sessionId]);
        
        if ($stmt->rowCount() === 0) {
            throw new Exception('Session not found');
        }
        
        // Get updated session
        $stmt = $pdo->prepare("SELECT * FROM guest_session WHERE id = ?");
        $stmt->execute([$sessionId]);
        $session = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Log activity
        logActivity($pdo, null, "Guest session payment confirmed: {$session['guest_name']} (ID: $sessionId) - Amount: ₱{$session['amount_paid']}");
        
        echo json_encode([
            'success' => true,
            'message' => 'Payment confirmed successfully',
            'data' => $session
        ]);
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function generateUniqueQRToken($pdo) {
    do {
        $token = 'GUEST_' . strtoupper(substr(md5(uniqid(rand(), true)), 0, 12));
        
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM guest_session WHERE qr_token = ?");
        $stmt->execute([$token]);
        $count = $stmt->fetchColumn();
    } while ($count > 0);
    
    return $token;
}

function logActivity($pdo, $userId, $activity) {
    try {
        $stmt = $pdo->prepare("
            INSERT INTO activity_log (user_id, activity, timestamp)
            VALUES (?, ?, NOW())
        ");
        $stmt->execute([$userId, $activity]);
    } catch (Exception $e) {
        // Log error but don't fail the main operation
        error_log("Failed to log activity: " . $e->getMessage());
    }
}
?>
