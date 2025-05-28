import 'package:flutter/material.dart';
import 'package:cbt_app/services/profil_service.dart'; // Ensure this import is correct
import 'main_screen.dart'; // Make sure this is the correct import for the main 
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String idSiswa; // Receive id_siswa from the previous screen

  const ProfileScreen({Key? key, required this.idSiswa}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, String>?> _profileData; // Store profile data

  @override
  void initState() {
    super.initState();
    // Fetch profile data when screen is loaded using id_siswa
    _profileData = ProfilService().getSiswaProfil(widget.idSiswa);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Profil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
        backgroundColor: const Color(0xFF036BB9),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Map<String, String>?>(
            future: _profileData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator()); // Show loading indicator
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}')); // Show error message
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('Tidak ada data profil siswa.')); // Show if no data
              } else {
                var profile = snapshot.data!;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileInfoRow(Icons.person, 'Nama', profile['nama_siswa'] ?? ''),
                    _buildProfileInfoRow(Icons.perm_identity, 'NIS', profile['nis'] ?? ''),
                    _buildProfileInfoRow(Icons.school, 'Kelas', profile['nama_kelas'] ?? ''),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate back to the MainScreen and pass idSiswa
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(), // Pass id_siswa to MainScreen
                          ),
                          (route) => false, // This ensures all previous routes are removed
                        );
                      },
                      icon: const Icon(Icons.exit_to_app,
                      color: Colors.white, 
                      ),
                      label: const Text('Keluar',
                      style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0078D4),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),

                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  // This function builds a row for profile information like Nama, NIS, and Kelas
  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
