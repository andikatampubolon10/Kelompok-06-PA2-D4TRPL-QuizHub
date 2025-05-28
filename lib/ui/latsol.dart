import 'package:flutter/material.dart';
import 'buttomnav.dart'; // Mengimpor sidebar untuk digunakan di bawah
import 'latsol1.dart';

class BukuPage extends StatelessWidget {
  const BukuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          "Latihan Soal",
          // style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildClassCard(context, "Kelas 7"),
            buildClassCard(context, "Kelas 8"),
            buildClassCard(context, "Kelas 9"),
          ],
        ),
      ),
      // Menambahkan sidebar (bottom navigation bar)
      // bottomNavigationBar: Sidebar(idSiswa: widget.idSiswa),
    );
  }

  Widget buildClassCard(BuildContext context, String className) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Image.asset(
          'assets/images/buku.png',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
        title: Text(
          className,
          // style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PageBook(className: className),
            ),
          );
        },
      ),
    );
  }
}
