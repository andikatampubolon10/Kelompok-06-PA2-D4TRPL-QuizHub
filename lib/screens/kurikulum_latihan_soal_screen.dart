import 'package:flutter/material.dart';
import 'package:cbt_app/services/kurikulum_service.dart';  // Import the KurikulumService
import 'package:cbt_app/screens/class_category_screen.dart';  // Import the ClassCategoryScreen



class KurikulumLatihanSoalScreen extends StatefulWidget {
  const KurikulumLatihanSoalScreen({super.key});

  @override
  _KurikulumLatihanSoalScreenState createState() =>
      _KurikulumLatihanSoalScreenState();
}

class _KurikulumLatihanSoalScreenState
    extends State<KurikulumLatihanSoalScreen> {
  late Future<List<Kurikulum>> _kurikulumList;

  @override
  void initState() {
    super.initState();
    // Fetch the kurikulum data when the screen loads
    _kurikulumList = KurikulumService().fetchKurikulum();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF036BB9),
          ),
          child: const Text(
            'Latihan Soal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
        ),

        // Displaying Kurikulum Data
        Expanded(
          child: FutureBuilder<List<Kurikulum>>(
            future: _kurikulumList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No Kurikulum available.'));
              } else {
                var kurikulumList = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  itemCount: kurikulumList.length,
                  itemBuilder: (context, index) {
                    var kurikulum = kurikulumList[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildGradeFolderItem(
                        kurikulum.namaKurikulum,
                        () {
                          // Pass the idKurikulum to ClassCategoryScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClassCategoryScreen(
                                year: '2025', // Pass the year if needed, or use dynamic logic for the year
                                idKurikulum: kurikulum.idKurikulum.toString(), // Pass the idKurikulum here
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
        ),
      ],
    );
  }

  Widget _buildGradeFolderItem(String grade, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.folder, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                grade,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
