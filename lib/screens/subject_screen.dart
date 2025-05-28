import 'package:flutter/material.dart';
import '../widgets/subject_item.dart';
import '../models/subject_data.dart';
import 'practice_screen.dart';
import '../widgets/custom_bottom_navigation.dart';

class SubjectScreen extends StatefulWidget {
  final int gradeLevel;

  const SubjectScreen({
    super.key,
    required this.gradeLevel,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final subjects = SubjectData().getSubjectsForGrade(widget.gradeLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Latihan Soal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        backgroundColor: const Color(0xFF0078D4),
        elevation: 0,
      ),
      body: subjects.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              itemCount: subjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return SubjectItem(
                  subject: subjects[index].name,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PracticeScreen(
                          subject: subjects[index].name,
                          gradeLevel: widget.gradeLevel,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/grade_selection');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/raport_course');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/explore');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book_outlined,
              size: 64,
              color: Color(0xFF0078D4),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada mata pelajaran untuk Kelas ${widget.gradeLevel}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan pilih kelas lain atau hubungi administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0078D4),
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
