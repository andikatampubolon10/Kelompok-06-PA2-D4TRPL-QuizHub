import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class Soal {
  final int idSoal;
  final String soal;
  final int idTipeSoal;
  final List<Jawaban> jawaban;

  Soal({
    required this.idSoal,
    required this.soal,
    required this.idTipeSoal,
    required this.jawaban,
  });

  factory Soal.fromJson(Map<String, dynamic> json) {
    var jawabanList = (json['jawaban'] as List)
        .map((jawabanJson) => Jawaban.fromJson(jawabanJson))
        .toList();

    return Soal(
      idSoal: json['id_soal'],
      soal: json['soal'],
      idTipeSoal: json['id_tipe_soal'],
      jawaban: jawabanList,
    );
  }
}

class Jawaban {
  final int idJawabanSoal;
  final String jawaban;
  final bool benar;

  Jawaban({
    required this.idJawabanSoal,
    required this.jawaban,
    required this.benar,
  });

  factory Jawaban.fromJson(Map<String, dynamic> json) {
    return Jawaban(
      idJawabanSoal: json['id_jawaban_soal'],
      jawaban: json['jawaban'],
      benar: json['benar'],
    );
  }
}


class SoalService {
  // Fungsi untuk mengambil soal dan jawaban berdasarkan idUjian
  Future<Soal> getSoalByUjian(int idUjian) async {
    final response = await http.get(
      Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/soal/$idUjian'), // Ganti dengan URL API yang sesuai
    );

    if (response.statusCode == 200) {
      // Parsing JSON dan mengembalikan objek Soal
      return Soal.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load questions and answers');
    }
  }
}