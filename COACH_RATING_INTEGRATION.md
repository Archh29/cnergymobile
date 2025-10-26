# Coach Rating & Feedback System

## ✅ Files Created

### User Side
- `lib/User/rate_coach_page.dart` - Page for users to rate and give feedback to their coach

### Coach Side
- `lib/Coach/coach_ratings_page.dart` - Page for coaches to view their ratings and reviews

### API
- `api/coach_rating.php` - Backend API for handling ratings and feedback

## 📋 Database Table Used

Uses existing `coach_review` table:
```sql
- id
- coach_id
- member_id  
- rating (1-5)
- feedback (text)
- created_at
```

## 🔧 Integration Instructions

### 1. **User Side Integration**

Add a button in the user's coach profile or dashboard to rate their coach:

```dart
// Example: Add to user dashboard or coach profile page
import 'rate_coach_page.dart';

// In your widget:
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateCoachPage(
          coachId: yourCoachId,  // Get from coach_member_list
          coachName: 'Coach Name',
        ),
      ),
    );
  },
  child: Text('Rate Your Coach'),
)
```

### 2. **Coach Side Integration**

Add a navigation option in the coach's profile or settings:

```dart
// Example: Add to coach profile page
import 'Coach/coach_ratings_page.dart';

// In your widget:
ListTile(
  leading: Icon(Icons.star, color: Color(0xFF4ECDC4)),
  title: Text('My Ratings & Reviews'),
  trailing: Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachRatingsPage(),
      ),
    );
  },
)
```

### 3. **API Setup**

Upload `api/coach_rating.php` to your server at `https://api.cnergy.site/`

The API supports these actions:
- `submit_review` - Submit new review
- `update_review` - Update existing review
- `check_review` - Check if user has already reviewed
- `get_coach_ratings` - Get all ratings for a coach

## 🎨 Features

### User Features:
- ⭐ Rate coach from 1-5 stars
- 💬 Write detailed feedback
- ✏️ Edit existing review
- 🔄 Visual feedback on submission

### Coach Features:
- 📊 Overall average rating
- 📈 Rating distribution chart
- 📝 All member reviews with names
- 🔄 Pull to refresh
- 📅 Review timestamps

## 🎯 Where to Add Rating Button

### Option 1: User Dashboard
Add a "Rate Your Coach" card in the user dashboard next to other actions.

### Option 2: Coach Profile
If you have a coach profile page, add a "Rate Coach" button there.

### Option 3: After Workout
Show a prompt to rate the coach after completing a workout session.

## 💡 Example Integration in User Dashboard

```dart
// In lib/User/user_dashboard.dart

Widget _buildRateCoachCard() {
  return GestureDetector(
    onTap: () async {
      // Get coach info from coach_member_list
      final coachInfo = await _getMyCoach();
      if (coachInfo != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RateCoachPage(
              coachId: coachInfo['coach_id'],
              coachName: coachInfo['coach_name'],
            ),
          ),
        );
      }
    },
    child: Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Color(0xFF4ECDC4), size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate Your Coach',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Share your experience',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    ),
  );
}
```

## 🔒 Security Notes

- Users can only rate coaches they are assigned to
- Reviews are tied to user accounts
- Coaches can only view their own ratings
- All data validated on server side

## 📱 UI/UX Highlights

- ✨ Modern gradient design matching your app theme
- 🌙 Dark mode optimized
- 📱 Fully responsive
- ⚡ Real-time validation
- 🔄 Loading states
- ✅ Success/error feedback

## 🚀 Next Steps

1. Upload `api/coach_rating.php` to your server
2. Add navigation buttons in your app
3. Test the flow
4. Optionally add notifications when coaches receive new reviews

## 📊 Future Enhancements

Consider adding:
- Push notifications when coach receives new review
- Monthly rating summary for coaches
- Respond to reviews feature
- Filter reviews by rating
- Export reviews as PDF

