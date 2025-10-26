<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database connection
$host = "localhost";
$dbname = "u773938685_cnergydb";      
$username = "u773938685_archh29";  
$password = "Gwapoko385@";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    error_log('Database Connection Error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    $action = $_GET['action'] ?? $_POST['action'] ?? json_decode(file_get_contents('php://input'), true)['action'] ?? '';

    switch ($action) {
        case 'submit_review':
            submitReview($pdo);
            break;
        
        case 'update_review':
            updateReview($pdo);
            break;
        
        case 'check_review':
            checkExistingReview($pdo);
            break;
        
        case 'get_coach_ratings':
            getCoachRatings($pdo);
            break;
        
        default:
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
    }
} catch (Exception $e) {
    error_log('Coach Rating API Error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

function submitReview($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $userId = $input['user_id'] ?? null;
    $coachId = $input['coach_id'] ?? null;
    $rating = $input['rating'] ?? null;
    $feedback = $input['feedback'] ?? '';

    if (!$userId || !$coachId || !$rating) {
        echo json_encode(['success' => false, 'message' => 'Missing required fields']);
        return;
    }

    if ($rating < 1 || $rating > 5) {
        echo json_encode(['success' => false, 'message' => 'Rating must be between 1 and 5']);
        return;
    }

    // Check if review already exists
    $checkStmt = $pdo->prepare("
        SELECT id FROM coach_review 
        WHERE member_id = ? AND coach_id = ?
    ");
    $checkStmt->execute([$userId, $coachId]);
    
    if ($checkStmt->fetch()) {
        echo json_encode(['success' => false, 'message' => 'You have already reviewed this coach. Use update instead.']);
        return;
    }

    $stmt = $pdo->prepare("
        INSERT INTO coach_review (coach_id, member_id, rating, feedback, created_at)
        VALUES (?, ?, ?, ?, NOW())
    ");
    
    $stmt->execute([$coachId, $userId, $rating, $feedback]);
    
    echo json_encode(['success' => true, 'message' => 'Review submitted successfully']);
}

function updateReview($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $userId = $input['user_id'] ?? null;
    $coachId = $input['coach_id'] ?? null;
    $rating = $input['rating'] ?? null;
    $feedback = $input['feedback'] ?? '';

    if (!$userId || !$coachId || !$rating) {
        echo json_encode(['success' => false, 'message' => 'Missing required fields']);
        return;
    }

    if ($rating < 1 || $rating > 5) {
        echo json_encode(['success' => false, 'message' => 'Rating must be between 1 and 5']);
        return;
    }

    $stmt = $pdo->prepare("
        UPDATE coach_review 
        SET rating = ?, feedback = ?, updated_at = CONVERT_TZ(NOW(), '+00:00', '+08:00')
        WHERE member_id = ? AND coach_id = ?
    ");
    
    $result = $stmt->execute([$rating, $feedback, $userId, $coachId]);
    
    if ($result && $stmt->rowCount() > 0) {
        echo json_encode(['success' => true, 'message' => 'Review updated successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Review not found or no changes made']);
    }
}

function checkExistingReview($pdo) {
    $userId = $_GET['user_id'] ?? null;
    $coachId = $_GET['coach_id'] ?? null;

    if (!$userId || !$coachId) {
        echo json_encode(['success' => false, 'message' => 'Missing required parameters']);
        return;
    }

    $stmt = $pdo->prepare("
        SELECT rating, feedback, CONVERT_TZ(COALESCE(updated_at, created_at), '+00:00', '+08:00') as last_modified
        FROM coach_review
        WHERE member_id = ? AND coach_id = ?
    ");
    $stmt->execute([$userId, $coachId]);
    $review = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($review) {
        echo json_encode([
            'success' => true,
            'has_review' => true,
            'review' => $review
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'has_review' => false
        ]);
    }
}

function getCoachRatings($pdo) {
    $coachId = $_GET['coach_id'] ?? null;

    if (!$coachId) {
        echo json_encode(['success' => false, 'message' => 'Missing coach_id']);
        return;
    }

    // Get average rating and total reviews
    $statsStmt = $pdo->prepare("
        SELECT 
            AVG(rating) as average_rating,
            COUNT(*) as total_reviews
        FROM coach_review
        WHERE coach_id = ?
    ");
    $statsStmt->execute([$coachId]);
    $stats = $statsStmt->fetch(PDO::FETCH_ASSOC);

    // Get rating distribution
    $distributionStmt = $pdo->prepare("
        SELECT rating, COUNT(*) as count
        FROM coach_review
        WHERE coach_id = ?
        GROUP BY rating
    ");
    $distributionStmt->execute([$coachId]);
    $distribution = [5 => 0, 4 => 0, 3 => 0, 2 => 0, 1 => 0];
    
    while ($row = $distributionStmt->fetch(PDO::FETCH_ASSOC)) {
        $distribution[(int)$row['rating']] = (int)$row['count'];
    }

    // Get all reviews with member names
    $reviewsStmt = $pdo->prepare("
        SELECT 
            cr.rating,
            cr.feedback,
            CONVERT_TZ(COALESCE(cr.updated_at, cr.created_at), '+00:00', '+08:00') as last_modified,
            CONCAT(u.fname, ' ', u.lname) as member_name
        FROM coach_review cr
        JOIN user u ON cr.member_id = u.id
        WHERE cr.coach_id = ?
        ORDER BY COALESCE(cr.updated_at, cr.created_at) DESC
    ");
    $reviewsStmt->execute([$coachId]);
    $reviews = $reviewsStmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'average_rating' => $stats['average_rating'] ? round((float)$stats['average_rating'], 1) : 0.0,
        'total_reviews' => (int)$stats['total_reviews'],
        'rating_distribution' => $distribution,
        'reviews' => $reviews
    ]);
}
?>

