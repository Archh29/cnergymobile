<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');

// Add debugging (remove in production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database connection
$host = "localhost";
$db_name = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? null;

// Extract user_id from GET parameters or POST body
$user_id = null;
if ($method === 'GET') {
    $user_id = $_GET['user_id'] ?? null;
} else if ($method === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);
    $user_id = $input['user_id'] ?? $_GET['user_id'] ?? null;
}

// Function to check if table exists
function tableExists($pdo, $tableName)
{
    try {
        $stmt = $pdo->prepare("SHOW TABLES LIKE ?");
        $stmt->execute([$tableName]);
        return $stmt->rowCount() > 0;
    } catch (PDOException $e) {
        return false;
    }
}

// Function to create table if it doesn't exist
function createTableIfNotExists($pdo)
{
    $sql = "CREATE TABLE IF NOT EXISTS `body_measurements` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `user_id` int(11) NOT NULL,
        `weight` decimal(5,2) DEFAULT NULL COMMENT 'Weight in kg',
        `body_fat_percentage` decimal(4,2) DEFAULT NULL COMMENT 'Body fat percentage',
        `bmi` decimal(4,2) DEFAULT NULL COMMENT 'Body Mass Index',
        `chest_cm` decimal(5,2) DEFAULT NULL COMMENT 'Chest measurement in cm',
        `waist_cm` decimal(5,2) DEFAULT NULL COMMENT 'Waist measurement in cm',
        `hips_cm` decimal(5,2) DEFAULT NULL COMMENT 'Hips measurement in cm',
        `arms_cm` decimal(5,2) DEFAULT NULL COMMENT 'Arms measurement in cm',
        `thighs_cm` decimal(5,2) DEFAULT NULL COMMENT 'Thighs measurement in cm',
        `notes` text DEFAULT NULL COMMENT 'Additional notes',
        `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `user_id` (`user_id`),
        KEY `created_at` (`created_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";

    try {
        $pdo->exec($sql);
        return true;
    } catch (PDOException $e) {
        error_log("Error creating table: " . $e->getMessage());
        return false;
    }
}

