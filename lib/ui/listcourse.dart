import 'package:flutter/material.dart';

class CourseListScreen extends StatefulWidget {
  // final String semester;

  const CourseListScreen({super.key,});

  @override
  _CourseListScreenState createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final List<Course> courses = [
    Course(
      title: "Ilmu Pengetahuan Alam",
      kelas: "Kelas 9",
      year: "2024/2025",
      imagePath: "assets/images/ipa.jpg",
    ),
    Course(
      title: "Seni Budaya",
      kelas: "Kelas 9",
      year: "2024/2025",
      imagePath: "assets/images/sbd.jpg",
    ),
    Course(
      title: "Pendidikan Agama",
      kelas: "Kelas 9",
      year: "2024/2025",
      imagePath: "assets/images/agama.jpg",
    ),
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredCourses = courses.where((course) {
      return course.title.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // title: Text("List Course - ${widget.semester}"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search course",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredCourses.length,
                itemBuilder: (context, index) {
                  return CourseCard(course: filteredCourses[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Course {
  final String title;
  final String kelas;
  final String year;
  final String imagePath;

  Course({
    required this.title,
    required this.kelas,
    required this.year,
    required this.imagePath,
  });
}

class CourseCard extends StatelessWidget {
  final Course course;

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                course.imagePath,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course.kelas,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            Text(
              "${course.year} - ${course.title}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => EnrollCourseScreen(
                  //       kelas: course.kelas,
                  //       year: course.year,
                  //       courseTitle: course.title,
                  //     ),
                  //   ),
                  // );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Enroll"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
