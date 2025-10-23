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

// Weekly Muscle Analytics API
// action=weekly&user_id=XX[&week_start=YYYY-MM-DD]

try {
    $action = $_GET['action'] ?? 'weekly';
    if ($action !== 'weekly') {
        echo json_encode(['success' => false, 'message' => 'Unsupported action']);
        exit;
    }

    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    if ($userId <= 0) {
        echo json_encode(['success' => false, 'message' => 'Missing or invalid user_id']);
        exit;
    }

    // Determine week range (Mon-Sun) based on optional week_start
    $weekStartParam = $_GET['week_start'] ?? null; // YYYY-MM-DD
    if ($weekStartParam) {
        $weekStart = new DateTime($weekStartParam);
    } else {
        // Default to current week (Monday as start)
        $today = new DateTime();
        $weekStart = clone $today;
        $weekStart->modify('monday this week');
    }
    $weekEnd = clone $weekStart;
    $weekEnd->modify('+6 day');

    $startDate = $weekStart->format('Y-m-d');
    $endDate = $weekEnd->format('Y-m-d');

    // Load user training preferences (fail gracefully if table doesn't exist)
    $trainingFocus = 'full_body';
    $customMuscleGroups = null;
    
    // CRITICAL DEBUG: Check if table exists
    try {
        $tableCheck = $pdo->query("SHOW TABLES LIKE 'user_training_preferences'");
        $tableExists = $tableCheck->rowCount() > 0;
        error_log("🔍 🔍 🔍 TABLE EXISTS: " . ($tableExists ? 'YES' : 'NO'));
        
        if ($tableExists) {
            // Check if user has preferences
            $prefStmt = $pdo->prepare("SELECT * FROM user_training_preferences WHERE user_id = :userId");
            $prefStmt->execute([':userId' => $userId]);
            $userPrefs = $prefStmt->fetch();
            
            error_log("🔍 🔍 🔍 USER ID: " . $userId);
            error_log("🔍 🔍 🔍 USER PREFS FOUND: " . ($userPrefs ? 'YES' : 'NO'));
            error_log("🔍 🔍 🔍 USER PREFS DATA: " . json_encode($userPrefs));
            
            if ($userPrefs) {
                $trainingFocus = $userPrefs['training_focus'];
                error_log("🔍 🔍 🔍 TRAINING FOCUS FROM DB: " . $trainingFocus);
            } else {
                error_log("🔍 🔍 🔍 NO PREFERENCES FOR THIS USER - USING DEFAULT: full_body");
            }
        }
    } catch (Exception $e) {
        error_log("🔍 🔍 🔍 ERROR LOADING PREFS: " . $e->getMessage());
    }
    
    // Old code for compatibility
    try {
        $prefStmt = $pdo->prepare("SELECT training_focus, custom_muscle_groups FROM user_training_preferences WHERE user_id = :userId");
        $prefStmt->execute([':userId' => $userId]);
        $userPrefs = $prefStmt->fetch();
        
        $trainingFocus = $userPrefs ? $userPrefs['training_focus'] : 'full_body';
        
        // Decode and ensure all IDs are integers
        if ($userPrefs && $userPrefs['custom_muscle_groups']) {
            $decoded = json_decode($userPrefs['custom_muscle_groups'], true);
            $customMuscleGroups = is_array($decoded) ? array_map('intval', $decoded) : null;
            error_log("🔍 PHP DEBUG - customMuscleGroups: " . json_encode($customMuscleGroups));
        } else {
            $customMuscleGroups = null;
            error_log("🔍 PHP DEBUG - customMuscleGroups is NULL");
        }
    } catch (Exception $e) {
        // Table doesn't exist yet, use defaults
        error_log("user_training_preferences table not found, using defaults: " . $e->getMessage());
    }

    // Load dismissed warnings (Smart Silence) - fail gracefully if table doesn't exist
    $dismissedWarnings = [];
    try {
        $dismissStmt = $pdo->prepare("SELECT muscle_group_id, warning_type, dismiss_count, is_permanent FROM user_warning_dismissals WHERE user_id = :userId");
        $dismissStmt->execute([':userId' => $userId]);
        foreach ($dismissStmt->fetchAll() as $row) {
            $key = (int)$row['muscle_group_id'] . '_' . $row['warning_type'];
            $dismissedWarnings[$key] = [
                'count' => (int)$row['dismiss_count'],
                'permanent' => (bool)$row['is_permanent']
            ];
        }
    } catch (Exception $e) {
        // Table doesn't exist yet, no warnings to dismiss
        error_log("user_warning_dismissals table not found: " . $e->getMessage());
    }

    // Core aggregation per muscle (include ALL sub-muscles even if no activity this week)
    $sql = "
        SELECT 
            tm.id AS muscle_id,
            tm.name AS muscle_name,
            tm.parent_id AS group_id,
            COALESCE(SUM((msl.reps * COALESCE(NULLIF(msl.weight,0), 1)) *
                   CASE WHEN etm.role='primary' THEN 1
                        WHEN etm.role='secondary' THEN 0.5
                        ELSE 0.25 END), 0) AS total_load,
            COUNT(DISTINCT CASE WHEN etm_p.id IS NOT NULL THEN psl.id END) AS total_sets,
            COUNT(DISTINCT CASE WHEN etm_p.id IS NOT NULL THEN pmel.log_date END) AS sessions,
            COALESCE(SUM(CASE WHEN etm_p.id IS NOT NULL THEN psl.reps ELSE 0 END), 0) AS total_reps,
            COUNT(DISTINCT mel.member_workout_exercise_id) AS total_exercises,
            MIN(mel.log_date) AS first_date,
            MAX(mel.log_date) AS last_date
        FROM target_muscle tm
        LEFT JOIN exercise_target_muscle etm ON etm.muscle_id = tm.id
        LEFT JOIN member_workout_exercise mwe ON mwe.exercise_id = etm.exercise_id
        LEFT JOIN member_exercise_log mel 
            ON mel.member_workout_exercise_id = mwe.id 
           AND mel.member_id = :userId 
           AND mel.log_date BETWEEN :startDate AND :endDate
        LEFT JOIN member_exercise_set_log msl ON msl.exercise_log_id = mel.id
        /* primary-only alias for accurate sets/reps/sessions */
        LEFT JOIN exercise_target_muscle etm_p 
            ON etm_p.exercise_id = mwe.exercise_id AND etm_p.muscle_id = tm.id AND etm_p.role='primary'
        LEFT JOIN member_exercise_log pmel 
            ON pmel.member_workout_exercise_id = mwe.id 
           AND pmel.member_id = :userId 
           AND pmel.log_date BETWEEN :startDate AND :endDate
        LEFT JOIN member_exercise_set_log psl ON psl.exercise_log_id = pmel.id
        WHERE tm.parent_id IS NOT NULL
        GROUP BY tm.id, tm.name, tm.parent_id
        ORDER BY tm.name ASC
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':userId' => $userId,
        ':startDate' => $startDate,
        ':endDate' => $endDate,
    ]);
    $rows = $stmt->fetchAll();

    // Aggregate per muscle group (include ALL groups even if no activity this week)
    $groupSql = "
        SELECT 
            g.id AS group_id,
            g.name AS group_name,
            COALESCE(SUM((msl.reps * COALESCE(NULLIF(msl.weight,0), 1)) *
                   CASE WHEN etm.role='primary' THEN 1
                        WHEN etm.role='secondary' THEN 0.5
                        ELSE 0.25 END), 0) AS total_load,
            COUNT(DISTINCT CASE WHEN etm_p.id IS NOT NULL THEN psl.id END) AS total_sets,
            COUNT(DISTINCT CASE WHEN etm_p.id IS NOT NULL THEN pmel.log_date END) AS sessions,
            COALESCE(SUM(CASE WHEN etm_p.id IS NOT NULL THEN psl.reps ELSE 0 END), 0) AS total_reps,
            COUNT(DISTINCT mel.member_workout_exercise_id) AS total_exercises
        FROM target_muscle g
        LEFT JOIN target_muscle tm ON tm.parent_id = g.id OR tm.id = g.id
        LEFT JOIN exercise_target_muscle etm ON etm.muscle_id = tm.id
        LEFT JOIN member_workout_exercise mwe ON mwe.exercise_id = etm.exercise_id
        LEFT JOIN member_exercise_log mel 
            ON mel.member_workout_exercise_id = mwe.id 
           AND mel.member_id = :userId 
           AND mel.log_date BETWEEN :startDate AND :endDate
        LEFT JOIN member_exercise_set_log msl ON msl.exercise_log_id = mel.id
        /* primary-only alias for accurate sets/reps/sessions */
        LEFT JOIN exercise_target_muscle etm_p 
            ON etm_p.exercise_id = mwe.exercise_id AND etm_p.muscle_id = tm.id AND etm_p.role='primary'
        LEFT JOIN member_exercise_log pmel 
            ON pmel.member_workout_exercise_id = mwe.id 
           AND pmel.member_id = :userId 
           AND pmel.log_date BETWEEN :startDate AND :endDate
        LEFT JOIN member_exercise_set_log psl ON psl.exercise_log_id = pmel.id
        WHERE g.parent_id IS NULL
        GROUP BY g.id, g.name
        ORDER BY g.name ASC
    ";

    $stmt2 = $pdo->prepare($groupSql);
    $stmt2->execute([
        ':userId' => $userId,
        ':startDate' => $startDate,
        ':endDate' => $endDate,
    ]);
    $groupRows = $stmt2->fetchAll();

    // Per-group exercise list (top 10 by usage)
    $exByGroupSql = "
        SELECT
            COALESCE(parent.id, tm.id) AS group_id,
            e.id AS exercise_id,
            e.name AS exercise_name,
            COALESCE(SUM(CASE WHEN etm.role='primary' THEN 1 ELSE 0 END), 0) AS sets,
            COALESCE(SUM(CASE WHEN etm.role='primary' THEN msl.reps ELSE 0 END), 0) AS reps,
            COALESCE(SUM((msl.reps * COALESCE(NULLIF(msl.weight,0), 1)) *
                   CASE WHEN etm.role='primary' THEN 1
                        WHEN etm.role='secondary' THEN 0.5
                        ELSE 0.25 END), 0) AS intensity
        FROM member_exercise_log mel
        JOIN member_workout_exercise mwe ON mwe.id = mel.member_workout_exercise_id
        JOIN exercise e ON e.id = mwe.exercise_id
        JOIN exercise_target_muscle etm ON etm.exercise_id = mwe.exercise_id
        JOIN target_muscle tm ON tm.id = etm.muscle_id
        LEFT JOIN target_muscle parent ON tm.parent_id = parent.id
        LEFT JOIN member_exercise_set_log msl ON msl.exercise_log_id = mel.id
        WHERE mel.member_id = :userId
          AND mel.log_date BETWEEN :startDate AND :endDate
        GROUP BY group_id, e.id, e.name
        ORDER BY group_id ASC, intensity DESC
    ";
    $stmt3 = $pdo->prepare($exByGroupSql);
    $stmt3->execute([':userId' => $userId, ':startDate' => $startDate, ':endDate' => $endDate]);
    $exByGroupAll = $stmt3->fetchAll();
    $exercisesByGroup = [];
    foreach ($exByGroupAll as $row) {
        $gid = (int)$row['group_id'];
        if (!isset($exercisesByGroup[$gid])) $exercisesByGroup[$gid] = [];
        if (count($exercisesByGroup[$gid]) < 10) {
            $exercisesByGroup[$gid][] = [
                'exercise_id' => (int)$row['exercise_id'],
                'exercise_name' => (string)$row['exercise_name'],
                'sets' => (int)$row['sets'],
                'reps' => (int)$row['reps'],
                'load' => (float)$row['intensity'],
            ];
        }
    }

    // Per-muscle exercise list (top 10)
    $exByMuscleSql = "
        SELECT
            tm.id AS muscle_id,
            e.id AS exercise_id,
            e.name AS exercise_name,
            COALESCE(SUM(CASE WHEN etm.role='primary' THEN 1 ELSE 0 END), 0) AS sets,
            COALESCE(SUM(CASE WHEN etm.role='primary' THEN msl.reps ELSE 0 END), 0) AS reps,
            COALESCE(SUM((msl.reps * COALESCE(NULLIF(msl.weight,0), 1)) *
                   CASE WHEN etm.role='primary' THEN 1
                        WHEN etm.role='secondary' THEN 0.5
                        ELSE 0.25 END), 0) AS intensity
        FROM member_exercise_log mel
        JOIN member_workout_exercise mwe ON mwe.id = mel.member_workout_exercise_id
        JOIN exercise e ON e.id = mwe.exercise_id
        JOIN exercise_target_muscle etm ON etm.exercise_id = mwe.exercise_id
        JOIN target_muscle tm ON tm.id = etm.muscle_id
        LEFT JOIN member_exercise_set_log msl ON msl.exercise_log_id = mel.id
        WHERE mel.member_id = :userId
          AND mel.log_date BETWEEN :startDate AND :endDate
        GROUP BY tm.id, e.id, e.name
        ORDER BY tm.id ASC, intensity DESC
    ";
    $stmt4 = $pdo->prepare($exByMuscleSql);
    $stmt4->execute([':userId' => $userId, ':startDate' => $startDate, ':endDate' => $endDate]);
    $exByMuscleAll = $stmt4->fetchAll();
    $exercisesByMuscle = [];
    foreach ($exByMuscleAll as $row) {
        $mid = (int)$row['muscle_id'];
        if (!isset($exercisesByMuscle[$mid])) $exercisesByMuscle[$mid] = [];
        if (count($exercisesByMuscle[$mid]) < 10) {
            $exercisesByMuscle[$mid][] = [
                'exercise_id' => (int)$row['exercise_id'],
                'exercise_name' => (string)$row['exercise_name'],
                'sets' => (int)$row['sets'],
                'reps' => (int)$row['reps'],
                'load' => (float)$row['intensity'],
            ];
        }
    }

    // Compute weekly averages and summary
    $totalLoad = 0; $totalSets = 0; $countMuscles = 0;
    foreach ($groupRows as $gr) {
        $totalLoad += (float)$gr['total_load'];
        $totalSets += (int)$gr['total_sets'];
        $countMuscles++;
    }
    $avgLoad = $countMuscles > 0 ? $totalLoad / $countMuscles : 0;
    $avgSets = $countMuscles > 0 ? $totalSets / $countMuscles : 0;

    // Determine which muscle groups to track based on training focus
    $trackedGroups = getTrackedMuscleGroups($trainingFocus, $customMuscleGroups, $groupRows);
    error_log("🔍 PHP DEBUG - trackedGroups: " . json_encode($trackedGroups));

    $focused = [];
    $neglected = [];
    $neglectedWithWarnings = []; // Only show warnings if not dismissed
    
    foreach ($groupRows as $gr) {
        $groupId = (int)$gr['group_id'];
        $groupName = $gr['group_name'];
        
        // Skip if not in tracked groups
        if (!in_array($groupId, $trackedGroups)) {
            continue;
        }
        
        $gl = (float)$gr['total_load'];
        $gs = (int)$gr['total_sets'];
        
        if ($avgLoad > 0 && $gl >= 1.5 * $avgLoad || ($avgSets > 0 && $gs >= 1.5 * $avgSets)) {
            $focused[] = $groupName;
        } elseif (($avgLoad > 0 && $gl <= 0.5 * $avgLoad) && ($avgSets > 0 && $gs <= 0.5 * $avgSets)) {
            $neglected[] = $groupName;
            
            // Check if warning should be shown (Smart Silence logic)
            $warningKey = $groupId . '_neglected';
            if (shouldShowWarning($warningKey, $dismissedWarnings)) {
                $neglectedWithWarnings[] = [
                    'group_id' => (int)$groupId, // Ensure integer type
                    'group_name' => (string)$groupName,
                    'can_dismiss' => true,
                    'message' => "You haven't trained $groupName much this week."
                ];
            }
        }
    }

    $summaryParts = [];
    if (!empty($focused)) {
        $summaryParts[] = 'You focused more on ' . implode(', ', $focused);
    }
    if (!empty($neglected)) {
        if ($trainingFocus !== 'full_body') {
            $summaryParts[] = 'with lighter work on ' . implode(', ', $neglected);
        } else {
            $summaryParts[] = 'but neglected ' . implode(', ', $neglected);
        }
    }
    
    // Training focus context message
    $focusMessage = getTrainingFocusMessage($trainingFocus);
    
    $summary = empty($summaryParts) ? 'Balanced effort across muscle groups this week.' : (implode(' ', $summaryParts) . '.');
    if ($focusMessage) {
        $summary .= ' ' . $focusMessage;
    }

    // Prepare response
    // Optional static image mapping (fallback) based on known target_muscle names
    $imageMap = [
        'Chest' => 'https://api.cnergy.site/image-servers.php?image=68e4bdc995d2a_1759821257.jpg',
        'Back' => 'https://api.cnergy.site/image-servers.php?image=68e3601c90c68_1759731740.jpg',
        'Shoulder' => 'https://api.cnergy.site/image-servers.php?image=68e35ff3c80bf_1759731699.jpg',
        'Core' => 'https://api.cnergy.site/image-servers.php?image=68e4bdbf3044e_1759821247.jpg',
        'Arms' => 'https://api.cnergy.site/image-servers.php?image=68e4bdaac1683_1759821226.jpg',
        'Legs' => 'https://api.cnergy.site/image-servers.php?image=68e4bdb72737e_1759821239.jpg',
        'Biceps' => 'https://api.cnergy.site/image-servers.php?image=68e35fc7a61a1_1759731655.jpg',
        'Upper Chest' => 'https://api.cnergy.site/image-servers.php?image=68f64dd7e8266_1760972247.jpg',
        'Middle Chest' => 'https://api.cnergy.site/image-servers.php?image=68f64de00c60e_1760972256.jpg',
        'Lower Chest' => 'https://api.cnergy.site/image-servers.php?image=68f64dcc3d660_1760972236.jpg',
        'Lats' => 'https://api.cnergy.site/image-servers.php?image=68f64d9478f41_1760972180.jpg',
        'Triceps' => 'https://api.cnergy.site/image-servers.php?image=68f64ea977586_1760972457.jpg',
        'Forearms' => 'https://api.cnergy.site/image-servers.php?image=68f64eb18b226_1760972465.jpg',
        'Quads' => 'https://api.cnergy.site/image-servers.php?image=68f64dad93d06_1760972205.jpg',
        'Hamstring' => 'https://api.cnergy.site/image-servers.php?image=68f64db61bead_1760972214.jpg',
        'Calves' => 'https://api.cnergy.site/image-servers.php?image=68f64d9e5c757_1760972190.jpg',
        'Obliques' => 'https://api.cnergy.site/image-servers.php?image=68f64e10591ac_1760972304.jpg',
    ];

    $muscleStats = array_map(function($r) use ($imageMap, $exercisesByMuscle) {
        $muscleId = (int)$r['muscle_id'];
        return [
            'muscle_id' => $muscleId,
            'muscle_name' => (string)$r['muscle_name'],
            'group_id' => isset($r['group_id']) && $r['group_id'] !== null ? (int)$r['group_id'] : null,
            'total_load' => (float)$r['total_load'],
            'total_sets' => (int)$r['total_sets'],
            'sessions' => isset($r['sessions']) ? (int)$r['sessions'] : 0,
            'total_reps' => isset($r['total_reps']) && $r['total_reps'] !== null ? (int)$r['total_reps'] : null,
            'total_exercises' => (int)$r['total_exercises'],
            'first_date' => $r['first_date'],
            'last_date' => $r['last_date'],
            'image_url' => $imageMap[$r['muscle_name']] ?? null,
            'exercises' => $exercisesByMuscle[$muscleId] ?? [],
        ];
    }, $rows);

    $groupStats = array_map(function($r) use ($imageMap, $exercisesByGroup) {
        $groupId = (int)$r['group_id'];
        return [
            'group_id' => $groupId,
            'group_name' => (string)$r['group_name'],
            'total_load' => (float)$r['total_load'],
            'total_sets' => (int)$r['total_sets'],
            'sessions' => isset($r['sessions']) ? (int)$r['sessions'] : 0,
            'total_reps' => isset($r['total_reps']) && $r['total_reps'] !== null ? (int)$r['total_reps'] : null,
            'total_exercises' => (int)$r['total_exercises'],
            'image_url' => $imageMap[$r['group_name']] ?? null,
            'exercises' => $exercisesByGroup[$groupId] ?? [],
        ];
    }, $groupRows);

    // Final type-safe response structure
    $response = [
        'success' => true,
        'data' => [
            'week_start' => (string)$startDate,
            'week_end' => (string)$endDate,
            'muscles' => $muscleStats,
            'groups' => $groupStats,
            'averages' => [
                'avg_group_load' => (float)$avgLoad,
                'avg_group_sets' => (float)$avgSets,
            ],
            'summary' => (string)$summary,
            'focused_groups' => array_values(array_map('strval', $focused)),
            'neglected_groups' => array_values(array_map('strval', $neglected)),
            'warnings' => array_values($neglectedWithWarnings),
            'training_focus' => (string)$trainingFocus,
            // Ensure tracked_muscle_groups is a clean array of integers
            'tracked_muscle_groups' => array_values(array_map(function($id) {
                return (int)$id;
            }, $trackedGroups)),
        ]
    ];

    // Optional debug info: add debug=1 to query string
    if ((isset($_GET['debug']) && $_GET['debug'] == '1')) {
        $groupIds = array_map(function($g){ return $g['group_id']; }, $groupStats);
        $muscleGroups = [];
        foreach ($muscleStats as $m) {
            $gid = $m['group_id'] ?? null;
            if ($gid === null) continue;
            if (!isset($muscleGroups[$gid])) $muscleGroups[$gid] = 0;
            $muscleGroups[$gid]++;
        }
        $response['debug'] = [
            'group_count' => count($groupStats),
            'muscle_count' => count($muscleStats),
            'group_ids' => $groupIds,
            'muscles_by_group' => $muscleGroups,
        ];
    }

    // Force numeric types in JSON output
    echo json_encode($response, JSON_NUMERIC_CHECK | JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Server error', 'error' => $e->getMessage()]);
    exit;
}

