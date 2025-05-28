import 'package:flutter/material.dart';

class Soal1Screen extends StatelessWidget {
  final String quizTitle;
  final VoidCallback onNext;

  const Soal1Screen({
    super.key,
    required this.quizTitle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quizTitle, style: const TextStyle(fontSize: 18)),
            Text(
              '2024/2025 - Ilmu Pengetahuan Alam',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Soal 1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('20:45', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700])),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bagian tumbuhan yang berfungsi untuk melakukan fotosintesis adalah?',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),
                const SizedBox(height: 32),
                Column(
                  children: [
                    _buildOption('a. Akar'),
                    const SizedBox(height: 12),
                    _buildOption('b. Batang'),
                    const SizedBox(height: 12),
                    _buildOption('c. Bunga'),
                    const SizedBox(height: 12),
                    _buildOption('d. Daun'),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Image.asset('assets/ikon/menu.png', width: 40),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: null, // Kosong karena soal pertama
              child: const Text('Sebelumnya'),
            ),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Selanjutnya'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String text) {
    return InkWell(
      onTap: () => debugPrint('Opsi dipilih: $text'),
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
