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

    // Get action parameter
    $action = $_GET['action'] ?? 'get_achievements';
    $user_id = $_GET['user_id'] ?? null;

    if (!$user_id) {
        sendError('User ID is required', 400);
    }

    switch ($action) {
        case 'get_achievements':
            // First, check and award any new achievements
            checkAndAwardAchievements($pdo, $user_id);
            
            // Get all available achievements
            $achievementsStmt = $pdo->prepare("
                SELECT 
                    a.id,
                    a.title,
                    a.description,
                    a.icon,
                    a.created_at
                FROM achievements a
                ORDER BY a.id ASC
            ");
            $achievementsStmt->execute();
            $achievements = $achievementsStmt->fetchAll();

            // Get user's earned achievements (after potential new awards)
            $userAchievementsStmt = $pdo->prepare("
                SELECT 
                    ma.achievement_id,
                    ma.awarded_at
                FROM member_achievements ma
                WHERE ma.user_id = ?
            ");
            $userAchievementsStmt->execute([$user_id]);
            $userAchievements = $userAchievementsStmt->fetchAll();

            // Create a map of user's earned achievements
            $earnedAchievements = [];
            foreach ($userAchievements as $earned) {
                $earnedAchievements[$earned['achievement_id']] = $earned['awarded_at'];
            }

            // Get user statistics for progress calculation
            $userStats = getUserStats($pdo, $user_id);

            // Transform achievements data
            $formattedAchievements = array_map(function($achievement) use ($earnedAchievements, $userStats) {
                $isUnlocked = isset($earnedAchievements[$achievement['id']]);
                $progress = calculateProgress($achievement, $userStats, $isUnlocked);
                $level = getAchievementLevel($achievement['id']);
                $points = getAchievementPoints($achievement['id']);
                $category = getAchievementCategory($achievement['id']);
                $color = getAchievementColor($achievement['id']);

                return [
                    'id' => (int)$achievement['id'],
                    'title' => $achievement['title'],
                    'description' => $achievement['description'],
                    'icon' => $achievement['icon'],
                    'progress' => $progress,
                    'level' => $level,
                    'unlocked' => $isUnlocked,
                    'points' => $points,
                    'category' => $category,
                    'color' => $color,
                    'awarded_at' => $isUnlocked ? $earnedAchievements[$achievement['id']] : null,
                    'created_at' => $achievement['created_at']
                ];
            }, $achievements);

            $response = [
                'success' => true,
                'data' => [
                    'achievements' => $formattedAchievements,
                    'total_points' => array_sum(array_column($formattedAchievements, 'points')),
                    'unlocked_count' => count(array_filter($formattedAchievements, function($a) { return $a['unlocked']; })),
                    'total_count' => count($formattedAchievements)
                ]
            ];

            sendResponse($response);
            break;

        case 'get_user_stats':
            $stats = getUserStats($pdo, $user_id);
            sendResponse([
                'success' => true,
                'data' => $stats
            ]);
            break;

        case 'check_achievements':
            // Check and award new achievements
            $newAchievements = checkAndAwardAchievements($pdo, $user_id);
            sendResponse([
                'success' => true,
                'data' => [
                    'new_achievements' => $newAchievements,
                    'count' => count($newAchievements)
                ]
            ]);
            break;

        case 'force_check':
            // Force check and award achievements (for debugging)
            $newAchievements = checkAndAwardAchievements($pdo, $user_id);
            sendResponse([
                'success' => true,
                'data' => [
                    'new_achievements' => $newAchievements,
                    'count' => count($newAchievements),
                    'message' => 'Achievements checked and awarded'
                ]
            ]);
            break;

        default:
            sendError('Invalid action', 400);
    }

} catch(PDOException $e) {
    error_log('Database error in achievements.php: ' . $e->getMessage());
    sendError('Database error: ' . $e->getMessage(), 500);
} catch(Exception $e) {
    error_log('Server error in achievements.php: ' . $e->getMessage());
    sendError('Server error: ' . $e->getMessage(), 500);
}

// Helper function to get user statistics
function getUserStats($pdo, $user_id) {
    // Get total check-ins
    $checkinsStmt = $pdo->prepare("
        SELECT COUNT(*) as total_checkins
        FROM attendance 
        WHERE user_id = ?
    ");
    $checkinsStmt->execute([$user_id]);
    $checkins = $checkinsStmt->fetch();

    // Get total workout sessions
    $workoutsStmt = $pdo->prepare("
        SELECT COUNT(*) as total_workouts
        FROM member_programhdr 
        WHERE user_id = ? AND completion_rate = 100
    ");
    $workoutsStmt->execute([$user_id]);
    $workouts = $workoutsStmt->fetch();

    // Get total sets logged
    $setsStmt = $pdo->prepare("
        SELECT COUNT(*) as total_sets
        FROM member_exercise_set_log mesl
        JOIN member_exercise_log mel ON mesl.exercise_log_id = mel.id
        WHERE mel.member_id = ?
    ");
    $setsStmt->execute([$user_id]);
    $sets = $setsStmt->fetch();

    // Get max weight lifted
    $maxWeightStmt = $pdo->prepare("
        SELECT MAX(mesl.weight) as max_weight
        FROM member_exercise_set_log mesl
        JOIN member_exercise_log mel ON mesl.exercise_log_id = mel.id
        WHERE mel.member_id = ? AND mesl.weight > 0
    ");
    $maxWeightStmt->execute([$user_id]);
    $maxWeight = $maxWeightStmt->fetch();

    // Get membership duration
    $membershipStmt = $pdo->prepare("
        SELECT 
            MIN(start_date) as first_membership,
            MAX(end_date) as last_membership
        FROM subscription 
        WHERE user_id = ? AND status_id = 2
    ");
    $membershipStmt->execute([$user_id]);
    $membership = $membershipStmt->fetch();

    // Get goals set
    $goalsStmt = $pdo->prepare("
        SELECT COUNT(*) as goals_set
        FROM member_fitness_goals 
        WHERE user_id = ?
    ");
    $goalsStmt->execute([$user_id]);
    $goals = $goalsStmt->fetch();

    // Get goals achieved
    $goalsAchievedStmt = $pdo->prepare("
        SELECT COUNT(*) as goals_achieved
        FROM my_goals 
        WHERE user_id = ? AND status = 'achieved'
    ");
    $goalsAchievedStmt->execute([$user_id]);
    $goalsAchieved = $goalsAchievedStmt->fetch();

    // Get coach assigned
    $coachStmt = $pdo->prepare("
        SELECT COUNT(*) as coach_assigned
        FROM coach_member_list 
        WHERE member_id = ? AND status = 'approved'
    ");
    $coachStmt->execute([$user_id]);
    $coach = $coachStmt->fetch();

    // Get reviews given
    $reviewsStmt = $pdo->prepare("
        SELECT COUNT(*) as reviews_given
        FROM coach_review 
        WHERE member_id = ?
    ");
    $reviewsStmt->execute([$user_id]);
    $reviews = $reviewsStmt->fetch();

    return [
        'total_checkins' => (int)$checkins['total_checkins'],
        'total_workouts' => (int)$workouts['total_workouts'],
        'total_sets' => (int)$sets['total_sets'],
        'max_weight' => (float)$maxWeight['max_weight'],
        'first_membership' => $membership['first_membership'],
        'last_membership' => $membership['last_membership'],
        'goals_set' => (int)$goals['goals_set'],
        'goals_achieved' => (int)$goalsAchieved['goals_achieved'],
        'coach_assigned' => (int)$coach['coach_assigned'],
        'reviews_given' => (int)$reviews['reviews_given']
    ];
}

// Helper function to calculate achievement progress
function calculateProgress($achievement, $userStats, $isUnlocked) {
    if ($isUnlocked) {
        return 1.0;
    }

    $achievementId = $achievement['id'];
    
    switch ($achievementId) {
        case 1: // First Check-In
            return $userStats['total_checkins'] > 0 ? 1.0 : 0.0;
        case 2: // Consistent Attendee (30 check-ins)
            return min($userStats['total_checkins'] / 30, 1.0);
        case 3: // Gym Rat (100 check-ins)
            return min($userStats['total_checkins'] / 100, 1.0);
        case 4: // 1 Month Member
            if ($userStats['first_membership']) {
                $months = (strtotime('now') - strtotime($userStats['first_membership'])) / (30 * 24 * 60 * 60);
                return min($months, 1.0);
            }
            return 0.0;
        case 5: // 6 Months Strong
            if ($userStats['first_membership']) {
                $months = (strtotime('now') - strtotime($userStats['first_membership'])) / (30 * 24 * 60 * 60);
                return min($months / 6, 1.0);
            }
            return 0.0;
        case 6: // 1 Year Loyalty
            if ($userStats['first_membership']) {
                $months = (strtotime('now') - strtotime($userStats['first_membership'])) / (30 * 24 * 60 * 60);
                return min($months / 12, 1.0);
            }
            return 0.0;
        case 7: // First Workout Logged
            return $userStats['total_workouts'] > 0 ? 1.0 : 0.0;
        case 8: // Strength Builder (500 sets)
            return min($userStats['total_sets'] / 500, 1.0);
        case 9: // Heavy Lifter (100kg+)
            return $userStats['max_weight'] >= 100 ? 1.0 : min($userStats['max_weight'] / 100, 1.0);
        case 10: // Goal Setter
            return $userStats['goals_set'] > 0 ? 1.0 : 0.0;
        case 11: // Goal Achiever
            return $userStats['goals_achieved'] > 0 ? 1.0 : 0.0;
        case 12: // Coach Assigned
            return $userStats['coach_assigned'] > 0 ? 1.0 : 0.0;
        case 13: // Feedback Giver
            return $userStats['reviews_given'] > 0 ? 1.0 : 0.0;
        default:
            return 0.0;
    }
}

// Helper function to get achievement level
function getAchievementLevel($achievementId) {
    $levels = [
        1 => 'Bronze', 2 => 'Silver', 3 => 'Gold', 4 => 'Bronze', 5 => 'Silver', 6 => 'Gold',
        7 => 'Bronze', 8 => 'Silver', 9 => 'Gold', 10 => 'Bronze', 11 => 'Gold', 12 => 'Silver', 13 => 'Bronze'
    ];
    return $levels[$achievementId] ?? 'Bronze';
}

// Helper function to get achievement points
function getAchievementPoints($achievementId) {
    $points = [
        1 => 50, 2 => 150, 3 => 300, 4 => 100, 5 => 250, 6 => 500,
        7 => 75, 8 => 200, 9 => 400, 10 => 50, 11 => 200, 12 => 150, 13 => 100
    ];
    return $points[$achievementId] ?? 100;
}

// Helper function to get achievement category
function getAchievementCategory($achievementId) {
    $categories = [
        1 => 'Attendance', 2 => 'Attendance', 3 => 'Attendance', 4 => 'Membership', 5 => 'Membership', 6 => 'Membership',
        7 => 'Fitness', 8 => 'Fitness', 9 => 'Strength', 10 => 'Goals', 11 => 'Goals', 12 => 'Community', 13 => 'Community'
    ];
    return $categories[$achievementId] ?? 'General';
}

// Helper function to get achievement color
function getAchievementColor($achievementId) {
    $colors = [
        1 => 0xFF4ECDC4, 2 => 0xFF96CEB4, 3 => 0xFFFFD700, 4 => 0xFF45B7D1, 5 => 0xFF4ECDC4, 6 => 0xFFFFD700,
        7 => 0xFFFF6B35, 8 => 0xFF96CEB4, 9 => 0xFFE74C3C, 10 => 0xFF4ECDC4, 11 => 0xFFFFD700, 12 => 0xFF96CEB4, 13 => 0xFF45B7D1
    ];
    return $colors[$achievementId] ?? 0xFF4ECDC4;
}

// Helper function to check and award new achievements
function checkAndAwardAchievements($pdo, $user_id) {
    $newAchievements = [];
    $userStats = getUserStats($pdo, $user_id);
    
    // Debug logging
    error_log("Checking achievements for user $user_id");
    error_log("User stats: " . json_encode($userStats));
    
    // Get all achievements
    $achievementsStmt = $pdo->prepare("SELECT id FROM achievements");
    $achievementsStmt->execute();
    $achievements = $achievementsStmt->fetchAll();
    
    // Get user's current achievements
    $userAchievementsStmt = $pdo->prepare("SELECT achievement_id FROM member_achievements WHERE user_id = ?");
    $userAchievementsStmt->execute([$user_id]);
    $userAchievements = array_column($userAchievementsStmt->fetchAll(), 'achievement_id');
    
    error_log("User already has achievements: " . json_encode($userAchievements));
    
    foreach ($achievements as $achievement) {
        $achievementId = $achievement['id'];
        
        // Skip if already earned
        if (in_array($achievementId, $userAchievements)) {
            continue;
        }
        
        // Check if achievement should be awarded
        $shouldAward = false;
        $progress = calculateProgress($achievement, $userStats, false);
        
        // Award if progress is 100% or more
        if ($progress >= 1.0) {
            $shouldAward = true;
            error_log("Achievement $achievementId should be awarded - progress: $progress");
        }
        
        // Also check specific criteria for extra safety
        switch ($achievementId) {
            case 1: // First Check-In
                $shouldAward = $userStats['total_checkins'] > 0;
                break;
            case 2: // Consistent Attendee
                $shouldAward = $userStats['total_checkins'] >= 30;
                break;
            case 3: // Gym Rat
                $shouldAward = $userStats['total_checkins'] >= 100;
                break;
            case 4: // 1 Month Member
                if ($userStats['first_membership']) {
                    $months = (strtotime('now') - strtotime($userStats['first_membership'])) / (30 * 24 * 60 * 60);
                    $shouldAward = $months >= 1;
                }
                break;
            case 5: // 6 Months Strong
                if ($userStats['first_membership']) {
                    $months = (strtotime('now') - strtotime($userStats['first_membership'])) / (30 * 24 * 60 * 60);
                    $shouldAward = $months >= 6;
                }
                break;
            case 6: // 1 Year Loyalty
                if ($userStats['first_membership']) {
                    $months = (strtotime('now') - strtotime($userStats['first_membership'])) / (30 * 24 * 60 * 60);
                    $shouldAward = $months >= 12;
                }
                break;
            case 7: // First Workout Logged
                $shouldAward = $userStats['total_workouts'] > 0;
                break;
            case 8: // Strength Builder
                $shouldAward = $userStats['total_sets'] >= 500;
                break;
            case 9: // Heavy Lifter
                $shouldAward = $userStats['max_weight'] >= 100;
                break;
            case 10: // Goal Setter
                $shouldAward = $userStats['goals_set'] > 0;
                break;
            case 11: // Goal Achiever
                $shouldAward = $userStats['goals_achieved'] > 0;
                break;
            case 12: // Coach Assigned
                $shouldAward = $userStats['coach_assigned'] > 0;
                break;
            case 13: // Feedback Giver
                $shouldAward = $userStats['reviews_given'] > 0;
                break;
        }
        
        if ($shouldAward) {
            try {
                // Award the achievement
                $awardStmt = $pdo->prepare("INSERT INTO member_achievements (user_id, achievement_id, awarded_at) VALUES (?, ?, NOW())");
                $awardStmt->execute([$user_id, $achievementId]);
                
                $newAchievements[] = [
                    'id' => $achievementId,
                    'awarded_at' => date('Y-m-d H:i:s')
                ];
                
                error_log("Awarded achievement $achievementId to user $user_id");
            } catch (Exception $e) {
                error_log("Error awarding achievement $achievementId: " . $e->getMessage());
            }
        }
    }
    
    error_log("New achievements awarded: " . json_encode($newAchievements));
    return $newAchievements;
}
?>

















