<?php
require_once 'db.php';

try {
    // Fetch active announcements ordered by priority and date
    $stmt = $pdo->prepare("
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
    
    $stmt->execute();
    $announcements = $stmt->fetchAll();
    
    // Transform data to match Flutter app structure
    $formattedAnnouncements = array_map(function($announcement) {
        // Map priority to isImportant
        $isImportant = $announcement['priority'] === 'high';
        
        // Map priority to color
        $color = match($announcement['priority']) {
            'high' => '#FF6B35',
            'medium' => '#4ECDC4', 
            'low' => '#96CEB4',
            default => '#96CEB4'
        };
        
        // Map priority to icon
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
    
    sendResponse([
        'success' => true,
        'data' => $formattedAnnouncements
    ]);
    
} catch(PDOException $e) {
    sendError('Database error: ' . $e->getMessage(), 500);
} catch(Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>

