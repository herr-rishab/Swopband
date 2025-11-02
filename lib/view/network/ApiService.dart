import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  static Future<Map<String, String>> _buildHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final firebaseId = prefs.getString("firebase_id") ?? "";

    return {
      'Content-Type': 'application/json',
      'firebase_id': firebaseId,
    };
  }

  static Future<http.Response?> post(String url, Map<String, dynamic> data) async {
    try {
      final headers = await _buildHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
      return response;
    } catch (e) {
      print("❌ POST Error: $e");
      return null;
    }
  }

  /// Multipart POST request (for file uploads)
  static Future<http.Response?> multipartPost(
    String url, {
    required Map<String, String> fields,
    File? file,
    String fileFieldName = 'profile',
    String? filename,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firebaseId = prefs.getString("firebase_id") ?? "";

      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      // Headers: do NOT set Content-Type; MultipartRequest sets it
      request.headers.addAll({
        'firebase_id': firebaseId,
      });

      request.fields.addAll(fields);

      if (file != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          fileFieldName,
          file.path,
          filename: filename,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response;
    } catch (e) {
      print("❌ MULTIPART POST Error: $e");
      return null;
    }
  }

  /// Multipart PUT request (for file uploads during updates)
  static Future<http.Response?> multipartPut(
    String url, {
    required Map<String, String> fields,
    File? file,
    String fileFieldName = 'profile',
    String? filename,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firebaseId = prefs.getString("firebase_id") ?? "";

      final uri = Uri.parse(url);
      final request = http.MultipartRequest('PUT', uri);

      // Headers: do NOT set Content-Type; MultipartRequest sets it
      request.headers.addAll({
        'firebase_id': firebaseId,
      });

      request.fields.addAll(fields);

      if (file != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          fileFieldName,
          file.path,
          filename: filename,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response;
    } catch (e) {
      print("❌ MULTIPART PUT Error: $e");
      return null;
    }
  }

  /// Multipart POST with update header (fallback for PUT issues)
  static Future<http.Response?> multipartPostWithUpdate(
    String url, {
    required Map<String, String> fields,
    File? file,
    String fileFieldName = 'profile',
    String? filename,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firebaseId = prefs.getString("firebase_id") ?? "";

      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      // Headers: do NOT set Content-Type; MultipartRequest sets it
      request.headers.addAll({
        'firebase_id': firebaseId,
        'X-HTTP-Method-Override': 'PUT', // Some backends use this
        'X-Requested-With': 'XMLHttpRequest',
      });

      request.fields.addAll(fields);

      if (file != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          fileFieldName,
          file.path,
          filename: filename,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response;
    } catch (e) {
      print("❌ MULTIPART POST WITH UPDATE Error: $e");
      return null;
    }
  }


  /// GET request
  static Future<http.Response?> get(String url) async {
    final headers = await _buildHeaders();
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return response;
    } catch (e) {
      print("❌ GET Error: $e");
      return null;
    }
  }

  /// PUT request
  static Future<http.Response?> put(String url, Map<String, dynamic> data) async {
    try {
      final headers = await _buildHeaders();
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
      return response;
    } catch (e) {
      print("❌ PUT Error: $e");
      return null;
    }
  }

  /// DELETE request
  static Future<http.Response?> delete(String url,
      {Map<String, dynamic>? data}) async {
    try {
      final headers = await _buildHeaders();

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      );
      return response;
    } catch (e) {
      print("❌ DELETE Error: $e");
      return null;
    }
  }

  /*final response = await ApiService.post(ApiUrls.userEndpoint, {
  "username": "frr",
  "name": "pff",
  "email": "ranga@gmail.com",
  "bio": "about me11",
  "profile_url": "https://..."
  });

  if (response != null) {
  final statusCode = response.statusCode;

  if (statusCode == 200 || statusCode == 201) {
  final data = jsonDecode(response.body);
  print("✅ Success: ${data['message'] ?? 'User created'}");
  // Access response fields: data['id'], data['name'], etc.
  } else if (statusCode == 400) {
  final error = jsonDecode(response.body);
  print("❌ Validation error: ${error['error'] ?? 'Invalid request'}");
  } else if (statusCode == 401) {
  print("❌ Unauthorized: Please log in again.");
  } else {
  print("❌ Unexpected error: ${response.body}");
  }
  } else {
  print("❌ No response received from server.");
  }*/

}
