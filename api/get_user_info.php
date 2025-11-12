<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
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

// Get user_id from query parameters
$userId = $_GET['user_id'] ?? null;

if (!$userId) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'User ID is required']);
    exit();
}

try {
    // Fetch user info
    $stmt = $pdo->prepare("
        SELECT 
            id,
            email,
            fname,
            mname,
            lname,
            user_type_id,
            account_status,
            gender_id,
            bday,
            created_at
        FROM user
        WHERE id = ?
    ");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    
    if (!$user) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'User not found']);
        exit();
    }
    
    // Get user type name
    $userTypeId = intval($user['user_type_id']);
    $userTypeMap = [
        1 => 'admin',
        2 => 'staff',
        3 => 'user',
        4 => 'coach'
    ];
    $userType = $userTypeMap[$userTypeId] ?? 'unknown';
    
    // Format user data
    $userData = [
        'id' => intval($user['id']),
        'email' => $user['email'],
        'fname' => $user['fname'] ?? '',
        'mname' => $user['mname'] ?? '',
        'lname' => $user['lname'] ?? '',
        'full_name' => trim(($user['fname'] ?? '') . ' ' . ($user['mname'] ?? '') . ' ' . ($user['lname'] ?? '')),
        'user_type_id' => $userTypeId,
        'user_type' => $userType,
        'account_status' => $user['account_status'] ?? 'active',
        'gender_id' => $user['gender_id'] ?? null,
        'bday' => $user['bday'] ?? null,
        'created_at' => $user['created_at'] ?? null,
    ];
    
    echo json_encode([
        'success' => true,
        'user' => $userData
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database error: ' . $e->getMessage()]);
    exit();
}
?>


