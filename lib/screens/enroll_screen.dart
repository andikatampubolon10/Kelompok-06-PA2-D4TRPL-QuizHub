import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EnrollScreen extends StatefulWidget {
  final String courseName;
  final String courseId;
  final String idSiswa;

  const EnrollScreen({
    super.key,
    required this.courseName,
    required this.courseId,
    required this.idSiswa,
  });

  @override
  State<EnrollScreen> createState() => _EnrollScreenState();
}

class _EnrollScreenState extends State<EnrollScreen> {
  final TextEditingController _passwordController = TextEditingController();
  int? _userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Debugging: Tampilkan courseId yang diterima pada terminal
    print("Received courseId: ${widget.courseId}");
    // Load the user ID when the screen initializes
    _loadUserId();
  }

  // Load the user ID from SharedPreferences
  Future<void> _loadUserId() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try different possible keys for user ID
      int? userId;
      
      // Try to get user ID directly
      userId = prefs.getInt('user_id') ?? 
               prefs.getInt('userId') ?? 
               prefs.getInt('id_siswa') ?? 
               prefs.getInt('idSiswa');
      
      // If not found, try to parse from user object
      if (userId == null) {
        final userJson = prefs.getString('user');
        if (userJson != null) {
          try {
            final user = jsonDecode(userJson);
            userId = user['id'] ?? user['user_id'] ?? user['userId'] ?? 
                    user['id_siswa'] ?? user['idSiswa'];
          } catch (e) {
            print("Error parsing user JSON: $e");
          }
        }
      }
      
      // If still not found, try to get from siswa object
      if (userId == null) {
        final siswaJson = prefs.getString('siswa');
        if (siswaJson != null) {
          try {
            final siswa = jsonDecode(siswaJson);
            userId = siswa['id'] ?? siswa['id_siswa'] ?? siswa['idSiswa'];
          } catch (e) {
            print("Error parsing siswa JSON: $e");
          }
        }
      }
      
      // If still not found, use fallback ID for testing
      if (userId == null) {
        userId = 1;
        print("No user ID found, using fallback ID: $userId");
      }
      
      setState(() {
        _userId = userId;
        _isLoading = false;
      });
      
      print("Loaded user ID: $_userId");
    } catch (e) {
      print("Error loading user ID: $e");
      setState(() {
        _isLoading = false;
        _userId = 1; // Fallback to ID 1 in case of error
      });
    }
  }

  // Fungsi untuk memanggil API EnrollKursus
  Future<void> enrollKursus(String password) async {
  // Convert idSiswa to integer if it is a valid number
  int? idSiswaInt = int.tryParse(widget.idSiswa);

  if (idSiswaInt == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid student ID. Please check your ID.')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  var url = Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/kursus/access/${widget.courseId}');

  try {
    print("Attempting to access course with ID: ${widget.courseId}");

    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'password': password,
      }),
    );

    print("Course access response status: ${response.statusCode}");
    print("Course access response body: ${response.body}");

    if (response.statusCode == 200) {
      // If successful, parse response JSON
      var data = jsonDecode(response.body);
      print("Course access successful: $data");

      // Extract course ID and name from response
      int courseIdInt;
      String courseName = data['kursus'] ?? widget.courseName;

      try {
        courseIdInt = data['id_kursus'] ?? int.parse(widget.courseId);
      } catch (e) {
        print("Error parsing course ID: $e");
        // Try to get course ID from the response
        courseIdInt = data['id_kursus'] ?? int.tryParse(widget.courseId) ?? 0;
      }

      print("Using course ID as integer: $courseIdInt");
      print("Using course name: $courseName");

      // Enroll the student using widget.idSiswa (now converted to an integer)
      print("Enrolling user $idSiswaInt in course $courseIdInt");

      var kursusSiswaResponse = await http.post(
        Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/kursus_siswa/enroll'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_siswa': idSiswaInt, // Use the converted integer value
          'id_kursus': courseIdInt, // Send as integer, not string
        }),
      );

      print("Enrollment response status: ${kursusSiswaResponse.statusCode}");
      print("Enrollment response body: ${kursusSiswaResponse.body}");

      if (kursusSiswaResponse.statusCode == 200) {
        // Save the newly enrolled course details to SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();

          // Get existing enrolled courses or create new list
          List<String> enrolledCourses = prefs.getStringList('enrolled_courses') ?? [];

          // Create a course object with all necessary details
          Map<String, dynamic> courseDetails = {
            'id_kursus': courseIdInt,
            'nama_kursus': courseName,
            'enrollment_date': DateTime.now().toIso8601String(),
          };

          // Add to the list and save
          enrolledCourses.add(jsonEncode(courseDetails));
          await prefs.setStringList('enrolled_courses', enrolledCourses);

          print("Saved enrolled course: $courseDetails");
        } catch (e) {
          print("Error saving enrolled course: $e");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully enrolled in the course!')),
        );

        // Return the course details to the previous screen
        Navigator.pop(context, {
          'success': true,
          'id_kursus': courseIdInt,
          'nama_kursus': courseName,
        });
      } else {
        // Try to parse error message from response
        String errorMsg = 'Failed to enroll in the course.';
        try {
          var errorData = jsonDecode(kursusSiswaResponse.body);
          if (errorData['error'] != null) {
            errorMsg = 'Error: ${errorData['error']}';
          }
        } catch (e) {
          print("Error parsing error response: $e");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );

        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect password. Status: ${response.statusCode}')),
      );

      setState(() {
        _isLoading = false;
      });
    }
  } catch (e) {
    print("Error during enrollment: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );

    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0078D4),
        title: Text(
          'Enroll Course',
          style: TextStyle(
            fontSize: 20,              // Set font size to 20
            fontWeight: FontWeight.w400, // Set font weight to normal (400)
            fontFamily: 'Poppins',      // Set the font family to Poppins
            color: Colors.white,       // Set text color to white
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class and Year info (sementara statis ya)
              
              const SizedBox(height: 32),

              // Title "Self Enrolment Student"
              const Center(
                child: Text(
                  'Self Enrolment Student',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User ID info
              if (_userId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  
                ),

              // Password Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Masukkan password course',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0078D4),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Password',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _userId == null
                        ? null // Disable button if user ID is not found
                        : () {
                          // Cek password dan enroll
                          if (_passwordController.text.isNotEmpty) {
                            enrollKursus(_passwordController.text);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password tidak boleh kosong!')),
                            );
                          }
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0078D4),
                        minimumSize: const Size(double.infinity, 48),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: const Text(
                        'Submit',
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
        ),
    );
  }
}