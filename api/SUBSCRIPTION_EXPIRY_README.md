# CNERGY GYM Subscription Expiry Email System

A comprehensive email notification system for gym membership expiry reminders. This system automatically sends personalized emails to members when their subscriptions are about to expire.

## Features

- **Automated Email Reminders**: Sends emails at 14 days, 7 days, 3 days, and 1 day before expiry
- **Dynamic Email Templates**: Different urgency levels with appropriate colors and messaging
- **Database Integration**: Queries the MySQL database for active subscriptions
- **Bulk Processing**: Can process multiple subscriptions at once
- **Admin Dashboard**: Web interface for monitoring and testing
- **Cron Job Support**: Automated daily checks
- **Test Functionality**: Built-in testing capabilities

## Files Overview

### Core Files
- `email_service.php` - Main email service class with subscription expiry methods
- `subscription_expiry_checker.php` - Cron job script for automated checks
- `test_subscription_expiry.php` - Test script for development
- `subscription_expiry_dashboard.php` - Web dashboard for administrators

## Installation & Setup

### 1. Database Requirements
Ensure your database has the following tables with the correct structure:
- `subscription` - Contains subscription data with `end_date` field
- `user` - Contains user information
- `member_subscription_plan` - Contains plan details
- `subscription_status` - Contains status information

### 2. Email Configuration
The system uses PHP's built-in `mail()` function. Ensure your server is configured to send emails:
- Configure SMTP settings in your server
- Test email functionality with the test scripts

### 3. File Permissions
Ensure the API files have proper read permissions:
```bash
chmod 644 api/*.php
```

## Usage

### Automated Daily Checks (Recommended)

Set up a cron job to run daily at 9:00 AM:
```bash
# Edit crontab
crontab -e

# Add this line
0 9 * * * /usr/bin/php /path/to/your/api/subscription_expiry_checker.php
```

### Manual Execution

#### Check All Expiring Subscriptions
```bash
php api/subscription_expiry_checker.php
```

#### Test the System
```bash
php api/subscription_expiry_checker.php test
```

#### Check Specific Day Expiry
```bash
php api/subscription_expiry_checker.php manual 7
```

#### Run Test Script
```bash
php api/test_subscription_expiry.php
```

### Web Dashboard

Access the admin dashboard at:
```
http://yoursite.com/api/subscription_expiry_dashboard.php
```

Features:
- View expiring subscriptions
- Send test emails
- Monitor system status
- Manual expiry checks

## Email Templates

The system includes four different email templates based on urgency:

### 14 Days Remaining
- **Color**: Green (#28a745)
- **Tone**: Gentle reminder
- **Icon**: 📅
- **Message**: Friendly heads up for planning renewal

### 7 Days Remaining
- **Color**: Yellow (#ffc107)
- **Tone**: Important notice
- **Icon**: ⚠️
- **Message**: Encouraging renewal to avoid interruption

### 3 Days Remaining
- **Color**: Orange (#fd7e14)
- **Tone**: Urgent reminder
- **Icon**: 🚨
- **Message**: Last chance to renew without interruption

### 1 Day Remaining
- **Color**: Red (#dc3545)
- **Tone**: Final notice
- **Icon**: 🔥
- **Message**: Urgent renewal to avoid service interruption

## Database Query

The system uses this query to find expiring subscriptions:

```sql
SELECT 
    s.id,
    s.user_id,
    s.end_date,
    s.plan_id,
    u.fname,
    u.lname,
    u.email,
    msp.plan_name,
    msp.price,
    DATEDIFF(s.end_date, CURDATE()) as days_remaining
FROM subscription s
JOIN user u ON s.user_id = u.id
JOIN member_subscription_plan msp ON s.plan_id = msp.id
WHERE s.status_id = 2 
AND s.end_date >= CURDATE()
AND DATEDIFF(s.end_date, CURDATE()) IN (14, 7, 3, 1)
ORDER BY s.end_date ASC
```

## API Methods

### EmailService Class Methods

#### `sendSubscriptionExpiryEmail($userEmail, $userName, $daysRemaining, $expiryDate, $subscriptionDetails)`
Sends a single subscription expiry email.

**Parameters:**
- `$userEmail` - User's email address
- `$userName` - User's full name
- `$daysRemaining` - Days until expiry (14, 7, 3, or 1)
- `$expiryDate` - Expiry date (Y-m-d format)
- `$subscriptionDetails` - Array with plan info

**Returns:** Array with success status and message

#### `checkAndSendExpiryEmails()`
Checks database and sends emails to all expiring subscriptions.

**Returns:** Array with summary of emails sent

## Configuration

### Email Settings
Update the email configuration in `email_service.php`:

```php
private $fromEmail = 'cnergyfitnessgym@cnergy.site';
private $fromName = 'CNERGY GYM';
```

### Database Connection
Ensure `db.php` is properly configured with your database credentials.

### Admin Email
Update the admin email in `subscription_expiry_checker.php`:

```php
$adminEmail = 'admin@cnergygym.com'; // Change this
```

## Monitoring & Logs

### Log Files
The system logs all activities to PHP error logs. Check your server's error log for:
- Email sending status
- Database query results
- System errors

### Admin Notifications
The system can send daily summary emails to administrators with:
- Total subscriptions checked
- Emails sent successfully
- Any errors encountered
- Detailed breakdown

## Troubleshooting

### Common Issues

#### Emails Not Sending
1. Check server mail configuration
2. Verify SMTP settings
3. Test with `test_subscription_expiry.php`
4. Check server error logs

#### Database Connection Issues
1. Verify database credentials in `db.php`
2. Check database server status
3. Ensure tables exist with correct structure

#### Cron Job Not Running
1. Check cron job syntax
2. Verify file paths are absolute
3. Check cron service status
4. Review cron logs

### Testing

#### Test Individual Email
```php
$emailService = new EmailService();
$result = $emailService->sendSubscriptionExpiryEmail(
    'test@example.com',
    'Test User',
    7,
    '2024-01-15',
    ['plan_name' => 'Test Plan', 'price' => 999.00]
);
```

#### Test Database Query
```php
$query = "SELECT COUNT(*) as count FROM subscription WHERE status_id = 2";
$result = $conn->query($query);
$row = $result->fetch_assoc();
echo "Active subscriptions: " . $row['count'];
```

## Security Considerations

- Ensure API files are not publicly accessible
- Use HTTPS for web dashboard
- Validate all user inputs
- Implement proper authentication for admin access
- Regular security updates

## Support

For issues or questions:
1. Check the error logs
2. Test with the provided test scripts
3. Verify database structure matches requirements
4. Contact system administrator

## Version History

- **v1.0** - Initial release with basic expiry email functionality
- **v1.1** - Added web dashboard and improved error handling
- **v1.2** - Enhanced email templates and admin notifications

---

**Note**: This system is designed specifically for the CNERGY GYM database structure. Modify queries and table references as needed for your specific setup.
