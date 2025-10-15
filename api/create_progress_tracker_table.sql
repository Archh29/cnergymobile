-- Create progress_tracker table to match API expectations
CREATE TABLE `progress_tracker` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `exercise_name` varchar(255) NOT NULL,
  `muscle_group` varchar(100) DEFAULT NULL,
  `weight` decimal(5,2) NOT NULL,
  `reps` int(11) NOT NULL,
  `sets` int(11) NOT NULL,
  `volume` decimal(10,2) DEFAULT NULL,
  `one_rep_max` decimal(5,2) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `program_name` varchar(255) DEFAULT NULL,
  `program_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_exercise_name` (`exercise_name`),
  KEY `idx_program_id` (`program_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `progress_tracker_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;