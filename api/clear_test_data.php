<?php
// Script to clear test data and start fresh
header('Content-Type: application/json');

$host = "localhost";
$db_name = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Clear existing body measurements for user 13 (your test user)
    $stmt = $pdo->prepare("DELETE FROM body_measurements WHERE user_id = 13");
    $result = $stmt->execute();

    if ($result) {
        $deletedRows = $stmt->rowCount();
        echo json_encode([
            "success" => true,
            "message" => "Cleared $deletedRows test entries for user 13",
            "note" => "Now when you access body measurements, it will automatically create a starting entry from your profile weight (80kg)"
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Failed to clear test data"
        ]);
    }

} catch (PDOException $e) {
    echo json_encode([
        "success" => false,
        "error" => "Database error: " . $e->getMessage()
    ]);
}
?>
