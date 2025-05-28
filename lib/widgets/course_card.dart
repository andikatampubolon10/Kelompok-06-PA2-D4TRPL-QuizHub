import 'package:flutter/material.dart';
import 'package:cbt_app/screens/home_detail_screen.dart';

class CourseCard extends StatelessWidget {
  final String idKursus;
  final String namaKursus;
  final int idSiswa;
  final String imageUrl;
  final String grade;
  final String year;
  final String subject;

  const CourseCard({
    Key? key,
    required this.idKursus,
    required this.namaKursus,
    required this.idSiswa,
    required this.imageUrl,
    required this.grade,
    required this.year,
    required this.subject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Log the course details for debugging
    print("Building CourseCard with ID: ${int.tryParse(idKursus) ?? 0}, Name: $namaKursus");
    
    // Parse the course ID
    int parsedId = int.tryParse(idKursus) ?? 0;
    
    // Validate the course ID
    if (parsedId <= 0) {
      print("Warning: Invalid course ID: $parsedId");
    }
    
    // Use a fallback name if the course name is empty
    String displayName = namaKursus.isNotEmpty ? namaKursus : "Unknown Course";
    
    // Ensure that even if id_kursus_siswa does not match id_kursus, the course still appears
    if (parsedId == 0) {
      // If ID is 0, set a fallback name or keep it as 'Unknown Course'
      displayName = "Course ID: $idKursus (Invalid or not found)";
    }
    
    return GestureDetector(
      onTap: () {
        // Only navigate if the course ID is valid
        if (parsedId > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeDetailScreen(
                idKursus: idKursus,
                idSiswa: idSiswa,
                kelas: grade,
                tahunAjaran: year,
                mataPelajaran: subject,
                namaKursus: displayName,
              ),
            ),
          );
        } else {
          // Show an error message if the course ID is invalid
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open course with invalid ID')),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading image: $error");
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
            // Course Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Grade and Year     
                  const SizedBox(height: 8),
                  // Subject
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
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
