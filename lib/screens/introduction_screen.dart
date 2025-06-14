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

  // Check if current time is within quiz time window
  bool _isQuizTimeValid() {
    if (widget.waktuMulai.isEmpty || widget.waktuSelesai.isEmpty) {
      return true; // If no time restrictions, allow access
    }

    try {
      DateTime now = DateTime.now();
      
      // Debug information
      print('Current time (local): $now');
      print('Raw waktuMulai: ${widget.waktuMulai}');
      print('Raw waktuSelesai: ${widget.waktuSelesai}');
      
      // Parse the UTC times and convert to local time
      DateTime startTimeUtc = DateTime.parse(widget.waktuMulai);
      DateTime endTimeUtc = DateTime.parse(widget.waktuSelesai);
      
      // Convert UTC times to local time
      DateTime startTimeLocal = startTimeUtc.toLocal();
      DateTime endTimeLocal = endTimeUtc.toLocal();
      
      // Debug parsed times
      print('Parsed startTime (UTC): $startTimeUtc');
      print('Parsed endTime (UTC): $endTimeUtc');
      print('Converted startTime (Local): $startTimeLocal');
      print('Converted endTime (Local): $endTimeLocal');
      print('Is now after startTime: ${now.isAfter(startTimeLocal)}');
      print('Is now before endTime: ${now.isBefore(endTimeLocal)}');
      
      // Check if current time is within the time window (using local times)
      bool isValid = now.isAfter(startTimeLocal) && now.isBefore(endTimeLocal);
      print('Quiz time is valid: $isValid');
      
      return isValid;
    } catch (e) {
      print('Error parsing quiz times: $e');
      return true; // If parsing fails, allow access
    }
  }

  // Get appropriate message for quiz timing
  String _getQuizTimingMessage() {
    if (widget.waktuMulai.isEmpty || widget.waktuSelesai.isEmpty) {
      return '';
    }

    try {
      DateTime now = DateTime.now();
      
      // Parse the UTC times and convert to local time
      DateTime startTimeUtc = DateTime.parse(widget.waktuMulai);
      DateTime endTimeUtc = DateTime.parse(widget.waktuSelesai);
      
      // Convert UTC times to local time
      DateTime startTimeLocal = startTimeUtc.toLocal();
      DateTime endTimeLocal = endTimeUtc.toLocal();

      if (now.isBefore(startTimeLocal)) {
        return 'Kuis belum dimulai. Kuis akan dibuka pada ${_formatDateTime(startTimeLocal.toIso8601String())}.';
      } else if (now.isAfter(endTimeLocal)) {
        return 'Kuis sudah berakhir. Kuis ditutup pada ${_formatDateTime(endTimeLocal.toIso8601String())}.';
      }
      return '';
    } catch (e) {
      print('Error checking quiz timing: $e');
      return '';
    }
  }

  // Format date string for display without using DateFormat
  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return 'Tidak ditentukan';
    
    try {
      // Parse the date string
      DateTime dateTime = DateTime.parse(dateTimeStr);
      
      // If it's UTC time, convert to local
      if (dateTimeStr.contains('Z') || dateTimeStr.contains('+')) {
        dateTime = dateTime.toLocal();
      }
      
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
      print('Error parsing date for display: $e');
      return dateTimeStr; // Return the original string if parsing fails
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

    // Check if quiz time is valid before proceeding
    if (!_isQuizTimeValid()) {
      setState(() {
        _errorMessage = _getQuizTimingMessage();
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
    // Get timing message to show if quiz is not available
    String timingMessage = _getQuizTimingMessage();
    bool isQuizAvailable = _isQuizTimeValid();
    
    // Debug information in the UI
    print('Quiz availability check:');
    print('waktuMulai: ${widget.waktuMulai}');
    print('waktuSelesai: ${widget.waktuSelesai}');
    print('Current time: ${DateTime.now()}');
    print('Is quiz available according to _isQuizTimeValid(): $isQuizAvailable');
    print('Timing message: $timingMessage');

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
              
              // Show timing message if quiz is not available
              if (timingMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          timingMessage,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Only show password field and button if quiz is available
              if (isQuizAvailable) ...[
                _buildPasswordField(),
                const SizedBox(height: 24),
                _buildStartButton(),
              ],
              
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
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
    // Convert UTC times to local time for display
    String startTimeText = 'Waktu mulai belum ditambahkan';
    String endTimeText = 'Waktu selesai belum ditambahkan';
    
    if (widget.waktuMulai.isNotEmpty) {
      try {
        DateTime startTimeUtc = DateTime.parse(widget.waktuMulai);
        DateTime startTimeLocal = startTimeUtc.toLocal();
        startTimeText = 'Kuis dibuka pada ${_formatDateTime(startTimeLocal.toIso8601String())}';
      } catch (e) {
        startTimeText = 'Kuis dibuka pada ${widget.waktuMulai}';
      }
    }
    
    if (widget.waktuSelesai.isNotEmpty) {
      try {
        DateTime endTimeUtc = DateTime.parse(widget.waktuSelesai);
        DateTime endTimeLocal = endTimeUtc.toLocal();
        endTimeText = 'Kuis ditutup pada ${_formatDateTime(endTimeLocal.toIso8601String())}';
      } catch (e) {
        endTimeText = 'Kuis ditutup pada ${widget.waktuSelesai}';
      }
    }

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