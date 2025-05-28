import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RaportService {
  // Base URL for the API
  final String baseUrl = 'https://kelompok06-trpl23-api-golang-production.up.railway.app';

  // Get courses enrolled by a student
  Future<List<Map<String, dynamic>>> getKursusBySiswa(String idSiswa) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kursus-siswa/$idSiswa'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map && data.containsKey('kursus') && data['kursus'] is List) {
          final List<dynamic> kursusList = data['kursus'];
          return kursusList.map((kursus) => Map<String, dynamic>.from(kursus)).toList();
        } else if (data is List) {
          return data.map((kursus) => Map<String, dynamic>.from(kursus)).toList();
        } else {
          return [];
        }
      } else {
        print('Failed to load courses: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  // Get exam results for a specific course
  Future<List<Map<String, dynamic>>> getExamResults(String idSiswa, String idKursus) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kursus/detail/$idSiswa/$idKursus'),
        headers: {
          'Content-Type': 'application/json',
          // Add any auth headers if needed
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Get the nilai_list (scores)
        final List<dynamic> nilaiList = data['nilai_list'] ?? [];
        
        // Get the ujian_list (exams with complete data)
        final List<dynamic> ujianList = data['ujian_list'] ?? [];
        
        // Create a map of exam IDs to exam names for quick lookup
        final Map<int, Map<String, dynamic>> examMap = {};
        for (var ujian in ujianList) {
          examMap[ujian['id_ujian']] = ujian;
        }
        
        // Combine the data from nilai_list with the exam names from ujian_list
        final List<Map<String, dynamic>> results = [];
        for (var nilai in nilaiList) {
          final int examId = nilai['id_ujian'];
          final examData = examMap[examId];
          
          if (examData != null) {
            results.add({
              'id_ujian': examId,
              'nama_ujian': examData['nama_ujian'],
              'nilai': nilai['nilai'],
              'tipe_ujian': examData['tipe_ujian'] ?? {},
            });
          }
        }
        
        return results;
      } else {
        throw Exception('Failed to load exam results: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching exam results: $e');
    }
  }

  Future<double> getTotalNilai(String idSiswa, String idKursus) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nilai-kursus-siswa/$idKursus/$idSiswa'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Debugging untuk melihat struktur data
        print("Received data: $data");

        // Periksa apakah 'nilai_total_per_tipe_ujian' ada di dalam response
        if (data['nilai'] != null) {
          List<dynamic> nilaiList = data['nilai'];

          // Debugging nilai yang diterima
          print("Received nilai list: $nilaiList");

          // Ambil nilai total jika ada
          double totalNilai = 0.0;
          for (var nilai in nilaiList) {
            double nilaiTotal = (nilai['nilai_total'] as num?)?.toDouble() ?? 0.0;
            totalNilai += nilaiTotal;
            print("Adding $nilaiTotal to total score");
          }

          // Debugging total nilai yang dihitung
          print("Total calculated score: $totalNilai");

          return totalNilai;
        } else {
          return 0.0; // Return 0 jika tidak ada data nilai
        }
      } else {
        print('Failed to load total score: ${response.statusCode}');
        return 0.0; // Return 0 jika response gagal
      }
    } catch (e) {
      print('Error fetching total score: $e');
      return 0.0; // Return 0 jika terjadi kesalahan
    }
  }


  // Get current user ID from SharedPreferences
  Future<String> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      return userId.toString();
    } catch (e) {
      print('Error getting user ID: $e');
      return '0';
    }
  }
}
