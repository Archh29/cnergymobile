# Auto-Verification Expiry Implementation (3-Day Period)

## Overview
This implementation automatically deletes **pending customer accounts** (user_type_id = 4) that haven't been verified within 3 days of registration. This keeps the database clean and allows users to re-register with the same email if their verification period expires.

**Note:** This 3-day verification system ONLY applies to customers. Staff, coaches, and admins are not subject to this auto-deletion as they don't require front desk verification.

## What Was Changed

### 1. **Database Registration (api/loginapp.php)**
   - Added `registration_date` field to track when account was created
   - Added `verification_deadline` field set to 3 days from registration
   - API response now includes deadline information

### 2. **Auto-Cleanup Script (api/cleanup_expired_accounts.php)**
   - Created new PHP script that runs 2-stage cleanup:
     - **Stage 1:** Changes pending accounts past deadline to 'rejected' status
     - **Stage 2:** Deletes rejected accounts older than 17 days
     - Logs all actions for audit trail
   - **How to set up cron job:**
     ```bash
     # Run daily at 2 AM
     0 2 * * * /usr/bin/php /path/to/api/cleanup_expired_accounts.php
     ```

### 3. **Frontend - Success Dialog (lib/SignUp.dart)**
   - Added warning message in signup success dialog
   - Shows: "⚠️ IMPORTANT: You have 3 days to verify your account at our front desk. Your account will be automatically deleted if not verified within this period."

### 4. **Login Screen (lib/login_screen.dart)**
   - Already handles pending accounts by showing error message
   - Blocked login if account is pending
   - Shows: "Your account is still pending. Please visit the front desk for verification to access the app."

## How It Works

### Registration Flow:
1. User signs up → Account created with status "pending"
2. `registration_date` = current timestamp
3. `verification_deadline` = current timestamp + 3 days
4. User sees success message with 3-day deadline warning

### Verification Period (Days 1-3):
- User has 3 days to visit front desk
- Shows countdown timer: "⏰ 2 days left..."
- Once verified, account status changes to "approved"
- User can then login normally

### Auto-Rejection (Day 3+):
- Cron job runs daily at 2 AM
- Stage 1: Finds accounts where:
  - `account_status` = 'pending'
  - `verification_deadline` < NOW()
  - Changes status from 'pending' to 'rejected'
- Accounts stay in database with 'rejected' status

### Grace Period (Days 3-17):
- Status is 'rejected'
- Login shows: "Account verification rejected. Please create a new account."
- User can contact support during this period
- Database entry remains for audit trail

### Final Cleanup (Day 17+):
- Stage 2: Finds accounts where:
  - `account_status` = 'rejected'
  - `created_at` + 17 days < NOW()
  - Deletes these old rejected accounts
- Logs deleted accounts for audit

### After Deletion:
- User tries to login → Account doesn't exist (invalid credentials)
- User can register again with same email (after 17 days total)
- New 3-day countdown starts

## Database Schema

You need to add these columns to the `user` table:

```sql
ALTER TABLE user ADD COLUMN registration_date DATETIME NULL;
ALTER TABLE user ADD COLUMN verification_deadline DATETIME NULL;
```

## Setup Instructions

### 1. Update Database
Run the SQL commands above to add the required columns.

### 2. Set Up Cron Job
Add to your server's crontab:
```bash
crontab -e
```

Add this line:
```
0 2 * * * /usr/bin/php /home/username/public_html/api/cleanup_expired_accounts.php >> /home/username/logs/cleanup.log 2>&1
```

Adjust paths according to your server setup.

### 3. Test the Cleanup Script
Run manually to test:
```bash
php /path/to/api/cleanup_expired_accounts.php
```

## Benefits

1. **Clean Database** - No accumulation of stale pending accounts
2. **User-Friendly** - Clear deadline messaging to users
3. **Convenience** - Users can re-register if they miss the deadline
4. **Automated** - No manual intervention needed
5. **Audit Trail** - All deleted accounts are logged

## Testing

To test this feature:

1. Create a new account
2. Verify the success message shows 3-day deadline warning
3. Wait 3 days (or manually update database to set deadline in past)
4. Run cleanup script manually
5. Verify account is deleted
6. Register again with same email

## Files Modified

- `api/loginapp.php` - Added deadline tracking to registration
- `lib/SignUp.dart` - Added 3-day deadline warning to success dialog
- `lib/login_screen.dart` - Already handles pending account blocking
- `api/cleanup_expired_accounts.php` - **NEW FILE** - Auto-deletion script

## Notes

- The 3-day period can be adjusted in the registration code
- The cleanup script runs daily automatically
- No user data is lost if they verify within 3 days
- Users can retry registration as many times as needed

