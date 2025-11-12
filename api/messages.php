<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');
header('Access-Control-Max-Age: 86400');

// Add debugging (remove in production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$dbname = "u773938685_cnergydb";      
$username = "u773938685_archh29";  
$password = "Gwapoko385@"; 

try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Connection failed: ' . $e->getMessage()]);
    exit();
}

// Helper function to format MySQL datetime to ISO 8601 - MORE ROBUST
function formatDateTimeToISO($mysqlDateTime) {
    // Handle null, empty, or invalid dates
    if (empty($mysqlDateTime) || $mysqlDateTime === null || $mysqlDateTime === '0000-00-00 00:00:00') {
        return null; // Return null instead of current time for empty dates
    }
    
    try {
        $date = new DateTime($mysqlDateTime);
        return $date->format('c'); // ISO 8601 format
    } catch (Exception $e) {
        return null; // Return null for invalid dates
    }
}

// Get the action from URL parameter
$action = $_GET['action'] ?? '';

if (empty($action)) {
    echo json_encode([
        'success' => false,
        'message' => 'No action provided',
        'available_actions' => [
            'test_connection',
            'debug_relationships', 
            'conversations',
            'messages',
            'send_message'
        ]
    ]);
    exit();
}

try {
    switch ($action) {
        case 'conversations':
            getConversations();
            break;
        case 'messages':
            getMessages();
            break;
        case 'send_message':
            try {
                sendMessage();
            } catch (Throwable $e) {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'message' => 'Fatal error in sendMessage: ' . $e->getMessage(),
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                    'trace' => $e->getTraceAsString()
                ]);
            }
            break;
        case 'mark_read':
            markMessagesAsRead();
            break;
        case 'get_or_create_conversation':
            getOrCreateConversation();
            break;
        case 'available_contacts':
            getAvailableContacts();
            break;
        case 'search_messages':
            searchMessages();
            break;
        case 'delete_message':
            deleteMessage();
            break;
        case 'unread_count':
            getUnreadCount();
            break;
        case 'update_online_status':
            updateOnlineStatus();
            break;
        case 'get_or_create_admin_conversation':
            getOrCreateAdminConversation();
            break;
        case 'submit_support_request':
            submitSupportRequest();
            break;
        case 'debug_relationships':
            debugRelationships();
            break;
        case 'test_connection':
            testConnection();
            break;
        case 'test_messages_table':
            testMessagesTable();
            break;
        default:
            http_response_code(400);
            echo json_encode([
                'success' => false, 
                'message' => 'Invalid action: ' . $action
            ]);
            exit();
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Server error: ' . $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}

// Test connection and table structure
function testConnection() {
    global $pdo;
    
    try {
        // Test basic connection
        $stmt = $pdo->query("SELECT 1 as test");
        $result = $stmt->fetch();
        
        // Check if coach_member_list table exists
        $tableCheck = $pdo->query("SHOW TABLES LIKE 'coach_member_list'");
        $tableExists = $tableCheck->rowCount() > 0;
        
        $response = [
            'success' => true,
            'message' => 'Connection successful',
            'connection_test' => $result,
            'table_exists' => $tableExists
        ];
        
        if ($tableExists) {
            // Check table structure
            $columns = $pdo->query("DESCRIBE coach_member_list")->fetchAll();
            $response['columns'] = $columns;
        }
        
        echo json_encode($response);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Test failed: ' . $e->getMessage()
        ]);
    }
}

// Test messages table structure
function testMessagesTable() {
    global $pdo;
    
    try {
        // Check if messages table exists
        $tableCheck = $pdo->query("SHOW TABLES LIKE 'messages'");
        $tableExists = $tableCheck->rowCount() > 0;
        
        $response = [
            'success' => true,
            'messages_table_exists' => $tableExists
        ];
        
        if ($tableExists) {
            // Get table structure
            $columns = $pdo->query("DESCRIBE messages")->fetchAll();
            $response['columns'] = $columns;
            
            // Try a simple select
            $testSelect = $pdo->query("SELECT COUNT(*) as count FROM messages LIMIT 1");
            $count = $testSelect->fetch();
            $response['message_count'] = $count['count'] ?? 0;
        } else {
            // Check what message-related tables exist
            $allTables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
            $messageTables = array_filter($allTables, function($table) {
                return stripos($table, 'message') !== false || stripos($table, 'chat') !== false;
            });
            $response['similar_tables'] = array_values($messageTables);
        }
        
        echo json_encode($response);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Test failed: ' . $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]);
    }
}

