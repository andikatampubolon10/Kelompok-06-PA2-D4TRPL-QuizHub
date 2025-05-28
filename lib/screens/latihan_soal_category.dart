import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Untuk decoding JSON
import 'latihan_soal_screen.dart';

class LatihanSoalCategory extends StatelessWidget {
  final String year;
  final String className;
  final String idKurikulum;
  final String idKelas;
  final String idMataPelajaran;

  const LatihanSoalCategory({
    super.key,
    required this.year,
    required this.className,
    required this.idKurikulum,
    required this.idKelas,
    required this.idMataPelajaran,
  });

  Future<List<Map<String, dynamic>>> fetchLatihanSoal(String idKurikulum, String idKelas, String idMataPelajaran) async {
    try {
      final url = 'https://kelompok06-trpl23-api-golang-production.up.railway.app/api/latihan-soal/$idKurikulum/$idKelas/$idMataPelajaran';
      print('Fetching from URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data'); // Debug: Print the full response

        if (data['latihan_soal'] != null) {
          final latihanSoalList = List<Map<String, dynamic>>.from(data['latihan_soal'].map((soal) {
            // Try to get the topic name from either 'Topik' or 'nama_latihan' field
            String topicName = 'No Name';
            if (soal['Topik'] != null) {
              topicName = soal['Topik'].toString();
            } else if (soal['topik'] != null) {
              topicName = soal['topik'].toString();
            } else if (soal['nama_latihan'] != null) {
              topicName = soal['nama_latihan'].toString();
            }

            // Only include the essential fields we need
            return {
              'nama_latihan': topicName,
              'id_latihan': soal['id_latihan']?.toString() ?? '',
              'mata_pelajaran': soal['mata_pelajaran']?.toString() ?? 'Umum',
            };
          }));

          print('Processed latihan soal list: $latihanSoalList'); // Debug: Print processed list
          return latihanSoalList;
        } else {
          print('No latihan_soal field found in response');
          // Check if the data structure is different
          if (data is List) {
            // If the API returns a direct list instead of an object with 'latihan_soal' field
            final latihanSoalList = List<Map<String, dynamic>>.from(data.map((soal) {
              // Try to get the topic name from either 'Topik' or 'nama_latihan' field
              String topicName = 'No Name';
              if (soal['Topik'] != null) {
                topicName = soal['Topik'].toString();
              } else if (soal['topik'] != null) {
                topicName = soal['topik'].toString();
              } else if (soal['nama_latihan'] != null) {
                topicName = soal['nama_latihan'].toString();
              }

              // Only include the essential fields we need
              return {
                'nama_latihan': topicName,
                'id_latihan': soal['id_latihan']?.toString() ?? '',
                'mata_pelajaran': soal['mata_pelajaran']?.toString() ?? 'Umum',
              };
            }));
            
            print('Processed direct list: $latihanSoalList'); // Debug: Print processed list
            return latihanSoalList;
          }
          throw Exception('No latihan soal found in response');
        }
      } else {
        print('Failed to load latihan soal: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load latihan soal');
      }
    } catch (e) {
      print('Error fetching latihan soal: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latihan Soal'),
        backgroundColor: const Color(0xFF0078D4),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchLatihanSoal(idKurikulum, idKelas, idMataPelajaran), // Ambil data
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
                      // Refresh the data
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LatihanSoalCategory(
                            year: year,
                            className: className,
                            idKurikulum: idKurikulum,
                            idKelas: idKelas,
                            idMataPelajaran: idMataPelajaran,
                          ),
                        ),
                      );
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
                  const Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada latihan soal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Latihan soal untuk mata pelajaran ini belum tersedia',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Refresh the data
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LatihanSoalCategory(
                            year: year,
                            className: className,
                            idKurikulum: idKurikulum,
                            idKelas: idKelas,
                            idMataPelajaran: idMataPelajaran,
                          ),
                        ),
                      );
                    },
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
            List<Map<String, dynamic>> latihanSoalList = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: latihanSoalList.length,
              itemBuilder: (context, index) {
                final latihanSoal = latihanSoalList[index];
                
                // Get only the topic name for display
                final topicName = latihanSoal['nama_latihan'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: const Color(0xFFF0F8FF),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0078D4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assignment, size: 32, color: Color(0xFF0078D4)),
                    ),
                    title: Text(
                      topicName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Remove the subtitle to avoid showing unwanted fields
                    trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF0078D4)),
                    onTap: () {
                      // Fixed navigation by passing all required parameters
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LatihanSoalScreen(
                            title: topicName, // Use the topic name as title
                            subject: idMataPelajaran, // Use idMataPelajaran since we're not showing mata_pelajaran anymore
                            gradeLevel: int.tryParse(idKelas) ?? 0, // Convert idKelas to int or use 0 as fallback
                            idLatihan: latihanSoal['id_latihan'], // Pass the idLatihan
                            // idSiswa is optional, so we don't need to pass it
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