switch ($action) {
    case 'get_measurements':
        if ($method === 'GET') {
            if (!$user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }

            try {
                // Create table if it doesn't exist
                createTableIfNotExists($pdo);

                if (!tableExists($pdo, 'body_measurements')) {
                    echo json_encode([]);
                    break;
                }

                $stmt = $pdo->prepare("SELECT
                    id,
                    user_id,
                    weight,
                    body_fat_percentage,
                    bmi,
                    chest_cm,
                    waist_cm,
                    hips_cm,
                    arms_cm,
                    thighs_cm,
                    notes,
                    CONVERT_TZ(created_at, '+00:00', '+08:00') as date_recorded
                FROM body_measurements 
                WHERE user_id = ?
                ORDER BY created_at DESC");
                $stmt->execute([$user_id]);
                $measurements = $stmt->fetchAll(PDO::FETCH_ASSOC);

                // Get user's account creation date and profile weight for reference
                $userStmt = $pdo->prepare("SELECT u.created_at as account_created, mpd.weight_kg as profile_weight 
                    FROM user u 
                    LEFT JOIN member_profile_details mpd ON u.id = mpd.user_id 
                    WHERE u.id = ?");
                $userStmt->execute([$user_id]);
                $userInfo = $userStmt->fetch(PDO::FETCH_ASSOC);

                // If no measurements exist, create a starting weight entry from account creation
                if (empty($measurements) && $userInfo && $userInfo['profile_weight']) {
                    $insertStmt = $pdo->prepare("INSERT INTO body_measurements (
                        user_id, 
                        weight, 
                        notes,
                        created_at
                    ) VALUES (?, ?, ?, ?)");

                    $insertStmt->execute([
                        $user_id,
                        $userInfo['profile_weight'],
                        'Starting weight from profile - Account created ' . $userInfo['account_created'],
                        $userInfo['account_created']
                    ]);

                    // Fetch measurements again to include the new entry
                    $stmt->execute([$user_id]);
                    $measurements = $stmt->fetchAll(PDO::FETCH_ASSOC);
                }

                // If measurements exist, find and update any starting weight entry to use account creation date
                if (!empty($measurements) && $userInfo && $userInfo['profile_weight']) {
                    $startingWeightEntry = null;
                    foreach ($measurements as $measurement) {
                        if (
                            isset($measurement['notes']) &&
                            (strpos($measurement['notes'], 'starting') !== false ||
                                strpos($measurement['notes'], 'profile') !== false)
                        ) {
                            $startingWeightEntry = $measurement;
                            break;
                        }
                    }

                    // If starting weight entry exists but has wrong date, update it
                    if ($startingWeightEntry && $startingWeightEntry['date_recorded'] !== $userInfo['account_created']) {
                        $updateStmt = $pdo->prepare("UPDATE body_measurements SET 
                            weight = ?, 
                            notes = ?,
                            created_at = ?
                            WHERE id = ?");

                        $updateStmt->execute([
                            $userInfo['profile_weight'],
                            'Starting weight from profile - Account created ' . $userInfo['account_created'],
                            $userInfo['account_created'],
                            $startingWeightEntry['id']
                        ]);

                        // Fetch measurements again to include the updated entry
                        $stmt->execute([$user_id]);
                        $measurements = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    }
                }

                // Convert IDs to integers
                foreach ($measurements as &$record) {
                    $record['id'] = (int) $record['id'];
                }

                echo json_encode($measurements);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error: " . $e->getMessage()]);
            }
        }
        break;

    case 'add_measurement':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);

            $measurement_user_id = $data['user_id'] ?? $user_id;
            if (!$measurement_user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }

            try {
                // Create table if it doesn't exist
                createTableIfNotExists($pdo);

                if (!tableExists($pdo, 'body_measurements')) {
                    http_response_code(500);
                    echo json_encode(["error" => "Failed to create body_measurements table"]);
                    break;
                }

                // Validate required fields
                if (!isset($data['weight']) || $data['weight'] === null || $data['weight'] === '') {
                    http_response_code(400);
                    echo json_encode(["error" => "Weight is required"]);
                    exit();
                }

                // Check if there's already a weight entry for today (excluding starting weight entries)
                $today = date('Y-m-d', strtotime('+8 hours')); // Philippines time
                $checkStmt = $pdo->prepare("SELECT id FROM body_measurements 
                    WHERE user_id = ? AND DATE(CONVERT_TZ(created_at, '+00:00', '+08:00')) = ? AND (notes IS NULL OR notes NOT LIKE '%profile%' OR notes NOT LIKE '%starting%')");
                $checkStmt->execute([$measurement_user_id, $today]);
                $existingEntry = $checkStmt->fetch(PDO::FETCH_ASSOC);

                if ($existingEntry) {
                    // Update existing entry for today (but not starting weight entries)
                    $updateStmt = $pdo->prepare("UPDATE body_measurements SET 
                        weight = ?, 
                        body_fat_percentage = ?, 
                        bmi = ?, 
                        chest_cm = ?, 
                        waist_cm = ?, 
                        hips_cm = ?, 
                        arms_cm = ?, 
                        thighs_cm = ?, 
                        notes = ?,
                        updated_at = CURRENT_TIMESTAMP
                        WHERE id = ? AND user_id = ? AND (notes IS NULL OR notes NOT LIKE '%profile%' OR notes NOT LIKE '%starting%')");

                    $updateStmt->execute([
                        $data['weight'] ?? null,
                        $data['body_fat_percentage'] ?? null,
                        $data['bmi'] ?? null,
                        $data['chest_cm'] ?? null,
                        $data['waist_cm'] ?? null,
                        $data['hips_cm'] ?? null,
                        $data['arms_cm'] ?? null,
                        $data['thighs_cm'] ?? null,
                        $data['notes'] ?? null,
                        $existingEntry['id'],
                        $measurement_user_id
                    ]);

                    echo json_encode([
                        "success" => true,
                        "id" => (int) $existingEntry['id'],
                        "message" => "Weight updated for today",
                        "action" => "updated"
                    ]);
                } else {
                    // Create new entry for today
                    $insertStmt = $pdo->prepare("INSERT INTO body_measurements (
                        user_id, 
                        weight, 
                        body_fat_percentage, 
                        bmi, 
                        chest_cm, 
                        waist_cm, 
                        hips_cm, 
                        arms_cm, 
                        thighs_cm, 
                        notes
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

                    $insertStmt->execute([
                        $measurement_user_id,
                        $data['weight'] ?? null,
                        $data['body_fat_percentage'] ?? null,
                        $data['bmi'] ?? null,
                        $data['chest_cm'] ?? null,
                        $data['waist_cm'] ?? null,
                        $data['hips_cm'] ?? null,
                        $data['arms_cm'] ?? null,
                        $data['thighs_cm'] ?? null,
                        $data['notes'] ?? null
                    ]);

                    $newId = (int) $pdo->lastInsertId();
                    echo json_encode([
                        "success" => true,
                        "id" => $newId,
                        "message" => "Weight saved for today",
                        "action" => "created"
                    ]);
                }

            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error: " . $e->getMessage()]);
            }
        }
        break;

    case 'update_measurement':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);

            if (!isset($data['id']) || !$data['id']) {
                http_response_code(400);
                echo json_encode(["error" => "Measurement ID is required"]);
                exit();
            }

            try {
                if (!tableExists($pdo, 'body_measurements')) {
                    http_response_code(404);
                    echo json_encode(["error" => "Table not found"]);
                    break;
                }

                // First check if this is a starting weight entry (protect it)
                $checkStmt = $pdo->prepare("SELECT notes FROM body_measurements WHERE id = ? AND user_id = ?");
                $checkStmt->execute([$data['id'], $data['user_id'] ?? $user_id]);
                $entry = $checkStmt->fetch(PDO::FETCH_ASSOC);

                if ($entry && ($entry['notes'] && (strpos($entry['notes'], 'profile') !== false || strpos($entry['notes'], 'starting') !== false))) {
                    http_response_code(400);
                    echo json_encode(["error" => "Cannot update starting weight entry"]);
                    exit();
                }

                $stmt = $pdo->prepare("UPDATE body_measurements SET 
                    weight = ?, 
                    body_fat_percentage = ?, 
                    bmi = ?, 
                    chest_cm = ?, 
                    waist_cm = ?, 
                    hips_cm = ?, 
                    arms_cm = ?, 
                    thighs_cm = ?, 
                    notes = ?,
                    updated_at = CURRENT_TIMESTAMP
                    WHERE id = ? AND user_id = ? AND (notes IS NULL OR notes NOT LIKE '%profile%' OR notes NOT LIKE '%starting%')");

                $stmt->execute([
                    $data['weight'] ?? null,
                    $data['body_fat_percentage'] ?? null,
                    $data['bmi'] ?? null,
                    $data['chest_cm'] ?? null,
                    $data['waist_cm'] ?? null,
                    $data['hips_cm'] ?? null,
                    $data['arms_cm'] ?? null,
                    $data['thighs_cm'] ?? null,
                    $data['notes'] ?? null,
                    $data['id'],
                    $data['user_id'] ?? $user_id
                ]);

                if ($stmt->rowCount() > 0) {
                    echo json_encode(["success" => true, "message" => "Measurement updated successfully"]);
                } else {
                    http_response_code(404);
                    echo json_encode(["error" => "Measurement not found or no changes made"]);
                }

            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error: " . $e->getMessage()]);
            }
        }
        break;

    case 'delete_measurement':
        if ($method === 'POST') {
            $data = json_decode(file_get_contents("php://input"), true);

            if (!isset($data['id']) || !$data['id']) {
                http_response_code(400);
                echo json_encode(["error" => "Measurement ID is required"]);
                exit();
            }

            try {
                if (!tableExists($pdo, 'body_measurements')) {
                    http_response_code(404);
                    echo json_encode(["error" => "Table not found"]);
                    break;
                }

                // First check if this is a starting weight entry (protect it)
                $checkStmt = $pdo->prepare("SELECT notes FROM body_measurements WHERE id = ? AND user_id = ?");
                $checkStmt->execute([$data['id'], $data['user_id'] ?? $user_id]);
                $entry = $checkStmt->fetch(PDO::FETCH_ASSOC);

                if ($entry && ($entry['notes'] && (strpos($entry['notes'], 'profile') !== false || strpos($entry['notes'], 'starting') !== false))) {
                    http_response_code(400);
                    echo json_encode(["error" => "Cannot delete starting weight entry"]);
                    exit();
                }

                $stmt = $pdo->prepare("DELETE FROM body_measurements WHERE id = ? AND user_id = ? AND (notes IS NULL OR notes NOT LIKE '%profile%' OR notes NOT LIKE '%starting%')");
                $stmt->execute([$data['id'], $data['user_id'] ?? $user_id]);

                if ($stmt->rowCount() > 0) {
                    echo json_encode(["success" => true, "message" => "Measurement deleted successfully"]);
                } else {
                    http_response_code(404);
                    echo json_encode(["error" => "Measurement not found"]);
                }

            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error: " . $e->getMessage()]);
            }
        }
        break;

    case 'get_latest_weight':
        if ($method === 'GET') {
            if (!$user_id) {
                http_response_code(400);
                echo json_encode(["error" => "user_id is required"]);
                exit();
            }

            try {
                if (!tableExists($pdo, 'body_measurements')) {
                    echo json_encode(["weight" => null]);
                    break;
                }

                $stmt = $pdo->prepare("SELECT weight, CONVERT_TZ(created_at, '+00:00', '+08:00') as created_at 
                    FROM body_measurements 
                    WHERE user_id = ? AND weight IS NOT NULL 
                    ORDER BY created_at DESC 
                    LIMIT `1");
                $stmt->execute([$user_id]);
                $result = $stmt->fetch(PDO::FETCH_ASSOC);

                echo json_encode($result ?: ["weight" => null]);

            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(["error" => "Database error: " . $e->getMessage()]);
            }
        }
        break;

    default:
        http_response_code(400);
        echo json_encode(["error" => "Invalid action"]);
        break;
}
?>