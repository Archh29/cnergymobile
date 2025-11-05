<?php
// membership_plans_api.php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// CORS and JSON
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
	http_response_code(204);
	exit;
}

// DB config
$host = "localhost";
$dbname = "u773938685_cnergydb";
$username = "u773938685_archh29";
$password = "Gwapoko385@";

try {
	$pdo = new PDO(
		"mysql:host=$host;dbname=$dbname;charset=utf8mb4",
		$username,
		$password,
		[
			PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
			PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
		]
	);
} catch (PDOException $e) {
	http_response_code(500);
	echo json_encode([
		"error" => "Database connection failed",
		"debug" => $e->getMessage()
	]);
	exit;
}

$method = $_SERVER['REQUEST_METHOD'];
$input = file_get_contents("php://input");
$data = json_decode($input, true);

try {
	switch ($method) {
		case 'GET':
			// Check if requesting subscriptions
			if (isset($_GET['action']) && $_GET['action'] === 'subscriptions') {
				getActiveSubscriptions($pdo);
			} else {
				getMembershipPlans($pdo);
			}
			break;
		case 'POST':
			createMembershipPlan($pdo, $data);
			break;
		case 'PUT':
			updateMembershipPlan($pdo, $data);
			break;
		case 'DELETE':
			deleteMembershipPlan($pdo, $data);
			break;
		default:
			http_response_code(405);
			echo json_encode(["error" => "Method not allowed"]);
			break;
	}
} catch (PDOException $e) {
	http_response_code(500);
	echo json_encode([
		"error" => "Database error: " . $e->getMessage()
	]);
} catch (Exception $e) {
	http_response_code(500);
	echo json_encode([
		"error" => "General error: " . $e->getMessage()
	]);
}

/**
 * GET: List all membership plans with features
 * Fields returned: id, plan_name, price, is_member_only, discounted_price, duration_months, duration_days
 */
