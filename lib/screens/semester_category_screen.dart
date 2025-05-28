import 'package:flutter/material.dart';
import 'latihan_soal_category.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For decoding JSON
import 'package:cbt_app/services/mata_pelajaran_service.dart';

class MataPelajaranCategoryScreen extends StatelessWidget {
  final String year;
  final String className;
  final String idKurikulum;  
  final String idKelas; 

  const MataPelajaranCategoryScreen({
    super.key,
    required this.year,
    required this.className,
    required this.idKurikulum, 
    required this.idKelas,
  });

  // Fetch mata pelajaran based on id_kurikulum
  Future<List<MataPelajaran>> fetchMataPelajaran(String idKurikulum) async {
    try {
      final response = await http.get(
        Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/mata-pelajaran/$idKurikulum'), 
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['mata_pelajaran'] != null) {
          final mataPelajaranList = (data['mata_pelajaran'] as List)
              .map((mapel) => MataPelajaran.fromJson(mapel))
              .toList();

          return mataPelajaranList;
        } else {
          throw Exception('No mata pelajaran found in response');
        }
      } else {
        throw Exception('Failed to load mata pelajaran');
      }
    } catch (e) {
      print('Error fetching mata pelajaran: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Kelas', 
          style: TextStyle(
          fontSize: 20.0,
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: const Color(0xFF0078D4),
      ),
      body: FutureBuilder<List<MataPelajaran>>(
        future: fetchMataPelajaran(idKurikulum), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No mata pelajaran found'));
          } else {
            List<MataPelajaran> mataPelajaranList = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mataPelajaranList.length,
              itemBuilder: (context, index) {
                return Card(
                  color: const Color(0xFFF0F8FF),
                  child: ListTile(
                    leading: const Icon(Icons.book, size: 32, color: Color(0xFF0078D4)),
                    title: Text(mataPelajaranList[index].namaMataPelajaran),
                    onTap: () {
                      // Pass idKurikulum, idKelas, and selected mataPelajaran to LatihanSoalCategory
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LatihanSoalCategory(
                            year: year,
                            className: className,
                            idKurikulum: idKurikulum,  // Pass idKurikulum
                            idKelas: idKelas,           // Pass idKelas
                             idMataPelajaran: mataPelajaranList[index].idMataPelajaran, // Pass selected mataPelajaran's id
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
