# Coach Session Management System

## Overview

This system implements a hybrid approach for managing coach session packages, providing both automatic session deduction and manual coach control for adjustments and corrections.

## Features

### 🔄 Hybrid Session Management
- **Automatic Deduction**: Sessions are automatically deducted when users start workouts (once per day)
- **Manual Control**: Coaches can undo incorrect deductions and manually adjust session counts
- **Audit Trail**: Complete history of all session usage and adjustments

### 📊 Session Management Features
- View complete session usage history for each member
- Undo accidental session deductions
- Manually adjust session counts (add or remove sessions)
- Track reasons for manual adjustments
- Real-time session count updates

### 🛡️ Safety Features
- Prevents double deduction on the same day
- Validates session adjustments (prevents negative sessions)
- Transaction-based operations for data integrity
- Complete audit logging

## System Architecture

### Frontend (Flutter)
- **SessionManagementPage**: Main interface for coaches to manage sessions
- **Integration**: Added to coach dashboard navigation
- **Real-time Updates**: Automatic refresh after operations

### Backend (PHP API)
- **coach_session_management.php**: Dedicated API with complete CORS support
- **Database Integration**: Direct connection to MySQL database
- **Error Handling**: Comprehensive error responses and logging

### Database Schema
- **coach_session_usage**: Enhanced table with undo and adjustment tracking
- **coach_member_list**: Stores current session counts and package info
- **admin_activity_log**: Tracks all session management activities

## API Endpoints

### GET Endpoints

#### Get Session History
```
GET /coach_session_management.php?action=get-session-history&member_id={id}
```
Returns complete session usage history for a member.

#### Get Member Session Info
```
GET /coach_session_management.php?action=get-member-session-info&member_id={id}
```
Returns current session package information and usage statistics.

### POST Endpoints

#### Undo Session Usage
```
POST /coach_session_management.php?action=undo-session-usage
Content-Type: application/json

{
  "usage_id": 123,
  "member_id": 456
}
```
Undoes a specific session usage, adding 1 session back to the package.

#### Adjust Session Count
```
POST /coach_session_management.php?action=adjust-session-count
Content-Type: application/json

{
  "member_id": 456,
  "adjustment": 2,
  "reason": "Manual adjustment by coach"
}
```
Manually adjusts session count (positive to add, negative to remove).

#### Add Session Usage
```
POST /coach_session_management.php?action=add-session-usage
Content-Type: application/json

{
  "member_id": 456,
  "coach_id": 789,
  "usage_date": "2024-01-15",
  "reason": "Manual session usage"
}
```
Manually adds a session usage record.

## Installation & Setup

### 1. Database Migration
Run the migration script to add necessary columns:
```sql
-- Execute coach_session_management_migration.sql
mysql -u username -p database_name < coach_session_management_migration.sql
```

### 2. API Configuration
- Upload `coach_session_management.php` to your API directory
- Ensure proper database credentials in the PHP file
- Verify CORS headers are working correctly

### 3. Flutter Integration
- The `SessionManagementPage` is automatically integrated into the coach dashboard
- No additional configuration required

## Usage Guide

### For Coaches

#### Accessing Session Management
1. Open the Coach Dashboard
2. Select a member from the Members tab
3. Navigate to the "Sessions" tab
4. View session history and manage sessions

#### Undoing Session Usage
1. Find the session usage record to undo
2. Click the undo button (↶ icon)
3. Confirm the action
4. Session will be added back to the member's package

#### Adjusting Session Count
1. Click the edit button (✏️ icon) in the app bar
2. Enter the adjustment amount (positive to add, negative to remove)
3. Provide a reason for the adjustment
4. Confirm the action

### For Developers

#### Testing the API
Use the provided test file:
```bash
php test_coach_session_management.php
```

#### Monitoring
- Check `admin_activity_log` table for all session management activities
- Monitor error logs for any API issues
- Use the session summary view for reporting

## Database Schema Changes

### coach_session_usage Table
```sql
-- New columns added:
undone_at DATETIME NULL                    -- When session was undone
adjustment_amount INT NULL                 -- Manual adjustment amount
adjustment_type ENUM(...) DEFAULT 'automatic' -- Type of adjustment
reason TEXT NULL                          -- Reason for manual operations
```

### New Database View
```sql
-- coach_session_summary view provides:
- Total usage records
- Active vs undone usage counts
- Manual adjustment totals
- Last activity timestamps
```

## Error Handling

### Common Error Scenarios
1. **No Active Package**: Member doesn't have an active session package
2. **Already Undone**: Attempting to undo an already undone session
3. **Invalid Adjustment**: Trying to reduce sessions below zero
4. **Duplicate Usage**: Attempting to use session on same date

### Error Response Format
```json
{
  "success": false,
  "message": "Descriptive error message"
}
```

## Security Considerations

### Access Control
- API endpoints should be protected with authentication
- Coaches should only access their assigned members' data
- All operations are logged for audit purposes

### Data Validation
- Input validation on all parameters
- SQL injection prevention with prepared statements
- Transaction-based operations for data integrity

## Troubleshooting

### Common Issues

#### CORS Errors
- Verify CORS headers in the PHP file
- Check that the API URL is correct in Flutter code

#### Database Connection Issues
- Verify database credentials
- Check database server connectivity
- Ensure proper permissions

#### Session Not Updating
- Check if member has active session package
- Verify coach-member relationship
- Check for transaction rollbacks in logs

### Debug Mode
Enable debug logging by checking the error logs:
```bash
tail -f /var/log/apache2/error.log
```

## Future Enhancements

### Planned Features
- Bulk session adjustments
- Session usage analytics dashboard
- Email notifications for low session counts
- Integration with payment systems
- Advanced reporting features

### Performance Optimizations
- Database query optimization
- Caching for frequently accessed data
- API response compression
- Background job processing

## Support

For technical support or feature requests:
1. Check the error logs first
2. Review the API test results
3. Verify database schema is up to date
4. Contact the development team with specific error messages

## Version History

### v1.0.0 (Current)
- Initial implementation of hybrid session management
- Complete undo and adjustment functionality
- Integration with coach dashboard
- Comprehensive API with CORS support
- Database migration scripts
- Testing and documentation

---

*This system provides a robust solution for managing coach session packages while maintaining data integrity and providing coaches with the flexibility to handle edge cases and corrections.*
