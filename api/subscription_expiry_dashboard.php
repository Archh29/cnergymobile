<?php
/**
 * Subscription Expiry Dashboard
 * 
 * A simple web interface to view and manage subscription expiry emails.
 * This can be used by administrators to monitor and test the system.
 */

// Include required files
require_once 'email_service.php';
require_once 'db.php';

// Set timezone
date_default_timezone_set('Asia/Manila');

// Handle AJAX requests
if (isset($_POST['action'])) {
    header('Content-Type: application/json');
    
    try {
        $emailService = new EmailService();
        
        switch ($_POST['action']) {
            case 'check_expiry':
                $summary = $emailService->checkAndSendExpiryEmails();
                echo json_encode(['success' => true, 'data' => $summary]);
                break;
                
            case 'send_test_email':
                $userEmail = $_POST['email'] ?? '';
                $userName = $_POST['name'] ?? 'Test User';
                $daysRemaining = (int)($_POST['days'] ?? 7);
                $expiryDate = date('Y-m-d', strtotime("+$daysRemaining days"));
                $subscriptionDetails = [
                    'plan_name' => $_POST['plan'] ?? 'Test Plan',
                    'price' => (float)($_POST['price'] ?? 999.00),
                    'subscription_id' => 999
                ];
                
                $result = $emailService->sendSubscriptionExpiryEmail(
                    $userEmail,
                    $userName,
                    $daysRemaining,
                    $expiryDate,
                    $subscriptionDetails
                );
                
                echo json_encode(['success' => true, 'data' => $result]);
                break;
                
            case 'get_expiring_subscriptions':
                $query = "
                    SELECT 
                        s.id,
                        s.user_id,
                        s.end_date,
                        s.plan_id,
                        u.fname,
                        u.lname,
                        u.email,
                        msp.plan_name,
                        msp.price,
                        DATEDIFF(s.end_date, CURDATE()) as days_remaining
                    FROM subscription s
                    JOIN user u ON s.user_id = u.id
                    JOIN member_subscription_plan msp ON s.plan_id = msp.id
                    WHERE s.status_id = 2 
                    AND s.end_date >= CURDATE()
                    AND DATEDIFF(s.end_date, CURDATE()) <= 30
                    ORDER BY s.end_date ASC
                ";
                
                $result = $conn->query($query);
                $subscriptions = [];
                
                if ($result) {
                    while ($row = $result->fetch_assoc()) {
                        $subscriptions[] = $row;
                    }
                }
                
                echo json_encode(['success' => true, 'data' => $subscriptions]);
                break;
                
            default:
                echo json_encode(['success' => false, 'message' => 'Invalid action']);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    
    exit;
}

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CNERGY GYM - Subscription Expiry Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
            color: #333;
        }
        
        .header {
            background: linear-gradient(135deg, #FF6B35 0%, #FF8E53 100%);
            color: white;
            padding: 20px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 8px;
        }
        
        .header p {
            opacity: 0.9;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .card {
            background: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .card h3 {
            color: #2c3e50;
            margin-bottom: 16px;
            font-size: 18px;
        }
        
        .btn {
            background: linear-gradient(135deg, #FF6B35 0%, #FF8E53 100%);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            transition: transform 0.2s ease;
            margin: 5px;
        }
        
        .btn:hover {
            transform: translateY(-2px);
        }
        
        .btn-secondary {
            background: #6c757d;
        }
        
        .btn-success {
            background: #28a745;
        }
        
        .btn-warning {
            background: #ffc107;
            color: #333;
        }
        
        .btn-danger {
            background: #dc3545;
        }
        
        .form-group {
            margin-bottom: 16px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #2c3e50;
        }
        
        .form-group input,
        .form-group select {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 8px;
            font-size: 14px;
        }
        
        .alert {
            padding: 16px;
            border-radius: 8px;
            margin: 16px 0;
        }
        
        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .alert-info {
            background: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 16px;
        }
        
        .table th,
        .table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        .table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #2c3e50;
        }
        
        .badge {
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .badge-success {
            background: #28a745;
            color: white;
        }
        
        .badge-warning {
            background: #ffc107;
            color: #333;
        }
        
        .badge-danger {
            background: #dc3545;
            color: white;
        }
        
        .badge-info {
            background: #17a2b8;
            color: white;
        }
        
        .loading {
            display: none;
            text-align: center;
            padding: 20px;
        }
        
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #FF6B35;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 10px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }
        
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .stat-number {
            font-size: 32px;
            font-weight: 700;
            color: #FF6B35;
            margin-bottom: 8px;
        }
        
        .stat-label {
            color: #6c757d;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>CNERGY GYM</h1>
        <p>Subscription Expiry Management Dashboard</p>
    </div>
    
    <div class="container">
        <!-- Statistics -->
        <div class="stats" id="stats">
            <div class="stat-card">
                <div class="stat-number" id="totalSubscriptions">-</div>
                <div class="stat-label">Total Active Subscriptions</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="expiringSoon">-</div>
                <div class="stat-label">Expiring in 30 Days</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="expiringThisWeek">-</div>
                <div class="stat-label">Expiring This Week</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="expiringToday">-</div>
                <div class="stat-label">Expiring Today</div>
            </div>
        </div>
        
        <div class="dashboard-grid">
            <!-- Quick Actions -->
            <div class="card">
                <h3>Quick Actions</h3>
                <button class="btn" onclick="checkExpiryEmails()">Check & Send Expiry Emails</button>
                <button class="btn btn-secondary" onclick="loadExpiringSubscriptions()">Refresh Subscription List</button>
                <button class="btn btn-success" onclick="showTestEmailForm()">Send Test Email</button>
            </div>
            
            <!-- Test Email Form -->
            <div class="card" id="testEmailForm" style="display: none;">
                <h3>Send Test Email</h3>
                <form id="testForm">
                    <div class="form-group">
                        <label>Email Address:</label>
                        <input type="email" id="testEmail" required>
                    </div>
                    <div class="form-group">
                        <label>Name:</label>
                        <input type="text" id="testName" required>
                    </div>
                    <div class="form-group">
                        <label>Days Remaining:</label>
                        <select id="testDays">
                            <option value="14">14 Days (2 Weeks)</option>
                            <option value="7" selected>7 Days (1 Week)</option>
                            <option value="3">3 Days</option>
                            <option value="1">1 Day (Urgent)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Plan Name:</label>
                        <input type="text" id="testPlan" value="Test Plan">
                    </div>
                    <div class="form-group">
                        <label>Price:</label>
                        <input type="number" id="testPrice" value="999.00" step="0.01">
                    </div>
                    <button type="submit" class="btn btn-success">Send Test Email</button>
                    <button type="button" class="btn btn-secondary" onclick="hideTestEmailForm()">Cancel</button>
                </form>
            </div>
            
            <!-- System Status -->
            <div class="card">
                <h3>System Status</h3>
                <div id="systemStatus">
                    <p>Email Service: <span class="badge badge-success">Active</span></p>
                    <p>Database: <span class="badge badge-success">Connected</span></p>
                    <p>Last Check: <span id="lastCheck">Never</span></p>
                </div>
            </div>
        </div>
        
        <!-- Results -->
        <div id="results"></div>
        
        <!-- Expiring Subscriptions Table -->
        <div class="card">
            <h3>Expiring Subscriptions (Next 30 Days)</h3>
            <div class="loading" id="loading">
                <div class="spinner"></div>
                <p>Loading subscriptions...</p>
            </div>
            <div id="subscriptionsTable"></div>
        </div>
    </div>
    
    <script>
        // Load initial data
        document.addEventListener('DOMContentLoaded', function() {
            loadExpiringSubscriptions();
        });
        
        // Test email form
        document.getElementById('testForm').addEventListener('submit', function(e) {
            e.preventDefault();
            sendTestEmail();
        });
        
        function showTestEmailForm() {
            document.getElementById('testEmailForm').style.display = 'block';
        }
        
        function hideTestEmailForm() {
            document.getElementById('testEmailForm').style.display = 'none';
        }
        
        function sendTestEmail() {
            const formData = new FormData();
            formData.append('action', 'send_test_email');
            formData.append('email', document.getElementById('testEmail').value);
            formData.append('name', document.getElementById('testName').value);
            formData.append('days', document.getElementById('testDays').value);
            formData.append('plan', document.getElementById('testPlan').value);
            formData.append('price', document.getElementById('testPrice').value);
            
            fetch('', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showAlert('Test email sent successfully!', 'success');
                    hideTestEmailForm();
                } else {
                    showAlert('Failed to send test email: ' + data.message, 'error');
                }
            })
            .catch(error => {
                showAlert('Error: ' + error.message, 'error');
            });
        }
        
        function checkExpiryEmails() {
            showLoading();
            
            const formData = new FormData();
            formData.append('action', 'check_expiry');
            
            fetch('', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                hideLoading();
                if (data.success) {
                    const summary = data.data;
                    let html = '<div class="alert alert-success">';
                    html += '<h4>Expiry Check Completed</h4>';
                    html += '<p><strong>Total Checked:</strong> ' + summary.total_checked + '</p>';
                    html += '<p><strong>Emails Sent:</strong> ' + summary.emails_sent + '</p>';
                    html += '<p><strong>Errors:</strong> ' + summary.errors + '</p>';
                    html += '</div>';
                    
                    if (summary.details && summary.details.length > 0) {
                        html += '<div class="card"><h3>Details</h3>';
                        html += '<table class="table">';
                        html += '<tr><th>Member</th><th>Email</th><th>Days</th><th>Status</th></tr>';
                        
                        summary.details.forEach(detail => {
                            const statusClass = detail.status === 'sent' ? 'badge-success' : 'badge-danger';
                            html += '<tr>';
                            html += '<td>' + detail.user + '</td>';
                            html += '<td>' + detail.email + '</td>';
                            html += '<td>' + detail.days_remaining + '</td>';
                            html += '<td><span class="badge ' + statusClass + '">' + detail.status + '</span></td>';
                            html += '</tr>';
                        });
                        
                        html += '</table></div>';
                    }
                    
                    document.getElementById('results').innerHTML = html;
                    document.getElementById('lastCheck').textContent = new Date().toLocaleString();
                    
                    // Refresh subscription list
                    loadExpiringSubscriptions();
                } else {
                    showAlert('Failed to check expiry emails: ' + data.message, 'error');
                }
            })
            .catch(error => {
                hideLoading();
                showAlert('Error: ' + error.message, 'error');
            });
        }
        
        function loadExpiringSubscriptions() {
            document.getElementById('loading').style.display = 'block';
            document.getElementById('subscriptionsTable').innerHTML = '';
            
            const formData = new FormData();
            formData.append('action', 'get_expiring_subscriptions');
            
            fetch('', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                document.getElementById('loading').style.display = 'none';
                
                if (data.success) {
                    const subscriptions = data.data;
                    updateStats(subscriptions);
                    displaySubscriptions(subscriptions);
                } else {
                    showAlert('Failed to load subscriptions: ' + data.message, 'error');
                }
            })
            .catch(error => {
                document.getElementById('loading').style.display = 'none';
                showAlert('Error: ' + error.message, 'error');
            });
        }
        
        function updateStats(subscriptions) {
            const total = subscriptions.length;
            const expiringSoon = subscriptions.filter(s => s.days_remaining <= 30).length;
            const expiringThisWeek = subscriptions.filter(s => s.days_remaining <= 7).length;
            const expiringToday = subscriptions.filter(s => s.days_remaining <= 1).length;
            
            document.getElementById('totalSubscriptions').textContent = total;
            document.getElementById('expiringSoon').textContent = expiringSoon;
            document.getElementById('expiringThisWeek').textContent = expiringThisWeek;
            document.getElementById('expiringToday').textContent = expiringToday;
        }
        
        function displaySubscriptions(subscriptions) {
            if (subscriptions.length === 0) {
                document.getElementById('subscriptionsTable').innerHTML = '<p>No subscriptions expiring in the next 30 days.</p>';
                return;
            }
            
            let html = '<table class="table">';
            html += '<tr><th>Member</th><th>Email</th><th>Plan</th><th>Price</th><th>Expiry Date</th><th>Days Remaining</th><th>Status</th></tr>';
            
            subscriptions.forEach(sub => {
                const fullName = sub.fname + ' ' + sub.lname;
                const expiryDate = new Date(sub.end_date).toLocaleDateString();
                let badgeClass = 'badge-info';
                
                if (sub.days_remaining <= 1) {
                    badgeClass = 'badge-danger';
                } else if (sub.days_remaining <= 7) {
                    badgeClass = 'badge-warning';
                } else if (sub.days_remaining <= 14) {
                    badgeClass = 'badge-success';
                }
                
                html += '<tr>';
                html += '<td>' + fullName + '</td>';
                html += '<td>' + sub.email + '</td>';
                html += '<td>' + sub.plan_name + '</td>';
                html += '<td>₱' + parseFloat(sub.price).toFixed(2) + '</td>';
                html += '<td>' + expiryDate + '</td>';
                html += '<td>' + sub.days_remaining + '</td>';
                html += '<td><span class="badge ' + badgeClass + '">' + getStatusText(sub.days_remaining) + '</span></td>';
                html += '</tr>';
            });
            
            html += '</table>';
            document.getElementById('subscriptionsTable').innerHTML = html;
        }
        
        function getStatusText(days) {
            if (days <= 1) return 'Urgent';
            if (days <= 3) return 'Critical';
            if (days <= 7) return 'Warning';
            if (days <= 14) return 'Notice';
            return 'Normal';
        }
        
        function showAlert(message, type) {
            const alertClass = 'alert-' + (type === 'error' ? 'error' : type);
            const html = '<div class="alert ' + alertClass + '">' + message + '</div>';
            document.getElementById('results').innerHTML = html;
        }
        
        function showLoading() {
            document.getElementById('results').innerHTML = '<div class="loading"><div class="spinner"></div><p>Processing...</p></div>';
        }
        
        function hideLoading() {
            // Loading will be hidden when results are displayed
        }
    </script>
</body>
</html>
