<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Support Requests - Admin Panel</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
        }
        
        .header p {
            opacity: 0.9;
            font-size: 14px;
        }
        
        .toolbar {
            padding: 20px 30px;
            background: #f8f9fa;
            border-bottom: 1px solid #dee2e6;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .search-box {
            flex: 1;
            min-width: 250px;
        }
        
        .search-box input {
            width: 100%;
            padding: 10px 15px;
            border: 2px solid #dee2e6;
            border-radius: 6px;
            font-size: 14px;
        }
        
        .search-box input:focus {
            outline: none;
            border-color: #FF6B35;
        }
        
        .stats {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        .stat-box {
            background: white;
            padding: 15px 20px;
            border-radius: 6px;
            border: 1px solid #dee2e6;
            min-width: 150px;
        }
        
        .stat-box .label {
            font-size: 12px;
            color: #6c757d;
            margin-bottom: 5px;
        }
        
        .stat-box .value {
            font-size: 24px;
            font-weight: bold;
            color: #FF6B35;
        }
        
        .content {
            padding: 30px;
        }
        
        .loading {
            text-align: center;
            padding: 40px;
            color: #6c757d;
        }
        
        .requests-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        .requests-table th {
            background: #f8f9fa;
            padding: 15px;
            text-align: left;
            font-weight: 600;
            color: #495057;
            border-bottom: 2px solid #dee2e6;
            position: sticky;
            top: 0;
        }
        
        .requests-table td {
            padding: 15px;
            border-bottom: 1px solid #dee2e6;
        }
        
        .requests-table tr:hover {
            background: #f8f9fa;
        }
        
        .email {
            color: #FF6B35;
            font-weight: 500;
        }
        
        .subject {
            font-weight: 500;
            color: #212529;
            max-width: 300px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        
        .message-preview {
            max-width: 400px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            color: #6c757d;
        }
        
        .source-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .source-badge.mobile_app {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .source-badge.mobile_app_deactivation {
            background: #fff3e0;
            color: #e65100;
        }
        
        .date {
            color: #6c757d;
            font-size: 13px;
        }
        
        .actions {
            display: flex;
            gap: 10px;
        }
        
        .btn {
            padding: 8px 15px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 500;
            transition: all 0.3s;
        }
        
        .btn-view {
            background: #FF6B35;
            color: white;
        }
        
        .btn-view:hover {
            background: #e55a2b;
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            overflow: auto;
        }
        
        .modal-content {
            background: white;
            margin: 50px auto;
            padding: 30px;
            border-radius: 12px;
            max-width: 700px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
        }
        
        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #dee2e6;
        }
        
        .modal-header h2 {
            color: #FF6B35;
        }
        
        .close {
            font-size: 28px;
            font-weight: bold;
            color: #6c757d;
            cursor: pointer;
            border: none;
            background: none;
        }
        
        .close:hover {
            color: #FF6B35;
        }
        
        .modal-body {
            line-height: 1.8;
        }
        
        .modal-body .field {
            margin-bottom: 20px;
        }
        
        .modal-body .label {
            font-weight: 600;
            color: #495057;
            margin-bottom: 5px;
            display: block;
        }
        
        .modal-body .value {
            color: #212529;
        }
        
        .message-content {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #6c757d;
        }
        
        .empty-state svg {
            width: 100px;
            height: 100px;
            margin-bottom: 20px;
            opacity: 0.3;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔔 Support Requests</h1>
            <p>Review and manage customer support requests</p>
        </div>
        
        <div class="toolbar">
            <div class="search-box">
                <input type="text" id="searchInput" placeholder="Search by email, subject, or message..." onkeyup="filterRequests()">
            </div>
            <div class="stats">
                <div class="stat-box">
                    <div class="label">Total Requests</div>
                    <div class="value" id="totalCount">0</div>
                </div>
                <div class="stat-box">
                    <div class="label">Showing</div>
                    <div class="value" id="showingCount">0</div>
                </div>
            </div>
        </div>
        
        <div class="content">
            <div id="loading" class="loading">Loading support requests...</div>
            <div id="contentArea" style="display: none;">
                <table class="requests-table" id="requestsTable">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Email</th>
                            <th>Subject</th>
                            <th>Message</th>
                            <th>Source</th>
                            <th>Date</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="requestsBody">
                    </tbody>
                </table>
            </div>
            <div id="emptyState" class="empty-state" style="display: none;">
                <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M20 6h-2.18c.11-.31.18-.65.18-1 0-1.66-1.34-3-3-3-1.05 0-1.96.54-2.5 1.35l-.5.67-.5-.68C10.96 2.54 10.05 2 9 2 7.34 2 6 3.34 6 5c0 .35.07.69.18 1H4c-1.11 0-1.99.89-1.99 2L2 19c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V8c0-1.11-.89-2-2-2zm-5-2c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1zM9 4c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1zm11 15H4v-2h16v2zm0-5H4V8h5.08L7 10.83 8.62 12 11 8.76l1-1.36 1 1.36L15.38 12 17 10.83 14.92 8H20v6z"/>
                </svg>
                <h3>No support requests found</h3>
                <p>All support requests will appear here</p>
            </div>
        </div>
    </div>
    
    <!-- Modal for viewing full request -->
    <div id="requestModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>Support Request Details</h2>
                <button class="close" onclick="closeModal()">&times;</button>
            </div>
            <div class="modal-body" id="modalBody">
            </div>
        </div>
    </div>
    
    <script>
        let allRequests = [];
        
        // Load support requests
        async function loadRequests() {
            try {
                const response = await fetch('admin_support_requests.php?action=get_all');
                const data = await response.json();
                
                if (data.success) {
                    allRequests = data.data;
                    document.getElementById('totalCount').textContent = data.total;
                    displayRequests(allRequests);
                    document.getElementById('loading').style.display = 'none';
                    document.getElementById('contentArea').style.display = 'block';
                } else {
                    throw new Error(data.message || 'Failed to load requests');
                }
            } catch (error) {
                console.error('Error loading requests:', error);
                document.getElementById('loading').innerHTML = 
                    '<div style="color: red;">Error loading support requests. Please refresh the page.</div>';
            }
        }
        
        // Display requests in table
        function displayRequests(requests) {
            const tbody = document.getElementById('requestsBody');
            const emptyState = document.getElementById('emptyState');
            
            if (requests.length === 0) {
                document.getElementById('contentArea').style.display = 'none';
                emptyState.style.display = 'block';
                document.getElementById('showingCount').textContent = '0';
                return;
            }
            
            document.getElementById('contentArea').style.display = 'block';
            emptyState.style.display = 'none';
            document.getElementById('showingCount').textContent = requests.length;
            
            tbody.innerHTML = requests.map(request => {
                const date = new Date(request.created_at);
                const formattedDate = date.toLocaleString('en-US', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                });
                
                const sourceClass = request.source.replace(/[^a-z0-9]/gi, '_');
                
                return `
                    <tr>
                        <td>${request.id}</td>
                        <td><span class="email">${escapeHtml(request.user_email)}</span></td>
                        <td><div class="subject">${escapeHtml(request.subject)}</div></td>
                        <td><div class="message-preview" title="${escapeHtml(request.message)}">${escapeHtml(request.message.substring(0, 80))}${request.message.length > 80 ? '...' : ''}</div></td>
                        <td><span class="source-badge ${sourceClass}">${escapeHtml(request.source)}</span></td>
                        <td><span class="date">${formattedDate}</span></td>
                        <td>
                            <div class="actions">
                                <button class="btn btn-view" onclick="viewRequest(${request.id})">View</button>
                            </div>
                        </td>
                    </tr>
                `;
            }).join('');
        }
        
        // View full request
        async function viewRequest(id) {
            try {
                const response = await fetch(`admin_support_requests.php?action=get_one&id=${id}`);
                const data = await response.json();
                
                if (data.success) {
                    const request = data.data;
                    const date = new Date(request.created_at);
                    const formattedDate = date.toLocaleString('en-US', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                    });
                    
                    document.getElementById('modalBody').innerHTML = `
                        <div class="field">
                            <div class="label">Request ID</div>
                            <div class="value">#${request.id}</div>
                        </div>
                        <div class="field">
                            <div class="label">Email</div>
                            <div class="value"><span class="email">${escapeHtml(request.user_email)}</span></div>
                        </div>
                        <div class="field">
                            <div class="label">Subject</div>
                            <div class="value">${escapeHtml(request.subject)}</div>
                        </div>
                        <div class="field">
                            <div class="label">Message</div>
                            <div class="message-content">${escapeHtml(request.message)}</div>
                        </div>
                        <div class="field">
                            <div class="label">Source</div>
                            <div class="value"><span class="source-badge ${request.source.replace(/[^a-z0-9]/gi, '_')}">${escapeHtml(request.source)}</span></div>
                        </div>
                        <div class="field">
                            <div class="label">Submitted</div>
                            <div class="value"><span class="date">${formattedDate}</span></div>
                        </div>
                    `;
                    
                    document.getElementById('requestModal').style.display = 'block';
                } else {
                    alert('Failed to load request details');
                }
            } catch (error) {
                console.error('Error loading request:', error);
                alert('Error loading request details');
            }
        }
        
        // Filter requests
        function filterRequests() {
            const searchTerm = document.getElementById('searchInput').value.toLowerCase();
            
            if (searchTerm === '') {
                displayRequests(allRequests);
                return;
            }
            
            const filtered = allRequests.filter(request => 
                request.user_email.toLowerCase().includes(searchTerm) ||
                request.subject.toLowerCase().includes(searchTerm) ||
                request.message.toLowerCase().includes(searchTerm)
            );
            
            displayRequests(filtered);
        }
        
        // Close modal
        function closeModal() {
            document.getElementById('requestModal').style.display = 'none';
        }
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('requestModal');
            if (event.target === modal) {
                closeModal();
            }
        }
        
        // Escape HTML
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        // Load requests on page load
        loadRequests();
        
        // Refresh every 30 seconds
        setInterval(loadRequests, 30000);
    </script>
</body>
</html>





