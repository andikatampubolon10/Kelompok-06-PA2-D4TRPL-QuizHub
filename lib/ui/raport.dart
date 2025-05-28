import 'package:flutter/material.dart';
import 'buttomnav.dart';
import 'raport1.dart';

class MedalPage extends StatelessWidget {
  const MedalPage({Key? key}) : super(key: key);

  final List<Map<String, String>> _courses = const [
    {
      'tahun': '2024 / 2025',
      'kelas': 'Kelas 9',
      'mapel': 'Ilmu Pengetahuan Alam',
    },
    {
      'tahun': '2024 / 2025',
      'kelas': 'Kelas 9',
      'mapel': 'Matematika',
    },
    {
      'tahun': '2024 / 2025',
      'kelas': 'Kelas 9',
      'mapel': 'Ilmu Pengetahuan Sosial',
    },
    {
      'tahun': '2024 / 2025',
      'kelas': 'Kelas 9',
      'mapel': 'Bahasa Indonesia',
    },
    {
      'tahun': '2024 / 2025',
      'kelas': 'Kelas 9',
      'mapel': 'Bahasa Inggris',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raport Course'),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: ListTile(
              leading: Image.asset(
                'assets/images/medali.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
              title: Text(
                course['tahun'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course['kelas'] ?? ''),
                  Text(course['mapel'] ?? ''),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RaportCoursePage(
                      tahun: course['tahun'] ?? '',
                      kelas: course['kelas'] ?? '',
                      mapel: course['mapel'] ?? '',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      // bottomNavigationBar: const Sidebar(),
    );
  }
}
