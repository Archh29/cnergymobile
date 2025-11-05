<?php
// Test script to verify notification triggers are working
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration
$host = "localhost";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<h2>🔍 Testing Notification Triggers</h2>\n";
    
    // Test 1: Member Registration Trigger
    echo "<h3>1. Testing Member Registration Trigger</h3>\n";
    $testUserId = 999; // Use a test user ID
    
    // Check notifications before
    $beforeStmt = $pdo->prepare("SELECT COUNT(*) as count FROM notification WHERE user_id = ?");
    $beforeStmt->execute([$testUserId]);
    $beforeCount = $beforeStmt->fetch()['count'];
    echo "Notifications before test: $beforeCount<br>\n";
    
    // Insert test user (this should trigger notify_member_registration)
    try {
        $insertStmt = $pdo->prepare("
            INSERT INTO user (id, username, email, password, user_type_id, created_at) 
            VALUES (?, 'test_user_trigger', 'test@trigger.com', 'testpass', 4, NOW())
        ");
        $insertStmt->execute([$testUserId]);
        echo "✅ Test user inserted successfully<br>\n";
        
        // Check notifications after
        $afterStmt = $pdo->prepare("SELECT COUNT(*) as count FROM notification WHERE user_id = ?");
        $afterStmt->execute([$testUserId]);
        $afterCount = $afterStmt->fetch()['count'];
        echo "Notifications after test: $afterCount<br>\n";
        
        if ($afterCount > $beforeCount) {
            echo "✅ Member registration trigger is working!<br>\n";
        } else {
            echo "❌ Member registration trigger may not be working<br>\n";
        }
        
        // Clean up test user
        $deleteStmt = $pdo->prepare("DELETE FROM user WHERE id = ?");
        $deleteStmt->execute([$testUserId]);
        echo "🧹 Test user cleaned up<br>\n";
        
    } catch (PDOException $e) {
        if ($e->getCode() == 23000) { // Duplicate entry
            echo "⚠️ Test user already exists, skipping test<br>\n";
        } else {
            echo "❌ Error: " . $e->getMessage() . "<br>\n";
        }
    }
    
    // Test 2: Product Added Trigger
    echo "<h3>2. Testing Product Added Trigger</h3>\n";
    $testProductId = 999;
    
    try {
        // Check notifications before
        $beforeStmt = $pdo->prepare("SELECT COUNT(*) as count FROM notification");
        $beforeStmt->execute();
        $beforeCount = $beforeStmt->fetch()['count'];
        echo "Total notifications before: $beforeCount<br>\n";
        
        // Insert test product
        $insertStmt = $pdo->prepare("
            INSERT INTO product (id, name, price, stock, created_at) 
            VALUES (?, 'Test Product Trigger', 99.99, 10, NOW())
        ");
        $insertStmt->execute([$testProductId]);
        echo "✅ Test product inserted<br>\n";
        
        // Check notifications after
        $afterStmt = $pdo->prepare("SELECT COUNT(*) as count FROM notification");
        $afterStmt->execute();
        $afterCount = $afterStmt->fetch()['count'];
        echo "Total notifications after: $afterCount<br>\n";
        
        if ($afterCount > $beforeCount) {
            echo "✅ Product added trigger is working!<br>\n";
        } else {
            echo "❌ Product added trigger may not be working<br>\n";
        }
        
        // Clean up
        $deleteStmt = $pdo->prepare("DELETE FROM product WHERE id = ?");
        $deleteStmt->execute([$testProductId]);
        echo "🧹 Test product cleaned up<br>\n";
        
    } catch (PDOException $e) {
        if ($e->getCode() == 23000) {
            echo "⚠️ Test product already exists, skipping test<br>\n";
        } else {
            echo "❌ Error: " . $e->getMessage() . "<br>\n";
        }
    }
    
    // Test 3: Check Recent Notifications
    echo "<h3>3. Recent Notifications (Last 10)</h3>\n";
    $recentStmt = $pdo->prepare("
        SELECT 
            n.id,
            n.message,
            n.timestamp,
            nt.type_name,
            ns.status_name,
            u.username
        FROM notification n
        LEFT JOIN notification_type nt ON n.type_id = nt.id
        LEFT JOIN notification_status ns ON n.status_id = ns.id
        LEFT JOIN user u ON n.user_id = u.id
        ORDER BY n.timestamp DESC
        LIMIT 10
    ");
    $recentStmt->execute();
    $recentNotifications = $recentStmt->fetchAll();
    
    if (empty($recentNotifications)) {
        echo "❌ No notifications found in database<br>\n";
    } else {
        echo "<table border='1' style='border-collapse: collapse; width: 100%;'>\n";
        echo "<tr><th>ID</th><th>Message</th><th>Type</th><th>Status</th><th>User</th><th>Timestamp</th></tr>\n";
        foreach ($recentNotifications as $notif) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($notif['id']) . "</td>";
            echo "<td>" . htmlspecialchars($notif['message']) . "</td>";
            echo "<td>" . htmlspecialchars($notif['type_name']) . "</td>";
            echo "<td>" . htmlspecialchars($notif['status_name']) . "</td>";
            echo "<td>" . htmlspecialchars($notif['username'] ?? 'N/A') . "</td>";
            echo "<td>" . htmlspecialchars($notif['timestamp']) . "</td>";
            echo "</tr>\n";
        }
        echo "</table>\n";
    }
    
    // Test 4: Check Trigger Definitions
    echo "<h3>4. Trigger Definitions</h3>\n";
    $triggerStmt = $pdo->prepare("
        SELECT 
            TRIGGER_NAME,
            EVENT_MANIPULATION,
            EVENT_OBJECT_TABLE,
            ACTION_TIMING,
            ACTION_STATEMENT
        FROM information_schema.TRIGGERS 
        WHERE TRIGGER_SCHEMA = ?
        AND TRIGGER_NAME LIKE 'notify_%'
        ORDER BY TRIGGER_NAME
    ");
    $triggerStmt->execute([$dbname]);
    $triggers = $triggerStmt->fetchAll();
    
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>\n";
    echo "<tr><th>Trigger Name</th><th>Event</th><th>Table</th><th>Timing</th></tr>\n";
    foreach ($triggers as $trigger) {
        echo "<tr>";
        echo "<td>" . htmlspecialchars($trigger['TRIGGER_NAME']) . "</td>";
        echo "<td>" . htmlspecialchars($trigger['EVENT_MANIPULATION']) . "</td>";
        echo "<td>" . htmlspecialchars($trigger['EVENT_OBJECT_TABLE']) . "</td>";
        echo "<td>" . htmlspecialchars($trigger['ACTION_TIMING']) . "</td>";
        echo "</tr>\n";
    }
    echo "</table>\n";
    
    echo "<h3>✅ Trigger Testing Complete!</h3>\n";
    
} catch (PDOException $e) {
    echo "❌ Database Error: " . $e->getMessage() . "\n";
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
?>




















