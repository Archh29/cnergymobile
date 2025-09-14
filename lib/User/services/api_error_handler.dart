import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiErrorHandler {
  /// Safely decode JSON response, handling HTML error pages
  static Map<String, dynamic>? safeJsonDecode(String responseBody) {
    try {
      // Check if response looks like HTML
      if (responseBody.trim().startsWith('<!DOCTYPE') || 
          responseBody.trim().startsWith('<html') ||
          responseBody.trim().startsWith('<')) {
        print('⚠️ API returned HTML instead of JSON: ${responseBody.substring(0, 100)}...');
        return {
          'success': false,
          'message': 'Server returned HTML error page instead of JSON',
          'error': 'HTML_RESPONSE',
          'html_preview': responseBody.substring(0, 200)
        };
      }
      
      // Try to decode as JSON
      return json.decode(responseBody);
    } catch (e) {
      print('❌ JSON decode error: $e');
      print('Response body: ${responseBody.substring(0, 200)}...');
      return {
        'success': false,
        'message': 'Invalid JSON response from server',
        'error': 'JSON_DECODE_ERROR',
        'raw_response': responseBody.substring(0, 200)
      };
    }
  }

  /// Make HTTP request with better error handling
  static Future<Map<String, dynamic>?> makeRequest(
    String url, {
    Map<String, String>? headers,
    String? body,
    String method = 'GET',
  }) async {
    try {
      print('🌐 Making $method request to: $url');
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body,
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            Uri.parse(url),
            headers: headers ?? {'Content-Type': 'application/json'},
          );
          break;
        default:
          response = await http.get(
            Uri.parse(url),
            headers: headers ?? {'Content-Type': 'application/json'},
          );
      }

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response headers: ${response.headers}');
      
      // Handle different status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return safeJsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'API endpoint not found (404)',
          'error': 'NOT_FOUND',
          'status_code': response.statusCode
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'Internal server error (500)',
          'error': 'SERVER_ERROR',
          'status_code': response.statusCode,
          'response_preview': response.body.substring(0, 200)
        };
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'error': 'HTTP_ERROR',
          'status_code': response.statusCode,
          'response_preview': response.body.substring(0, 200)
        };
      }
    } catch (e) {
      print('❌ Request exception: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NETWORK_ERROR'
      };
    }
  }

  /// Test API endpoint connectivity
  static Future<bool> testEndpoint(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      print('🧪 Endpoint test: $url -> ${response.statusCode}');
      return response.statusCode < 500; // Consider 4xx as "working" endpoint
    } catch (e) {
      print('❌ Endpoint test failed: $url -> $e');
      return false;
    }
  }
}






