<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$servername = "localhost";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database connection failed: ' . $e->getMessage()]);
    exit();
}

// Get authorization header
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;

// Try to get token from Authorization header (Bearer token)
$token = null;
if ($authHeader && preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
    $token = $matches[1];
}

// If no token in header, try to get from query parameter or cookie
if (!$token) {
    $token = $_GET['token'] ?? $_COOKIE['auth_token'] ?? null;
}

// Also check for user_id in query parameters (for admin dashboard)
$userId = $_GET['user_id'] ?? null;

// If we have a user_id, verify it's an admin/staff user
if ($userId) {
    try {
        $stmt = $pdo->prepare("
            SELECT id, email, fname, lname, user_type_id, account_status
            FROM user
            WHERE id = ? AND user_type_id IN (1, 2)
        ");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        
        if ($user) {
            echo json_encode([
                'success' => true,
                'authenticated' => true,
                'user' => [
                    'id' => intval($user['id']),
                    'email' => $user['email'],
                    'fname' => $user['fname'],
                    'lname' => $user['lname'],
                    'full_name' => trim($user['fname'] . ' ' . $user['lname']),
                    'user_type_id' => intval($user['user_type_id']),
                    'user_type' => $user['user_type_id'] == 1 ? 'admin' : ($user['user_type_id'] == 2 ? 'staff' : 'user'),
                    'account_status' => $user['account_status'] ?? 'active',
                ]
            ]);
            exit();
        } else {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'authenticated' => false,
                'error' => 'User not found or not authorized'
            ]);
            exit();
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
        exit();
    }
}

// If we have a token, validate it (simple JWT validation)
// For now, we'll return unauthorized if no user_id is provided
if (!$token && !$userId) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'authenticated' => false,
        'error' => 'No authentication provided. Please provide user_id or token.'
    ]);
    exit();
}

// If token is provided but we don't have user_id, try to decode token
// For a simple implementation, you might store token -> user_id mapping
// For now, return unauthorized
http_response_code(401);
echo json_encode([
    'success' => false,
    'authenticated' => false,
    'error' => 'Invalid or expired token'
]);
exit();
?>


