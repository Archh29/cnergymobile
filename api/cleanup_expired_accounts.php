<?php
/**
 * Auto-Delete Expired Unverified Accounts
 * 
 * This script should be run daily via cron job to delete CUSTOMER accounts that:
 * - Have status = 'pending'
 * - Have passed their verification_deadline
 * - Are customers (user_type_id = 4)
 * 
 * NOTE: Only applies to customers (user_type_id = 4)
 * Staff, coaches, and admins are NOT deleted by this script
 * 
 * How to set up cron job:
 * Add to crontab: 0 2 * * * /usr/bin/php /path/to/cleanup_expired_accounts.php
 * This runs daily at 2 AM
 */

// IMPORTANT: CORS Headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$servername = "localhost";
$username = "u773938685_archh29";
$password = "Gwapoko385@";
$dbname = "u773938685_cnergydb";

try {
    error_log("=== CLEANUP EXPIRED ACCOUNTS - STARTED ===");
    
    // Connect to database
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Stage 1: Mark pending accounts past deadline as 'rejected' (3 days grace period)
    $rejectStmt = $pdo->prepare("
        UPDATE user 
        SET account_status = 'rejected'
        WHERE account_status = 'pending' 
        AND verification_deadline < NOW()
        AND user_type_id = 4
    ");
    
    $rejectStmt->execute();
    $rejectedCount = $rejectStmt->rowCount();
    
    if ($rejectedCount > 0) {
        error_log("Stage 1: Marked $rejectedCount pending accounts as 'rejected' (past 3-day deadline)");
    }
    
    // Stage 2: Find and delete rejected accounts older than 17 days (14 days after rejection)
    $stmt = $pdo->prepare("
        SELECT id, email, fname, lname, created_at, account_status
        FROM user 
        WHERE account_status = 'rejected' 
        AND user_type_id = 4
        AND DATE_ADD(created_at, INTERVAL 17 DAY) < NOW()
    ");
    
    $stmt->execute();
    $expiredAccounts = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    error_log("Found " . count($expiredAccounts) . " rejected accounts older than 17 days");
    
    if (count($expiredAccounts) > 0) {
        // Delete rejected customer accounts older than 17 days
        $deleteStmt = $pdo->prepare("
            DELETE FROM user 
            WHERE account_status = 'rejected' 
            AND user_type_id = 4
            AND DATE_ADD(created_at, INTERVAL 17 DAY) < NOW()
        ");
        
        $deleteStmt->execute();
        $deletedCount = $deleteStmt->rowCount();
        
        error_log("Stage 2: Successfully deleted $deletedCount rejected accounts (older than 17 days)");
        
        // Log deleted accounts for audit
        foreach ($expiredAccounts as $account) {
            error_log("Deleted expired account - ID: {$account['id']}, Email: {$account['email']}, Name: {$account['fname']} {$account['lname']}");
        }
        
        // Return success with counts
        echo json_encode([
            'success' => true,
            'message' => "Processed accounts - Marked $rejectedCount as rejected, Deleted $deletedCount old rejected accounts",
            'rejected_count' => $rejectedCount,
            'deleted_count' => $deletedCount,
            'accounts_deleted' => $expiredAccounts
        ]);
    } else {
        error_log("No expired accounts found");
        echo json_encode([
            'success' => true,
            'message' => "Cleanup completed - Marked $rejectedCount as rejected, 0 accounts deleted",
            'rejected_count' => $rejectedCount,
            'deleted_count' => 0
        ]);
    }
    
    error_log("=== CLEANUP EXPIRED ACCOUNTS - COMPLETED ===");
    
} catch (PDOException $e) {
    error_log("Database error in cleanup script: " . $e->getMessage());
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $e->getMessage()
    ]);
    exit(1);
} catch (Exception $e) {
    error_log("Error in cleanup script: " . $e->getMessage());
    echo json_encode([
        'success' => false,
        'error' => 'Error: ' . $e->getMessage()
    ]);
    exit(1);
}
?>

