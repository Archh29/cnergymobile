<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration
$host = "localhost";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

// CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Function to send JSON response
function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

// Function to send error response
function sendError($message, $statusCode = 400) {
    http_response_code($statusCode);
    echo json_encode(['error' => $message], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    // Database connection
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    // Get action from request
    $action = $_GET['action'] ?? $_POST['action'] ?? '';
    $user_id = $_GET['user_id'] ?? $_POST['user_id'] ?? '';

    // Check if user_id is required for this action
    $actionsRequiringUserId = ['change_password', 'get_profile', 'update_profile'];
    if (in_array($action, $actionsRequiringUserId) && !$user_id) {
        sendError('User ID is required', 400);
    }

    switch ($action) {
        case 'change_password':
            // Change password functionality
            $current_password = $_POST['current_password'] ?? '';
            $new_password = $_POST['new_password'] ?? '';
            $confirm_password = $_POST['confirm_password'] ?? '';

            // Validate input
            if (empty($current_password) || empty($new_password) || empty($confirm_password)) {
                sendError('All password fields are required', 400);
            }

            if ($new_password !== $confirm_password) {
                sendError('New password and confirm password do not match', 400);
            }

            if (strlen($new_password) < 8) {
                sendError('New password must be at least 8 characters long', 400);
            }

            // Get current user data - Fixed table name to lowercase
            $userStmt = $pdo->prepare("SELECT password FROM user WHERE id = ?");
            $userStmt->execute([$user_id]);
            $user = $userStmt->fetch();

            if (!$user) {
                sendError('User not found', 404);
            }

            // Verify current password
            if (!password_verify($current_password, $user['password'])) {
                sendError('Current password is incorrect', 400);
            }

            // Hash new password
            $hashed_password = password_hash($new_password, PASSWORD_DEFAULT);

            // Update password - Fixed table name to lowercase
            $updateStmt = $pdo->prepare("UPDATE user SET password = ? WHERE id = ?");
            $updateStmt->execute([$hashed_password, $user_id]);

            sendResponse([
                'success' => true,
                'message' => 'Password changed successfully'
            ]);
            break;

        case 'get_profile':
            // Get user profile data - Fixed table names to lowercase
            $userStmt = $pdo->prepare("
                SELECT 
                    u.id,
                    u.email,
                    u.fname,
                    u.mname,
                    u.lname,
                    u.bday,
                    u.gender_id,
                    g.gender_name as gender_type,
                    mpd.fitness_level,
                    mpd.height_cm,
                    mpd.weight_kg,
                    mpd.target_weight,
                    mpd.body_fat,
                    mpd.activity_level,
                    mpd.workout_days_per_week,
                    mpd.equipment_access
                FROM user u
                LEFT JOIN gender g ON u.gender_id = g.id
                LEFT JOIN member_profile_details mpd ON u.id = mpd.user_id
                WHERE u.id = ?
            ");
            $userStmt->execute([$user_id]);
            $profile = $userStmt->fetch();

            if (!$profile) {
                sendError('User profile not found', 404);
            }

            // Convert ID to integer for Flutter compatibility
            $profile['id'] = (int)$profile['id'];
            if ($profile['gender_id'] !== null) {
                $profile['gender_id'] = (int)$profile['gender_id'];
            }

            sendResponse([
                'success' => true,
                'data' => $profile
            ]);
            break;

        case 'update_profile':
            // Update user profile data
            $fname = $_POST['fname'] ?? '';
            $mname = $_POST['mname'] ?? '';
            $lname = $_POST['lname'] ?? '';
            $email = $_POST['email'] ?? '';
            $bday = $_POST['bday'] ?? '';
            $gender_id = $_POST['gender_id'] ?? '';
            $fitness_level = $_POST['fitness_level'] ?? '';
            $height_cm = $_POST['height_cm'] ?? '';
            $weight_kg = $_POST['weight_kg'] ?? '';
            $target_weight = $_POST['target_weight'] ?? '';
            $body_fat = $_POST['body_fat'] ?? '';
            $activity_level = $_POST['activity_level'] ?? '';
            $workout_days_per_week = $_POST['workout_days_per_week'] ?? '';
            $equipment_access = $_POST['equipment_access'] ?? '';

            // Validate required fields
            if (empty($fname) || empty($lname) || empty($email)) {
                sendError('First name, last name, and email are required', 400);
            }

            // Validate email format
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                sendError('Invalid email format', 400);
            }

            // Check if email is already taken by another user - Fixed table name to lowercase
            $emailCheckStmt = $pdo->prepare("SELECT id FROM user WHERE email = ? AND id != ?");
            $emailCheckStmt->execute([$email, $user_id]);
            if ($emailCheckStmt->fetch()) {
                sendError('Email is already taken by another user', 400);
            }

            // Start transaction
            $pdo->beginTransaction();

            try {
                // Update user table - Fixed table name to lowercase
                $updateUserStmt = $pdo->prepare("
                    UPDATE user 
                    SET fname = ?, mname = ?, lname = ?, email = ?, bday = ?, gender_id = ?
                    WHERE id = ?
                ");
                $updateUserStmt->execute([
                    $fname, $mname, $lname, $email, $bday, $gender_id, $user_id
                ]);

                // Update or insert member profile details - Fixed table name to lowercase
                $profileCheckStmt = $pdo->prepare("SELECT id FROM member_profile_details WHERE user_id = ?");
                $profileCheckStmt->execute([$user_id]);
                $existingProfile = $profileCheckStmt->fetch();

                if ($existingProfile) {
                    // Update existing profile - Fixed table name to lowercase
                    $updateProfileStmt = $pdo->prepare("
                        UPDATE member_profile_details 
                        SET fitness_level = ?, height_cm = ?, weight_kg = ?, target_weight = ?, 
                            body_fat = ?, activity_level = ?, workout_days_per_week = ?, equipment_access = ?
                        WHERE user_id = ?
                    ");
                    $updateProfileStmt->execute([
                        $fitness_level, $height_cm, $weight_kg, $target_weight,
                        $body_fat, $activity_level, $workout_days_per_week, $equipment_access, $user_id
                    ]);
                } else {
                    // Insert new profile - Fixed table name to lowercase
                    $insertProfileStmt = $pdo->prepare("
                        INSERT INTO member_profile_details 
                        (user_id, fitness_level, height_cm, weight_kg, target_weight, body_fat, 
                         activity_level, workout_days_per_week, equipment_access)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ");
                    $insertProfileStmt->execute([
                        $user_id, $fitness_level, $height_cm, $weight_kg, $target_weight,
                        $body_fat, $activity_level, $workout_days_per_week, $equipment_access
                    ]);
                }

                $pdo->commit();

                sendResponse([
                    'success' => true,
                    'message' => 'Profile updated successfully'
                ]);

            } catch (Exception $e) {
                $pdo->rollBack();
                throw $e;
            }
            break;

        case 'get_genders':
            // Get available genders - Fixed table name to lowercase
            $genderStmt = $pdo->prepare("SELECT id, gender_name as type FROM gender ORDER BY id");
            $genderStmt->execute();
            $genders = $genderStmt->fetchAll();

            // Convert IDs to integers for Flutter compatibility
            foreach ($genders as &$gender) {
                $gender['id'] = (int)$gender['id'];
            }

            sendResponse([
                'success' => true,
                'data' => $genders
            ]);
            break;

        default:
            sendError('Invalid action', 400);
    }

} catch(PDOException $e) {
    error_log('Database error in profile_management.php: ' . $e->getMessage());
    sendError('Database error: ' . $e->getMessage(), 500);
} catch(Exception $e) {
    error_log('Server error in profile_management.php: ' . $e->getMessage());
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>

















