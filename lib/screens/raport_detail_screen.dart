import 'package:flutter/material.dart';
import 'package:cbt_app/services/raport_service.dart';

class RaportDetailScreen extends StatefulWidget {
  final String year;
  final String grade;
  final String subject;
  final String idSiswa;
  final String idKursus;

  const RaportDetailScreen({
    super.key,
    required this.year,
    required this.grade,
    required this.subject,
    required this.idSiswa,
    required this.idKursus,
  });

  @override
  State<RaportDetailScreen> createState() => _RaportDetailScreenState();
}

class _RaportDetailScreenState extends State<RaportDetailScreen> {
  final RaportService _raportService = RaportService();
  late Future<List<Map<String, dynamic>>> _examResults;
  bool _isLoading = true;

  double _finalScore = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExamResults();
    _loadFinalScore();
  }

  Future<void> _loadExamResults() async {
    setState(() {
      _examResults = _raportService.getExamResults(widget.idSiswa, widget.idKursus);
      _isLoading = false;
    });
  }

  Future<void> _loadFinalScore() async {
    try {
      // Ambil total nilai berdasarkan id_siswa dan id_kursus
      double totalScore = await _raportService.getTotalNilai(widget.idSiswa, widget.idKursus);
      setState(() {
        _finalScore = totalScore;  // Set nilai yang diterima ke _finalScore
      });
    } catch (e) {
      print("Error loading final score: $e");
      // Menangani error jika tidak ada data atau kesalahan lainnya
      setState(() {
        _finalScore = 0.0;  // Reset ke 0 jika terjadi error
      });
    }
  }

  // Calculate final score from all exams
  double calculateFinalScore(List<Map<String, dynamic>> exams) {
    if (exams.isEmpty) return 0;

    double totalScore = 0;
    for (var exam in exams) {
      totalScore += (exam['nilai'] as num?)?.toDouble() ?? 0;
    }

    return totalScore / exams.length;
  }

  // Convert score to grade
  String getGrade(double score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'E';
  }

   @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : FutureBuilder<List<Map<String, dynamic>>>(
            future: _examResults,
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
                        onPressed: _loadExamResults,
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
                      const Icon(Icons.assessment_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum ada nilai untuk kursus ini',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Anda belum mengikuti ujian atau kuis apapun',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadExamResults,
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
                final exams = snapshot.data!;
                final finalScore = calculateFinalScore(exams);
                final grade = getGrade(finalScore);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(widget.year, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(widget.grade, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(widget.subject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 24),
                      ...exams.map((exam) {
                        final examTitle = exam['nama_ujian']?.toString() ?? 'Ujian';
                        final score = (exam['nilai'] as num?)?.toInt() ?? 0;
                        return _buildProgressItem(examTitle, score);
                      }).toList(),
                      const SizedBox(height: 32),
                      _buildFinalScoreBox(finalScore.toInt(), grade),
                    ],
                  ),
                );
              }
            },
          );
  }

  Widget _buildProgressItem(String title, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0078D4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$score/100', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinalScoreBox(int finalScore, String grade) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Text('Nilai Akhir', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '$_finalScore',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.blue.shade300,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Text('Grade', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    grade,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}