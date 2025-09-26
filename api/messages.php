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
            sendMessage();
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
        case 'debug_relationships':
            debugRelationships();
            break;
        case 'test_connection':
            testConnection();
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

        // First check if user exists
        $userCheck = $pdo->prepare("SELECT id FROM user WHERE id = ?");
        $userCheck->execute([$userId]);
        if (!$userCheck->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'User not found',
                'user_id' => $userId
            ]);
            return;
        }

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
        
        if (empty($relationships)) {
            echo json_encode([
                'success' => true,
                'conversations' => [],
                'debug' => [
                    'user_id' => $userId,
                    'message' => 'No approved relationships found'
                ]
            ]);
            return;
        }
        
        $formattedConversations = [];
        
        foreach ($relationships as $relationship) {
            $otherUserId = $relationship['other_user_id'];
            
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
                ]
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
            
            // Get messages between these users (even without conversation record)
            $sql = "
                SELECT 
                    m.id,
                    m.sender_id,
                    m.receiver_id,
                    COALESCE(m.message, '') as message,
                    m.timestamp,
                    COALESCE(m.is_read, 0) as is_read
                FROM messages m
                WHERE (m.sender_id = ? AND m.receiver_id = ?) 
                OR (m.sender_id = ? AND m.receiver_id = ?)
                ORDER BY m.timestamp ASC
            ";
            
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$userId, $otherUserId, $otherUserId, $userId]);
            
        } else {
            // Regular conversation - verify user is part of it
            $verifyStmt = $pdo->prepare("
                SELECT participant1_id, participant2_id FROM conversations 
                WHERE id = ? AND (participant1_id = ? OR participant2_id = ?)
            ");
            $verifyStmt->execute([$conversationId, $userId, $userId]);
            
            if (!$verifyStmt->fetch()) {
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => 'Unauthorized access to conversation']);
                exit();
            }
            
            // Get messages for this conversation
            $sql = "
                SELECT 
                    m.id,
                    m.sender_id,
                    m.receiver_id,
                    COALESCE(m.message, '') as message,
                    m.timestamp,
                    COALESCE(m.is_read, 0) as is_read
                FROM messages m
                INNER JOIN conversations c ON (
                    (m.sender_id = c.participant1_id AND m.receiver_id = c.participant2_id) OR
                    (m.sender_id = c.participant2_id AND m.receiver_id = c.participant1_id)
                )
                WHERE c.id = ?
                ORDER BY m.timestamp ASC
            ";
            
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$conversationId]);
        }
        
        $messages = $stmt->fetchAll();
        
        // Format messages with proper date formatting
        $formattedMessages = [];
        foreach ($messages as $msg) {
            $timestamp = formatDateTimeToISO($msg['timestamp']);
            
            $formattedMessages[] = [
                'id' => (int)($msg['id'] ?? 0),
                'sender_id' => (int)($msg['sender_id'] ?? 0),
                'receiver_id' => (int)($msg['receiver_id'] ?? 0),
                'message' => $msg['message'] ?? '',
                'timestamp' => $timestamp, // ISO 8601 format or null
                'is_read' => (int)($msg['is_read'] ?? 0)
            ];
        }
        
        echo json_encode([
            'success' => true,
            'messages' => $formattedMessages
        ]);
        
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

        $input = json_decode(file_get_contents('php://input'), true);

        if (!isset($input['sender_id']) || !isset($input['receiver_id']) || !isset($input['message'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Sender ID, Receiver ID, and message are required']);
            exit();
        }

        $senderId = (int)$input['sender_id'];
        $receiverId = (int)$input['receiver_id'];
        $message = trim($input['message'] ?? '');

        if (empty($message)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Message cannot be empty']);
            exit();
        }

        // Get or create conversation
        $conversationStmt = $pdo->prepare("
            SELECT id FROM conversations 
            WHERE (participant1_id = ? AND participant2_id = ?) OR (participant1_id = ? AND participant2_id = ?)
        ");
        $conversationStmt->execute([$senderId, $receiverId, $receiverId, $senderId]);
        
        $conversation = $conversationStmt->fetch();
        
        if (!$conversation) {
            // Create new conversation
            $createConvStmt = $pdo->prepare("
                INSERT INTO conversations (participant1_id, participant2_id, created_at) 
                VALUES (?, ?, NOW())
            ");
            $createConvStmt->execute([$senderId, $receiverId]);
        }
        
        // Insert message
        $insertStmt = $pdo->prepare("
            INSERT INTO messages (sender_id, receiver_id, message, timestamp, is_read) 
            VALUES (?, ?, ?, NOW(), 0)
        ");
        $insertStmt->execute([$senderId, $receiverId, $message]);
        
        $messageId = $pdo->lastInsertId();
        
        // Get the inserted message with proper date formatting
        $getMessageStmt = $pdo->prepare("
            SELECT 
                id, 
                sender_id, 
                receiver_id, 
                COALESCE(message, '') as message, 
                timestamp, 
                COALESCE(is_read, 0) as is_read 
            FROM messages WHERE id = ?
        ");
        $getMessageStmt->execute([$messageId]);
        $newMessage = $getMessageStmt->fetch();
        
        $timestamp = formatDateTimeToISO($newMessage['timestamp']);
        
        echo json_encode([
            'success' => true,
            'message' => [
                'id' => (int)($newMessage['id'] ?? 0),
                'sender_id' => (int)($newMessage['sender_id'] ?? 0),
                'receiver_id' => (int)($newMessage['receiver_id'] ?? 0),
                'message' => $newMessage['message'] ?? '',
                'timestamp' => $timestamp, // ISO 8601 format
                'is_read' => (int)($newMessage['is_read'] ?? 0)
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false, 
            'message' => 'Error sending message: ' . $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]);
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
?>

















