import 'package:flutter/material.dart';
import 'quiz_main_screen.dart';

class OpenQuizPage extends StatefulWidget {
  final String quizTitle;

  const OpenQuizPage({super.key, required this.quizTitle});

  @override
  State<OpenQuizPage> createState() => _OpenQuizPageState();
}

class _OpenQuizPageState extends State<OpenQuizPage> {
  bool _obscurePassword = true;
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPetunjuk(),
            const SizedBox(height: 24),
            _buildWaktuInfo(),
            const SizedBox(height: 24),
            _buildPasswordInput(),
            const SizedBox(height: 32),
            _buildMulaiButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPetunjuk() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'PETUNJUK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInstructionItem('1. Kerjakan Quiz ini dengan jujur'),
          _buildInstructionItem('2. Soal Bersifat Pilihan Berganda'),
          _buildInstructionItem('3. Jika ketahuan mencontek, akan diproses di guru BK dan nilai akan 0'),
        ],
      ),
    );
  }

  Widget _buildWaktuInfo() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Kuis dibuka pada', style: TextStyle(fontSize: 14)),
        Text('Kamis, 10 Oktober 2024,18:00 WIB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('Waktu berakhir pada', style: TextStyle(fontSize: 14)),
        Text('Kamis, 10 Oktober 2024,20:00 WIB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPasswordInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: 'Masukkan Password',
          labelStyle: const TextStyle(color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMulaiButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_passwordController.text.isNotEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => QuizMainScreen(quizTitle: widget.quizTitle),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Masukkan password terlebih dahulu!')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: const Text(
          'MULAI QUIZ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
