<?php
// Admin API to view support requests
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With, Origin");
header("Access-Control-Max-Age: 86400");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Database configuration
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

$action = $_GET['action'] ?? '';

// === GET ALL SUPPORT REQUESTS ===
if ($action === 'get_all' || $action === '') {
    try {
        $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
        $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
        
        $stmt = $pdo->prepare("
            SELECT 
                id,
                user_email,
                subject,
                message,
                source,
                created_at
            FROM support_requests
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
        ");
        
        $stmt->execute([$limit, $offset]);
        $requests = $stmt->fetchAll();
        
        // Get total count
        $countStmt = $pdo->query("SELECT COUNT(*) as total FROM support_requests");
        $total = $countStmt->fetch()['total'];
        
        echo json_encode([
            'success' => true,
            'data' => $requests,
            'total' => (int)$total,
            'limit' => $limit,
            'offset' => $offset
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to fetch support requests',
            'error' => $e->getMessage()
        ]);
    }
    
// === GET SINGLE SUPPORT REQUEST ===
} elseif ($action === 'get_one') {
    $id = $_GET['id'] ?? null;
    
    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'Request ID is required']);
        exit;
    }
    
    try {
        $stmt = $pdo->prepare("
            SELECT 
                id,
                user_email,
                subject,
                message,
                source,
                created_at
            FROM support_requests
            WHERE id = ?
        ");
        
        $stmt->execute([$id]);
        $request = $stmt->fetch();
        
        if ($request) {
            echo json_encode([
                'success' => true,
                'data' => $request
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Support request not found'
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to fetch support request',
            'error' => $e->getMessage()
        ]);
    }
    
// === GET BY EMAIL ===
} elseif ($action === 'get_by_email') {
    $email = $_GET['email'] ?? null;
    
    if (!$email) {
        echo json_encode(['success' => false, 'message' => 'Email is required']);
        exit;
    }
    
    try {
        $stmt = $pdo->prepare("
            SELECT 
                id,
                user_email,
                subject,
                message,
                source,
                created_at
            FROM support_requests
            WHERE user_email = ?
            ORDER BY created_at DESC
        ");
        
        $stmt->execute([$email]);
        $requests = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'data' => $requests
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to fetch support requests',
            'error' => $e->getMessage()
        ]);
    }
    
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid action']);
}
?>





