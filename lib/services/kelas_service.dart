import 'dart:convert';
import 'package:http/http.dart' as http;

 // Import the Kelas model
class Kelas {
  final String idKelas; // Assuming `idKelas` is a String
  final String namaKelas;

  Kelas({required this.idKelas, required this.namaKelas});

  // Factory constructor to create Kelas from JSON
  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      idKelas: json['id_kelas'].toString(),
      namaKelas: json['nama_kelas'],
    );
  }
}


class KelasService {
  final String baseUrl = 'https://kelompok06-trpl23-api-golang-production.up.railway.app'; // Your API base URL

  // Fetch all classes from the API
  Future<List<Kelas>> fetchKelas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/kelas'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Extract the list of kelas from the response and create Kelas objects
        final kelasList = (data['kelas'] as List)
            .map((kelas) => Kelas.fromJson(kelas))
            .toList();

        return kelasList;
      } else {
        throw Exception('Failed to load Kelas');
      }
    } catch (e) {
      print('Error fetching kelas: $e');
      return [];
    }
  }
}
