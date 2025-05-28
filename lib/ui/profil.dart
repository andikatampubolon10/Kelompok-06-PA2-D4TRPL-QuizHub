import 'package:flutter/material.dart';
import 'package:cbt_app/services/profil_service.dart'; // Pastikan path sesuai
import 'home.dart'; // Ganti dengan path sesuai

class Profil extends StatefulWidget {
  final String idSiswa;  // Terima id_siswa

  const Profil({Key? key, required this.idSiswa}) : super(key: key);

  @override
  _ProfilState createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  late Future<Map<String, String>?> _profilData;  // Menyimpan data profil siswa

  @override
  void initState() {
    super.initState();
    _profilData = ProfilService().getSiswaProfil(widget.idSiswa);  // Ambil data profil siswa berdasarkan id_siswa
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Siswa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: FutureBuilder<Map<String, String>?>(
              future: _profilData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());  // Menunggu data
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));  // Menampilkan error
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: Text('Tidak ada data profil siswa.'));  // Jika data tidak ditemukan
                } else {
                  var profil = snapshot.data!;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar atau ikon pengguna
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Kotak informasi "Nama"
                      InfoCard(
                        icon: Icons.person,
                        label: 'Nama',
                        value: profil['nama_siswa'] ?? '',
                      ),
                      const SizedBox(height: 16),

                      // Kotak informasi "NIS"
                      InfoCard(
                        icon: Icons.badge,
                        label: 'NIS',
                        value: profil['nis'] ?? '',
                      ),
                      const SizedBox(height: 16),

                      // Kotak informasi "Kelas"
                      InfoCard(
                        icon: Icons.class_,
                        label: 'Kelas',
                        value: profil['nama_kelas'] ?? '',
                      ),
                      const SizedBox(height: 32),

                      // Tombol Keluar
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigasi atau log out jika diperlukan
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Keluar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget khusus untuk menampilkan kartu informasi (label dan value)
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
