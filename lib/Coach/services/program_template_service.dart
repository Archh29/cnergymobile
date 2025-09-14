import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/program_template_model.dart';
import '../models/member_model.dart';
import './coach_service.dart';

class ProgramTemplateService {
  static const String baseUrl = 'https://api.cnergy.site/coach_api.php';

  // Get coach's program templates
  static Future<List<ProgramTemplateModel>> getCoachProgramTemplates() async {
    try {
      final coachId = await CoachService.getCoachId();
      
      if (coachId == 0) {
        print('Error: No valid coach ID found');
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=coach-program-templates&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Debug: Program templates response status: ${response.statusCode}');
      print('Debug: Program templates response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final templatesList = data['templates'] as List? ?? [];
          print('Debug: Found ${templatesList.length} program templates');
          
          List<ProgramTemplateModel> templates = [];
          for (var templateData in templatesList) {
            try {
              final template = ProgramTemplateModel.fromJson(templateData);
              templates.add(template);
            } catch (e) {
              print('Error parsing program template: $e');
            }
          }
          
          return templates;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching program templates: $e');
      return [];
    }
  }

  static Future<List<MemberModel>> getAvailableMembers() async {
    try {
      final coachId = await CoachService.getCoachId();
      
      if (coachId == 0) {
        print('Error: No valid coach ID found');
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=available-members&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final membersList = data['members'] as List? ?? [];
          
          List<MemberModel> members = [];
          for (var memberData in membersList) {
            try {
              final member = MemberModel.fromJson(memberData);
              members.add(member);
            } catch (e) {
              print('Error parsing member: $e');
            }
          }
          
          return members;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching available members: $e');
      return [];
    }
  }

  static Future<bool> assignProgramToMember(String templateId, int memberId) async {
    try {
      final coachId = await CoachService.getCoachId();
      
      if (coachId == 0) return false;
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=assign-program-to-member'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'template_id': templateId,
          'member_id': memberId,
          'coach_id': coachId,
          'assigned_at': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error assigning program to member: $e');
      return false;
    }
  }

  // Duplicate a program template
  static Future<bool> duplicateProgramTemplate(String templateId, String newName) async {
    try {
      final coachId = await CoachService.getCoachId();
      
      if (coachId == 0) return false;
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=duplicate-program-template'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'template_id': templateId,
          'new_name': newName,
          'coach_id': coachId,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error duplicating program template: $e');
      return false;
    }
  }

  // Delete program template
  static Future<bool> deleteProgramTemplate(String templateId) async {
    try {
      final coachId = await CoachService.getCoachId();
      
      if (coachId == 0) return false;
      
      final response = await http.delete(
        Uri.parse('$baseUrl?action=delete-program-template&template_id=$templateId&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting program template: $e');
      return false;
    }
  }

  // Create a new program template
  static Future<bool> createProgramTemplate(ProgramTemplateModel template) async {
    try {
      final coachId = await CoachService.getCoachId();
      
      if (coachId == 0) return false;
      
      final templateData = template.toJson();
      templateData['coach_id'] = coachId;
      templateData['created_at'] = DateTime.now().toIso8601String();
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=create-program-template'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(templateData),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error creating program template: $e');
      return false;
    }
  }

  // Update program template
  static Future<bool> updateProgramTemplate(String templateId, Map<String, dynamic> updates) async {
    try {
      final coachId = await CoachService.getCoachId();
      
      if (coachId == 0) return false;
      
      updates['updated_by_coach'] = coachId;
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await http.put(
        Uri.parse('$baseUrl?action=update-program-template&template_id=$templateId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating program template: $e');
      return false;
    }
  }

  // Get popular/public program templates
  static Future<List<ProgramTemplateModel>> getPublicProgramTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=public-program-templates'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final templatesList = data['templates'] as List? ?? [];
          
          List<ProgramTemplateModel> templates = [];
          for (var templateData in templatesList) {
            try {
              final template = ProgramTemplateModel.fromJson(templateData);
              templates.add(template);
            } catch (e) {
              print('Error parsing public program template: $e');
            }
          }
          
          return templates;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching public program templates: $e');
      return [];
    }
  }
}
