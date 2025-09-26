<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/error.log');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// More robust action detection
$method = $_SERVER['REQUEST_METHOD'];
$action = null;

// Try multiple ways to get the action parameter
if (isset($_GET['action'])) {
    $action = $_GET['action'];
} elseif (isset($_REQUEST['action'])) {
    $action = $_REQUEST['action'];
} else {
    // Parse query string manually if needed
    $queryString = $_SERVER['QUERY_STRING'] ?? '';
    if (preg_match('/action=([^&]+)/', $queryString, $matches)) {
        $action = $matches[1];
    }
}

// Log the request for debugging
error_log("=== REQUEST DEBUG ===");
error_log("Method: " . $method);
error_log("Raw Query String: " . ($_SERVER['QUERY_STRING'] ?? 'none'));
error_log("GET array: " . json_encode($_GET));
error_log("REQUEST array: " . json_encode($_REQUEST));
error_log("Detected Action: " . ($action ?? 'null'));
error_log("Request URI: " . $_SERVER['REQUEST_URI']);

// Database configuration
$servername = "localhost";
$username = "u773938685_archh29";
$password = "Gwapoko385@";
$dbname = "u773938685_cnergydb";

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    error_log("Database connection successful");
} catch(PDOException $e) {
    error_log("Database connection failed: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Connection failed: ' . $e->getMessage()]);
    exit();
}

// Debug logging
error_log("Processing request - Method: $method, Action: " . ($action ?? 'null'));

// Route the request based on method and action
if ($method === 'GET' && $action === 'get_genders') {
    // Handle get genders - FIXED: using correct table name 'gender'
    error_log("=== GET GENDERS REQUEST ===");
    
    try {
        // Check if gender table exists (not genders)
        $stmt = $pdo->query("SHOW TABLES LIKE 'gender'");
        if ($stmt->rowCount() == 0) {
            error_log("Gender table does not exist");
            // Create some default genders if table doesn't exist
            echo json_encode([
                'success' => true, 
                'genders' => [
                    ['id' => 1, 'gender_name' => 'Male'],
                    ['id' => 2, 'gender_name' => 'Female'],
                    ['id' => 3, 'gender_name' => 'Other']
                ]
            ]);
            exit();
        }
        
        // FIXED: Query the correct table name 'gender' (not 'genders')
        $stmt = $pdo->prepare("SELECT id, gender_name FROM gender ORDER BY id");
        $stmt->execute();
        $genders = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        error_log("Found " . count($genders) . " genders: " . json_encode($genders));
        
        // Ensure proper data format
        $formattedGenders = [];
        foreach ($genders as $gender) {
            $formattedGenders[] = [
                'id' => (int)$gender['id'],
                'gender_name' => ucfirst($gender['gender_name']) // Capitalize first letter
            ];
        }
        
        echo json_encode([
            'success' => true, 
            'genders' => $formattedGenders
        ]);
        
    } catch (PDOException $e) {
        error_log("Get genders error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Failed to fetch genders: ' . $e->getMessage()]);
    }

} elseif ($method === 'GET' && $action === 'test_email') {
    // Test email endpoint
    error_log("=== EMAIL TEST ENDPOINT ===");
    
    $testEmail = $_GET['email'] ?? 'uyguangco.francisbaron@gmail.com';
    
    try {
        $emailServicePath = __DIR__ . '/email_service.php';
        if (!file_exists($emailServicePath)) {
            throw new Exception("Email service file not found at: $emailServicePath");
        }
        
        require_once $emailServicePath;
        $emailService = new EmailService();
        
        $result = $emailService->sendTestEmail($testEmail, 'Test User');
        
        echo json_encode([
            'success' => $result['success'],
            'message' => $result['message'],
            'test_email' => $testEmail
        ]);
        
    } catch (Exception $e) {
        error_log("Email test error: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Email test failed: ' . $e->getMessage()
        ]);
    }

} elseif ($method === 'GET' && $action === 'debug') {
    // Debug endpoint
    echo json_encode([
        'method' => $method,
        'action' => $action,
        'get_params' => $_GET,
        'request_params' => $_REQUEST,
        'query_string' => $_SERVER['QUERY_STRING'] ?? 'none',
        'server_info' => [
            'REQUEST_METHOD' => $_SERVER['REQUEST_METHOD'],
            'REQUEST_URI' => $_SERVER['REQUEST_URI'],
            'QUERY_STRING' => $_SERVER['QUERY_STRING'] ?? 'none'
        ],
        'files_exist' => [
            'email_service.php' => file_exists(__DIR__ . '/email_service.php'),
            'vendor/autoload.php' => file_exists(__DIR__ . '/vendor/autoload.php')
        ],
        'database_tables' => getTableList($pdo)
    ]);

} elseif ($method === 'POST') {
    // Check if this is a login request or registration request
    $input = json_decode(file_get_contents("php://input"), true);
    
    if (!$input) {
        error_log("No JSON input received");
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'No data received']);
        exit();
    }
    
    error_log("POST request input: " . json_encode($input));
    
    // Check if this is a login request (has email and password, but no other registration fields)
    $isLoginRequest = isset($input['email']) && isset($input['password']) && 
                     !isset($input['fname']) && !isset($input['lname']) && 
                     !isset($input['bday']) && !isset($input['gender_id']);
    
    if ($isLoginRequest) {
        // Handle login request
        error_log("=== LOGIN REQUEST DETECTED ===");
        
        if (!isset($input['email']) || !isset($input['password'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Email and password are required']);
            exit();
        }
        
        try {
            // FIXED: Query correct table names
            $stmt = $pdo->prepare("
                SELECT u.*, ut.type_name as user_role, g.gender_name 
                FROM user u 
                LEFT JOIN usertype ut ON u.user_type_id = ut.id 
                LEFT JOIN gender g ON u.gender_id = g.id 
                WHERE u.email = ?
            ");
            $stmt->execute([$input['email']]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($user && password_verify($input['password'], $user['password'])) {
                // Generate JWT token (simplified)
                $jwt_token = base64_encode(json_encode([
                    'user_id' => $user['id'],
                    'email' => $user['email'],
                    'exp' => time() + (24 * 60 * 60) // 24 hours
                ]));
                
                error_log("Login successful for user: " . $user['id']);
                
                echo json_encode([
                    'success' => true,
                    'jwt_token' => $jwt_token,
                    'user_id' => $user['id'],
                    'user_role' => $user['user_role'],
                    'user_name' => trim($user['fname'] . ' ' . $user['lname']),
                    'fname' => $user['fname'],
                    'lname' => $user['lname'],
                    'email' => $user['email'],
                    'account_status' => $user['account_status'],
                    'profile_completed' => $user['profile_completed'] ?? false
                ]);
            } else {
                error_log("Login failed for email: " . $input['email']);
                http_response_code(401);
                echo json_encode(['error' => 'Invalid email or password']);
            }
            
        } catch (PDOException $e) {
            error_log("Login error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Login failed. Please try again.']);
        }
        
    } else {
        // Handle user registration
        error_log("=== REGISTRATION REQUEST DETECTED ===");
        
        // Validate required fields for registration
        $requiredFields = ['email', 'password', 'fname', 'lname', 'bday', 'gender_id'];
        foreach ($requiredFields as $field) {
            if (!isset($input[$field]) || empty(trim($input[$field]))) {
                error_log("Missing required field: $field");
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => ucfirst($field) . ' is required']);
                exit();
            }
        }
        
        // Continue with existing registration logic...
        try {
            // FIXED: Check if user table exists (not users)
            $stmt = $pdo->query("SHOW TABLES LIKE 'user'");
            if ($stmt->rowCount() == 0) {
                error_log("User table does not exist");
                http_response_code(500);
                echo json_encode(['success' => false, 'error' => 'Database not properly configured - user table missing']);
                exit();
            }
            
            // FIXED: Check if email already exists in 'user' table
            $stmt = $pdo->prepare("SELECT id FROM user WHERE email = ?");
            $stmt->execute([$input['email']]);
            if ($stmt->rowCount() > 0) {
                error_log("Email already exists: " . $input['email']);
                http_response_code(400);
                echo json_encode(['success' => false, 'error' => 'Email already exists']);
                exit();
            }
            
            // Hash password
            $hashedPassword = password_hash($input['password'], PASSWORD_DEFAULT);
            
            // FIXED: Insert into 'user' table with correct column names
            $stmt = $pdo->prepare("
                INSERT INTO user (email, password, fname, mname, lname, bday, gender_id, user_type_id, account_status, created_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, 4, 'pending', NOW())
            ");
            
            $stmt->execute([
                $input['email'],
                $hashedPassword,
                $input['fname'],
                $input['mname'] ?? '',
                $input['lname'],
                $input['bday'],
                $input['gender_id']
            ]);
            
            $userId = $pdo->lastInsertId();
            error_log("User created successfully with ID: $userId");
            
            // Now try to send welcome email
            error_log("=== ATTEMPTING TO SEND EMAIL ===");
            
            // Include the email service - now from the same directory
            $emailServicePath = __DIR__ . '/email_service.php';
            error_log("Looking for email service at: $emailServicePath");
            
            if (!file_exists($emailServicePath)) {
                error_log("Email service file not found at: $emailServicePath");
                // Continue without email - don't fail registration
                echo json_encode([
                    'success' => true, 
                    'message' => 'Account created successfully! (Email service unavailable)',
                    'user_id' => $userId,
                    'email_sent' => false
                ]);
                exit();
            }
            
            try {
                require_once $emailServicePath;
                error_log("Email service file included successfully");
                
                if (!class_exists('EmailService')) {
                    error_log("EmailService class not found after including file");
                    throw new Exception("EmailService class not found");
                }
                
                $emailService = new EmailService();
                error_log("EmailService instance created");
                
                $userName = trim($input['fname'] . ' ' . $input['lname']);
                
                $userDetails = [
                    'email' => $input['email'],
                    'fname' => $input['fname'],
                    'lname' => $input['lname'],
                    'user_id' => $userId
                ];
                
                error_log("Calling sendWelcomeEmail for: " . $input['email']);
                $emailResult = $emailService->sendWelcomeEmail($input['email'], $userName, $userDetails);
                error_log("Email result: " . json_encode($emailResult));
                
            } catch (Exception $e) {
                error_log("Email service error: " . $e->getMessage());
                error_log("Email service stack trace: " . $e->getTraceAsString());
                
                // Don't fail registration if email fails
                $emailResult = ['success' => false, 'message' => 'Email service error: ' . $e->getMessage()];
            }
            
            // Return success response
            $response = [
                'success' => true, 
                'message' => $emailResult['success'] 
                    ? 'Account created successfully! Please check your email for welcome instructions.'
                    : 'Account created successfully! (Email could not be sent: ' . $emailResult['message'] . ')',
                'user_id' => $userId,
                'email_sent' => $emailResult['success'] ?? false,
                'email_error' => $emailResult['success'] ? null : $emailResult['message']
            ];
            
            error_log("Final response: " . json_encode($response));
            echo json_encode($response);
            
        } catch (PDOException $e) {
            error_log("Registration database error: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['success' => false, 'error' => 'Registration failed. Please try again.']);
        }
    }
} else {
    // Invalid request - provide more details
    error_log("Invalid request - Method: $method, Action: " . ($action ?? 'null'));
    
    http_response_code(400);
    echo json_encode([
        'error' => 'Invalid request',
        'debug' => [
            'method' => $method,
            'action' => $action,
            'query_string' => $_SERVER['QUERY_STRING'] ?? 'none',
            'get_params' => $_GET,
            'available_actions' => [
                'POST (no action)' => 'User registration',
                'POST action=login' => 'User login',
                'GET action=get_genders' => 'Get gender list',
                'GET action=test_email' => 'Test email service',
                'GET action=debug' => 'Debug information'
            ]
        ]
    ]);
}

// Helper function to get table list
function getTableList($pdo) {
    try {
        $stmt = $pdo->query("SHOW TABLES");
        return $stmt->fetchAll(PDO::FETCH_COLUMN);
    } catch (Exception $e) {
        return ['error' => $e->getMessage()];
    }
}
?>

















