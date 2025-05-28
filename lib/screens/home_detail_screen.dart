  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';
  import 'MateriDetailScreen.dart';  // Import MateriDetailScreen
  import 'introduction_screen.dart';  // Import IntroductionScreen
  import 'package:cbt_app/services/jawaban_siswa_service.dart'; // Import the service

  class HomeDetailScreen extends StatefulWidget {
    final String idKursus;
    final int idSiswa;
    final String? kelas;
    final String? tahunAjaran;
    final String? mataPelajaran;
    final String? namaKursus;

    const HomeDetailScreen({
      super.key,
      required this.idKursus,
      required this.idSiswa,
      this.kelas = 'Kelas 9',
      this.tahunAjaran = '2024/2025',
      this.mataPelajaran,
      this.namaKursus,
    });

    @override
    State<HomeDetailScreen> createState() => _HomeDetailScreenState();
  }

  class _HomeDetailScreenState extends State<HomeDetailScreen> {
    late Future<List<Map<String, dynamic>>> _items;
    late Future<Map<String, dynamic>> _kursusData;
    bool _isLoading = true;
    String _namaKursus = '';
    String _errorMessage = '';
    int _courseId = 0;
    Map<String, bool> _attemptedQuizzes = {}; // Track attempted quizzes
    final JawabanSiswaService _jawabanSiswaService = JawabanSiswaService(); // Add service instance

    @override
    void initState() {
      super.initState();
      print('ID Siswa yang diterima: ${widget.idSiswa}');
      _initializeScreen();

    }

    // Improve the _initializeScreen method to ensure we're getting the latest attempt status
    Future<void> _initializeScreen() async {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Parse the course ID to ensure it's an integer
        _courseId = _parseKursusId(widget.idKursus);
        print("Parsed id_kursus: $_courseId");

        if (_courseId <= 0) {
          throw Exception("Invalid course ID: $_courseId");
        }

        // First try to get course data from cache
        final cachedData = await _getCachedCourseData(_courseId);
        if (cachedData != null) {
          setState(() {
            _namaKursus = cachedData['nama_kursus'] ?? widget.namaKursus ?? 'Unknown Course';
          });
        } else if (widget.namaKursus != null && widget.namaKursus!.isNotEmpty) {
          // Use the provided course name if available
          setState(() {
            _namaKursus = widget.namaKursus!;
          });
        } else {
          // Fetch course name from API if not cached
          _kursusData = fetchKursusData(_courseId.toString());
          final data = await _kursusData;
          setState(() {
            _namaKursus = data['nama_kursus'] ?? 'Unknown Course';
          });
        }

        // Fetch items (materials and exams)
        _items = fetchData(_courseId.toString());
      
        // Get current user ID
        final userId = await _jawabanSiswaService.getCurrentUserId();
        final int siswaId = userId ?? 1;
      
        // Fetch the items first
        final items = await _items;
      
        // Check which quizzes have been attempted - ALWAYS fetch fresh data here
        Map<String, bool> attemptedQuizzes = {};
        for (var item in items) {
          if (item['type'] == 'quiz' || item['type'] == 'exam') {
            final idUjian = item['id_ujian']?.toString() ?? '0';
            // Always check with the server, don't use cached values
            final hasAttempted = await _jawabanSiswaService.hasStudentTakenQuiz(
              idUjian,
              siswaId,
            );
            attemptedQuizzes[idUjian] = hasAttempted;
            print('Quiz ID: $idUjian, Attempted: $hasAttempted');
          }
        }
      
        setState(() {
          _attemptedQuizzes = attemptedQuizzes;
          _isLoading = false;
        });
      } catch (e) {
        print("Error initializing screen: $e");
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }

    int _parseKursusId(String idKursus) {
      try {
        // Try to parse the ID as an integer
        return int.parse(idKursus);
      } catch (e) {
        print("Error parsing course ID: $e");
        // Return 0 or another default value to indicate an error
        return 0;
      }
    }

    Future<Map<String, dynamic>?> _getCachedCourseData(int courseId) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Try to get the specific course
        final courseJson = prefs.getString('course_$courseId');
        if (courseJson != null) {
          return jsonDecode(courseJson);
        }
        
        // Try to get from cached courses list
        final coursesJson = prefs.getString('cached_courses');
        if (coursesJson != null) {
          final List<dynamic> courses = jsonDecode(coursesJson);
          final course = courses.firstWhere(
            (c) => c['id_kursus'] == courseId,
            orElse: () => null,
          );
          return course;
        }
        
        return null;
      } catch (e) {
        print("Error getting cached course data: $e");
        return null;
      }
    }

    Future<Map<String, dynamic>> fetchKursusData(String idKursus) async {
      var url = Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/kursus/$idKursus');

      try {
        var response = await http.get(url);
        print("Kursus API response status: ${response.statusCode}");
        print("Kursus API response body: ${response.body}");
        
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          
          // Cache the course data
          _cacheCourseData(idKursus, data);
          
          return data;
        } else {
          throw Exception('Failed to load kursus data');
        }
      } catch (e) {
        print("Error fetching kursus data: $e");
        throw Exception('Error fetching kursus data: $e');
      }
    }

    Future<void> _cacheCourseData(String idKursus, Map<String, dynamic> data) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('course_$idKursus', jsonEncode(data));
      } catch (e) {
        print("Error caching course data: $e");
      }
    }

    Future<List<Map<String, dynamic>>> fetchData(String idKursus) async {
      var url = Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/ujian-materi-kursus/$idKursus');

      try {
        var response = await http.get(url);
        print("Items API response status: ${response.statusCode}");
        print("Items API response body: ${response.body}");

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          print("Decoded API data: $data");

          List<dynamic> materiData = data['materi'] ?? [];
          List<dynamic> ujianData = data['ujian'] ?? [];

          List<Map<String, dynamic>> combinedList = [];

          // Process materi data
          for (var materi in materiData) {
            combinedList.add({
              'title': materi['judul_materi'] ?? 'No Title',
              'type': 'material',
              'icon': Icons.menu_book,
              'description': materi['deskripsi'] ?? 'No Description',
              'file_url': materi['file_url'] ?? '',
            });
          }

          // Process ujian data
          for (var ujian in ujianData) {
            print("Ujian Data: $ujian");

            combinedList.add({
              'title': ujian['nama_ujian'] ?? 'No Title',
              'type': ujian['tipe_ujian'] == 1 ? 'quiz' : 'exam',
              'icon': ujian['tipe_ujian'] == 1 ? Icons.assignment : Icons.assessment,
              'id_ujian': ujian['id_ujian']?.toString() ?? '0', // Keep as string
              'tipe_ujian': ujian['tipe_ujian'] ?? 0,
              'waktu_mulai': ujian['waktu_mulai'] ?? '',
              'waktu_selesai': ujian['waktu_selesai'] ?? '',
              'durasi': ujian['durasi'] ?? 0,
            });
          }

          return combinedList;
        } else {
          throw Exception('Failed to load data');
        }
      } catch (e) {
        print("Error fetching data: $e");
        throw Exception('Error fetching data: $e');
      }
    }

    // Show warning dialog for attempted quizzes
    void _showAttemptedQuizWarning(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text('Ujian Sudah Dikerjakan'),
              ],
            ),
            content: Text(
              'Anda sudah mengerjakan ujian ini sebelumnya. Ujian hanya dapat dikerjakan satu kali.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      if (_isLoading) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFF036BB9),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Loading...', style: TextStyle(color: Colors.white)),
          ),
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (_errorMessage.isNotEmpty) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFF036BB9),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Error', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $_errorMessage'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _initializeScreen,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _namaKursus,
                style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF036BB9),
          toolbarHeight: 70,
        ),
        body: Container(
          color: const Color(0xFFF0F8FF),
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _items,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${snapshot.error}'),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _initializeScreen,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Tidak ada materi atau ujian tersedia.'));
              } else {
                var items = snapshot.data!;
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final bool isExam = item['type'] == 'exam';
                    final String idUjian = item['id_ujian']?.toString() ?? '0';
                    final bool hasAttempted = _attemptedQuizzes[idUjian] ?? false;
                    
                    return GestureDetector(
                      onTap: () {
                        // Navigate based on the type of item
                        if (item['type'] == 'material') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MateriDetailScreen(
                                title: item['title'],
                                description: item['description'],
                                file_url: item['file_url'],
                              ),
                            ),
                          );
                        } else if (item['type'] == 'quiz' || item['type'] == 'exam') {
                          // Check if the quiz has been attempted
                          if (hasAttempted) {
                            // Show warning dialog
                            _showAttemptedQuizWarning(context);
                          } else {
                            // Get the id_ujian as a string
                            final idUjian = item['id_ujian']?.toString() ?? '0';
                            print("Navigating with id_ujian: $idUjian");
                            
                            // Debug the value and type
                            print("id_ujian type: ${idUjian.runtimeType}");
                            print("id_ujian value: $idUjian");
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IntroductionScreen(
                                  title: item['title'] ?? 'No Title',
                                  subject: widget.mataPelajaran ?? _namaKursus,
                                  gradeLevel: 10,
                                  idKursus: widget.idKursus,
                                  idSiswa: widget.idSiswa,
                                  idUjian: item['id_ujian']?.toString() ?? '0', // Ensure this is a String
                                  idTipeUjian: item['tipe_ujian'] is int ? item['tipe_ujian'] : 0, // Ensure this is an int
                                  waktuMulai: item['waktu_mulai']?.toString() ?? '',
                                  waktuSelesai: item['waktu_selesai']?.toString() ?? '',
                                  durasi: item['durasi'] is int ? item['durasi'] : 0,
                                ),
                              ),
                            ).then((_) {
                              // Refresh the screen when returning from the quiz
                              _initializeScreen();
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(hasAttempted ? 0.5 : 0.95), // Blur effect for attempted quizzes
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isExam ? Colors.red.shade200 : Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isExam ? Colors.red.shade100 : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item['icon'],
                                color: isExam ? Colors.red : Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: hasAttempted ? Colors.black45 : Colors.black87, // Dimmed text for attempted quizzes
                                    ),
                                  ),
                                  if (hasAttempted && (item['type'] == 'quiz' || item['type'] == 'exam'))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Sudah dikerjakan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (hasAttempted && (item['type'] == 'quiz' || item['type'] == 'exam'))
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      );
    }
  }
