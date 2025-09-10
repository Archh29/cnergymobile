<?php
require_once 'db.php';

try {
    // Fetch active merchandise ordered by creation date
    $stmt = $pdo->prepare("
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
    
    $stmt->execute();
    $merchandise = $stmt->fetchAll();
    
    // Transform data to match Flutter app structure
    $formattedMerchandise = array_map(function($item, $index) {
        // Define colors and icons for variety
        $colors = ['#FF6B35', '#4ECDC4', '#96CEB4', '#45B7D1', '#F7DC6F', '#BB8FCE'];
        $icons = ['local_drink', 'water_drop', 'checkroom', 'fitness_center', 'sports_handball', 'sports_basketball'];
        
        $colorIndex = $index % count($colors);
        $iconIndex = $index % count($icons);
        
        return [
            'id' => (int)$item['id'],
            'name' => $item['name'],
            'price' => '₱' . number_format($item['price'], 2),
            'description' => 'Premium quality merchandise', // Default description
            'color' => $colors[$colorIndex],
            'icon' => $icons[$iconIndex],
            'imageUrl' => $item['image_url'],
            'createdAt' => $item['created_at']
        ];
    }, $merchandise, array_keys($merchandise));
    
    sendResponse([
        'success' => true,
        'data' => $formattedMerchandise
    ]);
    
} catch(PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
} catch(Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>