// Helper functions

function getTrackedMuscleGroups($trainingFocus, $customMuscleGroups, $allGroups) {
    $groupMap = [];
    foreach ($allGroups as $g) {
        $groupMap[strtolower($g['group_name'])] = (int)$g['group_id'];
    }
    
    switch ($trainingFocus) {
        case 'upper_body':
            $result = array_values(array_filter([
                $groupMap['chest'] ?? null,
                $groupMap['back'] ?? null,
                $groupMap['shoulder'] ?? null,
                $groupMap['shoulders'] ?? null,
                $groupMap['arms'] ?? null,
                $groupMap['core'] ?? null,
            ]));
            // Ensure all values are integers
            return array_values(array_map(function($v) { return (int)$v; }, $result));
        
        case 'lower_body':
            $result = array_values(array_filter([
                $groupMap['legs'] ?? null,
                $groupMap['glutes'] ?? null,
                $groupMap['calves'] ?? null,
            ]));
            return array_values(array_map(function($v) { return (int)$v; }, $result));
        
        case 'custom':
            $ids = $customMuscleGroups ? $customMuscleGroups : array_column($allGroups, 'group_id');
            return array_values(array_map(function($v) { return (int)$v; }, $ids));
        
        case 'full_body':
        default:
            $ids = array_column($allGroups, 'group_id');
            return array_values(array_map(function($v) { return (int)$v; }, $ids));
    }
}

function shouldShowWarning($warningKey, $dismissedWarnings) {
    if (!isset($dismissedWarnings[$warningKey])) {
        return true; // Not dismissed, show warning
    }
    
    $dismissal = $dismissedWarnings[$warningKey];
    
    // If permanently dismissed, never show
    if ($dismissal['permanent']) {
        return false;
    }
    
    // If dismissed (even temporarily), don't show it now
    // Smart Silence: Any dismissal hides the warning for now
    // The warning can reappear in future weeks if the issue persists
    // but will auto-hide after 3 consecutive dismissals
    return false;
}

function getTrainingFocusMessage($trainingFocus) {
    switch ($trainingFocus) {
        case 'upper_body':
            return 'Tracking: Upper body focus';
        case 'lower_body':
            return 'Tracking: Lower body focus';
        case 'custom':
            return 'Tracking: Custom muscle selection';
        default:
            return null;
    }
}

?>