// Debug relationships
function debugRelationships() {
    global $pdo;
    
    try {
        if (!isset($_GET['user_id'])) {
            echo json_encode(['success' => false, 'message' => 'User ID required']);
            exit();
        }
        
        $userId = (int)$_GET['user_id'];
        
        // Check if user exists
        $userCheck = $pdo->prepare("SELECT id, fname, lname FROM user WHERE id = ?");
        $userCheck->execute([$userId]);
        $user = $userCheck->fetch();
        
        if (!$user) {
            echo json_encode([
                'success' => false,
                'message' => 'User not found',
                'user_id' => $userId
            ]);
            return;
        }
        
        // Get all relationships for this user
        $stmt = $pdo->prepare("
            SELECT * FROM coach_member_list 
            WHERE coach_id = ? OR member_id = ?
        ");
        $stmt->execute([$userId, $userId]);
        $relationships = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'user_id' => $userId,
            'user' => $user,
            'relationships' => $relationships,
            'relationship_count' => count($relationships)
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Debug failed: ' . $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]);
    }
}

// Get all conversations for a user (FIXED DATE FORMAT - HANDLES NULL PROPERLY)
function getConversations() {
    global $pdo;
    
    try {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            exit();
        }

        if (!isset($_GET['user_id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'User ID is required']);
            exit();
        }

        $userId = (int)$_GET['user_id'];

        // First check if user exists and get email
        $userCheck = $pdo->prepare("SELECT id, email FROM user WHERE id = ?");
        $userCheck->execute([$userId]);
        $user = $userCheck->fetch();
        if (!$user) {
            echo json_encode([
                'success' => false,
                'message' => 'User not found',
                'user_id' => $userId
            ]);
            return;
        }
        $userEmail = $user['email'];

        // Get relationships where BOTH coach and staff have approved
        $relationshipSql = "
            SELECT DISTINCT
                CASE 
                    WHEN cml.coach_id = ? THEN cml.member_id 
                    ELSE cml.coach_id 
                END as other_user_id,
                COALESCE(u.fname, '') as fname,
                COALESCE(u.lname, '') as lname,
                COALESCE(u.email, '') as email,
                COALESCE(u.user_type_id, 0) as user_type_id,
                0 as is_online,
                COALESCE(cml.coach_approval, 'pending') as coach_approval,
                COALESCE(cml.staff_approval, 'pending') as staff_approval,
                COALESCE(cml.status, 'pending') as status
            FROM coach_member_list cml
            INNER JOIN user u ON u.id = CASE 
                WHEN cml.coach_id = ? THEN cml.member_id 
                ELSE cml.coach_id 
            END
            WHERE (cml.coach_id = ? OR cml.member_id = ?) 
            AND cml.coach_approval = 'approved' 
            AND cml.staff_approval = 'approved'
        ";
        
        $relationshipStmt = $pdo->prepare($relationshipSql);
        $relationshipStmt->execute([$userId, $userId, $userId, $userId]);
        $relationships = $relationshipStmt->fetchAll();
        
        $formattedConversations = [];
        $seenUserIds = []; // Track unique user IDs to prevent duplicates
        
        // Note: Admin conversations are NOT included in the list
        // Users access admin chat via the "Need Help? Chat with Admin" card only
        
        // Add regular conversations from coach_member_list
        foreach ($relationships as $relationship) {
            $otherUserId = $relationship['other_user_id'];
            
            // Skip if we've already seen this user
            if (isset($seenUserIds[$otherUserId])) {
                continue;
            }
            $seenUserIds[$otherUserId] = true;
            
            // Check if conversation exists
            $conversationSql = "
                SELECT id, participant1_id, participant2_id, created_at
                FROM conversations 
                WHERE (participant1_id = ? AND participant2_id = ?) 
                OR (participant1_id = ? AND participant2_id = ?)
            ";
            $conversationStmt = $pdo->prepare($conversationSql);
            $conversationStmt->execute([$userId, $otherUserId, $otherUserId, $userId]);
            $conversation = $conversationStmt->fetch();
            
            // If no conversation exists, create a virtual one
            if (!$conversation) {
                $conversationId = 0; // Virtual conversation ID
                $createdAt = formatDateTimeToISO(date('Y-m-d H:i:s')); // Current time
            } else {
                $conversationId = (int)$conversation['id'];
                $createdAt = formatDateTimeToISO($conversation['created_at']);
            }
            
            // Get last message (if any)
            $lastMessageSql = "
                SELECT message, timestamp 
                FROM messages 
                WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)
                ORDER BY timestamp DESC 
                LIMIT 1
            ";
            $lastMessageStmt = $pdo->prepare($lastMessageSql);
            $lastMessageStmt->execute([$userId, $otherUserId, $otherUserId, $userId]);
            $lastMessage = $lastMessageStmt->fetch();
            
            // Get unread count
            $unreadSql = "
                SELECT COUNT(*) as unread_count 
                FROM messages 
                WHERE sender_id = ? AND receiver_id = ? AND is_read = 0
            ";
            $unreadStmt = $pdo->prepare($unreadSql);
            $unreadStmt->execute([$otherUserId, $userId]);
            $unreadResult = $unreadStmt->fetch();
            
            // Handle last message time properly
            $lastMessageTime = null;
            if ($lastMessage && !empty($lastMessage['timestamp'])) {
                $lastMessageTime = formatDateTimeToISO($lastMessage['timestamp']);
            }
            
            $formattedConversations[] = [
                'id' => $conversationId,
                'participant1_id' => $userId,
                'participant2_id' => (int)$otherUserId,
                'created_at' => $createdAt, // ISO 8601 or null
                'last_message' => $lastMessage ? ($lastMessage['message'] ?? '') : '',
                'last_message_time' => $lastMessageTime, // ISO 8601 or null
                'unread_count' => (int)($unreadResult['unread_count'] ?? 0),
                'coach_approval' => $relationship['coach_approval'],
                'staff_approval' => $relationship['staff_approval'],
                'status' => $relationship['status'],
                'other_user' => [
                    'id' => (int)$relationship['other_user_id'],
                    'fname' => $relationship['fname'],
                    'lname' => $relationship['lname'],
                    'email' => $relationship['email'],
                    'user_type_id' => (int)$relationship['user_type_id'],
                    'is_online' => (int)$relationship['is_online']
                ],
                'is_support_request' => false
            ];
        }
        
        // Sort by last message time (most recent first), then by name
        usort($formattedConversations, function($a, $b) {
            if ($a['last_message_time'] && $b['last_message_time']) {
                return strtotime($b['last_message_time']) - strtotime($a['last_message_time']);
            } elseif ($a['last_message_time']) {
                return -1;
            } elseif ($b['last_message_time']) {
                return 1;
            } else {
                return strcmp($a['other_user']['fname'], $b['other_user']['fname']);
            }
        });
        
        echo json_encode([
            'success' => true,
            'conversations' => $formattedConversations
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false, 
            'message' => 'Error fetching conversations: ' . $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]);
    }
}

// Get messages for a specific conversation (FIXED DATE FORMAT)
function getMessages() {
    global $pdo;
    
    try {
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            exit();
        }

        if (!isset($_GET['conversation_id']) || !isset($_GET['user_id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Conversation ID and User ID are required']);
            exit();
        }

        $conversationId = (int)$_GET['conversation_id'];
        $userId = (int)$_GET['user_id'];

        // If conversation_id is 0, it's a virtual conversation - get other_user_id
        if ($conversationId === 0) {
            if (!isset($_GET['other_user_id'])) {
                // If other_user_id is not provided, return empty messages array
                // This allows the conversation to open even without messages
                echo json_encode([
                    'success' => true,
                    'messages' => [],
                    'debug' => [
                        'conversation_id' => $conversationId,
                        'user_id' => $userId,
                        'message' => 'Virtual conversation with no other_user_id - returning empty messages'
                    ]
                ]);
                return;
            }
            
            $otherUserId = (int)$_GET['other_user_id'];
            
            // Get messages between these users (even without conversation record) with sender info
            $sql = "
                SELECT 
                    m.id,
                    m.sender_id,
                    m.receiver_id,
                    COALESCE(m.message, '') as message,
                    m.timestamp,
                    COALESCE(m.is_read, 0) as is_read,
                    u.fname,
                    u.lname,
                    u.user_type_id
                FROM messages m
                INNER JOIN user u ON m.sender_id = u.id
                WHERE (m.sender_id = ? AND m.receiver_id = ?) 
                OR (m.sender_id = ? AND m.receiver_id = ?)
                ORDER BY m.timestamp ASC
            ";
            
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$userId, $otherUserId, $otherUserId, $userId]);
            
        } else {
            // Regular conversation - verify user is part of it and get other user info
            $verifyStmt = $pdo->prepare("
                SELECT participant1_id, participant2_id FROM conversations 
                WHERE id = ? AND (participant1_id = ? OR participant2_id = ?)
            ");
            $verifyStmt->execute([$conversationId, $userId, $userId]);
            $convData = $verifyStmt->fetch();
            
            if (!$convData) {
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => 'Unauthorized access to conversation']);
                exit();
            }
            
            // Determine the other user ID
            $otherUserId = ($convData['participant1_id'] == $userId) 
                ? (int)$convData['participant2_id'] 
                : (int)$convData['participant1_id'];
            
            // Check if current user is admin
            $currentUserStmt = $pdo->prepare("SELECT user_type_id FROM user WHERE id = ?");
            $currentUserStmt->execute([$userId]);
            $currentUser = $currentUserStmt->fetch();
            $isCurrentUserAdmin = $currentUser && (int)$currentUser['user_type_id'] === 1;
            
            // Get other user info (for admin conversations, ensure we get admin info)
            $otherUserStmt = $pdo->prepare("
                SELECT id, fname, lname, email, user_type_id 
                FROM user 
                WHERE id = ?
            ");
            $otherUserStmt->execute([$otherUserId]);
            $otherUserInfo = $otherUserStmt->fetch();
            
            // Get messages for this conversation with sender info
            // Include messages where receiver_id = 1 (user_type_id for admin) if current user is admin
            // OR if other participant is admin (for users sending to admin)
            $sql = "
                SELECT 
                    m.id,
                    m.sender_id,
                    m.receiver_id,
                    COALESCE(m.message, '') as message,
                    m.timestamp,
                    COALESCE(m.is_read, 0) as is_read,
                    u.fname,
                    u.lname,
                    u.user_type_id
                FROM messages m
                INNER JOIN user u ON m.sender_id = u.id
                WHERE (
                    -- Regular conversation messages
                    ((m.sender_id = ? AND m.receiver_id = ?) OR (m.sender_id = ? AND m.receiver_id = ?))
                    OR
                    -- Messages sent to admin (receiver_id = 1 = user_type_id for admin)
                    (m.receiver_id = 1 AND m.sender_id = ?)
                    OR
                    -- Messages from admin in this conversation
                    (m.sender_id = ? AND m.receiver_id = ?)
                )
                ORDER BY m.timestamp ASC
            ";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$userId, $otherUserId, $otherUserId, $userId, $userId, $otherUserId, $userId]);
        }
        
        $messages = $stmt->fetchAll();
        
        // Map user_type_id to user type name
        $userTypeMap = [
            1 => 'Admin',
            2 => 'Staff',
            3 => 'Coach',
            4 => 'User'
        ];
        
        // Format messages with proper date formatting and sender info
        $formattedMessages = [];
        foreach ($messages as $msg) {
            $timestamp = formatDateTimeToISO($msg['timestamp']);
            $userTypeName = $userTypeMap[$msg['user_type_id']] ?? 'User';
            
            $formattedMessages[] = [
                'id' => (int)($msg['id'] ?? 0),
                'sender_id' => (int)($msg['sender_id'] ?? 0),
                'receiver_id' => (int)($msg['receiver_id'] ?? 0),
                'message' => $msg['message'] ?? '',
                'timestamp' => $timestamp, // ISO 8601 format or null
                'is_read' => (int)($msg['is_read'] ?? 0),
                'sender_fname' => $msg['fname'] ?? '',
                'sender_lname' => $msg['lname'] ?? '',
                'sender_user_type' => $userTypeName,
                'sender_user_type_id' => (int)($msg['user_type_id'] ?? 4)
            ];
        }
        
        $response = [
            'success' => true,
            'messages' => $formattedMessages
        ];
        
        // Include other_user info if available (for fixing admin name display)
        if (isset($otherUserInfo) && $otherUserInfo) {
            $response['other_user'] = [
                'id' => (int)$otherUserInfo['id'],
                'fname' => $otherUserInfo['fname'] ?? '',
                'lname' => $otherUserInfo['lname'] ?? '',
                'email' => $otherUserInfo['email'] ?? '',
                'user_type_id' => (int)$otherUserInfo['user_type_id']
            ];
        }
        
        echo json_encode($response);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false, 
            'message' => 'Error fetching messages: ' . $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]);
    }
}

