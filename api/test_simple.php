<?php
require_once 'db.php';

// Test the progress_tracker table directly
try {
    $sql = "SELECT COUNT(*) as count FROM progress_tracker WHERE user_id = 61";
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    echo "Records in progress_tracker for user 61: " . $result['count'] . "\n";

    // Test the exact query that's failing
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

    echo "Query executed successfully. Found " . count($lifts) . " records.\n";

    if (count($lifts) > 0) {
        echo "Sample record: " . json_encode($lifts[0]) . "\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
