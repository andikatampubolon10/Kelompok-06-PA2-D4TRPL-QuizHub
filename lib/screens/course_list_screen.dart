import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'enroll_screen.dart';

// Gantilah URL ini dengan URL yang sesuai dengan API Anda
const String apiUrl = 'https://kelompok06-trpl23-api-golang-production.up.railway.app/kursus/available/'; // Endpoint baru

class CourseListScreen extends StatefulWidget {
  final String idSiswa; // Tambahkan id_siswa sebagai parameter
  const CourseListScreen({super.key, required this.idSiswa}); // Menerima id_siswa

  @override
  _CourseListScreenState createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  String searchQuery = '';
  late Future<List<Map<String, dynamic>>> _courses;

  @override
  void initState() {
    super.initState();
    _courses = fetchCourses(widget.idSiswa); // Memanggil fungsi untuk fetch data kursus sesuai id_siswa
  }

  Future<List<Map<String, dynamic>>> fetchCourses(String idSiswa) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl$idSiswa')); // Mengambil data kursus berdasarkan id_siswa

      // Debugging: Print status code and body of the response
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body); // Parse the response body

        // Debugging: Check the structure of the data
        print("Decoded data: $data");

        List<Map<String, dynamic>> courses = [];

        // Check if data is a List directly (no 'kursus' wrapper)
        if (data is List) {
          // If the API returns a list directly
          for (var kursus in data) {
            if (kursus is Map) {
              // Debug each course item
              print("Processing course item: $kursus");
              
              // Try multiple possible field names for course title
              String title = '';
              if (kursus['nama_kursus'] != null) {
                title = kursus['nama_kursus'].toString();
              } else if (kursus['name'] != null) {
                title = kursus['name'].toString();
              } else if (kursus['judul'] != null) {
                title = kursus['judul'].toString();
              } else if (kursus['title'] != null) {
                title = kursus['title'].toString();
              }
              
              print("Extracted title: '$title'");

              // Now using 'image_url' instead of 'image' for the image URL
              String imageUrl = kursus['image_url'] ?? '';

              courses.add({
                'id_kursus': kursus['id_kursus']?.toString() ?? '',
                'image_url': imageUrl, // Use 'image_url' now
                'title': title,
              });
            }
          }
        } 
        // Check if 'kursus' key exists and is a List
        else if (data is Map && data['kursus'] is List) {
          for (var kursus in data['kursus']) {
            if (kursus is Map) {
              // Debug each course item
              print("Processing course item from 'kursus' array: $kursus");
              
              // Try multiple possible field names for course title
              String title = '';
              if (kursus['nama_kursus'] != null) {
                title = kursus['nama_kursus'].toString();
              } else if (kursus['name'] != null) {
                title = kursus['name'].toString();
              } else if (kursus['judul'] != null) {
                title = kursus['judul'].toString();
              } else if (kursus['title'] != null) {
                title = kursus['title'].toString();
              }

              print("Extracted title: '$title'");

              // Now using 'image_url' instead of 'image' for the image URL
              String imageUrl = kursus['image_url'] ?? '';

              courses.add({
                'id_kursus': kursus['id_kursus']?.toString() ?? '',
                'image_url': imageUrl, // Use 'image_url' now
                'title': title,
              });
            }
          }
        } else if (data is Map && (data['message'] == 'No courses available' || 
                                  data['message'] == 'No available courses found')) {
          // Handle the case where the API explicitly returns a message indicating no courses
          print("API returned no courses message");
          return []; // Return empty list instead of throwing an exception
        } else if (data is Map && data.isEmpty) {
          // Handle empty object response
          print("API returned empty object");
          return []; // Return empty list
        } else if (data is List && data.isEmpty) {
          // Handle empty array response
          print("API returned empty array");
          return []; // Return empty list
        } else {
          // If we can't understand the data format, return empty list instead of throwing
          print("Unknown data format, returning empty list");
          return [];
        }

        // Print final courses list for debugging
        print("Final courses list: $courses");
        return courses;
      } else if (response.statusCode == 404) {
        // Handle 404 Not Found - likely means no courses available
        print("404 Not Found - No courses available");
        return []; // Return empty list instead of throwing
      } else {
        print("API error: ${response.statusCode}");
        return []; // Return empty list instead of throwing
      }
    } catch (e) {
      print("Error fetching courses: $e"); // Display error
      // Return empty list instead of re-throwing the exception
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'List Kursus',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
        backgroundColor: const Color(0xFF0078D4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search course',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // List Courses
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _courses, // Menampilkan data dari API
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator()); // Menampilkan loading saat data sedang diambil
                  } else if (snapshot.hasError) {
                    // Show a more user-friendly error message
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Terjadi kesalahan: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _courses = fetchCourses(widget.idSiswa);
                              });
                            },
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    // Show a more user-friendly message when no courses are available
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada kursus yang belum di enroll',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Semua kursus yang tersedia sudah Anda enroll',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _courses = fetchCourses(widget.idSiswa);
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0078D4),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final courses = snapshot.data!.where((course) {
                      final title = course['title'] as String? ?? '';
                      return title.toLowerCase().contains(searchQuery.toLowerCase()); // Filter data berdasarkan search query
                    }).toList();

                    if (courses.isEmpty) {
                      // No courses match the search query
                      return const Center(
                        child: Text(
                          'Tidak ada kursus yang sesuai dengan pencarian',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        final title = course['title'] as String? ?? '';
                        final imageUrl = course['image_url'] as String? ?? '';  // Now using image_url
                        final idKursus = course['id_kursus'] as String? ?? '';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              // Course Image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        height: 120,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 120,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(Icons.image_not_supported, size: 40),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        height: 120,
                                        color: Colors.blue[100],
                                        child: const Center(
                                          child: Icon(Icons.menu_book, size: 40, color: Colors.blue),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),

                              // Course Information
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Menyebar elemen secara horisontal
                                  children: [
                                    // Title di kiri
                                    Expanded(
                                      child: Text(
                                        title.isNotEmpty ? title : "No Title",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                    // Enroll Button di kanan
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EnrollScreen(
                                              courseName: title,
                                              courseId: idKursus,
                                              idSiswa: widget.idSiswa, // Pass idSiswa (pastikan ini adalah id_siswa yang benar)
                                            ),
                                          ),

                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0078D4),
                                      ),
                                      child: const Text(
                                        'Enroll',
                                        style: TextStyle(
                                          color: Colors.white,  // Change the text color to white
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),  
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
