import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JawabanSiswaService {
  // Base URL for the API
  final String baseUrl = 'https://kelompok06-trpl23-api-golang-production.up.railway.app/api';

  // Get all jawaban latihan by latihan ID
  Future<List<Map<String, dynamic>>?> getJawabanLatihanByLatihanId(String latihanId) async {
    try {
      // Updated to use the new endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/jawaban-latihan/latihan/$latihanId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        print('Failed to get jawaban latihan by latihan ID: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting jawaban latihan by latihan ID: $e');
      return null;
    }
  }

  // Updated method to get soal with jawaban by latihan ID using the new API endpoint
  Future<List<Map<String, dynamic>>?> getSoalWithJawabanByLatihanId(String latihanId) async {
    try {
      // Updated to use the new endpoint structure
      final response = await http.get(
        Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/soal-latihan/$latihanId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> soalData = data['data'] ?? [];
        
        // Debug: Print the raw response to see its structure
        print("API Response: ${response.body}");
        
        // Return the data as is, since it's already in the format we need
        return List<Map<String, dynamic>>.from(soalData);
      } else {
        print('Failed to get soal with jawaban by latihan ID: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting soal with jawaban by latihan ID: $e');
      return null;
    }
  }

  // Helper method to get the current user ID from SharedPreferences
  Future<int?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try different keys that might store the user ID
      int? userId = prefs.getInt('user_id');
      if (userId == null) {
        userId = prefs.getInt('id_siswa');
      }
      if (userId == null) {
        userId = prefs.getInt('siswa_id');
      }
      if (userId == null) {
        // Try to get it as a string and convert to int
        String? userIdStr = prefs.getString('user_id');
        if (userIdStr != null) {
          userId = int.tryParse(userIdStr);
        }
      }
      
      // If still null, check if we have a user object stored as JSON
      if (userId == null) {
        String? userJson = prefs.getString('user');
        if (userJson != null) {
          try {
            Map<String, dynamic> userData = jsonDecode(userJson);
            userId = userData['id'] ?? userData['id_siswa'] ?? userData['siswa_id'];
          } catch (e) {
            print('Error parsing user JSON: $e');
          }
        }
      }
      
      return userId;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  // Submit latihan answers - this is a mock implementation that doesn't actually save to the database
  Future<bool> submitLatihanAnswers({
    required String idLatihan,
    required List<Map<String, dynamic>> questions,
    required List<String?> selectedAnswers,
  }) async {
    try {
      // For practice exercises, we don't need to save answers to the database
      // Just return success
      return true;
    } catch (e) {
      print('Error submitting latihan answers: $e');
      return false;
    }
  }
}
