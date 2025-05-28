import 'package:flutter/material.dart';
import 'buttomnav.dart'; // Mengimpor sidebar untuk digunakan di bawah

class PageBook extends StatelessWidget {
  final String className;
  
  const PageBook({Key? key, required this.className}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text(
          "Detail $className",
          // style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildClassCard(context, "Ilmu Pengetahuan Alam"),
            buildClassCard(context, "Matematika"),
            buildClassCard(context, "Bahasa Indonesia"),
            buildClassCard(context, "Ilmu Pengetahuan Sosial"),
            buildClassCard(context, "Seni Budaya"),
            buildClassCard(context, "Bahasa Inggris"),
          ],
        ),
      ),
      // Menambahkan sidebar (bottom navigation bar)
      // bottomNavigationBar: const Sidebar(),
    );
  }

  Widget buildClassCard(BuildContext context, String subjectName) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Image.asset(
          'assets/images/books.png',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
        title: Text(
          subjectName,
          // style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        onTap: () {
          // Tambahkan navigasi ke halaman soal untuk subject terkait jika diperlukan
          // Misalnya:
          // Navigator.push(context, MaterialPageRoute(builder: (context) => SoalPage(subjectName: subjectName)));
        },
      ),
    );
  }
}
