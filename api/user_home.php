<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'db.php';

try {
    // Fetch all data in parallel using prepared statements
    $announcementsStmt = $pdo->prepare("
        SELECT 
            id,
            title,
            content as description,
            priority,
            date_posted,
            CASE 
                WHEN priority = 'high' THEN 1
                WHEN priority = 'medium' THEN 2
                WHEN priority = 'low' THEN 3
            END as priority_order
        FROM announcement 
        WHERE status = 'active' 
        ORDER BY priority_order ASC, date_posted DESC
    ");
    
    $merchandiseStmt = $pdo->prepare("
        SELECT 
            id,
            name,
            price,
            image_url,
            created_at
        FROM merchandise 
        WHERE status = 'active' 
        ORDER BY created_at DESC
    ");
    
    $promotionsStmt = $pdo->prepare("
        SELECT 
            id,
            title,
            description,
            icon,
            start_date,
            end_date,
            created_at
        FROM promotions 
        WHERE is_active = 1 
        AND CURDATE() BETWEEN start_date AND end_date
        ORDER BY created_at DESC
    ");
    
    // Execute all queries
    $announcementsStmt->execute();
    $merchandiseStmt->execute();
    $promotionsStmt->execute();
    
    $announcements = $announcementsStmt->fetchAll();
    $merchandise = $merchandiseStmt->fetchAll();
    $promotions = $promotionsStmt->fetchAll();
    
    // Transform announcements data
    $formattedAnnouncements = array_map(function($announcement) {
        $isImportant = $announcement['priority'] === 'high';
        
        $color = match($announcement['priority']) {
            'high' => '#FF6B35',
            'medium' => '#4ECDC4', 
            'low' => '#96CEB4',
            default => '#96CEB4'
        };
        
        $icon = match($announcement['priority']) {
            'high' => 'fitness_center',
            'medium' => 'schedule',
            'low' => 'group',
            default => 'info'
        };
        
        return [
            'id' => (int)$announcement['id'],
            'title' => $announcement['title'],
            'description' => $announcement['description'],
            'icon' => $icon,
            'color' => $color,
            'isImportant' => $isImportant,
            'datePosted' => $announcement['date_posted']
        ];
    }, $announcements);
    
    // Transform merchandise data
    $colors = ['#FF6B35', '#4ECDC4', '#96CEB4', '#45B7D1', '#F7DC6F', '#BB8FCE'];
    $icons = ['local_drink', 'water_drop', 'checkroom', 'fitness_center', 'sports_handball', 'sports_basketball'];
    
    $formattedMerchandise = array_map(function($item, $index) use ($colors, $icons) {
        $colorIndex = $index % count($colors);
        $iconIndex = $index % count($icons);
        
        return [
            'id' => (int)$item['id'],
            'name' => $item['name'],
            'price' => '₱' . number_format($item['price'], 2),
            'description' => 'Premium quality merchandise',
            'color' => $colors[$colorIndex],
            'icon' => $icons[$iconIndex],
            'imageUrl' => $item['image_url'],
            'createdAt' => $item['created_at']
        ];
    }, $merchandise, array_keys($merchandise));
    
    // Transform promotions data
    $promoColors = ['#FF6B35', '#4ECDC4', '#96CEB4', '#45B7D1', '#F7DC6F', '#BB8FCE'];
    $promoIcons = ['local_fire_department', 'school', 'people', 'star', 'gift', 'celebration'];
    
    $formattedPromotions = array_map(function($promotion, $index) use ($promoColors, $promoIcons) {
        $colorIndex = $index % count($promoColors);
        $iconIndex = $index % count($promoIcons);
        
        // Calculate days remaining
        $endDate = new DateTime($promotion['end_date']);
        $today = new DateTime();
        $daysRemaining = $today->diff($endDate)->days;
        
        // Generate discount text based on title
        $discount = 'SPECIAL';
        if (stripos($promotion['title'], 'discount') !== false) {
            $discount = 'DISCOUNT';
        } elseif (stripos($promotion['title'], 'free') !== false) {
            $discount = 'FREE';
        } elseif (stripos($promotion['title'], 'off') !== false) {
            $discount = 'SAVE';
        }
        
        $validUntil = $daysRemaining > 0 
            ? "Valid for {$daysRemaining} more days"
            : "Ends today";
            
        return [
            'id' => (int)$promotion['id'],
            'title' => $promotion['title'],
            'description' => $promotion['description'],
            'discount' => $discount,
            'validUntil' => $validUntil,
            'color' => $promoColors[$colorIndex],
            'icon' => $promoIcons[$iconIndex],
            'startDate' => $promotion['start_date'],
            'endDate' => $promotion['end_date'],
            'createdAt' => $promotion['created_at']
        ];
    }, $promotions, array_keys($promotions));
    
    // Return all data in one response
    sendResponse([
        'success' => true,
        'data' => [
            'announcements' => $formattedAnnouncements,
            'merchandise' => $formattedMerchandise,
            'promotions' => $formattedPromotions
        ]
    ]);
    
} catch(PDOException $e) {
    error_log('Database error in user_home.php: ' . $e->getMessage());
    sendError('Database error: ' . $e->getMessage(), 500);
} catch(Exception $e) {
    error_log('Server error in user_home.php: ' . $e->getMessage());
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>
