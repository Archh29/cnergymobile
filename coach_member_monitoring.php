<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Database configuration
$host = 'localhost';
$dbname = 'u773938685_cnergydb';
$username = 'u773938685_archh29';
$password = 'Gwapoko385@';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'error' => 'Database connection failed']);
    exit;
}

$action = $_GET['action'] ?? '';
$memberId = $_GET['member_id'] ?? '';

if (empty($memberId)) {
    echo json_encode(['success' => false, 'error' => 'Member ID is required']);
    exit;
}

switch ($action) {
    case 'get-attendance':
        echo json_encode(getAttendanceData($pdo, $memberId));
        break;
    case 'get-workout-logs':
        echo json_encode(getWorkoutLogs($pdo, $memberId));
        break;
    case 'get-profile-details':
        echo json_encode(getProfileDetails($pdo, $memberId));
        break;
    case 'get-fitness-goals':
        echo json_encode(getFitnessGoals($pdo, $memberId));
        break;
    case 'get-personal-records':
        echo json_encode(getPersonalRecords($pdo, $memberId));
        break;
    case 'get-progress-over-time':
        echo json_encode(getProgressOverTime($pdo, $memberId));
        break;
    case 'get-muscle-analytics':
        echo json_encode(getMuscleAnalytics($pdo, $memberId));
        break;
    default:
        echo json_encode(['success' => false, 'error' => 'Invalid action']);
}

