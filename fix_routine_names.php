<?php
// Script to fix routine names in the database
// This will replace placeholder names like "Rj Louise's Routine" with proper names

try {
    $pdo = new PDO('mysql:host=localhost;dbname=cnergydb', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Starting routine name fix...\n\n";
    
    // Get all routines with their workout details and goals
    $stmt = $pdo->prepare('
        SELECT 
            mp.id as routine_id,
            mp.goal,
            mp.difficulty,
            mp.created_by,
            mp.user_id,
            u.fname,
            u.lname,
            mpw.workout_details
        FROM member_programhdr mp
        LEFT JOIN member_program_workout mpw ON mp.id = mpw.member_program_hdr_id
        LEFT JOIN user u ON mp.user_id = u.id
        ORDER BY mp.id
    ');
    $stmt->execute();
    $routines = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $updatedCount = 0;
    
    foreach ($routines as $routine) {
        $routineId = $routine['routine_id'];
        $goal = $routine['goal'];
        $difficulty = $routine['difficulty'];
        $createdBy = $routine['created_by'];
        $userName = $routine['fname'] . ' ' . $routine['lname'];
        $workoutDetails = $routine['workout_details'];
        
        // Parse the workout_details JSON
        $workoutData = json_decode($workoutDetails, true);
        
        if ($workoutData && isset($workoutData['name'])) {
            $currentName = $workoutData['name'];
            
            // Check if it's a placeholder name
            if (strpos($currentName, "Rj Louise's Routine") !== false || 
                strpos($currentName, "asd") !== false ||
                strpos($currentName, "sss") !== false ||
                strpos($currentName, "ss") !== false ||
                strpos($currentName, "zXa") !== false ||
                strpos($currentName, "sdf") !== false ||
                strpos($currentName, "sadas") !== false ||
                strpos($currentName, "asda") !== false ||
                empty(trim($currentName))) {
                
                // Generate a proper name based on goal, difficulty, and user
                $newName = generateRoutineName($goal, $difficulty, $userName, $createdBy);
                
                // Update the workout_details JSON
                $workoutData['name'] = $newName;
                $newWorkoutDetails = json_encode($workoutData);
                
                // Update the database
                $updateStmt = $pdo->prepare('UPDATE member_program_workout SET workout_details = ? WHERE member_program_hdr_id = ?');
                $updateStmt->execute([$newWorkoutDetails, $routineId]);
                
                echo "Updated Routine ID {$routineId}: '{$currentName}' -> '{$newName}'\n";
                $updatedCount++;
            }
        }
    }
    
    echo "\nRoutine name fix completed!\n";
    echo "Total routines updated: {$updatedCount}\n";
    
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

function generateRoutineName($goal, $difficulty, $userName, $createdBy) {
    // If created by a coach/admin, use a professional name
    if ($createdBy && $createdBy != $userName) {
        $goalFormatted = ucwords(strtolower($goal));
        $difficultyFormatted = ucwords(strtolower($difficulty));
        return "{$goalFormatted} Program ({$difficultyFormatted})";
    }
    
    // For user-created routines, use goal-based names
    $goalFormatted = ucwords(strtolower($goal));
    $difficultyFormatted = ucwords(strtolower($difficulty));
    
    // Create more specific names based on goal
    switch (strtolower($goal)) {
        case 'muscle building':
            return "Muscle Building Routine ({$difficultyFormatted})";
        case 'general fitness':
            return "Fitness Routine ({$difficultyFormatted})";
        case 'fat loss':
            return "Fat Loss Program ({$difficultyFormatted})";
        case 'endurance':
            return "Endurance Training ({$difficultyFormatted})";
        case 'strength':
            return "Strength Building ({$difficultyFormatted})";
        default:
            return "{$goalFormatted} Workout ({$difficultyFormatted})";
    }
}
?>