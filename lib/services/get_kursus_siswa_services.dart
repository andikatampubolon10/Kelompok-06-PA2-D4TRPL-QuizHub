import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = 'https://kelompok06-trpl23-api-golang-production.up.railway.app';  // Ganti dengan URL yang sesuai

  Future<List<String>> getKursusBySiswa(String idSiswa) async {
    var url = Uri.parse('$_baseUrl/kursus-siswa/$idSiswa');  // Endpoint untuk mengambil kursus siswa

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<String> kursusList = [];
      for (var kursus in data['kursus']) {
        kursusList.add(kursus['nama_kursus']);
      }
      return kursusList;
    } else {
      throw Exception('Failed to load kursus');
    }
  }
}
