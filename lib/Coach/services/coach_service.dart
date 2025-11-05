import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/member_model.dart';
import '../models/routine.models.dart';
import '../models/workout_session_model.dart';
import '../models/goal_model.dart';
import '../../User/services/auth_service.dart';

class CoachService {
  static const String baseUrl = 'https://api.cnergy.site/coach_api.php';

  // Enhanced helper method to safely convert values to int
  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      // Handle quoted strings like "12"
      final cleanValue = value.replaceAll('"', '').trim();
      return int.tryParse(cleanValue);
    }
    if (value is double) return value.toInt();
    return null;
  }

  // Enhanced helper method to safely convert values to double
  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return null;
      final cleanValue = value.replaceAll('"', '').trim();
      return double.tryParse(cleanValue);
    }
    return null;
  }

  // Enhanced helper method to safely convert values to string
  static String? _safeParseString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      // Remove surrounding quotes if present
      final cleanValue = value.replaceAll(RegExp(r'^"|"$'), '').trim();
      return cleanValue.isEmpty ? null : cleanValue;
    }
    return value.toString();
  }

  // Enhanced helper method to safely parse DateTime
  static DateTime? _safeParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      final cleanValue = value.replaceAll('"', '').trim();
      return DateTime.tryParse(cleanValue);
    }
    return null;
  }

  // FIXED: Get coach ID from AuthService instead of SharedPreferences to avoid stale data
  static Future<int> getCoachId() async {
    try {
      print('🆔 DEBUG: Starting getCoachId()');
      
      // Import AuthService to get current user ID
      final currentUserId = AuthService.getCurrentUserId();
      print('🔍 DEBUG: Current user ID from AuthService: $currentUserId');
      
      if (currentUserId != null && currentUserId > 0) {
        print('✅ DEBUG: Using current user ID as coach ID: $currentUserId');
        return currentUserId;
      }
      
      // Fallback to SharedPreferences if AuthService fails
      print('⚠️ DEBUG: AuthService returned null/0, falling back to SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      int coachId = 0;
      
      print('🔍 DEBUG: Checking for user_id in SharedPreferences');
      // First, try to get as integer
      if (prefs.containsKey('user_id')) {
        print('🔍 DEBUG: user_id key exists in SharedPreferences');
        try {
          // Try getting as int first
          coachId = prefs.getInt('user_id') ?? 0;
          print('✅ DEBUG: Retrieved coach ID as int: $coachId');
        } catch (e) {
          print('⚠️ DEBUG: Failed to get as int, trying as string: $e');
          // If that fails, try getting as string and convert
          final stringId = prefs.getString('user_id');
          print('🔍 DEBUG: Retrieved string ID: "$stringId"');
          if (stringId != null && stringId.isNotEmpty) {
            final parsedId = int.tryParse(stringId);
            if (parsedId != null) {
              coachId = parsedId;
              print('✅ DEBUG: Converted string "$stringId" to int: $coachId');
              
              // Clean up: remove the string version and store as int
              await prefs.remove('user_id');
              await prefs.setInt('user_id', coachId);
              print('🔧 DEBUG: Fixed storage type for user_id');
            } else {
              print('❌ DEBUG: Could not parse string "$stringId" to int');
            }
          } else {
            print('❌ DEBUG: String ID is null or empty');
          }
        }
      } else {
        print('❌ DEBUG: user_id key does not exist in SharedPreferences');
      }
      
      print('🏁 DEBUG: Final coach ID: $coachId (type: ${coachId.runtimeType})');
      if (coachId == 0) {
        print('❌ DEBUG: WARNING - Coach ID is 0, this will cause API calls to fail!');
      }
      return coachId;
      
    } catch (e, stackTrace) {
      print('❌ DEBUG: Exception in getCoachId: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      return 0;
    }
  }

  // ENHANCED: Helper method to clean and validate member data with better type handling
  static Map<String, dynamic> _cleanMemberData(Map<String, dynamic> rawData) {
    final cleanedData = <String, dynamic>{};
    
    // List of fields that should be integers
    final intFields = [
      'id', 'user_id', 'member_id', 'request_id', 'coach_id',
      'user_type_id', 'gender_id', 'age', 'height', 'weight',
      'handled_by_coach', 'handled_by_staff', 'remaining_sessions'
    ];
    
    // List of fields that should be strings
    final stringFields = [
      'name', 'email', 'phone', 'fname', 'mname', 'lname',
      'username', 'profile_picture', 'status', 'created_at',
      'updated_at', 'date_of_birth', 'address', 'emergency_contact',
      'coach_approval', 'staff_approval', 'subscription_status',
      'plan_name', 'gender_name', 'bday', 'requested_at',
      'coach_approved_at', 'staff_approved_at', 'subscription_start',
      'subscription_end', 'membership_type', 'join_date',
      'rate_type', 'expires_at'
    ];
    
    // List of fields that should be doubles
    final doubleFields = ['bmi', 'body_fat_percentage', 'muscle_mass'];
    
    // Process each field in the raw data
    rawData.forEach((key, value) {
      try {
        if (intFields.contains(key)) {
          cleanedData[key] = _safeParseInt(value);
        } else if (doubleFields.contains(key)) {
          cleanedData[key] = _safeParseDouble(value);
        } else if (stringFields.contains(key)) {
          cleanedData[key] = _safeParseString(value);
        } else {
          // For unknown fields, try to clean them too
          if (value is String && value.startsWith('"') && value.endsWith('"')) {
            cleanedData[key] = value.replaceAll(RegExp(r'^"|"$'), '');
          } else {
            cleanedData[key] = value;
          }
          print('Debug: Unknown field "$key" with value: $value (${value.runtimeType})');
        }
      } catch (e) {
        print('Error processing field "$key" with value "$value": $e');
        cleanedData[key] = null;
      }
    });
    
    return cleanedData;
  }

  // -------------------- COACH MEMBER REQUEST FUNCTIONS --------------------

  // FIXED: Get pending member requests for a specific coach
  static Future<List<MemberModel>> getPendingRequests() async {
    try {
      final coachId = await getCoachId();
      
      print('Debug: Coach ID for pending requests: $coachId (type: ${coachId.runtimeType})');
      
      if (coachId == 0) {
        print('Error: No valid coach ID found');
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=coach-pending-requests&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Debug: Pending requests response status: ${response.statusCode}');
      print('Debug: Pending requests response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final requestsList = data['requests'] as List? ?? [];
          print('Debug: Found ${requestsList.length} pending requests');
          
          List<MemberModel> members = [];
          for (var memberData in requestsList) {
            try {
              print('Debug: Processing pending request data: $memberData');
              
              // FIXED: Extract the actual member data from the nested structure
              Map<String, dynamic> actualMemberData;
              
              if (memberData is Map<String, dynamic>) {
                // Check if this has a nested 'member' field
                if (memberData.containsKey('member') && memberData['member'] is Map) {
                  actualMemberData = Map<String, dynamic>.from(memberData['member'] as Map);
                  
                  // Also preserve the request_id from the parent object
                  if (memberData.containsKey('request_id')) {
                    actualMemberData['request_id'] = memberData['request_id'];
                  }
                  if (memberData.containsKey('id')) {
                    actualMemberData['request_id'] = memberData['id'];
                  }
                  
                  print('Debug: Extracted nested member data with request_id: $actualMemberData');
                } else {
                  // It's already the member data
                  actualMemberData = memberData;
                }
              } else {
                print('Warning: memberData is not a Map, skipping: $memberData');
                continue;
              }
              
              // FIXED: Clean and validate the member data before parsing
              final cleanedMemberData = _cleanMemberData(actualMemberData);
              print('Debug: Cleaned pending request data: $cleanedMemberData');
              
              final member = MemberModel.fromJson(cleanedMemberData);
              members.add(member);
              
            } catch (e, stackTrace) {
              print('Error parsing individual pending request: $e');
              print('Stack trace: $stackTrace');
              print('Problematic request data: $memberData');
              // Continue with other members instead of failing completely
            }
          }
          
          print('Debug: Successfully parsed ${members.length} pending requests');
          return members;
        } else {
          print('Error: API returned success=false: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        print('Error: HTTP ${response.statusCode}: ${response.body}');
      }
      return [];
    } catch (e, stackTrace) {
      print('Error fetching pending requests: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Coach approves a pending member request
  static Future<bool> approveMemberRequest(int requestId) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) {
        print('Error: No valid coach ID found');
        return false;
      }
      
      print('Debug: Approving request ID: $requestId with coach ID: $coachId');
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=approve-member-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'request_id': requestId,
          'coach_id': coachId,
        }),
      );
      
      print('Debug: Approval response status: ${response.statusCode}');
      print('Debug: Approval response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error approving member request: $e');
      return false;
    }
  }

  // Staff approves a pending member request
  static Future<bool> approveMemberRequestByStaff(int requestId, int staffId) async {
    try {
      print('Debug: Staff approving request ID: $requestId with staff ID: $staffId');
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=approve-member-request-staff'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'request_id': requestId,
          'staff_id': staffId,
        }),
      );
      
      print('Debug: Staff approval response status: ${response.statusCode}');
      print('Debug: Staff approval response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error approving member request by staff: $e');
      return false;
    }
  }

  // Coach rejects a pending member request
  static Future<bool> rejectMemberRequest(int requestId, {String? reason}) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) {
        print('Error: No valid coach ID found');
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=reject-member-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'request_id': requestId,
          'coach_id': coachId,
          'reason': reason ?? 'Not available',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error rejecting member request: $e');
      return false;
    }
  }

  // FIXED: Get assigned/approved members for a coach
  static Future<List<MemberModel>> getAssignedMembers() async {
    try {
      print('🔄 DEBUG: Starting getAssignedMembers()');
      final coachId = await getCoachId();
      
      print('🆔 DEBUG: Coach ID for assigned members: $coachId (type: ${coachId.runtimeType})');
      
      if (coachId == 0) {
        print('❌ DEBUG: No valid coach ID found, returning empty list');
        return [];
      }
      
      final url = '$baseUrl?action=coach-assigned-members&coach_id=$coachId';
      print('🌐 DEBUG: Making API call to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('📡 DEBUG: Assigned members response status: ${response.statusCode}');
      print('📄 DEBUG: Assigned members response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 DEBUG: Parsed JSON data: $data');
        
        if (data['success'] == true) {
          final membersList = data['members'] as List? ?? [];
          print('👥 DEBUG: Found ${membersList.length} assigned members in API response');
          
          List<MemberModel> members = [];
          for (int i = 0; i < membersList.length; i++) {
            var memberData = membersList[i];
            try {
              print('🔄 DEBUG: Processing member $i: $memberData');
              
              // FIXED: Extract the actual member data from the nested structure
              Map<String, dynamic> actualMemberData;
              
              if (memberData is Map<String, dynamic>) {
                // Check if this has a nested 'member' field
                if (memberData.containsKey('member') && memberData['member'] is Map) {
                  actualMemberData = Map<String, dynamic>.from(memberData['member'] as Map);
                  print('🔄 DEBUG: Extracted nested member data: $actualMemberData');
                } else {
                  // It's already the member data
                  actualMemberData = memberData;
                  print('🔄 DEBUG: Using direct member data: $actualMemberData');
                }
              } else {
                print('⚠️ DEBUG: memberData is not a Map, skipping: $memberData');
                continue;
              }
              
              // FIXED: Clean and validate the member data before parsing
              final cleanedMemberData = _cleanMemberData(actualMemberData);
              print('🧹 DEBUG: Cleaned member data: $cleanedMemberData');
              
              final member = MemberModel.fromJson(cleanedMemberData);
              print('✅ DEBUG: Successfully created MemberModel: ID=${member.id}, Name=${member.fullName}');
              members.add(member);
              
            } catch (e, stackTrace) {
              print('❌ DEBUG: Error parsing member $i: $e');
              print('❌ DEBUG: Stack trace: $stackTrace');
              print('❌ DEBUG: Problematic member data: $memberData');
              // Continue with other members instead of failing completely
            }
          }
          
          print('✅ DEBUG: Successfully parsed ${members.length} assigned members');
          for (int i = 0; i < members.length; i++) {
            print('👤 DEBUG: Final member $i: ID=${members[i].id}, Name=${members[i].fullName}, Email=${members[i].email}');
          }
          return members;
        } else {
          print('❌ DEBUG: API returned success=false: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ DEBUG: HTTP ${response.statusCode}: ${response.body}');
      }
      print('❌ DEBUG: Returning empty list due to API error');
      return [];
    } catch (e, stackTrace) {
      print('❌ DEBUG: Exception in getAssignedMembers(): $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      return [];
    }
  }

  // Get member's current request status
  static Future<Map<String, dynamic>?> getMemberRequestStatus(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=member-request-status&member_id=$memberId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['request'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching member request status: $e');
      return null;
    }
  }

  // -------------------- UTILITY FUNCTIONS --------------------

  // Helper function to clear and reset user_id in SharedPreferences
  static Future<void> clearAndSetUserId(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear any existing user_id entries
      await prefs.remove('user_id');
      
      // Set the correct integer value
      await prefs.setInt('user_id', userId);
      
      print('Debug: Successfully set user_id to $userId as integer');
    } catch (e) {
      print('Error setting user_id: $e');
    }
  }

  // Helper function to debug SharedPreferences
  static Future<void> debugSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      print('=== SharedPreferences Debug ===');
      print('Available keys: $keys');
      
      for (String key in keys) {
        final value = prefs.get(key);
        print('Key: "$key" = $value (${value.runtimeType})');
      }
      print('=== End Debug ===');
    } catch (e) {
      print('Error debugging SharedPreferences: $e');
    }
  }

  // Rest of your existing methods remain the same...
  static Future<List<RoutineModel>> getMemberRoutines(int memberId) async {
    try {
      print('🔄 DEBUG: Starting getMemberRoutines() for member $memberId');
      final coachId = await getCoachId();
      
      print('🆔 DEBUG: Fetching routines for member $memberId by coach $coachId');
      
      if (coachId == 0) {
        print('❌ DEBUG: Coach ID is 0, cannot fetch routines');
        return [];
      }
      
      final url = '$baseUrl?action=member-routines&member_id=$memberId&coach_id=$coachId&include_coach_created=true';
      print('🌐 DEBUG: Making API call to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('📡 DEBUG: Member routines response status: ${response.statusCode}');
      print('📄 DEBUG: Member routines response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 DEBUG: Parsed JSON data: $data');
        
        if (data['success'] == true) {
          final routinesList = data['routines'] as List? ?? [];
          print('🏋️ DEBUG: Found ${routinesList.length} routines for member $memberId');
          
          List<RoutineModel> routines = [];
          for (int i = 0; i < routinesList.length; i++) {
            var routineData = routinesList[i];
            try {
              print('🔄 DEBUG: Processing routine $i: $routineData');
              final routine = RoutineModel.fromJson(routineData);
              print('✅ DEBUG: Successfully created RoutineModel: ID=${routine.id}, Name="${routine.name}"');
              routines.add(routine);
            } catch (e) {
              print('❌ DEBUG: Error parsing routine $i: $e');
              print('❌ DEBUG: Problematic routine data: $routineData');
            }
          }
          
          print('✅ DEBUG: Successfully parsed ${routines.length} routines for member $memberId');
          return routines;
        } else {
          print('❌ DEBUG: API returned success=false: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ DEBUG: HTTP ${response.statusCode}: ${response.body}');
      }
      print('❌ DEBUG: Returning empty list due to API error');
      return [];
    } catch (e) {
      print('❌ DEBUG: Exception in getMemberRoutines: $e');
      print('❌ DEBUG: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  static Future<List<RoutineModel>> getCoachCreatedRoutinesForMember(int memberId) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) {
        print('Error: No valid coach ID found');
        return [];
      }
      
      print('Debug: Fetching coach-created routines for member $memberId by coach $coachId');
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=coach-created-routines&member_id=$memberId&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Debug: Coach-created routines response status: ${response.statusCode}');
      print('Debug: Coach-created routines response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final routinesList = data['routines'] as List? ?? [];
          print('Debug: Found ${routinesList.length} coach-created routines for member $memberId');
          
          return routinesList
              .map((routine) => RoutineModel.fromJson(routine))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching coach-created routines: $e');
      return [];
    }
  }


  static Future<bool> createRoutineForMember(int memberId, RoutineModel routine) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return false;
      
      final routineData = routine.toJson();
      routineData['member_id'] = memberId;
      routineData['created_by_coach'] = coachId;
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=create-routine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(routineData),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error creating routine for member: $e');
      return false;
    }
  }

  static Future<bool> updateMemberRoutine(int routineId, Map<String, dynamic> updates) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return false;
      
      updates['updated_by_coach'] = coachId;
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await http.put(
        Uri.parse('$baseUrl?action=update-routine&routine_id=$routineId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating member routine: $e');
      return false;
    }
  }

  // -------------------- PROGRESS AND ANALYTICS FUNCTIONS --------------------

  static Future<Map<String, dynamic>> getMemberProgress(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=member-progress&member_id=$memberId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['progress'] ?? {};
        }
      }
      return {};
    } catch (e) {
      print('Error fetching member progress: $e');
      return {};
    }
  }

  static Future<List<WorkoutSessionModel>> getMemberWorkoutSessions(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=member-sessions&member_id=$memberId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['sessions'] as List? ?? [])
              .map((session) => WorkoutSessionModel.fromJson(session))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching member sessions: $e');
      return [];
    }
  }

  static Future<bool> addSessionFeedback(int sessionId, String feedback, double rating) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return false;
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=session-feedback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'coach_id': coachId,
          'feedback': feedback,
          'rating': rating,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error adding session feedback: $e');
      return false;
    }
  }

  // -------------------- GOAL MANAGEMENT FUNCTIONS --------------------

  static Future<List<GoalModel>> getMemberGoals(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=member-goals&member_id=$memberId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['goals'] as List? ?? [])
              .map((goal) => GoalModel.fromJson(goal))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching member goals: $e');
      return [];
    }
  }

  static Future<bool> createGoalForMember(int memberId, GoalModel goal) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return false;
      
      final goalData = goal.toJson();
      goalData['member_id'] = memberId;
      goalData['created_by_coach'] = coachId;
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=create-goal'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(goalData),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error creating goal for member: $e');
      return false;
    }
  }

  // -------------------- COMMUNICATION FUNCTIONS --------------------

  static Future<bool> sendMessageToMember(int memberId, String message) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return false;
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=send-message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'coach_id': coachId,
          'member_id': memberId,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // -------------------- ADDITIONAL UTILITY FUNCTIONS --------------------

  // Get coach dashboard statistics
  static Future<Map<String, dynamic>> getCoachDashboardStats() async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return {};
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=coach-dashboard-stats&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['stats'] ?? {};
        }
      }
      return {};
    } catch (e) {
      print('Error fetching coach dashboard stats: $e');
      return {};
    }
  }

  // Get member details by ID
  static Future<MemberModel?> getMemberById(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=get-member&member_id=$memberId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['member'] != null) {
          final cleanedMemberData = _cleanMemberData(Map<String, dynamic>.from(data['member']));
          return MemberModel.fromJson(cleanedMemberData);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching member by ID: $e');
      return null;
    }
  }

  // Update member information
  static Future<bool> updateMemberInfo(int memberId, Map<String, dynamic> updates) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return false;
      
      updates['updated_by_coach'] = coachId;
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await http.put(
        Uri.parse('$baseUrl?action=update-member&member_id=$memberId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating member info: $e');
      return false;
    }
  }

  // Search members by name or email
  static Future<List<MemberModel>> searchMembers(String query) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return [];
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=search-members&coach_id=$coachId&query=${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final membersList = data['members'] as List? ?? [];
          
          List<MemberModel> members = [];
          for (var memberData in membersList) {
            try {
              final cleanedMemberData = _cleanMemberData(Map<String, dynamic>.from(memberData));
              final member = MemberModel.fromJson(cleanedMemberData);
              members.add(member);
            } catch (e) {
              print('Error parsing search result member: $e');
              // Continue with other members
            }
          }
          
          return members;
        }
      }
      return [];
    } catch (e) {
      print('Error searching members: $e');
      return [];
    }
  }

  // Get coach profile information
  static Future<Map<String, dynamic>?> getCoachProfile() async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return null;
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=coach-profile&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['profile'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching coach profile: $e');
      return null;
    }
  }

  // Update coach profile
  static Future<bool> updateCoachProfile(Map<String, dynamic> updates) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return false;
      
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await http.put(
        Uri.parse('$baseUrl?action=update-coach-profile&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating coach profile: $e');
      return false;
    }
  }

  // Bulk operations for efficiency
  static Future<bool> bulkApproveMemberRequests(List<int> requestIds) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return false;
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=bulk-approve-requests'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'request_ids': requestIds,
          'coach_id': coachId,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error bulk approving requests: $e');
      return false;
    }
  }

  // Get notification settings
  static Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return null;
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=notification-settings&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['settings'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching notification settings: $e');
      return null;
    }
  }

  // Update notification settings
  static Future<bool> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      final coachId = await getCoachId();
      
      if (coachId == 0) return false;
      
      final response = await http.put(
        Uri.parse('$baseUrl?action=update-notification-settings&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(settings),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating notification settings: $e');
      return false;
    }
  }

}
