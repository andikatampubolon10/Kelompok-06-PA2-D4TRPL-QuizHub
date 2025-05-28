import 'package:flutter/material.dart';
import '../widgets/grade_folder_item.dart';
import '../models/subject_data.dart';
import 'subject_screen.dart';

class GradeSelectionScreen extends StatelessWidget {
  const GradeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get all available grades from the data model
    final List<int> grades = SubjectData().getAllGrades();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0078D4),
          ),
          child: const Text(
            'Latihan Soal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),

        // List Grade
        Expanded(
          child: Container(
            color: const Color(0xFFF0F8FF),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              itemCount: grades.length,
              itemBuilder: (context, index) {
                final grade = grades[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GradeFolderItem(
                    grade: 'Kelas $grade',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectScreen(gradeLevel: grade),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
