import 'package:flutter/material.dart';

class RaportCoursePage extends StatelessWidget {
  final String tahun;
  final String kelas;
  final String mapel;

  const RaportCoursePage({
    Key? key,
    required this.tahun,
    required this.kelas,
    required this.mapel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Raport Course'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dinamis
              Text(
                tahun,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kelas,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                mapel,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Quiz & ujian
              buildScoreSection(
                title: 'Quiz 1 - Sistem Pencernaan',
                score: 45,
                maxScore: 100,
              ),
              buildScoreSection(
                title: 'Quiz 2 - Sistem Pernapasan',
                score: 50,
                maxScore: 100,
              ),
              buildScoreSection(
                title: 'Ujian Tengah Semester',
                score: 75,
                maxScore: 100,
              ),
              buildScoreSection(
                title: 'Ujian Akhir Semester',
                score: 80,
                maxScore: 100,
              ),

              const SizedBox(height: 32),
              // Nilai akhir dan grade
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: const [
                        Text(
                          'Nilai Akhir',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '65',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey,
                    ),
                    Column(
                      children: const [
                        Text(
                          'Grade',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'B',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildScoreSection({
    required String title,
    required double score,
    required double maxScore,
  }) {
    final progressValue = score / maxScore;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              Text('${score.toInt()} / ${maxScore.toInt()}'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressValue,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }
}