// Send a new message (FIXED DATE FORMAT)
function sendMessage() {
    global $pdo;
    
    try {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            exit();
        }

        $rawInput = file_get_contents('php://input');
        error_log('Send message raw input: ' . $rawInput);
        
        $input = json_decode($rawInput, true);
        
        if (json_last_error() !== JSON_ERROR_NONE) {
            http_response_code(400);
            echo json_encode([
                'success' => false, 
                'message' => 'Invalid JSON: ' . json_last_error_msg(),
                'raw_input' => substr($rawInput, 0, 200)
            ]);
            exit();
        }

        if (!isset($input['sender_id']) || !isset($input['message'])) {
            http_response_code(400);
            echo json_encode([
                'success' => false, 
                'message' => 'Sender ID and message are required',
                'received' => array_keys($input ?? [])
            ]);
            exit();
        }

        $senderId = (int)$input['sender_id'];
        $message = trim($input['message'] ?? '');
        
        if (empty($message)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Message cannot be empty']);
            exit();
        }
        
        // Validate that sender exists
        $checkSender = $pdo->prepare("SELECT id FROM user WHERE id = ?");
        $checkSender->execute([$senderId]);
        if (!$checkSender->fetch()) {
            throw new Exception("Sender user ID $senderId does not exist");
        }
        
        // Determine receiver ID - either from conversation_id or receiver_id
        $receiverId = null;
        $isAdminReceiver = false;
        $receiverTypeId = null;
        
        if (isset($input['conversation_id']) && $input['conversation_id'] > 0) {
            // Get receiver from conversation
            $convStmt = $pdo->prepare("
                SELECT participant1_id, participant2_id 
                FROM conversations 
                WHERE id = ? AND (participant1_id = ? OR participant2_id = ?)
            ");
            $convStmt->execute([(int)$input['conversation_id'], $senderId, $senderId]);
            $conv = $convStmt->fetch();
            
            if (!$conv) {
                throw new Exception("Conversation not found or user is not a participant");
            }
            
            // Determine the other participant
            $otherParticipantId = ($conv['participant1_id'] == $senderId) 
                ? (int)$conv['participant2_id'] 
                : (int)$conv['participant1_id'];
            
            // Check if the other participant is an admin
            $checkOtherParticipant = $pdo->prepare("SELECT user_type_id FROM user WHERE id = ?");
            $checkOtherParticipant->execute([$otherParticipantId]);
            $otherParticipant = $checkOtherParticipant->fetch();
            
            if ($otherParticipant && (int)$otherParticipant['user_type_id'] === 1) {
                // Receiving admin - use user_type_id (1) as receiver_id
                $receiverId = 1; // user_type_id for Admin
                $isAdminReceiver = true;
                $receiverTypeId = 1;
            } else {
                // Regular user - use user_id as receiver_id
                $receiverId = $otherParticipantId;
            }
        } elseif (isset($input['receiver_id'])) {
            $potentialReceiverId = (int)$input['receiver_id'];
            
            // Check if this is a user_type_id (admin = 1) or a specific user_id
            if ($potentialReceiverId === 1) {
                // Could be user_type_id = 1 (Admin) or user_id = 1
                // Check if user_id 1 exists and is admin
                $checkUser = $pdo->prepare("SELECT id, user_type_id FROM user WHERE id = ?");
                $checkUser->execute([$potentialReceiverId]);
                $user = $checkUser->fetch();
                
                if ($user && (int)$user['user_type_id'] === 1) {
                    // It's an admin user - use user_type_id (1) as receiver_id
                    $receiverId = 1; // user_type_id for Admin
                    $isAdminReceiver = true;
                    $receiverTypeId = 1;
                } else {
                    // Regular user with id = 1
                    $receiverId = $potentialReceiverId;
                }
            } else {
                // Validate that receiver exists
                $checkReceiver = $pdo->prepare("SELECT id, user_type_id FROM user WHERE id = ?");
                $checkReceiver->execute([$potentialReceiverId]);
                $receiver = $checkReceiver->fetch();
                
                if (!$receiver) {
                    throw new Exception("Receiver user ID $potentialReceiverId does not exist");
                }
                
                // Check if receiver is admin
                if ((int)$receiver['user_type_id'] === 1) {
                    // Receiving admin - use user_type_id (1) as receiver_id
                    $receiverId = 1; // user_type_id for Admin
                    $isAdminReceiver = true;
                    $receiverTypeId = 1;
                } else {
                    // Regular user
                    $receiverId = $potentialReceiverId;
                }
            }
        } else {
            http_response_code(400);
            echo json_encode([
                'success' => false, 
                'message' => 'Either conversation_id or receiver_id is required'
            ]);
            exit();
        }
        
        // For non-admin receivers, validate that receiver exists
        if (!$isAdminReceiver) {
            $checkReceiver = $pdo->prepare("SELECT id FROM user WHERE id = ?");
            $checkReceiver->execute([$receiverId]);
            if (!$checkReceiver->fetch()) {
                throw new Exception("Receiver user ID $receiverId does not exist");
            }
        }
        
        error_log("Send message - Sender: $senderId, Receiver: $receiverId" . ($isAdminReceiver ? " (user_type_id=1, all admins)" : ""). ", Message length: " . strlen($message));

        // Get or create conversation
        // For admin conversations, we still need a specific admin user_id for the conversation table
        // But the message receiver_id will be user_type_id (1)
        if ($isAdminReceiver) {
            // Get the first admin user_id for conversation purposes
            $adminForConvStmt = $pdo->prepare("SELECT id FROM user WHERE user_type_id = 1 ORDER BY id ASC LIMIT 1");
            $adminForConvStmt->execute();
            $adminForConv = $adminForConvStmt->fetch();
            $adminUserId = $adminForConv ? (int)$adminForConv['id'] : 1;
            
            // Use consistent ordering: always use smaller ID as participant1_id
            $participant1 = min($senderId, $adminUserId);
            $participant2 = max($senderId, $adminUserId);
        } else {
            // Use consistent ordering to avoid duplicate conversations
            $participant1 = min($senderId, $receiverId);
            $participant2 = max($senderId, $receiverId);
        }
        
        $conversationStmt = $pdo->prepare("
            SELECT id FROM conversations 
            WHERE (participant1_id = ? AND participant2_id = ?) OR (participant1_id = ? AND participant2_id = ?)
        ");
        $conversationStmt->execute([$participant1, $participant2, $participant2, $participant1]);
        
        $conversation = $conversationStmt->fetch();
        
        if (!$conversation) {
            // Create new conversation with consistent ordering
            try {
                $createConvStmt = $pdo->prepare("
                    INSERT INTO conversations (participant1_id, participant2_id, created_at) 
                    VALUES (?, ?, NOW())
                ");
                $convResult = $createConvStmt->execute([$participant1, $participant2]);
                
                if (!$convResult) {
                    $errorInfo = $createConvStmt->errorInfo();
                    error_log('Conversation creation failed: ' . print_r($errorInfo, true));
                    // Don't throw - continue with message insertion even if conversation creation fails
                    // The message will still work
                }
            } catch (PDOException $e) {
                error_log('Conversation creation PDO error: ' . $e->getMessage());
                // Continue - message can still be sent
            }
        }
        
        // Check if messages table exists
        $tableCheck = $pdo->query("SHOW TABLES LIKE 'messages'");
        if ($tableCheck->rowCount() == 0) {
            throw new Exception('Messages table does not exist in database');
        }
        
        // If sending to admin (receiver_id = 1 means user_type_id = 1), update/create support request
        if ($isAdminReceiver) {
            $tableCheck = $pdo->query("SHOW TABLES LIKE 'support_requests'");
            if ($tableCheck->rowCount() > 0) {
                // Get sender (user) email
                $senderInfoStmt = $pdo->prepare("SELECT email, fname, lname FROM user WHERE id = ?");
                $senderInfoStmt->execute([$senderId]);
                $senderInfo = $senderInfoStmt->fetch();
                
                if ($senderInfo && !empty($senderInfo['email'])) {
                    $userEmail = $senderInfo['email'];
                    $userName = trim(($senderInfo['fname'] ?? '') . ' ' . ($senderInfo['lname'] ?? ''));
                    if (empty($userName)) {
                        $userName = 'User';
                    }
                    
                    // Check if there's an existing support request (within last 30 days)
                    $existingSupportStmt = $pdo->prepare("
                        SELECT id FROM support_requests 
                        WHERE user_email = ? 
                        AND source = 'mobile_app_chat' 
                        AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                        ORDER BY created_at DESC 
                        LIMIT 1
                    ");
                    $existingSupportStmt->execute([$userEmail]);
                    $existingSupport = $existingSupportStmt->fetch();
                    
                    if ($existingSupport) {
                        // Update existing support request message with the new message
                        $updateSupportStmt = $pdo->prepare("
                            UPDATE support_requests 
                            SET message = CONCAT(message, '\n\n[New Message] ', ?)
                            WHERE id = ?
                        ");
                        $updateSupportStmt->execute([$message, (int)$existingSupport['id']]);
                    } else {
                        // Create new support request
                        try {
                            $supportStmt = $pdo->prepare("
                                INSERT INTO support_requests (user_email, subject, message, source, created_at) 
                                VALUES (?, ?, ?, 'mobile_app_chat', NOW())
                            ");
                            $supportStmt->execute([
                                $userEmail,
                                'Chat Support Request - ' . $userName,
                                'User message: ' . $message
                            ]);
                        } catch (Exception $e) {
                            error_log('Failed to create support request entry: ' . $e->getMessage());
                            // Continue - don't fail message sending if support request creation fails
                        }
                    }
                }
            }
        }
        
        // Insert message
        try {
            $insertStmt = $pdo->prepare("
                INSERT INTO messages (sender_id, receiver_id, message, timestamp, is_read) 
                VALUES (?, ?, ?, NOW(), 0)
            ");
            $result = $insertStmt->execute([$senderId, $receiverId, $message]);
            
            if (!$result) {
                $errorInfo = $insertStmt->errorInfo();
                throw new Exception('Failed to insert message: ' . ($errorInfo[2] ?? 'Unknown database error') . ' (Code: ' . ($errorInfo[0] ?? 'N/A') . ')');
            }
        } catch (PDOException $e) {
            error_log('Message insert PDO error: ' . $e->getMessage());
            error_log('PDO error info: ' . print_r($e->errorInfo, true));
            throw new Exception('Database error inserting message: ' . $e->getMessage() . ' (SQLSTATE: ' . $e->getCode() . ')');
        }
        
        $messageId = $pdo->lastInsertId();
        
        if ($messageId <= 0) {
            throw new Exception('Failed to create message - no message ID returned from database');
        }
        
        // Get the inserted message with sender information
        // Use LEFT JOIN in case user doesn't exist (shouldn't happen, but safer)
        $getMessageStmt = $pdo->prepare("
            SELECT 
                m.id, 
                m.sender_id, 
                m.receiver_id, 
                COALESCE(m.message, '') as message, 
                m.timestamp, 
                COALESCE(m.is_read, 0) as is_read,
                COALESCE(u.fname, '') as fname,
                COALESCE(u.lname, '') as lname,
                COALESCE(u.user_type_id, 4) as user_type_id
            FROM messages m
            LEFT JOIN user u ON m.sender_id = u.id
            WHERE m.id = ?
        ");
        $getMessageStmt->execute([$messageId]);
        $newMessage = $getMessageStmt->fetch();
        
        if (!$newMessage) {
            throw new Exception('Failed to retrieve created message from database. Message ID: ' . $messageId);
        }
        
        $timestamp = formatDateTimeToISO($newMessage['timestamp']);
        
        // Map user_type_id to user type name
        $userTypeMap = [
            1 => 'Admin',
            2 => 'Staff',
            3 => 'Coach',
            4 => 'User'
        ];
        $userTypeName = $userTypeMap[$newMessage['user_type_id']] ?? 'User';
        
        echo json_encode([
            'success' => true,
            'message' => [
                'id' => (int)($newMessage['id'] ?? 0),
                'sender_id' => (int)($newMessage['sender_id'] ?? 0),
                'receiver_id' => (int)($newMessage['receiver_id'] ?? 0),
                'message' => $newMessage['message'] ?? '',
                'timestamp' => $timestamp, // ISO 8601 format
                'is_read' => (int)($newMessage['is_read'] ?? 0),
                'sender_fname' => $newMessage['fname'] ?? '',
                'sender_lname' => $newMessage['lname'] ?? '',
                'sender_user_type' => $userTypeName,
                'sender_user_type_id' => (int)($newMessage['user_type_id'] ?? 4)
            ]
        ]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        error_log('Send message PDO error: ' . $e->getMessage());
        error_log('PDO error info: ' . print_r($e->errorInfo, true));
        $errorResponse = [
            'success' => false, 
            'message' => 'Database error: ' . $e->getMessage(),
            'error_code' => $e->getCode(),
            'sqlstate' => $e->errorInfo[0] ?? 'N/A',
            'driver_code' => $e->errorInfo[1] ?? 'N/A',
            'driver_message' => $e->errorInfo[2] ?? 'N/A'
        ];
        echo json_encode($errorResponse);
        exit();
    } catch (Throwable $e) {
        http_response_code(500);
        error_log('Send message error: ' . $e->getMessage());
        error_log('File: ' . $e->getFile() . ', Line: ' . $e->getLine());
        error_log('Stack trace: ' . $e->getTraceAsString());
        $errorResponse = [
            'success' => false, 
            'message' => 'Error sending message: ' . $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine(),
            'type' => get_class($e)
        ];
        echo json_encode($errorResponse);
        exit();
    }
}

// Placeholder functions for other endpoints
function markMessagesAsRead() {
    echo json_encode(['success' => true, 'message' => 'markMessagesAsRead function called']);
}

function getOrCreateConversation() {
    echo json_encode(['success' => true, 'message' => 'getOrCreateConversation function called']);
}

function getAvailableContacts() {
    echo json_encode(['success' => true, 'message' => 'getAvailableContacts function called']);
}

function searchMessages() {
    echo json_encode(['success' => true, 'message' => 'searchMessages function called']);
}

function deleteMessage() {
    echo json_encode(['success' => true, 'message' => 'deleteMessage function called']);
}

function getUnreadCount() {
    echo json_encode(['success' => true, 'message' => 'getUnreadCount function called']);
}

function updateOnlineStatus() {
    echo json_encode(['success' => true, 'message' => 'updateOnlineStatus function called']);
}

// Get or create conversation with admin
// Uses user_type_id = 1 to find admin, not specific user_id
// Links to support_requests table - creates support_request first, then conversation
function getOrCreateAdminConversation() {
    global $pdo;
    
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $userId = (int)($input['user_id'] ?? 0);
        
        if ($userId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid user_id']);
            exit();
        }
        
        // Get user email for support_requests table
        $userStmt = $pdo->prepare("SELECT email, fname, lname FROM user WHERE id = ?");
        $userStmt->execute([$userId]);
        $user = $userStmt->fetch();
        
        if (!$user) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found']);
            exit();
        }
        
        $userEmail = $user['email'];
        $userName = trim(($user['fname'] ?? '') . ' ' . ($user['lname'] ?? ''));
        if (empty($userName)) {
            $userName = 'User';
        }
        
        // Find admin user by user_type_id = 1 (not by specific user_id)
        $adminStmt = $pdo->prepare("
            SELECT id, fname, lname, email, user_type_id 
            FROM user 
            WHERE user_type_id = 1 
            ORDER BY id ASC 
            LIMIT 1
        ");
        $adminStmt->execute();
        $admin = $adminStmt->fetch();
        
        if (!$admin) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'No admin user found. Please contact support.']);
            exit();
        }
        
        $adminId = (int)$admin['id'];
        
        // Check if support_requests table exists
        $tableCheck = $pdo->query("SHOW TABLES LIKE 'support_requests'");
        $supportRequestsExists = $tableCheck->rowCount() > 0;
        
        $supportRequestId = null;
        
        if ($supportRequestsExists) {
            // Check if there's an existing support request for this user (recent one, within last 30 days)
            $existingSupportStmt = $pdo->prepare("
                SELECT id FROM support_requests 
                WHERE user_email = ? 
                AND source = 'mobile_app_chat' 
                AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                ORDER BY created_at DESC 
                LIMIT 1
            ");
            $existingSupportStmt->execute([$userEmail]);
            $existingSupport = $existingSupportStmt->fetch();
            
            if ($existingSupport) {
                $supportRequestId = (int)$existingSupport['id'];
            } else {
                // Create new support request entry
                try {
                    $supportStmt = $pdo->prepare("
                        INSERT INTO support_requests (user_email, subject, message, source, created_at) 
                        VALUES (?, ?, ?, 'mobile_app_chat', NOW())
                    ");
                    $supportStmt->execute([
                        $userEmail,
                        'Chat Support Request - ' . $userName,
                        'User initiated chat conversation with admin via mobile app'
                    ]);
                    $supportRequestId = (int)$pdo->lastInsertId();
                } catch (Exception $e) {
                    error_log('Failed to create support request entry: ' . $e->getMessage());
                    // Continue without support_request_id if creation fails
                }
            }
        }
        
        // Use consistent ordering: always use smaller ID as participant1_id
        $participant1 = min($userId, $adminId);
        $participant2 = max($userId, $adminId);
        
        // Check if conversation already exists
        $convStmt = $pdo->prepare("
            SELECT id FROM conversations 
            WHERE (participant1_id = ? AND participant2_id = ?) 
            OR (participant1_id = ? AND participant2_id = ?)
        ");
        $convStmt->execute([$participant1, $participant2, $participant2, $participant1]);
        $conversation = $convStmt->fetch();
        
        if ($conversation) {
            $conversationId = (int)$conversation['id'];
        } else {
            // Create new conversation with consistent ordering
            $createStmt = $pdo->prepare("
                INSERT INTO conversations (participant1_id, participant2_id, created_at) 
                VALUES (?, ?, NOW())
            ");
            $createStmt->execute([$participant1, $participant2]);
            $conversationId = (int)$pdo->lastInsertId();
        }
        
        // Always return admin user info (not the current user)
        $response = [
            'success' => true,
            'conversation_id' => $conversationId,
            'admin_user' => [
                'id' => $adminId,
                'fname' => $admin['fname'] ?? 'Admin',
                'lname' => $admin['lname'] ?? 'Support',
                'email' => $admin['email'] ?? 'admin@cnergy.site',
                'user_type_id' => (int)$admin['user_type_id']
            ]
        ];
        
        // Include support_request_id if available
        if ($supportRequestId !== null) {
            $response['support_request_id'] = $supportRequestId;
        }
        
        echo json_encode($response);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}

// Submit support request
function submitSupportRequest() {
    global $pdo;
    
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $userId = (int)($input['user_id'] ?? 0);
        $subject = trim($input['subject'] ?? '');
        $message = trim($input['message'] ?? '');
        
        if ($userId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid user_id']);
            exit();
        }
        
        if (empty($subject)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Subject is required']);
            exit();
        }
        
        if (empty($message)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Message is required']);
            exit();
        }
        
        // Get user email
        $userStmt = $pdo->prepare("SELECT email, fname, lname FROM user WHERE id = ?");
        $userStmt->execute([$userId]);
        $user = $userStmt->fetch();
        
        if (!$user) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found']);
            exit();
        }
        
        $userEmail = $user['email'];
        
        // Check if support_requests table exists
        $tableCheck = $pdo->query("SHOW TABLES LIKE 'support_requests'");
        if ($tableCheck->rowCount() == 0) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Support requests table does not exist']);
            exit();
        }
        
        // Insert support request
        $supportStmt = $pdo->prepare("
            INSERT INTO support_requests (user_email, subject, message, source, created_at) 
            VALUES (?, ?, ?, 'mobile_app_form', NOW())
        ");
        $supportStmt->execute([$userEmail, $subject, $message]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Support request submitted successfully'
        ]);
        
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}
?>
