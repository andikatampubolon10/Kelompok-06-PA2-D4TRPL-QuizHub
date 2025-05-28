import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JawabanSiswaNilaiService {
  final String _baseUrl = 'https://kelompok06-trpl23-api-golang-production.up.railway.app'; // Ganti dengan URL API Anda

  // Mendapatkan jawaban siswa berdasarkan id_siswa dan id_ujian
  Future<List<JawabanSiswa>> getJawabanSiswa(BuildContext context, String idSiswa, String idUjian) async {
    var url = Uri.parse('$_baseUrl/jawaban-siswa/$idUjian/$idSiswa'); // Endpoint API

    try {
      print("Fetching answers for student ID: $idSiswa and exam ID: $idUjian");
      var response = await http.get(url);
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<dynamic> jawabanData = data['jawaban'];  // Mendapatkan data jawaban siswa dari response

        List<JawabanSiswa> jawabanList = [];
        for (var jawaban in jawabanData) {
          jawabanList.add(JawabanSiswa.fromJson(jawaban));
        }
        return jawabanList;
      } else {
        throw Exception('Failed to load student answers');
      }
    } catch (e) {
      print("Error: $e");
      throw Exception('Error fetching student answers: $e');
    }
  }

  // Fungsi untuk menghitung nilai total siswa
  double hitungNilaiTotal(List<JawabanSiswa> jawabanList) {
    double totalNilai = 0;

    // Menambahkan nilai_per_soal jika benar = true
    for (var jawaban in jawabanList) {
      if (jawaban.benar) {
        totalNilai += jawaban.nilaiPerSoal;
      }
    }
    
    return totalNilai;
  }

  // Fungsi untuk menjumlahkan nilai berdasarkan kondisi benar = true (1)
  double hitungNilaiByBenarTrue(List<JawabanSiswa> jawabanList) {
    double totalNilai = 0;

    // Menjumlahkan nilai_per_soal jika benar = true (1)
    for (var jawaban in jawabanList) {
      if (jawaban.benar == true) { // atau bisa menggunakan `jawaban.benar == 1` jika benar = 1
        totalNilai += jawaban.nilaiPerSoal;
      }
    }

    return totalNilai;
  }
}

class JawabanSiswa {
  final int idJawabanSiswa;
  final String jawabanSiswa;
  final bool benar; // Menggunakan bool, bisa jadi true atau false
  final double nilaiPerSoal;
  final int idSoal;
  final int idSiswa;
  final int idUjian;
  final int idJawabanSoal;
  final bool grade;

  JawabanSiswa({
    required this.idJawabanSiswa,
    required this.jawabanSiswa,
    required this.benar,
    required this.nilaiPerSoal,
    required this.idSoal,
    required this.idSiswa,
    required this.idUjian,
    required this.idJawabanSoal,
    required this.grade,
  });

  // Factory method untuk membuat objek JawabanSiswa dari JSON
  factory JawabanSiswa.fromJson(Map<String, dynamic> json) {
    return JawabanSiswa(
      idJawabanSiswa: json['id_jawaban_siswa'],
      jawabanSiswa: json['jawaban_siswa'],
      benar: json['benar'], // Menggunakan boolean true/false
      nilaiPerSoal: json['nilai_per_soal'].toDouble(),
      idSoal: json['id_soal'],
      idSiswa: json['id_siswa'],
      idUjian: json['id_ujian'],
      idJawabanSoal: json['id_jawaban_soal'],
      grade: json['grade'],
    );
  }

  // Convert JawabanSiswa ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id_jawaban_siswa': idJawabanSiswa,
      'jawaban_siswa': jawabanSiswa,
      'benar': benar,
      'nilai_per_soal': nilaiPerSoal,
      'id_soal': idSoal,
      'id_siswa': idSiswa,
      'id_ujian': idUjian,
      'id_jawaban_soal': idJawabanSoal,
      'grade': grade,
    };
  }
}
