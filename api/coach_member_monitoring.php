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
    case 'get-compliance-metrics':
        echo json_encode(getComplianceMetrics($pdo, $memberId));
        break;
    case 'debug-workout-data':
        echo json_encode(debugWorkoutData($pdo, $memberId));
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

        // Get recent workouts with prescribed vs actual comparison
        $stmt = $pdo->prepare("
            SELECT 
                mel.log_date,
                mel.actual_sets,
                mel.actual_reps,
                mel.total_kg,
                mwe.sets as prescribed_sets,
                mwe.reps as prescribed_reps,
                mwe.weight as prescribed_weight,
                e.name as exercise_name,
                -- Calculate compliance percentages
                CASE 
                    WHEN mwe.sets > 0 THEN ROUND((mel.actual_sets / mwe.sets) * 100, 1)
                    ELSE 0 
                END as sets_compliance,
                CASE 
                    WHEN (mwe.sets * mwe.reps) > 0 THEN ROUND((mel.actual_reps / (mwe.sets * mwe.reps)) * 100, 1)
                    ELSE 0 
                END as reps_compliance,
                CASE 
                    WHEN (mwe.sets * mwe.reps * mwe.weight) > 0 THEN ROUND((mel.total_kg / (mwe.sets * mwe.reps * mwe.weight)) * 100, 1)
                    ELSE 0 
                END as volume_compliance,
                -- Calculate prescribed volume
                (mwe.sets * mwe.reps * mwe.weight) as prescribed_volume
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            LEFT JOIN exercise e ON mwe.exercise_id = e.id
            WHERE mel.member_id = ?
            ORDER BY mel.log_date DESC, mel.id DESC
            LIMIT 10
        ");
        $stmt->execute([$memberId]);
        $recentWorkouts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Get overall compliance metrics
        $stmt = $pdo->prepare("
            SELECT 
                AVG(CASE 
                    WHEN mwe.sets > 0 THEN (mel.actual_sets / mwe.sets) * 100
                    ELSE 0 
                END) as avg_sets_compliance,
                AVG(CASE 
                    WHEN (mwe.sets * mwe.reps) > 0 THEN (mel.actual_reps / (mwe.sets * mwe.reps)) * 100
                    ELSE 0 
                END) as avg_reps_compliance,
                AVG(CASE 
                    WHEN (mwe.sets * mwe.reps * mwe.weight) > 0 THEN (mel.total_kg / (mwe.sets * mwe.reps * mwe.weight)) * 100
                    ELSE 0 
                END) as avg_volume_compliance,
                COUNT(*) as total_exercise_sessions
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            WHERE mel.member_id = ?
        ");
        $stmt->execute([$memberId]);
        $complianceMetrics = $stmt->fetch(PDO::FETCH_ASSOC);

        return [
            'success' => true,
            'data' => [
                'total_workouts' => $totalWorkouts,
                'this_week_workouts' => $thisWeekWorkouts,
                'total_sets' => $totals['total_sets'] ?? 0,
                'total_reps' => $totals['total_reps'] ?? 0,
                'total_weight' => $totals['total_weight'] ?? 0,
                'recent_workouts' => $recentWorkouts,
                'compliance_metrics' => [
                    'avg_sets_compliance' => round($complianceMetrics['avg_sets_compliance'] ?? 0, 1),
                    'avg_reps_compliance' => round($complianceMetrics['avg_reps_compliance'] ?? 0, 1),
                    'avg_volume_compliance' => round($complianceMetrics['avg_volume_compliance'] ?? 0, 1),
                    'total_exercise_sessions' => $complianceMetrics['total_exercise_sessions'] ?? 0
                ]
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
                e.name as exercise_name,
                MAX(mel.total_kg) as max_weight,
                MAX(mel.actual_reps) as max_reps,
                mel.log_date as achieved_date,
                'PR' as record_type
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            LEFT JOIN exercise e ON mwe.exercise_id = e.id
            WHERE mel.member_id = ? AND mel.total_kg > 0
            GROUP BY e.id, e.name
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

        // Get volume progress (total weight lifted per month)
        $stmt = $pdo->prepare("
            SELECT 
                DATE_FORMAT(log_date, '%Y-%m') as month,
                SUM(total_kg) as total_volume
            FROM member_exercise_log 
            WHERE member_id = ? AND total_kg > 0
            AND log_date >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY DATE_FORMAT(log_date, '%Y-%m')
            ORDER BY month ASC
        ");
        $stmt->execute([$memberId]);
        $volumeData = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $volumeProgress = array_map(function($item) {
            return [
                'date' => $item['month'] . '-01',
                'value' => $item['total_volume']
            ];
        }, $volumeData);

        // Get compliance progress (average compliance per month)
        $stmt = $pdo->prepare("
            SELECT 
                DATE_FORMAT(mel.log_date, '%Y-%m') as month,
                AVG(CASE 
                    WHEN mwe.sets > 0 THEN (mel.actual_sets / mwe.sets) * 100
                    ELSE 0 
                END) as avg_sets_compliance,
                AVG(CASE 
                    WHEN (mwe.sets * mwe.reps) > 0 THEN (mel.actual_reps / (mwe.sets * mwe.reps)) * 100
                    ELSE 0 
                END) as avg_reps_compliance,
                AVG(CASE 
                    WHEN (mwe.sets * mwe.reps * mwe.weight) > 0 THEN (mel.total_kg / (mwe.sets * mwe.reps * mwe.weight)) * 100
                    ELSE 0 
                END) as avg_volume_compliance
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            WHERE mel.member_id = ?
            AND mel.log_date >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY DATE_FORMAT(mel.log_date, '%Y-%m')
            ORDER BY month ASC
        ");
        $stmt->execute([$memberId]);
        $complianceData = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $complianceProgress = array_map(function($item) {
            return [
                'date' => $item['month'] . '-01',
                'sets_compliance' => round($item['avg_sets_compliance'] ?? 0, 1),
                'reps_compliance' => round($item['avg_reps_compliance'] ?? 0, 1),
                'volume_compliance' => round($item['avg_volume_compliance'] ?? 0, 1)
            ];
        }, $complianceData);

        // Get progressive overload data (week-over-week improvements)
        $stmt = $pdo->prepare("
            SELECT 
                DATE_FORMAT(log_date, '%Y-%u') as week,
                AVG(total_kg) as avg_weight_per_session,
                SUM(total_kg) as total_volume,
                COUNT(DISTINCT log_date) as workout_days
            FROM member_exercise_log 
            WHERE member_id = ? AND total_kg > 0
            AND log_date >= DATE_SUB(NOW(), INTERVAL 12 WEEK)
            GROUP BY DATE_FORMAT(log_date, '%Y-%u')
            ORDER BY week ASC
        ");
        $stmt->execute([$memberId]);
        $progressiveData = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $progressiveOverload = array_map(function($item) {
            return [
                'date' => $item['week'],
                'avg_weight' => round($item['avg_weight_per_session'] ?? 0, 1),
                'total_volume' => round($item['total_volume'] ?? 0, 1),
                'workout_days' => $item['workout_days']
            ];
        }, $progressiveData);

        return [
            'success' => true,
            'data' => [
                'weight_progress' => $weightProgress,
                'strength_progress' => $strengthProgress,
                'attendance_progress' => $attendanceProgress,
                'volume_progress' => $volumeProgress,
                'compliance_progress' => $complianceProgress,
                'progressive_overload' => $progressiveOverload
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

function getComplianceMetrics($pdo, $memberId) {
    try {
        // Get exercise-specific compliance metrics
        $stmt = $pdo->prepare("
            SELECT 
                e.name as exercise_name,
                COUNT(*) as total_sessions,
                AVG(CASE 
                    WHEN mwe.sets > 0 THEN (mel.actual_sets / mwe.sets) * 100
                    ELSE 0 
                END) as avg_sets_compliance,
                AVG(CASE 
                    WHEN (mwe.sets * mwe.reps) > 0 THEN (mel.actual_reps / (mwe.sets * mwe.reps)) * 100
                    ELSE 0 
                END) as avg_reps_compliance,
                AVG(CASE 
                    WHEN (mwe.sets * mwe.reps * mwe.weight) > 0 THEN (mel.total_kg / (mwe.sets * mwe.reps * mwe.weight)) * 100
                    ELSE 0 
                END) as avg_volume_compliance,
                -- Get latest performance
                MAX(mel.log_date) as last_workout,
                AVG(mel.actual_sets) as avg_actual_sets,
                AVG(mel.actual_reps) as avg_actual_reps,
                AVG(mel.total_kg) as avg_actual_weight,
                AVG(mwe.sets) as avg_prescribed_sets,
                AVG(mwe.reps) as avg_prescribed_reps,
                AVG(mwe.weight) as avg_prescribed_weight
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            LEFT JOIN exercise e ON mwe.exercise_id = e.id
            WHERE mel.member_id = ?
            GROUP BY e.id, e.name
            HAVING total_sessions > 0
            ORDER BY avg_volume_compliance DESC
        ");
        $stmt->execute([$memberId]);
        $exerciseCompliance = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Get weekly compliance trends
        $stmt = $pdo->prepare("
            SELECT 
                DATE_FORMAT(mel.log_date, '%Y-%u') as week,
                COUNT(*) as total_sessions,
                AVG(CASE 
                    WHEN mwe.sets > 0 THEN (mel.actual_sets / mwe.sets) * 100
                    ELSE 0 
                END) as avg_sets_compliance,
                AVG(CASE 
                    WHEN (mwe.sets * mwe.reps) > 0 THEN (mel.actual_reps / (mwe.sets * mwe.reps)) * 100
                    ELSE 0 
                END) as avg_reps_compliance,
                AVG(CASE 
                    WHEN (mwe.sets * mwe.reps * mwe.weight) > 0 THEN (mel.total_kg / (mwe.sets * mwe.reps * mwe.weight)) * 100
                    ELSE 0 
                END) as avg_volume_compliance
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            WHERE mel.member_id = ?
            AND mel.log_date >= DATE_SUB(NOW(), INTERVAL 8 WEEK)
            GROUP BY DATE_FORMAT(mel.log_date, '%Y-%u')
            ORDER BY week ASC
        ");
        $stmt->execute([$memberId]);
        $weeklyTrends = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Get overall compliance summary
        $stmt = $pdo->prepare("
            SELECT 
                COUNT(*) as total_exercise_sessions,
                COUNT(DISTINCT DATE(mel.log_date)) as total_workout_days,
                AVG(CASE 
                    WHEN mwe.sets > 0 THEN (mel.actual_sets / mwe.sets) * 100
                    ELSE 0 
                END) as overall_sets_compliance,
                AVG(CASE 
                    WHEN (mwe.sets * mwe.reps) > 0 THEN (mel.actual_reps / (mwe.sets * mwe.reps)) * 100
                    ELSE 0 
                END) as overall_reps_compliance,
                AVG(CASE 
                    WHEN (mwe.sets * mwe.reps * mwe.weight) > 0 THEN (mel.total_kg / (mwe.sets * mwe.reps * mwe.weight)) * 100
                    ELSE 0 
                END) as overall_volume_compliance,
                -- Calculate improvement trends
                (SELECT AVG(CASE 
                    WHEN mwe.sets > 0 THEN (mel.actual_sets / mwe.sets) * 100
                    ELSE 0 
                END) FROM member_exercise_log mel 
                LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
                WHERE mel.member_id = ? AND mel.log_date >= DATE_SUB(NOW(), INTERVAL 2 WEEK)) as recent_sets_compliance,
                (SELECT AVG(CASE 
                    WHEN mwe.sets > 0 THEN (mel.actual_sets / mwe.sets) * 100
                    ELSE 0 
                END) FROM member_exercise_log mel 
                LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
                WHERE mel.member_id = ? AND mel.log_date < DATE_SUB(NOW(), INTERVAL 2 WEEK) 
                AND mel.log_date >= DATE_SUB(NOW(), INTERVAL 4 WEEK)) as previous_sets_compliance
            FROM member_exercise_log mel
            LEFT JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            WHERE mel.member_id = ?
        ");
        $stmt->execute([$memberId, $memberId, $memberId]);
        $overallSummary = $stmt->fetch(PDO::FETCH_ASSOC);

        // Calculate improvement percentage
        $improvementPercentage = 0;
        if ($overallSummary['previous_sets_compliance'] > 0) {
            $improvementPercentage = round(
                (($overallSummary['recent_sets_compliance'] - $overallSummary['previous_sets_compliance']) / 
                 $overallSummary['previous_sets_compliance']) * 100, 1
            );
        }

        return [
            'success' => true,
            'data' => [
                'exercise_compliance' => array_map(function($item) {
                    return [
                        'exercise_name' => $item['exercise_name'],
                        'total_sessions' => $item['total_sessions'],
                        'avg_sets_compliance' => round($item['avg_sets_compliance'] ?? 0, 1),
                        'avg_reps_compliance' => round($item['avg_reps_compliance'] ?? 0, 1),
                        'avg_volume_compliance' => round($item['avg_volume_compliance'] ?? 0, 1),
                        'last_workout' => $item['last_workout'],
                        'avg_actual_sets' => round($item['avg_actual_sets'] ?? 0, 1),
                        'avg_actual_reps' => round($item['avg_actual_reps'] ?? 0, 1),
                        'avg_actual_weight' => round($item['avg_actual_weight'] ?? 0, 1),
                        'avg_prescribed_sets' => round($item['avg_prescribed_sets'] ?? 0, 1),
                        'avg_prescribed_reps' => round($item['avg_prescribed_reps'] ?? 0, 1),
                        'avg_prescribed_weight' => round($item['avg_prescribed_weight'] ?? 0, 1)
                    ];
                }, $exerciseCompliance),
                'weekly_trends' => array_map(function($item) {
                    return [
                        'week' => $item['week'],
                        'total_sessions' => $item['total_sessions'],
                        'avg_sets_compliance' => round($item['avg_sets_compliance'] ?? 0, 1),
                        'avg_reps_compliance' => round($item['avg_reps_compliance'] ?? 0, 1),
                        'avg_volume_compliance' => round($item['avg_volume_compliance'] ?? 0, 1)
                    ];
                }, $weeklyTrends),
                'overall_summary' => [
                    'total_exercise_sessions' => $overallSummary['total_exercise_sessions'] ?? 0,
                    'total_workout_days' => $overallSummary['total_workout_days'] ?? 0,
                    'overall_sets_compliance' => round($overallSummary['overall_sets_compliance'] ?? 0, 1),
                    'overall_reps_compliance' => round($overallSummary['overall_reps_compliance'] ?? 0, 1),
                    'overall_volume_compliance' => round($overallSummary['overall_volume_compliance'] ?? 0, 1),
                    'improvement_percentage' => $improvementPercentage
                ]
            ]
        ];
    } catch (Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}
?>
