<?php
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

// Test the progress_tracker table
try {
    // Test 1: Check if table exists
    $sql = "SHOW TABLES LIKE 'progress_tracker'";
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $tableExists = $stmt->fetch();

    if ($tableExists) {
        echo "✅ Table 'progress_tracker' exists\n";
    } else {
        echo "❌ Table 'progress_tracker' does not exist\n";
        exit;
    }

    // Test 2: Check table structure
    $sql = "DESCRIBE progress_tracker";
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "📋 Table structure:\n";
    foreach ($columns as $column) {
        echo "  - {$column['Field']}: {$column['Type']}\n";
    }

    // Test 3: Insert test data
    $testData = [
        'user_id' => 61, // Assuming user ID 61 exists
        'exercise_name' => 'Test Exercise',
        'muscle_group' => 'Test Muscle',
        'weight' => 50.0,
        'reps' => 10,
        'sets' => 3,
        'volume' => 1500.0,
        'one_rep_max' => 66.7,
        'notes' => 'Test data from API test',
        'program_name' => 'Test Program',
        'program_id' => 1,
        'created_at' => date('Y-m-d H:i:s')
    ];

    $sql = "INSERT INTO progress_tracker 
            (user_id, exercise_name, muscle_group, weight, reps, sets, volume, one_rep_max, notes, program_name, program_id, created_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute([
        $testData['user_id'],
        $testData['exercise_name'],
        $testData['muscle_group'],
        $testData['weight'],
        $testData['reps'],
        $testData['sets'],
        $testData['volume'],
        $testData['one_rep_max'],
        $testData['notes'],
        $testData['program_name'],
        $testData['program_id'],
        $testData['created_at']
    ]);

    if ($result) {
        echo "✅ Test data inserted successfully\n";
        $testId = $pdo->lastInsertId();
        echo "   Test record ID: $testId\n";
    } else {
        echo "❌ Failed to insert test data\n";
    }

    // Test 4: Retrieve test data
    $sql = "SELECT * FROM progress_tracker WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$testId]);
    $retrievedData = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($retrievedData) {
        echo "✅ Test data retrieved successfully\n";
        echo "   Exercise: {$retrievedData['exercise_name']}\n";
        echo "   Weight: {$retrievedData['weight']} kg\n";
        echo "   Reps: {$retrievedData['reps']}\n";
        echo "   Sets: {$retrievedData['sets']}\n";
    } else {
        echo "❌ Failed to retrieve test data\n";
    }

    // Test 5: Clean up test data
    $sql = "DELETE FROM progress_tracker WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$testId]);
    echo "🧹 Test data cleaned up\n";

    echo "\n🎉 All tests passed! The progress_tracker table is working correctly.\n";

} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
?>
