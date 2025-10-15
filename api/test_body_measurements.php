<?php
// Test script for body measurements API
header('Content-Type: application/json');

$host = "localhost";
$db_name = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    echo json_encode([
        "success" => true,
        "message" => "Database connection successful",
        "tables" => []
    ]);

    // Check if body_measurements table exists
    $stmt = $pdo->prepare("SHOW TABLES LIKE 'body_measurements'");
    $stmt->execute();
    $tableExists = $stmt->rowCount() > 0;

    if ($tableExists) {
        echo "\n\nTable 'body_measurements' exists!";

        // Get table structure
        $stmt = $pdo->prepare("DESCRIBE body_measurements");
        $stmt->execute();
        $structure = $stmt->fetchAll();

        echo "\n\nTable structure:\n";
        print_r($structure);

        // Count records
        $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM body_measurements");
        $stmt->execute();
        $count = $stmt->fetch();

        echo "\n\nTotal records: " . $count['count'];

    } else {
        echo "\n\nTable 'body_measurements' does not exist!";
        echo "\nPlease run the SQL script to create it.";
    }

} catch (PDOException $e) {
    echo json_encode([
        "success" => false,
        "error" => "Database connection failed: " . $e->getMessage()
    ]);
}
?>