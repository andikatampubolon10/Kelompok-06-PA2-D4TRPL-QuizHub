import 'package:flutter/material.dart';
import 'raport_detail_screen.dart';
import 'package:cbt_app/services/raport_service.dart';

class RaportCourseScreen extends StatefulWidget {
  final String idSiswa; // Add idSiswa parameter

  const RaportCourseScreen({super.key, required this.idSiswa});

  @override
  State<RaportCourseScreen> createState() => _RaportCourseScreenState();
}

class _RaportCourseScreenState extends State<RaportCourseScreen> {
  bool _showDetail = false;
  String _selectedYear = '';
  String _selectedGrade = '';
  String _selectedSubject = '';
  String _selectedKursusId = '';

  final RaportService _raportService = RaportService();
  late Future<List<Map<String, dynamic>>> _courses;
  bool _isLoading = true;
  late String _userId;

  @override
  void initState() {
    super.initState();
    // Use the passed idSiswa to load the courses
    _userId = widget.idSiswa;
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    setState(() {
      _courses = _raportService.getKursusBySiswa(_userId);
      _isLoading = false;
    });
  }

  void _openDetail(String year, String grade, String subject, String kursusId) {
    setState(() {
      _showDetail = true;
      _selectedYear = year;
      _selectedGrade = grade;
      _selectedSubject = subject;
      _selectedKursusId = kursusId;
    });
  }

  void _backToCourse() {
    setState(() {
      _showDetail = false;
      _selectedYear = '';
      _selectedGrade = '';
      _selectedSubject = '';
      _selectedKursusId = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Raport',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
        leading: _showDetail
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _backToCourse,
              )
            : null,
        backgroundColor: const Color(0xFF036BB9),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _showDetail
            ? RaportDetailScreen(
                year: _selectedYear,
                grade: _selectedGrade,
                subject: _selectedSubject,
                idSiswa: _userId,
                idKursus: _selectedKursusId,
              )
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCourseList(),
      ),
    );
  }

  Widget _buildCourseList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _courses,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _courses = _raportService.getKursusBySiswa(_userId);
                    });
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Tidak ada kursus yang diikuti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anda belum mengikuti kursus apapun',
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
                      _courses = _raportService.getKursusBySiswa(_userId);
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(
                            'Refresh',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0078D4),
                  ),
                ),
              ],
            ),
          );
        } else {
          final courses = snapshot.data!;
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final kursusId = course['id_kursus']?.toString() ?? '';
              final kursusName = course['nama_kursus']?.toString() ?? 'Kursus Tanpa Nama';

              // For demonstration purposes, we'll use placeholder data for year and grade
              // In a real app, you would get this from the API
              final year = '2024 / 2025';
              final grade = 'Kelas 9';

              return _buildCourseCard(year, grade, kursusName, kursusId);
            },
          );
        }
      },
    );
  }

  Widget _buildCourseCard(String year, String grade, String subject, String kursusId) {
    return GestureDetector(
      onTap: () => _openDetail(year, grade, subject, kursusId),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use a placeholder icon if the image is not available
            Icon(
              Icons.menu_book,
              size: 48,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(year, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(grade, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subject, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
