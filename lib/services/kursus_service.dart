import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KursusService {
  final String _baseUrl = 'https://kelompok06-trpl23-api-golang-production.up.railway.app'; // Replace with your API URL

  // Get all courses for a student
  Future<List<Course>> getKursusBySiswa(BuildContext context, String idSiswa) async {
  // Mengambil data kursus berdasarkan id_siswa dari kursus_siswa
  var url = Uri.parse('$_baseUrl/kursus-siswa/$idSiswa'); // Endpoint yang mengambil kursus berdasarkan id_siswa

  try {
    print("Fetching courses for student ID: $idSiswa");
    var response = await http.get(url);
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      // Check if 'kursus' is null or empty
      if (data['kursus'] == null) {
        print("No courses available.");
        return []; // Return empty list if kursus is null
      }

      List<dynamic> kursusData = data['kursus'];  // Mendapatkan data kursus dari response

      List<Course> kursusList = [];
      for (var kursus in kursusData) {
        print("Processing course data: $kursus");

        // Pastikan kita mengambil id_kursus yang sesuai
        int idKursus = kursus['id_kursus'] ?? 0;
        String namaKursus = kursus['nama_kursus'] ?? 'Unknown Course';
        String imageUrl = kursus['image_url'] ?? '';  // Menggunakan image_url sekarang

        // Menambahkan kursus yang valid
        if (idKursus > 0) {
          kursusList.add(Course(idKursus: idKursus, namaKursus: namaKursus, imageUrl: imageUrl));
        } else {
          print("Skipping course with invalid id_kursus: $idKursus");
        }
      }
      return kursusList;
    } else {
      print("Failed to load courses: ${response.statusCode}");
      return []; // Return empty list if response is not 200
    }
  } catch (e) {
    print("Error: $e");
    return []; // Return empty list if an error occurs
  }
}


  
  // Get a single course by ID
  Future<Course> getKursusById(String idKursus) async {
    var url = Uri.parse('$_baseUrl/kursus/$idKursus');
    
    try {
      print("Fetching course with ID: $idKursus");
      var response = await http.get(url);
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("Course data: $data");
        
        // Create a course object with the correct ID and name
        return Course(
          idKursus: int.tryParse(idKursus) ?? 0,
          namaKursus: data['nama_kursus'] ?? 'Course $idKursus',
          imageUrl: data['image_url'] ?? '',  // Menggunakan image_url
        );
      } else {
        print("API error: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load course: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching course: $e");
      throw Exception('Failed to load course: $e');
    }
  }
  
  // Add a course to the cache
  Future<void> addCourseToCache(Course course) async {
    try {
      List<Course> cachedCourses = await _getCachedCourses() ?? [];
      
      // Check if the course already exists in the cache
      bool courseExists = cachedCourses.any((c) => c.idKursus == course.idKursus);
      
      if (!courseExists) {
        cachedCourses.add(course);
        await _cacheCourses(cachedCourses);
        print("Added course to cache: ID=${course.idKursus}, Name=${course.namaKursus}");
      } else {
        print("Course already exists in cache: ID=${course.idKursus}");
      }
    } catch (e) {
      print("Error adding course to cache: $e");
    }
  }
  
  // Cache courses in SharedPreferences
  Future<void> _cacheCourses(List<Course> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = courses.map((course) => course.toJson()).toList();
      await prefs.setString('cached_courses', jsonEncode(coursesJson));
      print("Cached ${courses.length} courses");
    } catch (e) {
      print("Error caching courses: $e");
    }
  }
  
  // Get cached courses from SharedPreferences
  Future<List<Course>?> _getCachedCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = prefs.getString('cached_courses');
      if (coursesJson != null) {
        final List<dynamic> decoded = jsonDecode(coursesJson);
        var courses = decoded.map((json) => Course.fromJson(json)).toList();
        print("Retrieved ${courses.length} courses from cache");
        return courses;
      }
      print("No cached courses found");
      return null;
    } catch (e) {
      print("Error getting cached courses: $e");
      return null;
    }
  }
  
  // Clear the course cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_courses');
      print("Course cache cleared");
    } catch (e) {
      print("Error clearing course cache: $e");
    }
  }
}

class Course {
  final int idKursus;
  final String namaKursus;
  final String imageUrl;

  Course({
    required this.idKursus,
    required this.namaKursus,
    required this.imageUrl,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    // IMPORTANT: Always use id_kursus, not id_kursus_siswa
    var idKursus = json['id_kursus'];
    
    // Handle different types of id_kursus
    int parsedId;
    if (idKursus is int) {
      parsedId = idKursus;
    } else if (idKursus is String) {
      parsedId = int.tryParse(idKursus) ?? 0;
    } else {
      parsedId = 0;
    }
    
    // Make sure we have a valid course name
    String namaKursus = json['nama_kursus'] ?? '';
    if (namaKursus.isEmpty) {
      // If nama_kursus is empty, try to get it from other fields
      namaKursus = json['kursus'] ?? json['nama'] ?? 'Course $parsedId';
    }
    
    return Course(
      idKursus: parsedId,
      namaKursus: namaKursus,
      imageUrl: json['image_url'] ?? '',  // Menggunakan image_url sekarang
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id_kursus': idKursus,
      'nama_kursus': namaKursus,
      'image_url': imageUrl,  // Menggunakan image_url

    };
  }
}