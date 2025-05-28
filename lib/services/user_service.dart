import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = 'https://kelompok06-trpl23-api-golang-production.up.railway.app'; // Your backend base URL

  Future<String?> fetchUserName(String idSiswa) async {
  var url = Uri.parse('$baseUrl/profil/$idSiswa');
  print('Fetching user from $url');

  try {
    final response = await http.get(url);
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['nama_siswa'];
    } else {
      return 'Gagal ambil data: ${response.statusCode}';
    }
  } catch (e) {
    print('Exception occurred: $e');
    return 'Exception: $e';
  }
}

}
