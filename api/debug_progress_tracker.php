<?php
header('Content-Type: application/json');

// Database connection
$host = "localhost";
$db_name = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    throw new Exception("Connection failed: " . $e->getMessage());
}

try {
    // Test 1: Check if table exists
    $sql = "SHOW TABLES LIKE 'progress_tracker'";
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $tableExists = $stmt->fetch();

    if (!$tableExists) {
        throw new Exception('progress_tracker table does not exist');
    }

    // Test 2: Check table structure
    $sql = "DESCRIBE progress_tracker";
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Test 3: Check if there's any data
    $sql = "SELECT COUNT(*) as count FROM progress_tracker";
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $count = $stmt->fetch(PDO::FETCH_ASSOC);

    // Test 4: Try the exact query that's failing
    $sql = "SELECT id, user_id, exercise_name, muscle_group, weight, reps, sets, 
                   volume, one_rep_max, notes, program_name, program_id, 
                   created_at as date
            FROM progress_tracker 
            WHERE user_id = ? AND exercise_name = ?
            ORDER BY created_at DESC
            LIMIT 10";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([61, 'Deadlift']);
    $lifts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'table_exists' => true,
        'columns' => $columns,
        'total_records' => $count['count'],
        'query_result_count' => count($lifts),
        'sample_data' => $lifts
    ]);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
