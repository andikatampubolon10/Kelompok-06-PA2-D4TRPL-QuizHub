import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

// Model Kursus untuk menampung data kursus
class Kursus {
  final String namaKursus;
  final String image;

  Kursus({required this.namaKursus, required this.image});

  factory Kursus.fromJson(Map<String, dynamic> json) {
    return Kursus(
      namaKursus: json['nama_kursus'],
      image: json['image'],
    );
  }
}

class KursusService {
  // Fungsi untuk mengambil kursus berdasarkan id_siswa
  Future<List<Kursus>> getKursusBySiswa(BuildContext context, String idSiswa) async {
    var url = Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/kursus-siswa/$idSiswa'); // Ganti dengan URL yang sesuai

    // Mengirim request GET ke API
    var response = await http.get(url);

    if (response.statusCode == 200) {
      // Parse response JSON menjadi list kursus
      var data = jsonDecode(response.body);
      List<Kursus> kursusList = [];
      for (var item in data['kursus']) {
        kursusList.add(Kursus.fromJson(item));
      }
      return kursusList;
    } else {
      // Menampilkan error jika gagal mengambil data
      throw Exception('Failed to load courses');
    }
  }
}
