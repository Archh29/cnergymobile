-- Create guest_session table
CREATE TABLE IF NOT EXISTS `guest_session` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guest_name` varchar(100) NOT NULL,
  `guest_type` enum('walkin','trial','guest') DEFAULT 'walkin',
  `amount_paid` decimal(10,2) NOT NULL,
  `qr_token` varchar(255) NOT NULL,
  `valid_until` datetime NOT NULL,
  `paid` tinyint(1) DEFAULT 0,
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `qr_token` (`qr_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

