import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'quiz_screen.dart'; // Import QuizScreen

class IntroductionScreen extends StatefulWidget {
  final String idUjian;
  final String title;
  final String subject;
  final int gradeLevel;
  final int idSiswa;
  final int idTipeUjian;
  final String idKursus;
  final String waktuMulai; // Add this field
  final String waktuSelesai; // Add this field
  final int durasi; // Add this field in minutes

  const IntroductionScreen({
    super.key,
    required this.idUjian,
    required this.title,
    required this.subject,
    required this.idSiswa,
    required this.gradeLevel,
    required this.idTipeUjian,
    required this.idKursus,
    this.waktuMulai = '', // Default value
    this.waktuSelesai = '', // Default value
    this.durasi = 0, // Default value
  });

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // Format date string for display without using DateFormat
  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return 'Tidak ditentukan';
    
    try {
      // Parse the date string
      DateTime dateTime = DateTime.parse(dateTimeStr);
      
      // Format the date manually
      List<String> months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      
      List<String> days = [
        'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
      ];
      
      // Get day of week (1-7, where 1 is Monday)
      int dayOfWeek = dateTime.weekday;
      String dayName = days[dayOfWeek - 1];
      
      String formattedDate = '$dayName, ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      
      return '$formattedDate WIB';
    } catch (e) {
      print('Error parsing date: $e');
      return dateTimeStr;
    }
  }

  // Format duration for display
  String _formatDuration(int minutes) {
    if (minutes <= 0) return 'Tidak ditentukan';
    
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '$hours jam ${remainingMinutes > 0 ? '$remainingMinutes menit' : ''}';
    } else {
      return '$minutes menit';
    }
  }


  Future<bool> hasStudentTakenQuiz(String idUjian, int siswaId) async {
    try {
      var url = Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/check-attempt-ujian');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_ujian': idUjian,
          'id_siswa': siswaId,
        }), 
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['hasAttempted'] ?? false;
      } else {
        print('Failed to check quiz attempt. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error checking quiz attempt: $e');
      return false;
    }
  }


  // Function to validate the entered password by calling the API
  Future<void> _validatePassword() async {
  final password = _passwordController.text;

  if (password.isEmpty) {
    setState(() {
      _errorMessage = 'Password tidak boleh kosong.';
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = '';
    print("Received id_ujian: ${widget.idUjian}");
  });

  var url = Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/login-ujian/${widget.idUjian}');
  try {
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password_masuk': password}),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      // Password benar, navigasi ke QuizScreen
      // Parse idUjian to int here for QuizScreen
      int parsedIdUjian;
      try {
        parsedIdUjian = int.parse(widget.idUjian);
      } catch (e) {
        print("Error parsing idUjian: $e");
        parsedIdUjian = 0; // Default value if parsing fails
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            title: widget.title,
            subject: widget.subject,
            gradeLevel: widget.gradeLevel,
            idUjian: parsedIdUjian,  // Pass as int after parsing
            idTipeUjian: widget.idTipeUjian,
            idKursus: widget.idKursus,
            idSiswa: widget.idSiswa,
            durasi: widget.durasi, // Pass duration to QuizScreen
          ),
        ),
      );
    } else {
      // Password salah
      setState(() {
        _errorMessage = 'Password salah, silakan coba lagi.';
      });
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan koneksi: $e';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF036BB9),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.w400,
            fontFamily: 'Poppins',
          ),
        ),
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildInstructions(),
              const SizedBox(height: 24),
              _buildScheduleInfo(),
              const SizedBox(height: 24),
              _buildPasswordField(),
              const SizedBox(height: 24),
              _buildStartButton(),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Petunjuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('1. Kerjakan Quiz ini dengan jujur'),
          const Text('2. Soal Bersifat Pilihan Berganda'),
          const Text('3. Jika ketahuan mencontek, nilai akan 0'),
          if (widget.durasi > 0) ...[
            const SizedBox(height: 8),
            Text('4. Durasi ujian: ${_formatDuration(widget.durasi)}'),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleInfo() {
    // Use the actual waktu_mulai and waktu_selesai if available
    final startTimeText = widget.waktuMulai.isNotEmpty 
        ? 'Kuis dibuka pada ${_formatDateTime(widget.waktuMulai)}'
        : 'Waktu mulai belum ditambahkan';
        
    final endTimeText = widget.waktuSelesai.isNotEmpty
        ? 'Kuis ditutup pada ${_formatDateTime(widget.waktuSelesai)}'
        : 'Waktu selesai belum ditambahkan';

    return Column(
      children: [
        Text(
          startTimeText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 12),
        Text(
          endTimeText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Masukkan Password', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _validatePassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0078D4),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text(
              'Mulai Quiz',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
    );
  }
}