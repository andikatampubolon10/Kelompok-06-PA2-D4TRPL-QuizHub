import 'dart:convert';
import 'package:http/http.dart' as http;

class MataPelajaran {
  final String idMataPelajaran;
  final String namaMataPelajaran;

  MataPelajaran({required this.idMataPelajaran, required this.namaMataPelajaran});

  // Factory constructor to create MataPelajaran from JSON
  factory MataPelajaran.fromJson(Map<String, dynamic> json) {
    return MataPelajaran(
      idMataPelajaran: json['id_mata_pelajaran'].toString(),
      namaMataPelajaran: json['nama_mata_pelajaran'],
    );
  }
}

Future<List<MataPelajaran>> fetchMataPelajaran(String idKurikulum) async {
  try {
    final response = await http.get(
      Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/mata-pelajaran/$idKurikulum'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['mata_pelajaran'] != null) {
        // Map the response to a list of MataPelajaran objects
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

