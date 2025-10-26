<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, Origin");
header("Access-Control-Max-Age: 86400");

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

// Handle REST API endpoints - try multiple approaches
$request_uri = $_SERVER['REQUEST_URI'];
$path = parse_url($request_uri, PHP_URL_PATH);

// Debug logging
error_log("Request URI: " . $request_uri);
error_log("Parsed Path: " . $path);
error_log("Action before processing: " . $action);

// Method 1: Check if URL contains /users/ pattern
if (preg_match('/\/users\/(\d+)/', $path, $matches)) {
    $user_id = $matches[1];
    error_log("Method 1 - Found user ID in URL: " . $user_id);
    
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $action = 'fetch';
        $_GET['user_id'] = $user_id;
    } elseif ($_SERVER['REQUEST_METHOD'] === 'PUT') {
        $action = 'update';
        $input['id'] = $user_id;
    }
}
// Method 2: Check query parameters for user_id
elseif (isset($_GET['user_id']) && !empty($_GET['user_id'])) {
    error_log("Method 2 - Found user_id in query params: " . $_GET['user_id']);
    $action = 'fetch';
}
// Method 3: Check if action is fetch but no user_id
elseif ($action === 'fetch' && !isset($_GET['user_id'])) {
    error_log("Method 3 - Action is fetch but no user_id found");
    // Try to extract from URL path
    $path_parts = array_filter(explode('/', trim($path, '/')));
    if (count($path_parts) >= 2 && $path_parts[0] === 'users' && is_numeric($path_parts[1])) {
        $_GET['user_id'] = $path_parts[1];
        error_log("Method 3 - Extracted user_id from path: " . $path_parts[1]);
    }
}

error_log("Final action: " . $action);
error_log("Final user_id: " . ($_GET['user_id'] ?? 'not set'));

// === FETCH USER AND PREMIUM STATUS ===
if ($action === 'fetch') {
    $user_id = $_GET['user_id'] ?? null;
    if (!$user_id) {
        echo json_encode(['success' => false, 'message' => 'User ID required']);
        exit;
    }

    try {
        // Fetch user info including account_status - using lowercase table name
        $stmt = $pdo->prepare("SELECT * FROM user WHERE id = ?");
        $stmt->execute([$user_id]);
        $user = $stmt->fetch();

        if (!$user) {
            echo json_encode(['success' => false, 'message' => 'User not found']);
            exit;
        }

        // Check for active approved subscription - using correct table names
        $stmt = $pdo->prepare("
            SELECT 1
            FROM subscription s
            JOIN subscription_status ss ON s.status_id = ss.id
            WHERE s.user_id = ?
              AND ss.status_name = 'approved'
              AND s.start_date <= CURDATE()
              AND s.end_date >= CURDATE()
            ORDER BY s.end_date DESC
            LIMIT 1
        ");
        $stmt->execute([$user_id]);
        $active = $stmt->fetch();

        $user['is_premium'] = $active ? true : false;
        
        // Return data in the format expected by Flutter UserService
        echo json_encode([
            'success' => true, 
            'user' => $user,
            'data' => $user  // Also include as 'data' for compatibility
        ]);
        exit;
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Database query failed', 'error' => $e->getMessage()]);
        exit;
    }
}

// === UPDATE USER ===
if ($action === 'update') {
    $id = $input['id'] ?? null;
    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'User ID is missing']);
        exit;
    }

    try {
        $fields = ['email', 'password', 'user_type_id', 'gender_id', 'fname', 'mname', 'lname', 'bday', 'account_status'];
        $updates = [];
        $params = [];

        foreach ($fields as $field) {
            if (isset($input[$field])) {
                $updates[] = "$field = ?";
                $params[] = $input[$field];
            }
        }

        if (empty($updates)) {
            echo json_encode(['success' => false, 'message' => 'No fields to update']);
            exit;
        }

        $params[] = $id;
        $sql = "UPDATE user SET " . implode(", ", $updates) . " WHERE id = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        echo json_encode(['success' => true, 'message' => 'User updated']);
        exit;
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Update failed', 'error' => $e->getMessage()]);
        exit;
    }
}

// === DELETE USER ===
if ($action === 'delete') {
    $user_id = $input['user_id'] ?? null;
    if (!$user_id) {
        echo json_encode(['success' => false, 'message' => 'User ID required']);
        exit;
    }

    try {
        $stmt = $pdo->prepare("DELETE FROM user WHERE id = ?");
        $stmt->execute([$user_id]);

        echo json_encode(['success' => true, 'message' => 'User deleted']);
        exit;
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Delete failed', 'error' => $e->getMessage()]);
        exit;
    }
}

// === UPLOAD AVATAR ===
if ($action === 'upload_avatar') {
    $user_id = $_POST['user_id'] ?? null;
    if (!$user_id || !isset($_FILES['avatar'])) {
        echo json_encode(['success' => false, 'message' => 'Missing user ID or file']);
        exit;
    }

    try {
        $uploadDir = "uploads/";
        if (!file_exists($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $filename = uniqid("avatar_") . "_" . basename($_FILES["avatar"]["name"]);
        $targetFile = $uploadDir . $filename;

        if (move_uploaded_file($_FILES["avatar"]["tmp_name"], $targetFile)) {
            echo json_encode(['success' => true, 'avatar_url' => $targetFile]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to upload file']);
        }
        exit;
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Upload failed', 'error' => $e->getMessage()]);
        exit;
    }
}

// === INVALID ACTION ===
echo json_encode(['success' => false, 'message' => 'Invalid action']);
?>
