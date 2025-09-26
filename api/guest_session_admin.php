<?php
// Simple admin interface for managing guest sessions
// Database configuration
$host = "127.0.0.1:3306";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    die('Database connection failed: ' . $e->getMessage());
}

// Check if user is admin (you can implement proper authentication here)
session_start();
if (!isset($_SESSION['user_type']) || $_SESSION['user_type'] !== 'admin') {
    die('Access denied. Admin privileges required.');
}

$pdo = getConnection();

// Handle actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    
    switch ($action) {
        case 'approve':
            approveSession($_POST['session_id']);
            break;
        case 'reject':
            rejectSession($_POST['session_id']);
            break;
        case 'mark_paid':
            markPaid($_POST['session_id']);
            break;
    }
}

function approveSession($sessionId) {
    global $pdo;
    $stmt = $pdo->prepare("UPDATE guest_session SET status = 'approved' WHERE id = ?");
    $stmt->execute([$sessionId]);
    header('Location: guest_session_admin.php?message=approved');
    exit;
}

function rejectSession($sessionId) {
    global $pdo;
    $stmt = $pdo->prepare("UPDATE guest_session SET status = 'rejected' WHERE id = ?");
    $stmt->execute([$sessionId]);
    header('Location: guest_session_admin.php?message=rejected');
    exit;
}

function markPaid($sessionId) {
    global $pdo;
    $stmt = $pdo->prepare("UPDATE guest_session SET paid = 1, status = 'approved' WHERE id = ?");
    $stmt->execute([$sessionId]);
    header('Location: guest_session_admin.php?message=paid');
    exit;
}

// Get all guest sessions
$stmt = $pdo->prepare("
    SELECT * FROM guest_session 
    ORDER BY created_at DESC
");
$stmt->execute();
$sessions = $stmt->fetchAll(PDO::FETCH_ASSOC);

$message = $_GET['message'] ?? '';
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Guest Session Management</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #FF6B35;
            padding-bottom: 10px;
        }
        .message {
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
        }
        .success { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .table th, .table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .table th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        .status {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
        }
        .status.pending { background-color: #fff3cd; color: #856404; }
        .status.approved { background-color: #d4edda; color: #155724; }
        .status.rejected { background-color: #f8d7da; color: #721c24; }
        .btn {
            padding: 6px 12px;
            margin: 2px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
        }
        .btn-success { background-color: #28a745; color: white; }
        .btn-danger { background-color: #dc3545; color: white; }
        .btn-primary { background-color: #007bff; color: white; }
        .btn:hover { opacity: 0.8; }
        .qr-token {
            font-family: monospace;
            font-size: 11px;
            background-color: #f8f9fa;
            padding: 2px 4px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Guest Session Management</h1>
        
        <?php if ($message): ?>
            <div class="message success">
                <?php
                switch ($message) {
                    case 'approved': echo 'Session approved successfully!'; break;
                    case 'rejected': echo 'Session rejected successfully!'; break;
                    case 'paid': echo 'Payment confirmed successfully!'; break;
                }
                ?>
            </div>
        <?php endif; ?>
        
        <table class="table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Guest Name</th>
                    <th>Type</th>
                    <th>Amount</th>
                    <th>Status</th>
                    <th>Paid</th>
                    <th>QR Token</th>
                    <th>Created</th>
                    <th>Valid Until</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($sessions as $session): ?>
                    <tr>
                        <td><?= htmlspecialchars($session['id']) ?></td>
                        <td><?= htmlspecialchars($session['guest_name']) ?></td>
                        <td><?= strtoupper(htmlspecialchars($session['guest_type'])) ?></td>
                        <td>₱<?= number_format($session['amount_paid'], 2) ?></td>
                        <td>
                            <span class="status <?= $session['status'] ?>">
                                <?= strtoupper($session['status']) ?>
                            </span>
                        </td>
                        <td>
                            <?= $session['paid'] ? '✅ Yes' : '❌ No' ?>
                        </td>
                        <td>
                            <span class="qr-token"><?= htmlspecialchars($session['qr_token']) ?></span>
                        </td>
                        <td><?= date('M j, Y H:i', strtotime($session['created_at'])) ?></td>
                        <td><?= date('M j, Y H:i', strtotime($session['valid_until'])) ?></td>
                        <td>
                            <?php if ($session['status'] === 'pending'): ?>
                                <form method="POST" style="display: inline;">
                                    <input type="hidden" name="action" value="approve">
                                    <input type="hidden" name="session_id" value="<?= $session['id'] ?>">
                                    <button type="submit" class="btn btn-success">Approve</button>
                                </form>
                                <form method="POST" style="display: inline;">
                                    <input type="hidden" name="action" value="reject">
                                    <input type="hidden" name="session_id" value="<?= $session['id'] ?>">
                                    <button type="submit" class="btn btn-danger">Reject</button>
                                </form>
                            <?php endif; ?>
                            
                            <?php if ($session['status'] === 'approved' && !$session['paid']): ?>
                                <form method="POST" style="display: inline;">
                                    <input type="hidden" name="action" value="mark_paid">
                                    <input type="hidden" name="session_id" value="<?= $session['id'] ?>">
                                    <button type="submit" class="btn btn-primary">Mark Paid</button>
                                </form>
                            <?php endif; ?>
                            
                            <?php if ($session['status'] === 'approved' && $session['paid']): ?>
                                <span style="color: green; font-weight: bold;">✅ Ready</span>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
        
        <?php if (empty($sessions)): ?>
            <p style="text-align: center; color: #666; margin: 40px 0;">No guest sessions found.</p>
        <?php endif; ?>
    </div>
</body>
</html>
