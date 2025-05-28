import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'quiz/openquiz.dart'; // Pastikan path ke OpenQuizPage sudah benar

class HomePage1 extends StatefulWidget {
  final String idKursus;
  final String namaKursus; // Menambahkan nama_kursus ke konstruktor

  HomePage1({required this.idKursus, required this.namaKursus}); // Terima id_kursus dan nama_kursus

  @override
  _HomePage1State createState() => _HomePage1State();
}

class _HomePage1State extends State<HomePage1> {
  late Future<List<Ujian>> _ujianList;

  @override
  void initState() {
    super.initState();
    // Menampilkan id_kursus yang diterima di terminal
    print("id_kursus yang diterima di HomePage1: ${widget.idKursus}");

    // Mengambil data ujian berdasarkan id_kursus yang diterima
    _ujianList = getUjianByKursus(widget.idKursus);
  }

  Future<List<Ujian>> getUjianByKursus(String idKursus) async {
    var url = Uri.parse('http://192.168.56.1:8080/ujian-kursus/$idKursus');  // Sesuaikan dengan API endpoint Anda

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<dynamic> ujianData = data['ujian'];
        return ujianData.map((ujian) => Ujian.fromJson(ujian)).toList();
      } else {
        throw Exception('Failed to load ujian');
      }
    } catch (e) {
      throw Exception('Failed to load ujian');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.namaKursus, // Menampilkan nama kursus yang diteruskan
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.white,  // Menetapkan warna teks menjadi putih
                fontWeight: FontWeight.w300,  // Menetapkan ketebalan font lebih ramping
                fontFamily: 'Poppins',
                ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF036BB9),
        toolbarHeight: 70,
      ),
      body: FutureBuilder<List<Ujian>>(
        future: _ujianList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Tidak ada ujian tersedia.'));
          } else {
            var ujianList = snapshot.data!;
            return ListView.builder(
              itemCount: ujianList.length,
              itemBuilder: (context, index) {
                var ujian = ujianList[index];
                bool isQuiz = ujian.idTipeUjian == 1;  // 1 untuk Quiz, 2 untuk Ujian

                return InkWell(
                  onTap: () {
                    if (isQuiz) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OpenQuizPage(quizTitle: ujian.namaUjian),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          isQuiz ? 'assets/images/quiz.png' : 'assets/images/exam.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ujian.namaUjian,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Ujian {
  final String namaUjian;
  final int idTipeUjian;

  Ujian({required this.namaUjian, required this.idTipeUjian});

  factory Ujian.fromJson(Map<String, dynamic> json) {
    return Ujian(
      namaUjian: json['nama_ujian'],
      idTipeUjian: json['id_tipe_ujian'],
    );
  }
}
