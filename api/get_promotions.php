<?php
require_once 'db.php';

try {
    // Fetch active promotions that are currently valid
    $stmt = $pdo->prepare("
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
    
    $stmt->execute();
    $promotions = $stmt->fetchAll();
    
    // Transform data to match Flutter app structure
    $formattedPromotions = array_map(function($promotion, $index) {
        // Define colors and icons for variety
        $colors = ['#FF6B35', '#4ECDC4', '#96CEB4', '#45B7D1', '#F7DC6F', '#BB8FCE'];
        $icons = ['local_fire_department', 'school', 'people', 'star', 'gift', 'celebration'];
        
        $colorIndex = $index % count($colors);
        $iconIndex = $index % count($icons);
        
        // Calculate days remaining
        $endDate = new DateTime($promotion['end_date']);
        $today = new DateTime();
        $daysRemaining = $today->diff($endDate)->days;
        
        // Generate discount text based on title or use default
        $discount = 'SPECIAL';
        if (stripos($promotion['title'], 'discount') !== false) {
            $discount = 'DISCOUNT';
        } elseif (stripos($promotion['title'], 'free') !== false) {
            $discount = 'FREE';
        } elseif (stripos($promotion['title'], 'off') !== false) {
            $discount = 'SAVE';
        }
        
        // Format valid until text
        $validUntil = $daysRemaining > 0 
            ? "Valid for {$daysRemaining} more days"
            : "Ends today";
            
        return [
            'id' => (int)$promotion['id'],
            'title' => $promotion['title'],
            'description' => $promotion['description'],
            'discount' => $discount,
            'validUntil' => $validUntil,
            'color' => $colors[$colorIndex],
            'icon' => $icons[$iconIndex],
            'startDate' => $promotion['start_date'],
            'endDate' => $promotion['end_date'],
            'createdAt' => $promotion['created_at']
        ];
    }, $promotions, array_keys($promotions));
    
    sendResponse([
        'success' => true,
        'data' => $formattedPromotions
    ]);
    
} catch(PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
} catch(Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>