function getAttendanceData($pdo, $memberId) {
    try {
        // Get total check-ins
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as total_checkins 
            FROM attendance 
            WHERE user_id = ? AND check_in IS NOT NULL
        ");
        $stmt->execute([$memberId]);
        $totalCheckIns = $stmt->fetch(PDO::FETCH_ASSOC)['total_checkins'];

        // Get this week's check-ins
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as this_week_checkins 
            FROM attendance 
            WHERE user_id = ? 
            AND check_in >= DATE_SUB(NOW(), INTERVAL WEEKDAY(NOW()) DAY)
            AND check_in IS NOT NULL
        ");
        $stmt->execute([$memberId]);
        $thisWeekCheckIns = $stmt->fetch(PDO::FETCH_ASSOC)['this_week_checkins'];

        // Get this month's check-ins
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as this_month_checkins 
            FROM attendance 
            WHERE user_id = ? 
            AND check_in >= DATE_FORMAT(NOW(), '%Y-%m-01')
            AND check_in IS NOT NULL
        ");
        $stmt->execute([$memberId]);
        $thisMonthCheckIns = $stmt->fetch(PDO::FETCH_ASSOC)['this_month_checkins'];

        // Get last check-in
        $stmt = $pdo->prepare("
            SELECT check_in, check_out 
            FROM attendance 
            WHERE user_id = ? AND check_in IS NOT NULL
            ORDER BY check_in DESC 
            LIMIT 1
        ");
        $stmt->execute([$memberId]);
        $lastCheckIn = $stmt->fetch(PDO::FETCH_ASSOC);

        // Calculate current streak
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as current_streak
            FROM (
                SELECT DATE(check_in) as check_date
                FROM attendance 
                WHERE user_id = ? AND check_in IS NOT NULL
                GROUP BY DATE(check_in)
                ORDER BY check_date DESC
            ) as daily_checkins
            WHERE check_date >= DATE_SUB(CURDATE(), INTERVAL (
                SELECT COUNT(*) - 1
                FROM (
                    SELECT DATE(check_in) as check_date
                    FROM attendance 
                    WHERE user_id = ? AND check_in IS NOT NULL
                    GROUP BY DATE(check_in)
                    ORDER BY check_date DESC
                ) as all_checkins
            ) DAY)
        ");
        $stmt->execute([$memberId, $memberId]);
        $currentStreak = $stmt->fetch(PDO::FETCH_ASSOC)['current_streak'];

        // Get weekly data for chart
        $stmt = $pdo->prepare("
            SELECT 
                DAYNAME(check_in) as day,
                COUNT(*) as checkins
            FROM attendance 
            WHERE user_id = ? 
            AND check_in >= DATE_SUB(NOW(), INTERVAL WEEKDAY(NOW()) DAY)
            AND check_in IS NOT NULL
            GROUP BY DAYNAME(check_in)
            ORDER BY FIELD(DAYNAME(check_in), 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
        ");
        $stmt->execute([$memberId]);
        $weeklyData = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return [
            'success' => true,
            'data' => [
                'total_checkins' => $totalCheckIns,
                'this_week_checkins' => $thisWeekCheckIns,
                'this_month_checkins' => $thisMonthCheckIns,
                'current_streak' => $currentStreak,
                'last_checkin' => $lastCheckIn,
                'weekly_data' => $weeklyData
            ]
        ];
    } catch (Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

function getWorkoutLogs($pdo, $memberId) {
    try {
        // Get total workouts
        $stmt = $pdo->prepare("
            SELECT COUNT(DISTINCT log_date) as total_workouts
            FROM member_exercise_log 
            WHERE member_id = ?
        ");
        $stmt->execute([$memberId]);
        $totalWorkouts = $stmt->fetch(PDO::FETCH_ASSOC)['total_workouts'];

        // Get this week's workouts
        $stmt = $pdo->prepare("
            SELECT COUNT(DISTINCT log_date) as this_week_workouts
            FROM member_exercise_log 
            WHERE member_id = ? 
            AND log_date >= DATE_SUB(NOW(), INTERVAL WEEKDAY(NOW()) DAY)
        ");
        $stmt->execute([$memberId]);
        $thisWeekWorkouts = $stmt->fetch(PDO::FETCH_ASSOC)['this_week_workouts'];

        // Get total sets, reps, and weight
        $stmt = $pdo->prepare("
            SELECT 
                SUM(actual_sets) as total_sets,
                SUM(actual_reps) as total_reps,
                SUM(total_kg) as total_weight
            FROM member_exercise_log 
            WHERE member_id = ?
        ");
        $stmt->execute([$memberId]);
        $totals = $stmt->fetch(PDO::FETCH_ASSOC);

        // Get recent workouts with exercise names
        $stmt = $pdo->prepare("
            SELECT 
                mel.log_date,
                mel.actual_sets,
                mel.actual_reps,
                mel.total_kg,
                e.exercise_name
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            LEFT JOIN exercise e ON mwe.exercise_id = e.id
            WHERE mel.member_id = ?
            ORDER BY mel.log_date DESC, mel.id DESC
            LIMIT 10
        ");
        $stmt->execute([$memberId]);
        $recentWorkouts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return [
            'success' => true,
            'data' => [
                'total_workouts' => $totalWorkouts,
                'this_week_workouts' => $thisWeekWorkouts,
                'total_sets' => $totals['total_sets'] ?? 0,
                'total_reps' => $totals['total_reps'] ?? 0,
                'total_weight' => $totals['total_weight'] ?? 0,
                'recent_workouts' => $recentWorkouts
            ]
        ];
    } catch (Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

function getProfileDetails($pdo, $memberId) {
    try {
        $stmt = $pdo->prepare("
            SELECT 
                fitness_level,
                fitness_goal,
                gender_id,
                birthdate,
                height_cm,
                weight_kg,
                target_weight,
                body_fat,
                activity_level,
                workout_days_per_week,
                equipment_access,
                created_at,
                profile_completed,
                profile_completed_at,
                onboarding_completed_at
            FROM member_profile_details 
            WHERE user_id = ?
        ");
        $stmt->execute([$memberId]);
        $profile = $stmt->fetch(PDO::FETCH_ASSOC);

        return [
            'success' => true,
            'data' => $profile ?: []
        ];
    } catch (Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

function getFitnessGoals($pdo, $memberId) {
    try {
        $stmt = $pdo->prepare("
            SELECT 
                id,
                goal_name,
                created_at,
                is_achieved,
                achieved_at
            FROM member_fitness_goals 
            WHERE user_id = ?
            ORDER BY created_at DESC
        ");
        $stmt->execute([$memberId]);
        $goals = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return [
            'success' => true,
            'data' => [
                'goals' => $goals
            ]
        ];
    } catch (Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

function getPersonalRecords($pdo, $memberId) {
    try {
        // Get personal records for each exercise
        $stmt = $pdo->prepare("
            SELECT 
                e.exercise_name,
                MAX(mel.total_kg) as max_weight,
                MAX(mel.actual_reps) as max_reps,
                mel.log_date as achieved_date,
                'PR' as record_type
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            LEFT JOIN exercise e ON mwe.exercise_id = e.id
            WHERE mel.member_id = ? AND mel.total_kg > 0
            GROUP BY e.id, e.exercise_name
            HAVING max_weight > 0
            ORDER BY max_weight DESC
        ");
        $stmt->execute([$memberId]);
        $records = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return [
            'success' => true,
            'data' => [
                'records' => $records
            ]
        ];
    } catch (Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

function getProgressOverTime($pdo, $memberId) {
    try {
        // Get weight progress (from profile details if available, or from workout logs)
        $weightProgress = [];
        
        // Get monthly attendance progress
        $stmt = $pdo->prepare("
            SELECT 
                DATE_FORMAT(check_in, '%Y-%m') as month,
                COUNT(*) as visits
            FROM attendance 
            WHERE user_id = ? AND check_in IS NOT NULL
            AND check_in >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY DATE_FORMAT(check_in, '%Y-%m')
            ORDER BY month ASC
        ");
        $stmt->execute([$memberId]);
        $attendanceData = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $attendanceProgress = array_map(function($item) {
            return [
                'date' => $item['month'] . '-01',
                'value' => $item['visits']
            ];
        }, $attendanceData);

        // Get strength progress (max weight lifted per month)
        $stmt = $pdo->prepare("
            SELECT 
                DATE_FORMAT(log_date, '%Y-%m') as month,
                MAX(total_kg) as max_weight
            FROM member_exercise_log 
            WHERE member_id = ? AND total_kg > 0
            AND log_date >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY DATE_FORMAT(log_date, '%Y-%m')
            ORDER BY month ASC
        ");
        $stmt->execute([$memberId]);
        $strengthData = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $strengthProgress = array_map(function($item) {
            return [
                'date' => $item['month'] . '-01',
                'value' => $item['max_weight']
            ];
        }, $strengthData);

        return [
            'success' => true,
            'data' => [
                'weight_progress' => $weightProgress,
                'strength_progress' => $strengthProgress,
                'attendance_progress' => $attendanceProgress
            ]
        ];
    } catch (Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

function getMuscleAnalytics($pdo, $memberId) {
    try {
        // Get this week's muscle hits (unique muscle groups worked)
        $stmt = $pdo->prepare("
            SELECT COUNT(DISTINCT etm.muscle_id) as this_week_muscle_hits
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            LEFT JOIN exercise e ON mwe.exercise_id = e.id
            LEFT JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
            WHERE mel.member_id = ? 
            AND mel.log_date >= DATE_SUB(NOW(), INTERVAL WEEKDAY(NOW()) DAY)
        ");
        $stmt->execute([$memberId]);
        $thisWeekMuscleHits = $stmt->fetch(PDO::FETCH_ASSOC)['this_week_muscle_hits'];

        // Get this month's muscle hits
        $stmt = $pdo->prepare("
            SELECT COUNT(DISTINCT etm.muscle_id) as this_month_muscle_hits
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            LEFT JOIN exercise e ON mwe.exercise_id = e.id
            LEFT JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
            WHERE mel.member_id = ? 
            AND mel.log_date >= DATE_FORMAT(NOW(), '%Y-%m-01')
        ");
        $stmt->execute([$memberId]);
        $thisMonthMuscleHits = $stmt->fetch(PDO::FETCH_ASSOC)['this_month_muscle_hits'];

        // Get top muscle groups this week
        $stmt = $pdo->prepare("
            SELECT 
                m.muscle_name as muscle_group,
                COUNT(DISTINCT e.id) as exercise_count,
                COUNT(DISTINCT mel.log_date) as workout_sessions,
                SUM(mel.actual_reps) as total_reps,
                AVG(mel.total_kg) as avg_weight
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            LEFT JOIN exercise e ON mwe.exercise_id = e.id
            LEFT JOIN exercise_target_muscle etm ON e.id = etm.exercise_id
            LEFT JOIN muscle m ON etm.muscle_id = m.id
            WHERE mel.member_id = ? 
            AND mel.log_date >= DATE_SUB(NOW(), INTERVAL WEEKDAY(NOW()) DAY)
            AND m.muscle_name IS NOT NULL
            GROUP BY m.id, m.muscle_name
            ORDER BY total_reps DESC
            LIMIT 5
        ");
        $stmt->execute([$memberId]);
        $topMuscleGroups = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return [
            'success' => true,
            'data' => [
                'this_week_muscle_hits' => $thisWeekMuscleHits,
                'this_month_muscle_hits' => $thisMonthMuscleHits,
                'top_muscle_groups' => $topMuscleGroups
            ]
        ];
    } catch (Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}
?>
