import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilService {
  final String baseUrl = 'https://kelompok06-trpl23-api-golang-production.up.railway.app';  // Replace with your actual API URL

  // Fetch the profile data using id_siswa
  Future<Map<String, String>?> getSiswaProfil(String idSiswa) async {
    var url = Uri.parse('$baseUrl/profil/$idSiswa');  // API endpoint for fetching student profile

    try {
      // Sending GET request to fetch the profile
      var response = await http.get(url);

      // Check if the request was successful
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // Ensure the API returned valid data (you could check for specific fields too)
        if (data != null) {
          return {
            'nama_siswa': data['nama_siswa'] ?? 'Tidak ada nama',  // Default value if not available
            'nis': data['nis']?.toString() ?? 'NIS tidak tersedia', // Default value for NIS
            'nama_kelas': data['nama_kelas'] ?? 'Kelas tidak ditemukan', // Default value for Kelas
          };
        } else {
          throw Exception('Data profil siswa tidak tersedia');
        }
      } else {
        throw Exception('Failed to load profil: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors that occur during the request
      throw Exception('Error fetching profil: $e');
    }
  }
}
