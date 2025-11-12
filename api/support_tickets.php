<?php
// Handle OPTIONS preflight request FIRST - before any output
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
    header('Access-Control-Max-Age: 86400');
    http_response_code(200);
    exit();
}

// Set CORS headers for actual requests
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');

// Include email service
require_once __DIR__ . '/email_service.php';

$servername = "localhost";
$dbname = "u773938685_cnergydb";      
$username = "u773938685_archh29";  
$password = "Gwapoko385@"; 

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Connection failed: ' . $e->getMessage()]);
    exit();
}

// Get input from POST body or GET parameters
$input = [];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $rawInput = file_get_contents("php://input");
    if (!empty($rawInput)) {
        $input = json_decode($rawInput, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            $input = [];
        }
    }
}

// Get action from GET, POST body, or form data
$action = $_GET['action'] ?? ($input['action'] ?? ($_POST['action'] ?? ''));

try {
    switch ($action) {
        case 'create_ticket':
            createSupportTicket($pdo, $input);
            break;
        case 'get_user_tickets':
            getUserTickets($pdo);
            break;
        case 'get_all_tickets': // Admin function - get all tickets
            getAllTickets($pdo);
            break;
        case 'get_ticket':
            getTicket($pdo);
            break;
        case 'get_ticket_by_number': // Public endpoint - get ticket by ticket number and email
            getTicketByNumber($pdo, $input);
            break;
        case 'get_ticket_messages':
            getTicketMessages($pdo);
            break;
        case 'send_message':
            sendTicketMessage($pdo, $input);
            break;
        case 'update_status':
            updateTicketStatus($pdo, $input);
            break;
        default:
            echo json_encode([
                'success' => false,
                'message' => 'No action provided',
                'available_actions' => [
                    'create_ticket',
                    'get_user_tickets',
                    'get_all_tickets',
                    'get_ticket',
                    'get_ticket_by_number',
                    'get_ticket_messages',
                    'send_message',
                    'update_status'
                ]
            ]);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

// Create a new support ticket
function createSupportTicket($pdo, $input) {
    // Support both user_id and email for finding user
    $userId = $input['user_id'] ?? null;
    $userEmail = $input['email'] ?? null;
    $subject = $input['subject'] ?? '';
    $description = $input['description'] ?? '';
    $source = $input['source'] ?? 'mobile_app';
    
    if (empty($subject)) {
        echo json_encode(['success' => false, 'error' => 'Subject is required']);
        return;
    }
    
    if (empty($description)) {
        echo json_encode(['success' => false, 'error' => 'Description is required']);
        return;
    }
    
    // Require either user_id or email
    if (!$userId && !$userEmail) {
        echo json_encode(['success' => false, 'error' => 'Either user_id or email is required']);
        return;
    }
    
    // If user_id not provided, try to find user by email
    if (!$userId && $userEmail) {
        try {
            $userStmt = $pdo->prepare("SELECT id, email FROM user WHERE email = ? LIMIT 1");
            $userStmt->execute([$userEmail]);
            $user = $userStmt->fetch();
            
            if ($user) {
                $userId = intval($user['id']);
                error_log("Found user_id: $userId for email: $userEmail");
                // Use email from database to ensure consistency
                $userEmail = $user['email'];
            } else {
                error_log("No user found for email: $userEmail - creating ticket with email only");
                // Still create ticket but without user_id (for cases where user doesn't exist yet)
                // This can happen if the user account was deleted but they're trying to contact support
            }
        } catch (PDOException $e) {
            error_log("Error looking up user by email: " . $e->getMessage());
            // Continue without user_id - userEmail is already set from input
        }
    }
    
    // Determine source if not provided
    if ($source === 'mobile_app') {
        if (stripos($subject, 'deactivation') !== false || stripos($subject, 'deactivate') !== false) {
            $source = 'mobile_app_deactivation';
        } elseif (stripos($subject, 'verification') !== false || stripos($subject, 'rejected') !== false) {
            $source = 'mobile_app_rejection';
        }
    }
    
    // Get user email if we have user_id but not email
    if ($userId && !$userEmail) {
        try {
            $userStmt = $pdo->prepare("SELECT email FROM user WHERE id = ? LIMIT 1");
            $userStmt->execute([$userId]);
            $user = $userStmt->fetch();
            if ($user) {
                $userEmail = $user['email'];
            }
        } catch (PDOException $e) {
            error_log("Error getting user email: " . $e->getMessage());
        }
    }
    
    try {
        // Insert support request with user_id, user_email, status, source, and updated_at
        $stmt = $pdo->prepare("
            INSERT INTO support_requests (user_id, user_email, subject, message, status, source, updated_at)
            VALUES (?, ?, ?, ?, 'pending', ?, NOW())
        ");
        
        $stmt->execute([$userId, $userEmail, $subject, $description, $source]);
        $ticketId = $pdo->lastInsertId();
        
        // Generate ticket number immediately after insert
        $ticketNumber = 'REQ-' . str_pad($ticketId, 5, '0', STR_PAD_LEFT);
        $updateStmt = $pdo->prepare("UPDATE support_requests SET ticket_number = ?, updated_at = NOW() WHERE id = ?");
        $updateStmt->execute([$ticketNumber, $ticketId]);
        
        // Get the created ticket
        $stmt = $pdo->prepare("
            SELECT id, ticket_number, user_id, user_email, subject, message, status, created_at, updated_at
            FROM support_requests
            WHERE id = ?
        ");
        $stmt->execute([$ticketId]);
        $ticket = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Get user info for email notification (if user_id exists)
        $user = null;
        if ($userId) {
            $userStmt = $pdo->prepare("SELECT email, fname, mname, lname FROM user WHERE id = ?");
            $userStmt->execute([$userId]);
            $user = $userStmt->fetch();
            
            // Update user_email if needed (for backward compatibility)
            if ($user && !empty($user['email'])) {
                $updateEmailStmt = $pdo->prepare("UPDATE support_requests SET user_email = ? WHERE id = ?");
                $updateEmailStmt->execute([$user['email'], $ticketId]);
                $ticket['user_email'] = $user['email'];
            }
        }
        
        // Create initial message from the description (only if user_id exists)
        if ($userId) {
            try {
                $messageStmt = $pdo->prepare("
                    INSERT INTO support_request_messages (request_id, sender_id, message)
                    VALUES (?, ?, ?)
                ");
                $messageStmt->execute([$ticketId, $userId, $description]);
            } catch (PDOException $e) {
                // Log error but don't fail ticket creation
                error_log("Failed to create initial message: " . $e->getMessage());
            }
        }
        
        // Send email notification to user (if user email exists)
        if ($userEmail) {
            try {
                $emailService = new EmailService();
                // Use user's name if available, otherwise use email or default
                $userName = 'Valued Customer';
                if ($user) {
                    $userName = trim(($user['fname'] ?? '') . ' ' . ($user['mname'] ?? '') . ' ' . ($user['lname'] ?? ''));
                    $userName = $userName ?: 'Valued Customer';
                }
                
                $emailSubject = "[Ticket #{$ticketNumber}] Support Request Received - CNERGY GYM";
                $emailMessage = createTicketCreatedEmailTemplate($userName, $ticketNumber, $subject, $description);
                
                $emailResult = $emailService->sendSupportEmail(
                    $userEmail,
                    $userName,
                    $emailSubject,
                    $emailMessage
                );
                
                if (!$emailResult['success']) {
                    error_log("Failed to send ticket creation email: " . $emailResult['message']);
                }
            } catch (Exception $e) {
                error_log("Error sending ticket creation email: " . $e->getMessage());
            }
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Support ticket created successfully',
            'ticket' => $ticket
        ]);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Failed to create ticket: ' . $e->getMessage()]);
    }
}

// Get all tickets for a user
function getUserTickets($pdo) {
    $userId = $_GET['user_id'] ?? null;
    
    if (!$userId) {
        echo json_encode(['success' => false, 'error' => 'User ID is required']);
        return;
    }
    
    try {
        $stmt = $pdo->prepare("
            SELECT 
                id,
                COALESCE(ticket_number, '') as ticket_number,
                user_id,
                subject,
                message as description,
                COALESCE(status, 'pending') as status,
                created_at,
                updated_at,
                (SELECT COUNT(*) FROM support_request_messages WHERE request_id = support_requests.id) as message_count,
                (SELECT created_at FROM support_request_messages 
                 WHERE request_id = support_requests.id 
                 ORDER BY created_at DESC LIMIT 1) as last_message_at
            FROM support_requests
            WHERE user_id = ?
            ORDER BY created_at DESC
        ");
        
        $stmt->execute([$userId]);
        $tickets = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Format tickets to ensure all required fields are present and generate ticket_number if missing
        $formattedTickets = array_map(function($ticket) use ($pdo) {
            // Generate ticket number if it's empty
            $ticketNumber = !empty($ticket['ticket_number']) 
                ? $ticket['ticket_number'] 
                : 'REQ-' . str_pad($ticket['id'], 5, '0', STR_PAD_LEFT);
            
            // Update ticket_number in database if it was empty
            if (empty($ticket['ticket_number'])) {
                try {
                    $updateStmt = $pdo->prepare("UPDATE support_requests SET ticket_number = ? WHERE id = ?");
                    $updateStmt->execute([$ticketNumber, $ticket['id']]);
                } catch (PDOException $e) {
                    error_log("Failed to update ticket number: " . $e->getMessage());
                }
            }
            
            return [
                'id' => intval($ticket['id']),
                'ticket_number' => $ticketNumber,
                'user_id' => intval($ticket['user_id']),
                'subject' => $ticket['subject'] ?? '',
                'description' => $ticket['description'] ?? $ticket['message'] ?? '',
                'status' => $ticket['status'] ?? 'pending',
                'created_at' => $ticket['created_at'],
                'updated_at' => $ticket['updated_at'] ?? null,
                'resolved_at' => null, // Not in original table, can be added later
                'message_count' => intval($ticket['message_count'] ?? 0),
                'last_message_at' => $ticket['last_message_at'] ?? null,
            ];
        }, $tickets);
        
        echo json_encode([
            'success' => true,
            'tickets' => $formattedTickets
        ]);
    } catch (PDOException $e) {
        error_log("Error fetching tickets: " . $e->getMessage());
        echo json_encode(['success' => false, 'error' => 'Failed to fetch tickets: ' . $e->getMessage()]);
    }
}

// Get all tickets (admin view - returns all tickets with user info)
function getAllTickets($pdo) {
    try {
        // Fetch all support requests with user info and message counts
        $stmt = $pdo->query("
            SELECT 
                sr.id,
                COALESCE(sr.ticket_number, CONCAT('REQ-', LPAD(sr.id, 5, '0'))) as ticket_number,
                sr.user_id,
                sr.subject,
                sr.message,
                COALESCE(sr.status, 'pending') as status,
                sr.source,
                sr.created_at,
                sr.updated_at,
                sr.user_email,
                CONCAT_WS(' ', u.fname, u.mname, u.lname) as user_name,
                u.email as user_email_from_user,
                (SELECT COUNT(*) FROM support_request_messages WHERE request_id = sr.id) as message_count,
                (SELECT created_at FROM support_request_messages 
                 WHERE request_id = sr.id 
                 ORDER BY created_at DESC LIMIT 1) as last_message_at
            FROM support_requests sr
            LEFT JOIN user u ON sr.user_id = u.id
            ORDER BY sr.created_at DESC
        ");
        
        $tickets = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Format tickets and generate ticket_number if missing
        $formattedTickets = array_map(function($ticket) use ($pdo) {
            // Generate ticket number if it's empty
            $ticketNumber = !empty($ticket['ticket_number']) 
                ? $ticket['ticket_number'] 
                : 'REQ-' . str_pad($ticket['id'], 5, '0', STR_PAD_LEFT);
            
            // Update ticket_number in database if it was empty
            if (empty($ticket['ticket_number']) || $ticket['ticket_number'] === null) {
                try {
                    $updateStmt = $pdo->prepare("UPDATE support_requests SET ticket_number = ? WHERE id = ?");
                    $updateStmt->execute([$ticketNumber, $ticket['id']]);
                } catch (PDOException $e) {
                    error_log("Failed to update ticket number: " . $e->getMessage());
                }
            }
            
            // Use user_email from user table if available, fallback to support_requests.user_email
            $userEmail = !empty($ticket['user_email_from_user']) 
                ? $ticket['user_email_from_user'] 
                : ($ticket['user_email'] ?? '');
            
            return [
                'id' => intval($ticket['id']),
                'ticket_number' => $ticketNumber,
                'user_id' => intval($ticket['user_id'] ?? 0),
                'user_name' => $ticket['user_name'] ?? '',
                'user_email' => $userEmail,
                'subject' => $ticket['subject'] ?? '',
                'message' => $ticket['message'] ?? '',
                'status' => $ticket['status'] ?? 'pending',
                'source' => $ticket['source'] ?? '',
                'created_at' => $ticket['created_at'],
                'updated_at' => $ticket['updated_at'] ?? null,
                'resolved_at' => null, // Not in original table
                'message_count' => intval($ticket['message_count'] ?? 0),
                'last_message_at' => $ticket['last_message_at'] ?? null,
            ];
        }, $tickets);
        
        echo json_encode($formattedTickets);
    } catch (PDOException $e) {
        error_log("Error fetching tickets: " . $e->getMessage());
        echo json_encode(['success' => false, 'error' => 'Failed to fetch tickets: ' . $e->getMessage()]);
    }
}

// Get a specific ticket (supports both user and admin access)
function getTicket($pdo) {
    global $input;
    $ticketId = $_GET['ticket_id'] ?? null;
    $userId = $_GET['user_id'] ?? null;
    $adminId = $_GET['admin_id'] ?? ($input['admin_id'] ?? null);
    
    if (!$ticketId) {
        echo json_encode(['success' => false, 'error' => 'Ticket ID is required']);
        return;
    }
    
    try {
        // Check if admin is accessing (admin can access any ticket)
        $isAdmin = false;
        if ($adminId) {
            $adminStmt = $pdo->prepare("SELECT user_type_id FROM user WHERE id = ?");
            $adminStmt->execute([$adminId]);
            $admin = $adminStmt->fetch(PDO::FETCH_ASSOC);
            $isAdmin = $admin && in_array($admin['user_type_id'], [1, 2]);
        }
        
        // Build query based on whether it's admin or user
        if ($isAdmin) {
            // Admin can access any ticket
            $stmt = $pdo->prepare("
                SELECT 
                    sr.id,
                    COALESCE(sr.ticket_number, CONCAT('REQ-', LPAD(sr.id, 5, '0'))) as ticket_number,
                    sr.user_id,
                    sr.subject,
                    sr.message,
                    sr.status,
                    sr.source,
                    sr.created_at,
                    sr.updated_at,
                    sr.resolution_notes,
                    sr.user_email,
                    CONCAT_WS(' ', u.fname, u.mname, u.lname) as user_name,
                    u.email as user_email_from_user
                FROM support_requests sr
                LEFT JOIN user u ON sr.user_id = u.id
                WHERE sr.id = ?
            ");
            $stmt->execute([$ticketId]);
        } else {
            // User can only access their own tickets
            if (!$userId) {
                echo json_encode(['success' => false, 'error' => 'User ID is required']);
                return;
            }
        $stmt = $pdo->prepare("
            SELECT 
                id,
                ticket_number,
                user_id,
                subject,
                message as description,
                status,
                created_at,
                updated_at,
                resolution_notes
            FROM support_requests
            WHERE id = ? AND user_id = ?
        ");
            $stmt->execute([$ticketId, $userId]);
        }
        
        $ticket = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$ticket) {
            echo json_encode(['success' => false, 'error' => 'Ticket not found']);
            return;
        }
        
        // Format ticket for admin view
        if ($isAdmin) {
            $ticketNumber = !empty($ticket['ticket_number']) 
                ? $ticket['ticket_number'] 
                : 'REQ-' . str_pad($ticket['id'], 5, '0', STR_PAD_LEFT);
            
            $userEmail = !empty($ticket['user_email_from_user']) 
                ? $ticket['user_email_from_user'] 
                : ($ticket['user_email'] ?? '');
            
            echo json_encode([
                'success' => true,
                'ticket' => [
                    'id' => intval($ticket['id']),
                    'ticket_number' => $ticketNumber,
                    'user_id' => intval($ticket['user_id'] ?? 0),
                    'user_name' => $ticket['user_name'] ?? '',
                    'user_email' => $userEmail,
                    'subject' => $ticket['subject'] ?? '',
                    'message' => $ticket['message'] ?? '',
                    'status' => $ticket['status'] ?? 'pending',
                    'source' => $ticket['source'] ?? '',
                    'created_at' => $ticket['created_at'],
                    'updated_at' => $ticket['updated_at'] ?? null,
                    'resolved_at' => null, // Not in original table
                    'resolution_notes' => $ticket['resolution_notes'] ?? null,
                ]
            ]);
        } else {
        echo json_encode([
            'success' => true,
            'ticket' => $ticket
        ]);
        }
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Failed to fetch ticket: ' . $e->getMessage()]);
    }
}

// Get ticket by ticket number and email (public endpoint - no login required)
function getTicketByNumber($pdo, $input) {
    $ticketNumber = $_GET['ticket_number'] ?? ($input['ticket_number'] ?? '');
    $email = $_GET['email'] ?? ($input['email'] ?? '');
    
    if (empty($ticketNumber)) {
        echo json_encode(['success' => false, 'error' => 'Ticket number is required']);
        return;
    }
    
    if (empty($email)) {
        echo json_encode(['success' => false, 'error' => 'Email is required for verification']);
        return;
    }
    
    try {
        // Find ticket by ticket number
        $stmt = $pdo->prepare("
            SELECT 
                sr.id,
                sr.ticket_number,
                sr.user_id,
                sr.subject,
                sr.message,
                sr.status,
                sr.source,
                sr.created_at,
                sr.updated_at,
                sr.user_email,
                u.email as user_email_from_user,
                CONCAT_WS(' ', u.fname, u.mname, u.lname) as user_name
            FROM support_requests sr
            LEFT JOIN user u ON sr.user_id = u.id
            WHERE sr.ticket_number = ?
        ");
        $stmt->execute([$ticketNumber]);
        $ticket = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$ticket) {
            echo json_encode(['success' => false, 'error' => 'Ticket not found']);
            return;
        }
        
        // Verify email matches ticket owner
        $userEmail = !empty($ticket['user_email_from_user']) 
            ? $ticket['user_email_from_user'] 
            : ($ticket['user_email'] ?? '');
        
        // Case-insensitive email comparison
        if (strtolower(trim($userEmail)) !== strtolower(trim($email))) {
            echo json_encode(['success' => false, 'error' => 'Email does not match this ticket']);
            return;
        }
        
        // Get ticket messages
        $messagesStmt = $pdo->prepare("
            SELECT 
                stm.id,
                stm.request_id as ticket_id,
                stm.sender_id,
                stm.message,
                stm.created_at,
                u.fname,
                u.mname,
                u.lname,
                u.user_type_id,
                CONCAT_WS(' ', u.fname, u.mname, u.lname) as sender_name,
                CASE 
                    WHEN u.user_type_id IN (1, 2) THEN 'admin'
                    WHEN u.user_type_id = 3 THEN 'coach'
                    WHEN u.user_type_id = 4 THEN 'member'
                    ELSE 'user'
                END as sender_type
            FROM support_request_messages stm
            INNER JOIN user u ON stm.sender_id = u.id
            WHERE stm.request_id = ?
            ORDER BY stm.created_at ASC
        ");
        $messagesStmt->execute([$ticket['id']]);
        $messages = $messagesStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Format response
        echo json_encode([
            'success' => true,
            'ticket' => [
                'id' => intval($ticket['id']),
                'ticket_number' => $ticket['ticket_number'],
                'user_id' => intval($ticket['user_id'] ?? 0),
                'user_name' => $ticket['user_name'] ?? '',
                'user_email' => $userEmail,
                'subject' => $ticket['subject'] ?? '',
                'message' => $ticket['message'] ?? '',
                'status' => $ticket['status'] ?? 'pending',
                'source' => $ticket['source'] ?? '',
                'created_at' => $ticket['created_at'],
                'updated_at' => $ticket['updated_at'] ?? null,
            ],
            'messages' => $messages
        ]);
    } catch (PDOException $e) {
        error_log("Error fetching ticket by number: " . $e->getMessage());
        echo json_encode(['success' => false, 'error' => 'Failed to fetch ticket: ' . $e->getMessage()]);
    }
}

// Get messages for a ticket (supports both user and admin access)
function getTicketMessages($pdo) {
    $ticketId = $_GET['ticket_id'] ?? null;
    $userId = $_GET['user_id'] ?? null;
    $adminId = $_GET['admin_id'] ?? null;
    
    if (!$ticketId) {
        echo json_encode(['success' => false, 'error' => 'Ticket ID is required']);
        return;
    }
    
    try {
        // Check if admin is accessing (admin can access any ticket)
        $isAdmin = false;
        if ($adminId) {
            $adminStmt = $pdo->prepare("SELECT user_type_id FROM user WHERE id = ?");
            $adminStmt->execute([$adminId]);
            $admin = $adminStmt->fetch(PDO::FETCH_ASSOC);
            $isAdmin = $admin && in_array($admin['user_type_id'], [1, 2]);
        }
        
        // Verify user has access to this ticket (unless admin)
        if (!$isAdmin) {
        $checkStmt = $pdo->prepare("SELECT user_id FROM support_requests WHERE id = ?");
        $checkStmt->execute([$ticketId]);
        $ticket = $checkStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$ticket || ($userId && $ticket['user_id'] != $userId)) {
            echo json_encode(['success' => false, 'error' => 'Access denied']);
            return;
            }
        }
        
        // Get messages with sender info
        $stmt = $pdo->prepare("
            SELECT 
                stm.id,
                stm.request_id as ticket_id,
                stm.sender_id,
                stm.message,
                stm.created_at,
                u.fname,
                u.mname,
                u.lname,
                u.user_type_id,
                CONCAT_WS(' ', u.fname, u.mname, u.lname) as sender_name,
                CASE 
                    WHEN u.user_type_id IN (1, 2) THEN 'admin'
                    WHEN u.user_type_id = 3 THEN 'coach'
                    WHEN u.user_type_id = 4 THEN 'member'
                    ELSE 'user'
                END as sender_type
            FROM support_request_messages stm
            INNER JOIN user u ON stm.sender_id = u.id
            WHERE stm.request_id = ?
            ORDER BY stm.created_at ASC
        ");
        
        $stmt->execute([$ticketId]);
        $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'messages' => $messages
        ]);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Failed to fetch messages: ' . $e->getMessage()]);
    }
}

// Send a message in a ticket
function sendTicketMessage($pdo, $input) {
    $ticketId = $input['ticket_id'] ?? null;
    $senderId = $input['sender_id'] ?? null;
    $message = $input['message'] ?? '';
    
    if (!$ticketId) {
        echo json_encode(['success' => false, 'error' => 'Ticket ID is required']);
        return;
    }
    
    if (!$senderId) {
        echo json_encode(['success' => false, 'error' => 'Sender ID is required']);
        return;
    }
    
    if (empty(trim($message))) {
        echo json_encode(['success' => false, 'error' => 'Message is required']);
        return;
    }
    
    try {
        // Verify ticket exists and user has access
        $checkStmt = $pdo->prepare("SELECT user_id, status FROM support_requests WHERE id = ?");
        $checkStmt->execute([$ticketId]);
        $ticket = $checkStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$ticket) {
            echo json_encode(['success' => false, 'error' => 'Ticket not found']);
            return;
        }
        
        // Check if user is the ticket owner or admin/staff
        $userStmt = $pdo->prepare("SELECT user_type_id FROM user WHERE id = ?");
        $userStmt->execute([$senderId]);
        $user = $userStmt->fetch(PDO::FETCH_ASSOC);
        
        $isAdmin = $user && in_array($user['user_type_id'], [1, 2]); // Admin or Staff
        $isOwner = $ticket['user_id'] == $senderId;
        
        if (!$isAdmin && !$isOwner) {
            echo json_encode(['success' => false, 'error' => 'Access denied']);
            return;
        }
        
        // Insert message
        $stmt = $pdo->prepare("
            INSERT INTO support_request_messages (request_id, sender_id, message)
            VALUES (?, ?, ?)
        ");
        
        $stmt->execute([$ticketId, $senderId, $message]);
        $messageId = $pdo->lastInsertId();
        
        // If admin replied to a resolved ticket, change status back to in_progress (also updates updated_at)
        if ($isAdmin && $ticket['status'] === 'resolved') {
            $statusUpdateStmt = $pdo->prepare("UPDATE support_requests SET status = 'in_progress', updated_at = NOW() WHERE id = ?");
            $statusUpdateStmt->execute([$ticketId]);
        } else {
        // Update ticket's updated_at timestamp
        $updateStmt = $pdo->prepare("UPDATE support_requests SET updated_at = NOW() WHERE id = ?");
        $updateStmt->execute([$ticketId]);
        }
        
        // Get the created message with sender info
        $getMsgStmt = $pdo->prepare("
            SELECT 
                stm.id,
                stm.request_id as ticket_id,
                stm.sender_id,
                stm.message,
                stm.created_at,
                u.fname,
                u.mname,
                u.lname,
                u.user_type_id,
                CONCAT_WS(' ', u.fname, u.mname, u.lname) as sender_name,
                CASE 
                    WHEN u.user_type_id IN (1, 2) THEN 'admin'
                    WHEN u.user_type_id = 3 THEN 'coach'
                    WHEN u.user_type_id = 4 THEN 'member'
                    ELSE 'user'
                END as sender_type
            FROM support_request_messages stm
            INNER JOIN user u ON stm.sender_id = u.id
            WHERE stm.id = ?
        ");
        $getMsgStmt->execute([$messageId]);
        $createdMessage = $getMsgStmt->fetch(PDO::FETCH_ASSOC);
        
        // Send email notification if admin replied to user
        if ($isAdmin) {
            try {
                // Get ticket and user info
                $ticketStmt = $pdo->prepare("
                    SELECT sr.ticket_number, sr.subject, sr.user_id, u.email, u.fname, u.mname, u.lname
                    FROM support_requests sr
                    LEFT JOIN user u ON sr.user_id = u.id
                    WHERE sr.id = ?
                ");
                $ticketStmt->execute([$ticketId]);
                $ticketInfo = $ticketStmt->fetch(PDO::FETCH_ASSOC);
                
                if ($ticketInfo && !empty($ticketInfo['email'])) {
                    $emailService = new EmailService();
                    $userName = trim(($ticketInfo['fname'] ?? '') . ' ' . ($ticketInfo['mname'] ?? '') . ' ' . ($ticketInfo['lname'] ?? ''));
                    $userName = $userName ?: 'Valued Customer';
                    
                    // Get admin name
                    $adminName = $createdMessage['sender_name'] ?? 'CNERGY Support Team';
                    
                    $emailSubject = "[Ticket #{$ticketInfo['ticket_number']}] New Reply from CNERGY Support";
                    $emailMessage = createAdminReplyEmailTemplate($userName, $ticketInfo['ticket_number'], $ticketInfo['subject'], $message, $adminName);
                    
                    $emailResult = $emailService->sendSupportEmail(
                        $ticketInfo['email'],
                        $userName,
                        $emailSubject,
                        $emailMessage
                    );
                    
                    if (!$emailResult['success']) {
                        error_log("Failed to send admin reply email: " . $emailResult['message']);
                    }
                }
            } catch (Exception $e) {
                error_log("Error sending admin reply email: " . $e->getMessage());
            }
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Message sent successfully',
            'data' => $createdMessage
        ]);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Failed to send message: ' . $e->getMessage()]);
    }
}

// Update ticket status (admin only)
function updateTicketStatus($pdo, $input) {
    $ticketId = $input['ticket_id'] ?? null;
    $status = $input['status'] ?? null;
    $adminId = $input['admin_id'] ?? null;
    
    if (!$ticketId || !$status) {
        echo json_encode(['success' => false, 'error' => 'Ticket ID and status are required']);
        return;
    }
    
    if (!in_array($status, ['pending', 'in_progress', 'resolved'])) {
        echo json_encode(['success' => false, 'error' => 'Invalid status']);
        return;
    }
    
    try {
        // Verify admin
        if ($adminId) {
            $adminStmt = $pdo->prepare("SELECT user_type_id FROM user WHERE id = ?");
            $adminStmt->execute([$adminId]);
            $admin = $adminStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$admin || !in_array($admin['user_type_id'], [1, 2])) {
                echo json_encode(['success' => false, 'error' => 'Unauthorized']);
                return;
            }
        }
        
        // Get ticket and user info for email notification
        $ticketStmt = $pdo->prepare("
            SELECT sr.ticket_number, sr.subject, sr.user_id, sr.status as old_status, u.email, u.fname, u.mname, u.lname
            FROM support_requests sr
            LEFT JOIN user u ON sr.user_id = u.id
            WHERE sr.id = ?
        ");
        $ticketStmt->execute([$ticketId]);
        $ticketInfo = $ticketStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$ticketInfo) {
            echo json_encode(['success' => false, 'error' => 'Ticket not found']);
            return;
        }
        
        $oldStatus = $ticketInfo['old_status'];
        
        // Update status
            $stmt = $pdo->prepare("
                UPDATE support_requests 
                SET status = ?, updated_at = NOW()
                WHERE id = ?
            ");
        
        $stmt->execute([$status, $ticketId]);
        
        // Send email notification if status changed and user email exists
        if ($oldStatus !== $status && $ticketInfo && !empty($ticketInfo['email'])) {
            try {
                $emailService = new EmailService();
                $userName = trim(($ticketInfo['fname'] ?? '') . ' ' . ($ticketInfo['mname'] ?? '') . ' ' . ($ticketInfo['lname'] ?? ''));
                $userName = $userName ?: 'Valued Customer';
                
                $emailSubject = "[Ticket #{$ticketInfo['ticket_number']}] Status Updated - CNERGY GYM";
                $emailMessage = createStatusChangeEmailTemplate($userName, $ticketInfo['ticket_number'], $ticketInfo['subject'], $oldStatus, $status);
                
                $emailResult = $emailService->sendSupportEmail(
                    $ticketInfo['email'],
                    $userName,
                    $emailSubject,
                    $emailMessage
                );
                
                if (!$emailResult['success']) {
                    error_log("Failed to send status change email: " . $emailResult['message']);
                }
            } catch (Exception $e) {
                error_log("Error sending status change email: " . $e->getMessage());
            }
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Ticket status updated successfully'
        ]);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Failed to update status: ' . $e->getMessage()]);
    }
}

// ========================================
// EMAIL TEMPLATE FUNCTIONS
// ========================================

/**
 * Create email template for ticket creation notification
 */
function createTicketCreatedEmailTemplate($userName, $ticketNumber, $subject, $description) {
    $publicTicketUrl = "https://cnergy.site/ticket-status?ticket=" . urlencode($ticketNumber);
    
    return "
CNERGY GYM - Support Ticket Created
=====================================

Hello {$userName}!

Your support ticket has been created successfully. We've received your request and our team will review it shortly.

TICKET DETAILS:
- Ticket Number: {$ticketNumber}
- Subject: {$subject}
- Status: Pending
- Created: " . date('F j, Y g:i A') . "

YOUR MESSAGE:
{$description}

WHAT HAPPENS NEXT:
1. Our support team will review your ticket
2. You'll receive an email when we respond
3. You can check your ticket status at any time using the link below

CHECK TICKET STATUS (No Login Required):
{$publicTicketUrl}

IMPORTANT NOTES:
- Keep your ticket number ({$ticketNumber}) for reference
- If your account is locked, you can still check ticket status using the link above
- You'll receive email notifications for all updates
- Our team typically responds within 24-48 hours

NEED URGENT HELP?
If this is an urgent matter, please contact us directly:
- Phone: (555) 123-4567
- Email: cnergyfitnessgym@cnergy.site
- Visit: 123 Fitness Street, Gym City, GC 12345

Thank you for contacting CNERGY GYM Support!
We're here to help you resolve your issue.

---
This is an automated email. Please do not reply directly to this email.
To reply to your ticket, use the ticket status page link above.
";
}

/**
 * Create email template for admin reply notification
 */
function createAdminReplyEmailTemplate($userName, $ticketNumber, $subject, $adminMessage, $adminName) {
    $publicTicketUrl = "https://cnergy.site/ticket-status?ticket=" . urlencode($ticketNumber);
    
    return "
CNERGY GYM - New Reply on Your Support Ticket
===============================================

Hello {$userName}!

You have a new reply from our support team on your ticket.

TICKET DETAILS:
- Ticket Number: {$ticketNumber}
- Subject: {$subject}
- Replied by: {$adminName}
- Date: " . date('F j, Y g:i A') . "

SUPPORT TEAM REPLY:
{$adminMessage}

VIEW FULL CONVERSATION (No Login Required):
{$publicTicketUrl}

You can view the complete conversation and reply to this message using the link above.

IMPORTANT:
- If your account is locked, you can still access your ticket using the link above
- You'll receive email notifications for all future replies
- Our team is working to resolve your issue as quickly as possible

NEED MORE HELP?
- Phone: (555) 123-4567
- Email: cnergyfitnessgym@cnergy.site
- Visit: 123 Fitness Street, Gym City, GC 12345

Thank you for your patience!

---
This is an automated email. Please do not reply directly to this email.
To reply to your ticket, use the ticket status page link above.
";
}

/**
 * Create email template for status change notification
 */
function createStatusChangeEmailTemplate($userName, $ticketNumber, $subject, $oldStatus, $newStatus) {
    $publicTicketUrl = "https://cnergy.site/ticket-status?ticket=" . urlencode($ticketNumber);
    
    $statusMessages = [
        'pending' => 'Your ticket is pending review',
        'in_progress' => 'Our team is working on your ticket',
        'resolved' => 'Your ticket has been resolved'
    ];
    
    $statusMessage = $statusMessages[$newStatus] ?? 'Your ticket status has been updated';
    $statusLabel = ucwords(str_replace('_', ' ', $newStatus));
    
    $resolutionMessage = '';
    if ($newStatus === 'resolved') {
        $resolutionMessage = "
RESOLUTION:
Your support ticket has been resolved. If you're still experiencing issues or have questions, please reply to this ticket or contact us directly.

If your account was locked and has been unlocked, you can now log in to the app using your credentials.
";
    }
    
    return "
CNERGY GYM - Ticket Status Update
==================================

Hello {$userName}!

Your support ticket status has been updated.

TICKET DETAILS:
- Ticket Number: {$ticketNumber}
- Subject: {$subject}
- Previous Status: " . ucwords(str_replace('_', ' ', $oldStatus)) . "
- New Status: {$statusLabel}
- Updated: " . date('F j, Y g:i A') . "

STATUS UPDATE:
{$statusMessage}

{$resolutionMessage}

VIEW TICKET STATUS (No Login Required):
{$publicTicketUrl}

You can view the complete conversation and check the current status using the link above.

IMPORTANT:
- If your account is locked, you can still access your ticket using the link above
- If your issue is resolved and your account is unlocked, you can now log in
- If you have questions, please reply to this ticket or contact us

NEED MORE HELP?
- Phone: (555) 123-4567
- Email: cnergyfitnessgym@cnergy.site
- Visit: 123 Fitness Street, Gym City, GC 12345

Thank you for your patience!

---
This is an automated email. Please do not reply directly to this email.
To reply to your ticket, use the ticket status page link above.
";
}
?>

