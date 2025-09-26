<?php
// Debug script for session management API
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$memberId = 10;
$debugInfo = [];

try {
    // Test database connection
    $pdo = new PDO("mysql:host=localhost;dbname=u773938685_cnergydb", "u773938685_archh29", "Gwapoko385@");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $debugInfo['database_connection'] = 'success';
    
    // Test 1: Check if member exists in coach_member_list
    $stmt = $pdo->prepare("SELECT * FROM coach_member_list WHERE member_id = ?");
    $stmt->execute([$memberId]);
    $memberData = $stmt->fetchAll();
    
    $debugInfo['coach_member_list'] = [
        'count' => count($memberData),
        'records' => $memberData
    ];
    
    // Test 2: Check session usage records
    $stmt = $pdo->prepare("
        SELECT csu.*, cml.member_id 
        FROM coach_session_usage csu
        JOIN coach_member_list cml ON csu.coach_member_id = cml.id
        WHERE cml.member_id = ?
    ");
    $stmt->execute([$memberId]);
    $usageData = $stmt->fetchAll();
    
    $debugInfo['session_usage'] = [
        'count' => count($usageData),
        'records' => $usageData
    ];
    
    // Test 3: Check table structure
    $stmt = $pdo->query("DESCRIBE coach_member_list");
    $memberColumns = $stmt->fetchAll();
    
    $stmt = $pdo->query("DESCRIBE coach_session_usage");
    $usageColumns = $stmt->fetchAll();
    
    $debugInfo['table_structures'] = [
        'coach_member_list' => $memberColumns,
        'coach_session_usage' => $usageColumns
    ];
    
    // Test 4: Try the exact query from the API
    try {
        $stmt = $pdo->prepare("
            SELECT 
                csu.id,
                csu.usage_date,
                csu.created_at,
                cml.remaining_sessions,
                cml.rate_type,
                cml.session_package_count,
                cml.status as subscription_status
            FROM coach_session_usage csu
            JOIN coach_member_list cml ON csu.coach_member_id = cml.id
            WHERE cml.member_id = ?
            ORDER BY csu.usage_date DESC, csu.created_at DESC
        ");
        $stmt->execute([$memberId]);
        $history = $stmt->fetchAll();
        $debugInfo['api_query_test'] = [
            'success' => true,
            'count' => count($history),
            'data' => $history
        ];
    } catch (PDOException $e) {
        $debugInfo['api_query_test'] = [
            'success' => false,
            'error' => $e->getMessage()
        ];
    }
    
    $debugInfo['overall_status'] = 'success';
    
} catch (PDOException $e) {
    $debugInfo['overall_status'] = 'database_error';
    $debugInfo['error'] = $e->getMessage();
} catch (Exception $e) {
    $debugInfo['overall_status'] = 'general_error';
    $debugInfo['error'] = $e->getMessage();
}

echo json_encode($debugInfo, JSON_PRETTY_PRINT);
?>
