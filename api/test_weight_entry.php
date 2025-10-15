<?php
// Simple test to add a weight entry
header('Content-Type: application/json');

$host = "localhost";
$db_name = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Test adding a weight entry
    $stmt = $pdo->prepare("INSERT INTO body_measurements (user_id, weight, notes) VALUES (?, ?, ?)");
    $result = $stmt->execute([61, 75.5, "Test entry from PHP"]);

    if ($result) {
        $newId = $pdo->lastInsertId();
        echo json_encode([
            "success" => true,
            "message" => "Weight entry added successfully",
            "id" => $newId
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Failed to add weight entry"
        ]);
    }

} catch (PDOException $e) {
    echo json_encode([
        "success" => false,
        "error" => "Database error: " . $e->getMessage()
    ]);
}
?>