function getMembershipPlans(PDO $pdo): void {
	try {
		// Get membership plans
		$stmt = $pdo->query("
			SELECT
				id,
				plan_name,
				price,
				IFNULL(is_member_only, 0) AS is_member_only,
				discounted_price,
				IFNULL(duration_months, 1) AS duration_months,
				IFNULL(duration_days, 0) AS duration_days
			FROM `member_subscription_plan`
			ORDER BY price ASC, id ASC
		");
		$plans = $stmt->fetchAll();

		// Attach features for each plan
		$featureStmt = $pdo->prepare("
			SELECT id, feature_name, description
			FROM `subscription_feature`
			WHERE plan_id = ?
			ORDER BY id
		");
		
		foreach ($plans as &$plan) {
			$featureStmt->execute([$plan['id']]);
			$plan['features'] = $featureStmt->fetchAll();
			$plan['is_member_only'] = (bool)$plan['is_member_only'];
			// Fix the name field to match frontend expectations
			$plan['name'] = $plan['plan_name'];
		}
		unset($plan);

		// Get analytics data
		$analytics = getAnalyticsData($pdo);

		echo json_encode([
			"plans" => $plans,
			"analytics" => $analytics
		]);
	} catch (Throwable $e) {
		throw new Exception("Error fetching plans: " . $e->getMessage());
	}
}

function getAnalyticsData(PDO $pdo): array {
	try {
		// Total plans
		$totalPlansStmt = $pdo->query("SELECT COUNT(*) as count FROM `member_subscription_plan`");
		$totalPlans = $totalPlansStmt->fetch()['count'] ?? 0;

		// Active subscriptions (approved status = 2)
		$activeSubsStmt = $pdo->query("
			SELECT COUNT(*) as count 
			FROM `subscription` s
			JOIN `subscription_status` ss ON s.status_id = ss.id
			WHERE ss.status_name = 'approved' AND s.end_date >= CURDATE()
		");
		$activeSubscriptions = $activeSubsStmt->fetch()['count'] ?? 0;

		// Monthly revenue from current month subscriptions (exclude cancelled, rejected, expired)
		$revenueStmt = $pdo->query("
			SELECT COALESCE(SUM(s.amount_paid), 0) as revenue
			FROM `subscription` s
			JOIN `subscription_status` ss ON s.status_id = ss.id
			WHERE ss.status_name = 'approved' 
			AND ss.status_name NOT IN ('cancelled', 'rejected', 'expired')
			AND MONTH(s.start_date) = MONTH(CURDATE()) 
			AND YEAR(s.start_date) = YEAR(CURDATE())
		");
		$monthlyRevenue = $revenueStmt->fetch()['revenue'] ?? 0;

		// Average plan price
		$avgPriceStmt = $pdo->query("SELECT AVG(price) as avg_price FROM `member_subscription_plan`");
		$averagePlanPrice = $avgPriceStmt->fetch()['avg_price'] ?? 0;

		// Debug: Add some logging
		error_log("Analytics Debug - Total Plans: " . $totalPlans);
		error_log("Analytics Debug - Active Subscriptions: " . $activeSubscriptions);
		error_log("Analytics Debug - Monthly Revenue: " . $monthlyRevenue);
		error_log("Analytics Debug - Average Plan Price: " . $averagePlanPrice);

		return [
			'totalPlans' => (int)$totalPlans,
			'activeSubscriptions' => (int)$activeSubscriptions,
			'monthlyRevenue' => (float)$monthlyRevenue,
			'averagePlanPrice' => (float)$averagePlanPrice
		];
	} catch (Throwable $e) {
		error_log("Analytics Error: " . $e->getMessage());
		// Return default values if there's an error
		return [
			'totalPlans' => 0,
			'activeSubscriptions' => 0,
			'monthlyRevenue' => 0,
			'averagePlanPrice' => 0
		];
	}
}

/**
 * GET: Get active subscriptions with member details and expiration warnings
 */
function getActiveSubscriptions(PDO $pdo): void {
	try {
		// Get filter parameters
		$statusFilter = $_GET['status'] ?? 'all';
		$expiringFilter = $_GET['expiring'] ?? 'all';
		$planFilter = $_GET['plan'] ?? 'all';

		$whereConditions = [];
		$params = [];

		// Base query to get subscriptions with user and plan details
		$query = "
			SELECT 
				s.id,
				s.user_id,
				s.plan_id,
				s.start_date,
				s.end_date,
				s.amount_paid,
				s.discount_type,
				s.discounted_price,
				CONCAT(u.fname, ' ', u.lname) as member_name,
				u.email as member_email,
				msp.plan_name,
				msp.price as plan_price,
				ss.status_name,
				DATEDIFF(s.end_date, CURDATE()) as days_until_expiry,
				CASE 
					WHEN s.end_date < CURDATE() THEN 'expired'
					WHEN DATEDIFF(s.end_date, CURDATE()) <= 3 THEN 'critical'
					WHEN DATEDIFF(s.end_date, CURDATE()) <= 7 THEN 'warning'
					WHEN DATEDIFF(s.end_date, CURDATE()) <= 14 THEN 'notice'
					ELSE 'normal'
				END as expiry_status,
				CASE 
					WHEN s.end_date < CURDATE() THEN 'expired'
					ELSE ss.status_name
				END as computed_status
			FROM `subscription` s
			JOIN `user` u ON s.user_id = u.id
			JOIN `member_subscription_plan` msp ON s.plan_id = msp.id
			JOIN `subscription_status` ss ON s.status_id = ss.id
		";

		// Apply filters
		if ($statusFilter !== 'all') {
			$whereConditions[] = "ss.status_name = ?";
			$params[] = $statusFilter;
		}

		// Exclude subscriptions with 0 payment
		$whereConditions[] = "s.amount_paid > 0";

		if ($expiringFilter !== 'all') {
			switch ($expiringFilter) {
				case 'critical':
					$whereConditions[] = "DATEDIFF(s.end_date, CURDATE()) <= 3 AND s.end_date >= CURDATE()";
					break;
				case 'warning':
					$whereConditions[] = "DATEDIFF(s.end_date, CURDATE()) <= 7 AND s.end_date >= CURDATE()";
					break;
				case 'notice':
					$whereConditions[] = "DATEDIFF(s.end_date, CURDATE()) <= 14 AND s.end_date >= CURDATE()";
					break;
				case 'expired':
					$whereConditions[] = "s.end_date < CURDATE()";
					break;
				case 'active':
					$whereConditions[] = "s.end_date >= CURDATE() AND ss.status_name = 'approved'";
					break;
			}
		}

		if ($planFilter !== 'all') {
			$whereConditions[] = "s.plan_id = ?";
			$params[] = $planFilter;
		}

		// Add WHERE clause if conditions exist
		if (!empty($whereConditions)) {
			$query .= " WHERE " . implode(' AND ', $whereConditions);
		}

		$query .= " ORDER BY s.end_date ASC, s.id DESC";

		$stmt = $pdo->prepare($query);
		$stmt->execute($params);
		$subscriptions = $stmt->fetchAll();

		// Get expiration warnings count
		$warningsQuery = "
			SELECT 
				SUM(CASE WHEN DATEDIFF(s.end_date, CURDATE()) <= 3 AND s.end_date >= CURDATE() THEN 1 ELSE 0 END) as critical_count,
				SUM(CASE WHEN DATEDIFF(s.end_date, CURDATE()) <= 7 AND s.end_date >= CURDATE() THEN 1 ELSE 0 END) as warning_count,
				SUM(CASE WHEN DATEDIFF(s.end_date, CURDATE()) <= 14 AND s.end_date >= CURDATE() THEN 1 ELSE 0 END) as notice_count
			FROM `subscription` s
			JOIN `subscription_status` ss ON s.status_id = ss.id
			WHERE ss.status_name = 'approved'
		";
		$warningsStmt = $pdo->query($warningsQuery);
		$warnings = $warningsStmt->fetch();

		// Get available plans for filter dropdown
		$plansStmt = $pdo->query("SELECT id, plan_name FROM `member_subscription_plan` ORDER BY plan_name");
		$availablePlans = $plansStmt->fetchAll();

		echo json_encode([
			"subscriptions" => $subscriptions,
			"warnings" => $warnings,
			"availablePlans" => $availablePlans,
			"totalCount" => count($subscriptions)
		]);
	} catch (Throwable $e) {
		throw new Exception("Error fetching subscriptions: " . $e->getMessage());
	}
}

/**
 * POST: Create a new membership plan (and optional features)
 * Required: name (plan_name), price
 * Optional: is_member_only, discounted_price, duration_months, features[]
 */
function createMembershipPlan(PDO $pdo, ?array $data): void {
	if (!$data) throw new Exception("No data received");
	if (!isset($data['name']) || !isset($data['price'])) {
		http_response_code(400);
		echo json_encode(["error" => "Missing required fields: name, price"]);
		return;
	}

	$pdo->beginTransaction();
	try {
		// Insert plan (matching lowercase table/columns)
		$stmt = $pdo->prepare("
			INSERT INTO `member_subscription_plan`
				(plan_name, price, is_member_only, discounted_price, duration_months, duration_days)
			VALUES
				(?, ?, ?, ?, ?, ?)
		");
		$stmt->execute([
			(string)$data['name'],
			(float)$data['price'],
			isset($data['is_member_only']) ? (int)$data['is_member_only'] : 0,
			array_key_exists('discounted_price', $data) ? $data['discounted_price'] : null,
			isset($data['duration_months']) ? (int)$data['duration_months'] : 1,
			isset($data['duration_days']) ? (int)$data['duration_days'] : 0,
		]);

		$planId = (int)$pdo->lastInsertId();

		// Insert features if provided and table exists
		if (isset($data['features']) && is_array($data['features']) && !empty($data['features'])) {
			try {
				$pdo->query("DESCRIBE `subscription_feature`");
				$featureStmt = $pdo->prepare("
					INSERT INTO `subscription_feature` (plan_id, feature_name, description)
					VALUES (?, ?, ?)
				");
				foreach ($data['features'] as $feature) {
					if (!empty($feature['feature_name'])) {
						$featureStmt->execute([
							$planId,
							(string)$feature['feature_name'],
							isset($feature['description']) ? (string)$feature['description'] : ''
						]);
					}
				}
			} catch (PDOException $e) {
				// features table not present; skip
			}
		}

		$pdo->commit();
		echo json_encode(["success" => true, "id" => $planId]);
	} catch (Throwable $e) {
		$pdo->rollBack();
		throw $e;
	}
}

/**
 * PUT: Update a membership plan (and replace features if provided)
 * Required: id, name, price
 */
function updateMembershipPlan(PDO $pdo, ?array $data): void {
	if (!$data) throw new Exception("No data received");
	if (!isset($data['id']) || !isset($data['name']) || !isset($data['price'])) {
		http_response_code(400);
		echo json_encode(["error" => "Missing required fields: id, name, price"]);
		return;
	}

	$pdo->beginTransaction();
	try {
		$stmt = $pdo->prepare("
			UPDATE `member_subscription_plan`
			SET plan_name = ?, price = ?, is_member_only = ?, discounted_price = ?, duration_months = ?, duration_days = ?
			WHERE id = ?
		");
		$stmt->execute([
			(string)$data['name'],
			(float)$data['price'],
			isset($data['is_member_only']) ? (int)$data['is_member_only'] : 0,
			array_key_exists('discounted_price', $data) ? $data['discounted_price'] : null,
			isset($data['duration_months']) ? (int)$data['duration_months'] : 1,
			isset($data['duration_days']) ? (int)$data['duration_days'] : 0,
			(int)$data['id'],
		]);

		// Replace features if provided and table exists
		if (isset($data['features']) && is_array($data['features'])) {
			try {
				$pdo->query("DESCRIBE `subscription_feature`");
				$del = $pdo->prepare("DELETE FROM `subscription_feature` WHERE plan_id = ?");
				$del->execute([(int)$data['id']]);

				$ins = $pdo->prepare("
					INSERT INTO `subscription_feature` (plan_id, feature_name, description)
					VALUES (?, ?, ?)
				");
				foreach ($data['features'] as $feature) {
					if (!empty($feature['feature_name'])) {
						$ins->execute([
							(int)$data['id'],
							(string)$feature['feature_name'],
							isset($feature['description']) ? (string)$feature['description'] : ''
						]);
					}
				}
			} catch (PDOException $e) {
				// features table not present; skip
			}
		}

		$pdo->commit();
		echo json_encode(["success" => true]);
	} catch (Throwable $e) {
		$pdo->rollBack();
		throw $e;
	}
}

/**
 * DELETE: Delete a membership plan (and its features if present)
 * Required: id
 */
function deleteMembershipPlan(PDO $pdo, ?array $data): void {
	if (!$data) throw new Exception("No data received");
	if (!isset($data['id'])) {
		http_response_code(400);
		echo json_encode(["error" => "Missing ID"]);
		return;
	}

	$pdo->beginTransaction();
	try {
		// Delete features first if table exists
		try {
			$pdo->query("DESCRIBE `subscription_feature`");
			$delFeat = $pdo->prepare("DELETE FROM `subscription_feature` WHERE plan_id = ?");
			$delFeat->execute([(int)$data['id']]);
		} catch (PDOException $e) {
			// no features table; continue
		}

		$delPlan = $pdo->prepare("DELETE FROM `member_subscription_plan` WHERE id = ?");
		$delPlan->execute([(int)$data['id']]);

		$pdo->commit();
		echo json_encode(["success" => true]);
	} catch (Throwable $e) {
		$pdo->rollBack();
		throw $e;
	}
}