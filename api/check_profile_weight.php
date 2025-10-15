<?php
// Script to check and fix profile weight
header('Content-Type: application/json');

$host = "localhost";
$db_name = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $user_id = 13; // Your user ID

    // Check current profile weight
    $profileStmt = $pdo->prepare("SELECT weight_kg, height_cm FROM member_profile_details WHERE user_id = ?");
    $profileStmt->execute([$user_id]);
    $profile = $profileStmt->fetch(PDO::FETCH_ASSOC);

    if ($profile) {
        echo "Current profile weight: " . $profile['weight_kg'] . "kg\n";
        echo "Current profile height: " . $profile['height_cm'] . "cm\n";

        // If weight is 80kg, update it to 82kg
        if ($profile['weight_kg'] == 80.00) {
            $updateStmt = $pdo->prepare("UPDATE member_profile_details SET weight_kg = 82.00 WHERE user_id = ?");
            $updateStmt->execute([$user_id]);

            echo json_encode([
                "success" => true,
                "message" => "Profile weight updated from 80kg to 82kg",
                "old_weight" => "80kg",
                "new_weight" => "82kg"
            ]);
        } else {
            echo json_encode([
                "success" => true,
                "message" => "Profile weight is already correct",
                "current_weight" => $profile['weight_kg'] . "kg"
            ]);
        }
    } else {
        echo json_encode([
            "success" => false,
            "error" => "Profile not found"
        ]);
    }

} catch (PDOException $e) {
    echo json_encode([
        "success" => false,
        "error" => "Database error: " . $e->getMessage()
    ]);
}
?>
