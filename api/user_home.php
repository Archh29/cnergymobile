<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration
$host = "localhost";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

// CORS headers - MUST be set before any output
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400'); // Cache preflight for 24 hours
header('Content-Type: application/json; charset=utf-8');

// Handle preflight requests - MUST be handled first
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // Return 200 OK for preflight requests
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
    
    // Get user ID from request (optional for today's workout)
    $userId = $_GET['user_id'] ?? null;
    
    // Fetch all data in parallel using prepared statements
    $announcementsStmt = $pdo->prepare("
        SELECT 
            id,
            title,
            content as description,
            priority,
            date_posted,
            CASE 
                WHEN priority = 'high' THEN 1
                WHEN priority = 'medium' THEN 2
                WHEN priority = 'low' THEN 3
            END as priority_order
        FROM announcement 
        WHERE status = 'active' 
        ORDER BY priority_order ASC, date_posted DESC
    ");
    
    $merchandiseStmt = $pdo->prepare("
        SELECT 
            id,
            name,
            price,
            image_url,
            created_at
        FROM merchandise 
        WHERE status = 'active' 
        ORDER BY created_at DESC
    ");
    
    // Updated promotions query - show all active promotions regardless of date
    $promotionsStmt = $pdo->prepare("
        SELECT 
            id,
            title,
            description,
            icon,
            start_date,
            end_date,
            created_at
        FROM promotions 
        WHERE is_active = 1 
        ORDER BY created_at DESC
    ");
    
    // Get current gym capacity (people currently in gym TODAY - checked in today and haven't checked out)
    $gymCapacityStmt = $pdo->prepare("
        SELECT COUNT(*) as current_count
        FROM attendance 
        WHERE DATE(check_in) = CURDATE()
        AND check_out IS NULL
    ");
    
    // Execute basic queries
    $announcementsStmt->execute();
    $merchandiseStmt->execute();
    $promotionsStmt->execute();
    $gymCapacityStmt->execute();
    
    // Only query today's workout if user_id is provided
    $todayWorkout = null;
    if ($userId) {
        // Get today's day of the week
        $today = date('l'); // Monday, Tuesday, etc.
        
        // Query for today's workout (for display only)
        $todayWorkoutStmt = $pdo->prepare("
            SELECT 
                s.id as schedule_id,
                s.day_of_week,
                s.workout_id,
                s.scheduled_time,
                s.is_rest_day,
                s.notes,
                mpw.workout_details,
                mph.id as program_id,
                mph.goal as program_goal,
                mph.difficulty as program_difficulty,
                COALESCE(
                    JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.name')), 
                    mph.goal,
                    'Workout'
                ) as workout_name,
                COALESCE(
                    JSON_UNQUOTE(JSON_EXTRACT(mpw.workout_details, '$.duration')), 
                    30
                ) as workout_duration
            FROM member_program_schedule s
            LEFT JOIN member_program_workout mpw ON s.workout_id = mpw.id
            LEFT JOIN member_programhdr mph ON s.member_program_hdr_id = mph.id
            WHERE mph.user_id = :user_id 
            AND s.day_of_week = :today
            AND s.is_active = 1
            ORDER BY mph.updated_at DESC
            LIMIT 1
        ");
        
        $todayWorkoutStmt->execute([
            ':user_id' => $userId,
            ':today' => $today
        ]);
        
        $todayWorkout = $todayWorkoutStmt->fetch(); // Single row
    }
    
    $announcements = $announcementsStmt->fetchAll();
    $merchandise = $merchandiseStmt->fetchAll();
    $promotions = $promotionsStmt->fetchAll();
    $gymCapacity = $gymCapacityStmt->fetch();
    
    // Transform announcements data
    $formattedAnnouncements = array_map(function($announcement) {
        $isImportant = $announcement['priority'] === 'high';
        
        // Use switch instead of match for PHP 7.x compatibility
        switch($announcement['priority']) {
            case 'high':
                $color = '#FF6B35';
                $icon = 'fitness_center';
                break;
            case 'medium':
                $color = '#4ECDC4';
                $icon = 'schedule';
                break;
            case 'low':
                $color = '#96CEB4';
                $icon = 'group';
                break;
            default:
                $color = '#96CEB4';
                $icon = 'info';
                break;
        }
        
        return [
            'id' => (int)$announcement['id'],
            'title' => $announcement['title'],
            'description' => $announcement['description'],
            'icon' => $icon,
            'color' => $color,
            'isImportant' => $isImportant,
            'datePosted' => $announcement['date_posted']
        ];
    }, $announcements);
    
    // Transform merchandise data
    $colors = ['#FF6B35', '#4ECDC4', '#96CEB4', '#45B7D1', '#F7DC6F', '#BB8FCE'];
    $icons = ['local_drink', 'water_drop', 'checkroom', 'fitness_center', 'sports_handball', 'sports_basketball'];
    
    $formattedMerchandise = array_map(function($item, $index) use ($colors, $icons) {
        $colorIndex = $index % count($colors);
        $iconIndex = $index % count($icons);
        
        return [
            'id' => (int)$item['id'],
            'name' => $item['name'],
            'price' => '₱' . number_format($item['price'], 2),
            'description' => 'Premium quality merchandise',
            'color' => $colors[$colorIndex],
            'icon' => $icons[$iconIndex],
            'imageUrl' => $item['image_url'],
            'createdAt' => $item['created_at']
        ];
    }, $merchandise, array_keys($merchandise));
    
    // Transform promotions data
    $promoColors = ['#FF6B35', '#4ECDC4', '#96CEB4', '#45B7D1', '#F7DC6F', '#BB8FCE'];
    $promoIcons = ['local_fire_department', 'school', 'people', 'star', 'card_giftcard', 'celebration'];
    
    $formattedPromotions = array_map(function($promotion, $index) use ($promoColors, $promoIcons) {
        $colorIndex = $index % count($promoColors);
        $iconIndex = $index % count($promoIcons);
        
        // Calculate days remaining
        $endDate = new DateTime($promotion['end_date']);
        $today = new DateTime();
        $daysRemaining = $today->diff($endDate)->days;
        
        // Generate discount text based on title
        $discount = 'SPECIAL';
        if (stripos($promotion['title'], 'discount') !== false) {
            $discount = 'DISCOUNT';
        } elseif (stripos($promotion['title'], 'free') !== false) {
            $discount = 'FREE';
        } elseif (stripos($promotion['title'], 'off') !== false) {
            $discount = 'SAVE';
        }
        
        // Check if promotion is currently active based on dates
        $startDate = new DateTime($promotion['start_date']);
        $isCurrentlyActive = ($today >= $startDate && $today <= $endDate);
        
        if ($isCurrentlyActive) {
            $validUntil = $daysRemaining > 0 
                ? "Valid for {$daysRemaining} more days"
                : "Ends today";
        } else if ($today < $startDate) {
            $validUntil = "Starts on " . $startDate->format('M d, Y');
        } else {
            $validUntil = "Expired";
        }
            
        return [
            'id' => (int)$promotion['id'],
            'title' => $promotion['title'],
            'description' => $promotion['description'],
            'discount' => $discount,
            'validUntil' => $validUntil,
            'color' => $promoColors[$colorIndex],
            'icon' => $promoIcons[$iconIndex],
            'startDate' => $promotion['start_date'],
            'endDate' => $promotion['end_date'],
            'createdAt' => $promotion['created_at'],
            'isActive' => $isCurrentlyActive
        ];
    }, $promotions, array_keys($promotions));
    
    // Format today's workout data (for display only)
    $formattedTodayWorkout = null;
    if ($todayWorkout) {
        $formattedTodayWorkout = [
            'scheduleId' => (int)$todayWorkout['schedule_id'],
            'dayOfWeek' => $todayWorkout['day_of_week'],
            'workoutId' => $todayWorkout['workout_id'] ? (int)$todayWorkout['workout_id'] : null,
            'programId' => (int)$todayWorkout['program_id'],
            'scheduledTime' => $todayWorkout['scheduled_time'],
            'isRestDay' => (bool)$todayWorkout['is_rest_day'],
            'notes' => $todayWorkout['notes'],
            'workoutName' => $todayWorkout['workout_name'],
            'workoutDuration' => $todayWorkout['workout_duration'],
            'programGoal' => $todayWorkout['program_goal'],
            'programDifficulty' => $todayWorkout['program_difficulty']
        ];
    }
    
    // Get gym capacity data
    $currentCount = (int)$gymCapacity['current_count'];
    $maxCapacity = 30; // Gym capacity limit
    $isFull = $currentCount >= $maxCapacity;
    $availableSpots = max(0, $maxCapacity - $currentCount);
    
    // Return all data in one response
    sendResponse([
        'success' => true,
        'data' => [
            'announcements' => $formattedAnnouncements,
            'merchandise' => $formattedMerchandise,
            'promotions' => $formattedPromotions,
            'todayWorkout' => $formattedTodayWorkout,
            'gymCapacity' => [
                'currentCount' => $currentCount,
                'maxCapacity' => $maxCapacity,
                'availableSpots' => $availableSpots,
                'isFull' => $isFull,
                'percentage' => round(($currentCount / $maxCapacity) * 100)
            ]
        ]
    ]);
    
} catch(PDOException $e) {
    error_log('Database error in user_home.php: ' . $e->getMessage());
    sendError('Database error: ' . $e->getMessage(), 500);
} catch(Exception $e) {
    error_log('Server error in user_home.php: ' . $e->getMessage());
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>