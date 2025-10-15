<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Database connection
$host = "localhost";
$db_name = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo json_encode(['error' => "Connection failed: " . $e->getMessage()]);
    exit();
}

try {
    // Test query to get your real workout data
    $sql = "SELECT 
                mel.id,
                mel.member_id as user_id,
                e.name as exercise_name,
                'Unknown' as muscle_group,
                mesl.weight,
                mesl.reps,
                mel.actual_sets as sets,
                (mesl.reps * mesl.weight) as volume,
                mel.log_date as date
            FROM member_exercise_log mel
            JOIN member_workout_exercise mwe ON mel.member_workout_exercise_id = mwe.id
            JOIN exercise e ON mwe.exercise_id = e.id
            LEFT JOIN member_exercise_set_log mesl ON mel.id = mesl.exercise_log_id
            WHERE mel.member_id = 3 
            ORDER BY e.name, mel.log_date DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $lifts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $lifts,
        'count' => count($lifts)
    ]);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>