import 'package:intl/intl.dart';

class CnergyDateUtils {
  // Format: MM/DD/YYYY
  static const String _displayFormat = 'MM/dd/yyyy';
  // Format: YYYY-MM-DD (for API/database)
  static const String _apiFormat = 'yyyy-MM-dd';
  // Format: MM/DD/YYYY h:mm a (for datetime with 12-hour format)
  static const String _displayDateTimeFormat = 'MM/dd/yyyy h:mm a';
  // Format: YYYY-MM-DD HH:mm:ss (for API datetime)
  static const String _apiDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  /// Convert DateTime to display format (MM/DD/YYYY)
  static String toDisplayDate(DateTime date) {
    return DateFormat(_displayFormat).format(date);
  }

  /// Convert DateTime to display datetime format (MM/DD/YYYY HH:mm)
  static String toDisplayDateTime(DateTime date) {
    return DateFormat(_displayDateTimeFormat).format(date);
  }

  /// Convert DateTime to API format (YYYY-MM-DD)
  static String toApiDate(DateTime date) {
    return DateFormat(_apiFormat).format(date);
  }

  /// Convert DateTime to API datetime format (YYYY-MM-DD HH:mm:ss)
  static String toApiDateTime(DateTime date) {
    return DateFormat(_apiDateTimeFormat).format(date);
  }

  /// Parse display date string (MM/DD/YYYY) to DateTime
  static DateTime? parseDisplayDate(String dateString) {
    try {
      return DateFormat(_displayFormat).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse API date string (YYYY-MM-DD) to DateTime
  static DateTime? parseApiDate(String dateString) {
    try {
      return DateFormat(_apiFormat).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse API datetime string (YYYY-MM-DD HH:mm:ss) to DateTime
  static DateTime? parseApiDateTime(String dateString) {
    try {
      return DateFormat(_apiDateTimeFormat).parse(dateString);
    } catch (e) {
      // Try parsing without seconds
      try {
        return DateFormat('yyyy-MM-dd HH:mm').parse(dateString);
      } catch (e2) {
        return null;
      }
    }
  }

  /// Get current date in display format
  static String getCurrentDisplayDate() {
    return toDisplayDate(DateTime.now());
  }

  /// Get current date in API format
  static String getCurrentApiDate() {
    return toApiDate(DateTime.now());
  }

  /// Get current datetime in API format
  static String getCurrentApiDateTime() {
    return toApiDateTime(DateTime.now());
  }

  /// Format date for user input (MM/DD/YYYY)
  static String formatForInput(DateTime date) {
    return toDisplayDate(date);
  }

  /// Parse user input date (MM/DD/YYYY) to DateTime
  static DateTime? parseInputDate(String input) {
    return parseDisplayDate(input);
  }

  /// Calculate age from birthdate
  static int calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month || 
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  /// Get relative date string (e.g., "2 days ago", "Due tomorrow")
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 0) return 'In $difference days';
    if (difference < 0) return '${-difference} days ago';
    
    return toDisplayDate(date);
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Check if date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }
}
