import 'dart:convert';
import 'package:http/http.dart' as http;

class SoalJawaban {
  final Soal soal;
  final List<Jawaban> jawaban;

  SoalJawaban({required this.soal, required this.jawaban});

  factory SoalJawaban.fromJson(Map<String, dynamic> json) {
    return SoalJawaban(
      soal: Soal.fromJson(json['soal']),
      jawaban: (json['jawaban'] as List)
          .map((item) => Jawaban.fromJson(item))
          .toList(),
    );
  }
}

class Soal {
  final String idSoal;
  final String soal;
  final int idTipeSoal; // ← ganti dari idTipeUjian ke idTipeSoal

  Soal({
    required this.idSoal,
    required this.soal,
    required this.idTipeSoal,
  });

  factory Soal.fromJson(Map<String, dynamic> json) {
    return Soal(
      idSoal: json['id_soal'],
      soal: json['soal'],
      idTipeSoal: json['id_tipe_soal'], // ← ambil dari API
    );
  }
}

Future<SoalJawaban> fetchQuestionsAndAnswers(String idSoal) async {
  final response = await http.get(Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/soal/${idSoal}'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return SoalJawaban.fromJson(data);
  } else {
    throw Exception('Gagal memuat soal dan jawaban');
  }
}

class Jawaban {
  final String idJawaban;
  final String jawaban;
  final bool benar;

  Jawaban({
    required this.idJawaban,
    required this.jawaban,
    required this.benar,
  });

  factory Jawaban.fromJson(Map<String, dynamic> json) {
    return Jawaban(
      idJawaban: json['id_jawaban'],
      jawaban: json['jawaban'],
      benar: json['benar'],
    );
  }
}
