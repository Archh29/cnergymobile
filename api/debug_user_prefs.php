<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$host = "localhost";
$db = "u773938685_cnergydb";
$user = "u773938685_archh29";
$pass = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    
    $userId = $_GET['user_id'] ?? null;
    
    if (!$userId) {
        echo json_encode(['error' => 'user_id required']);
        exit;
    }
    
    // Get user preferences
    $stmt = $pdo->prepare("SELECT * FROM user_training_preferences WHERE user_id = ?");
    $stmt->execute([$userId]);
    $prefs = $stmt->fetch();
    
    echo json_encode([
        'user_id' => $userId,
        'preferences' => $prefs,
        'custom_muscle_groups_decoded' => $prefs ? json_decode($prefs['custom_muscle_groups'] ?? '[]', true) : null,
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>

