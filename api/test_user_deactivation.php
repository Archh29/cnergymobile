<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, Origin");
header("Access-Control-Max-Age: 86400");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$host = "localhost";
$db = "u773938685_cnergydb";      
$user = "u773938685_archh29";  
$pass = "Gwapoko385@"; 

$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed', 'error' => $e->getMessage()]);
    exit;
}

$input = json_decode(file_get_contents("php://input"), true);
$action = $_GET['action'] ?? ($input['action'] ?? '');

// === DEACTIVATE USER ===
if ($action === 'deactivate') {
    $user_id = $input['user_id'] ?? null;
    if (!$user_id) {
        echo json_encode(['success' => false, 'message' => 'User ID required']);
        exit;
    }

    try {
        $stmt = $pdo->prepare("UPDATE user SET account_status = 'deactivated' WHERE id = ?");
        $stmt->execute([$user_id]);
        
        echo json_encode(['success' => true, 'message' => 'User account deactivated successfully']);
        exit;
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Database query failed', 'error' => $e->getMessage()]);
        exit;
    }
}

// === REACTIVATE USER ===
if ($action === 'reactivate') {
    $user_id = $input['user_id'] ?? null;
    if (!$user_id) {
        echo json_encode(['success' => false, 'message' => 'User ID required']);
        exit;
    }

    try {
        $stmt = $pdo->prepare("UPDATE user SET account_status = 'approved' WHERE id = ?");
        $stmt->execute([$user_id]);
        
        echo json_encode(['success' => true, 'message' => 'User account reactivated successfully']);
        exit;
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Database query failed', 'error' => $e->getMessage()]);
        exit;
    }
}

// === GET USER STATUS ===
if ($action === 'status') {
    $user_id = $_GET['user_id'] ?? null;
    if (!$user_id) {
        echo json_encode(['success' => false, 'message' => 'User ID required']);
        exit;
    }

    try {
        $stmt = $pdo->prepare("SELECT id, fname, lname, email, account_status FROM user WHERE id = ?");
        $stmt->execute([$user_id]);
        $user = $stmt->fetch();
        
        if (!$user) {
            echo json_encode(['success' => false, 'message' => 'User not found']);
            exit;
        }
        
        echo json_encode(['success' => true, 'data' => $user]);
        exit;
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Database query failed', 'error' => $e->getMessage()]);
        exit;
    }
}

echo json_encode(['success' => false, 'message' => 'Invalid action']);
?>





