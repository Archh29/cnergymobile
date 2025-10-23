-- Training Focus Preferences and Smart Silence System
-- Copy and paste this entire file into your MySQL database

-- Table for user training focus preferences
CREATE TABLE IF NOT EXISTS user_training_preferences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    training_focus VARCHAR(50) NOT NULL DEFAULT 'full_body',
    -- Options: 'full_body', 'upper_body', 'lower_body', 'custom'
    custom_muscle_groups JSON NULL,
    -- Array of muscle group IDs user wants to track (only used when training_focus = 'custom')
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_user (user_id),
    INDEX idx_user_focus (user_id, training_focus)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note: Add foreign key manually if user table exists:
-- ALTER TABLE user_training_preferences ADD CONSTRAINT fk_user_preferences FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE;

-- Table for tracking dismissed/silenced warnings (Smart Silence)
CREATE TABLE IF NOT EXISTS user_warning_dismissals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    muscle_group_id INT NOT NULL,
    warning_type VARCHAR(50) NOT NULL DEFAULT 'neglected',
    -- Options: 'neglected', 'undertrained', 'imbalanced'
    first_dismissed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    dismiss_count INT DEFAULT 1,
    -- How many consecutive weeks this has been dismissed
    is_permanent BOOLEAN DEFAULT FALSE,
    -- If true, never show this warning again until user resets
    notes TEXT NULL,
    -- Optional: user can add notes like "knee injury" or "intentionally skipping"
    UNIQUE KEY unique_user_muscle_warning (user_id, muscle_group_id, warning_type),
    INDEX idx_user_dismissals (user_id),
    INDEX idx_active_dismissals (user_id, is_permanent)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note: Add foreign keys manually after verifying table names:
-- ALTER TABLE user_warning_dismissals ADD CONSTRAINT fk_warning_user FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE;
-- ALTER TABLE user_warning_dismissals ADD CONSTRAINT fk_warning_muscle FOREIGN KEY (muscle_group_id) REFERENCES target_muscle(id) ON DELETE CASCADE;

-- Insert default preferences for existing users (optional - run this if you want all existing users to have default settings)
INSERT INTO user_training_preferences (user_id, training_focus)
SELECT id, 'full_body'
FROM user
WHERE NOT EXISTS (
    SELECT 1 FROM user_training_preferences WHERE user_training_preferences.user_id = user.id
)
ON DUPLICATE KEY UPDATE training_focus = training_focus;

-- Example queries for testing:

-- View all user preferences
-- SELECT * FROM user_training_preferences;

-- View all dismissed warnings
-- SELECT * FROM user_warning_dismissals;

-- Get a specific user's training focus
-- SELECT * FROM user_training_preferences WHERE user_id = 1;

-- Get a user's dismissed warnings with muscle group names
-- SELECT 
--     uwd.*,
--     tm.name as muscle_group_name
-- FROM user_warning_dismissals uwd
-- JOIN target_muscle tm ON tm.id = uwd.muscle_group_id
-- WHERE uwd.user_id = 1;

