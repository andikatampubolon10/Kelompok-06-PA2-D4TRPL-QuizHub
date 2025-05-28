import 'dart:async'; // Add this import for Timer
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/services/jawaban_siswa_service.dart'; // Import the service
import 'package:connectivity_plus/connectivity_plus.dart'; // For internet connectivity

class QuizScreen extends StatefulWidget {
  final String title;
  final String subject;
  final String idKursus;
  final int gradeLevel;
  final int idUjian;
  final int idSiswa;
  final int idTipeUjian;
  final int durasi; // Add this field for duration in minutes

  const QuizScreen({
    Key? key,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.idUjian,
    required this.idKursus,
    required this.idSiswa,
    required this.idTipeUjian,
    this.durasi = 0, // Default value
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> questions = [];
  late List<String?> _selectedAnswers;
  bool _isMenuOpen = false;
  bool _quizCompleted = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSaving = false;
  bool _isOnline = true;
  bool _isAppInBackground = false;
  int _backgroundWarningCount = 0;
  final int _maxBackgroundWarnings = 3;
  
  // Connectivity subscription
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Timer variables
  late Timer _timer;
  int _remainingSeconds = 0;
  String _timerText = "00:00";
  bool _isTimerRunning = false;
  
  // Auto-save timer
  Timer? _autoSaveTimer;
  final int _autoSaveIntervalSeconds = 30; // Save answers every 30 seconds

  // Create an instance of the JawabanSiswaService
  final JawabanSiswaService _jawabanSiswaService = JawabanSiswaService();

  // Menambahkan status soal yang sudah dilihat
  late List<bool> _viewedQuestions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('ID Siswa yang diterima: ${widget.idSiswa}');
    _initSecurityFeatures();
    _setupConnectivityListener();
    _saveUserIdIfProvided();
    _loadQuestions();
    _initializeTimer();
    _startAutoSaveTimer();
  }
  
  // Initialize security features
  Future<void> _initSecurityFeatures() async {
    // Set the device orientation to portrait only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Enter fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Keep screen on
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, 
      overlays: []
    );
    
    // Note: We've removed flutter_windowmanager dependency
    // The FLAG_SECURE feature (preventing screenshots) is not available without it
    // But we can still implement other security measures
  }
  
  // Setup connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOnline = (result != ConnectivityResult.none);
      });
      
      if (_isOnline) {
        _syncAnswersWithServer();
      } else {
        _saveAnswersLocally();
      }
    });
    
    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _isOnline = (result != ConnectivityResult.none);
      });
    });
  }
  
  // Show warning when app goes to background
  void _showBackgroundWarning() {
    _backgroundWarningCount++;
    
    if (_backgroundWarningCount <= _maxBackgroundWarnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Peringatan: Anda keluar dari aplikasi ujian. Peringatan ke-$_backgroundWarningCount dari $_maxBackgroundWarnings'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      // Auto-submit after max warnings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda telah keluar dari aplikasi ujian terlalu banyak. Ujian akan diakhiri otomatis.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      
      _submitAnswersAndShowResult();
    }
  }
  
  // Start auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(Duration(seconds: _autoSaveIntervalSeconds), (timer) {
      if (!_quizCompleted) {
        _saveAnswersLocally();
        
        if (_isOnline) {
          _syncAnswersWithServer();
        }
      }
    });
  }
  
  // Save answers locally
  Future<void> _saveAnswersLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create a map of the current state
      final Map<String, dynamic> quizState = {
        'idUjian': widget.idUjian,
        'idSiswa': widget.idSiswa,
        'idTipeUjian': widget.idTipeUjian,
        'selectedAnswers': _selectedAnswers,
        'currentQuestionIndex': _currentQuestionIndex,
        'remainingSeconds': _remainingSeconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Save to SharedPreferences
      await prefs.setString('quiz_state_${widget.idUjian}', jsonEncode(quizState));
      print('Answers saved locally');
    } catch (e) {
      print('Error saving answers locally: $e');
    }
  }
  
  // Sync answers with server
  Future<void> _syncAnswersWithServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quizStateJson = prefs.getString('quiz_state_${widget.idUjian}');
      
      if (quizStateJson != null) {
        // Submit answers to server
        final success = await _jawabanSiswaService.submitQuizAnswers(
          idUjian: widget.idUjian.toString(),
          questions: questions,
          selectedAnswers: _selectedAnswers,
        );
        
        if (success) {
          print('Answers synced with server');
        } else {
          print('Failed to sync answers with server');
        }
      }
    } catch (e) {
      print('Error syncing answers with server: $e');
    }
  }
  
  // Load saved answers if available
  Future<void> _loadSavedAnswers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quizStateJson = prefs.getString('quiz_state_${widget.idUjian}');
      
      if (quizStateJson != null) {
        final quizState = jsonDecode(quizStateJson);
        
        // Check if the saved state is for the current quiz
        if (quizState['idUjian'] == widget.idUjian) {
          // Check if the saved state is not too old (e.g., more than 1 hour)
          final timestamp = quizState['timestamp'] as int;
          final now = DateTime.now().millisecondsSinceEpoch;
          final diff = now - timestamp;
          
          if (diff < 3600000) { // 1 hour in milliseconds
            setState(() {
              _selectedAnswers = List<String?>.from(quizState['selectedAnswers']);
              _currentQuestionIndex = quizState['currentQuestionIndex'];
              _remainingSeconds = quizState['remainingSeconds'];
              _updateTimerText();
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Jawaban sebelumnya telah dimuat'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error loading saved answers: $e');
    }
  }

  // Initialize the timer with the duration from widget
  void _initializeTimer() {
    if (widget.durasi > 0) {
      _remainingSeconds = widget.durasi * 60; // Convert minutes to seconds
      _updateTimerText();
      _startTimer();
    }
  }

  // Start the countdown timer
  void _startTimer() {
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _updateTimerText();
        });
      } else {
        _timer.cancel();
        _isTimerRunning = false;
        // Auto-submit when time runs out
        if (!_quizCompleted) {
          _autoSubmitDueToTimeout();
        }
      }
    });
  }

  // Update the timer display text
  void _updateTimerText() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    _timerText = "${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}";
  }

  // Auto-submit when time runs out
  void _autoSubmitDueToTimeout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Waktu habis! Jawaban akan dikirim otomatis.'),
        backgroundColor: Colors.orange,
      ),
    );
    _submitAnswersAndShowResult();
  }

  @override
  void dispose() {
    if (_isTimerRunning) {
      _timer.cancel();
    }
    
    if (_autoSaveTimer != null) {
      _autoSaveTimer!.cancel();
    }
    
    _connectivitySubscription.cancel();
    
    // Restore system UI and orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is in background
      setState(() {
        _isAppInBackground = true;
      });
      
      if (!_quizCompleted) {
        _saveAnswersLocally();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is in foreground
      bool wasInBackground = _isAppInBackground;
      
      setState(() {
        _isAppInBackground = false;
      });
      
      if (wasInBackground && !_quizCompleted) {
        _showBackgroundWarning();
      }
    } else if (state == AppLifecycleState.detached) {
      // App is being terminated
      if (!_quizCompleted) {
        _saveAnswersLocally();
        if (_isOnline) {
          _submitAnswersAndShowResult();
        }
      }
    } else if (state == AppLifecycleState.inactive) {
      // App is inactive (e.g., split screen)
      setState(() {
        _isAppInBackground = true;
      });
      
      if (!_quizCompleted) {
        _showBackgroundWarning();
      }
    }
  }

  // Save the user ID if it was provided
  Future<void> _saveUserIdIfProvided() async {
    if (widget.idSiswa != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', widget.idSiswa!);
        print('User ID saved: ${widget.idSiswa}');
      } catch (e) {
        print('Error saving user ID: $e');
      }
    }
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Debug the idUjian value
      print("Loading questions for idUjian: ${widget.idUjian}");
      print("idUjian type: ${widget.idUjian.runtimeType}");
      
      // Menggunakan endpoint API dengan idUjian sebagai integer
      final response = await http.get(
        Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/soal-ujian/${widget.idUjian}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if data exists and is not null
        if (data == null) {
          setState(() {
            questions = [];
            _isLoading = false;
          });
          return;
        }
        
        // Check if 'data' field exists and is not null
        final List<dynamic> soalData = data['data'] ?? [];
        
        // If there are no questions, set empty list and return
        if (soalData.isEmpty) {
          setState(() {
            questions = [];
            _isLoading = false;
          });
          return;
        }

        // Transformasi data dari API ke format yang dibutuhkan aplikasi
        List<Map<String, dynamic>> formattedQuestions = [];

        for (var item in soalData) {
          // Check if item is not null
          if (item == null) continue;
          
          final soal = item['soal'] ?? {};
          final jawabanList = item['jawaban'] != null ? List.from(item['jawaban']) : [];
          final idTipeSoal = soal['id_tipe_soal'] ?? 1;
          final idSoal = soal['id_soal']?.toString() ?? '';

          // Menentukan tipe soal berdasarkan id_tipe_soal
          String questionType;
          List<String> options = [];

          switch (idTipeSoal) {
            case 1: // Multiple Choice
              questionType = 'multiple_choice';
              if (jawabanList.isNotEmpty) {
                options = jawabanList.map<String>((jawaban) {
                  return jawaban['teks_jawaban']?.toString() ?? 'No option text';
                }).toList();
                
                // Shuffle options once here, when loading questions
                options.shuffle();
              } else {
                print("Warning: No answer options found for question $idSoal");
              }
              break;
            case 2: // True/False
              questionType = 'true_false';
              if (jawabanList.isNotEmpty) {
                options = jawabanList.map<String>((jawaban) {
                  return jawaban['jawaban']?.toString() ?? 'No option text';
                }).toList();
              } else {
                options = ['Benar', 'Salah']; // fallback default
                print("Warning: No answer options found for True/False question $idSoal");
              }
              break;
            case 3: // Essay
              questionType = 'essay';
              break;
            default:
              questionType = 'multiple_choice';
          }

          formattedQuestions.add({
            'id': idSoal,
            'question': soal['soal']?.toString() ?? 'No question text',
            'image_url': soal['image_url']?.toString(),
            'image': soal['image_url']?.toString(),
            'options': options,
            'type': questionType,
            'id_tipe_soal': idTipeSoal,
            'jawaban_list': jawabanList,
          });
        }
        
        // Randomize the order of questions for each student
        formattedQuestions.shuffle();

        setState(() {
          questions = formattedQuestions;
          _selectedAnswers = List<String?>.filled(questions.length, null);
          _viewedQuestions = List<bool>.filled(questions.length, false);
          if (questions.isNotEmpty) {
            _viewedQuestions[0] = true;
          }
          _isLoading = false;
        });
        
        // Load saved answers if available
        _loadSavedAnswers();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
      print("Gagal memuat soal: $e");
    }
  }

  void _handleAnswer(String answer) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
    });
    
    // Save answer locally
    _saveAnswersLocally();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _viewedQuestions[_currentQuestionIndex] = true; // Menandai soal telah dilihat
      });
    } else {
      // Jika sudah di soal terakhir, tampilkan dialog konfirmasi
      _showConfirmationDialog();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _viewedQuestions[_currentQuestionIndex] = true; // Menandai soal telah dilihat
      });
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selesaikan Ujian?'),
          content: const Text('Apakah Anda yakin ingin menyelesaikan ujian ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitAnswersAndShowResult();
              },
              child: const Text('Ya, Selesaikan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAnswersAndShowResult() async {
  setState(() {
    _isSaving = true;
    _quizCompleted = true;
  });

  try {
    // Step 1: Submit the answers first (assumes a method to submit answers is available)
    final prefs = await SharedPreferences.getInstance();
    final int idSiswa = prefs.getInt('user_id') ?? 1;

    final success = await _jawabanSiswaService.submitQuizAnswers(
      idUjian: widget.idUjian.toString(),
      questions: questions,
      selectedAnswers: _selectedAnswers,
    );

    if (success) {
      // Step 2: Get the calculated score for the student
      double totalScore = await _jawabanSiswaService.getCalculatedScore(
        widget.idUjian.toString(),
        idSiswa,
      );

      print('Calculated total score: $totalScore');

      // Step 3: Submit the score to 'tipe_nilai' table
      int idTipeUjian = widget.idTipeUjian;
      final scoreSubmittedToTipeNilai = await _jawabanSiswaService.submitNilaiToTipeNilai(
        totalScore,
        idTipeUjian,
        idSiswa,
        widget.idUjian,
      );

      if (!scoreSubmittedToTipeNilai) {
        print('Failed to submit score to tipe_nilai');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save score to server (tipe_nilai)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Step 4: Now calculate total score per exam type (tipe_ujian)
      Map<int, double> totalScores = await _jawabanSiswaService.calculateScoresByTipeUjian(
        widget.idKursus,  // Pass idKursus here instead of idUjian
        idSiswa,
      );

      print('Calculated scores per tipe_ujian: $totalScores');

      // Step 5: Submit each score for the corresponding tipe_ujian (exam type)
      for (var tipeUjianId in totalScores.keys) {
        final score = totalScores[tipeUjianId] ?? 0;

        final scoreSubmittedToNilaiKursus = await _jawabanSiswaService.submitScoreToNilaiKursus(
          score,
          tipeUjianId,
          idSiswa,
          widget.idKursus,  // Pass idKursus here (course ID)
        );

        if (scoreSubmittedToNilaiKursus) {
          print('Score for tipe_ujian $tipeUjianId submitted successfully');
        } else {
          print('Failed to submit score for tipe_ujian $tipeUjianId');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save score to server (nilai_kursus)'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Step 6: Finally, submit the calculated score to 'nilai' table
      final scoreSubmittedToNilai = await _jawabanSiswaService.submitCalculatedScoreToNilai(
        totalScore,
        widget.idKursus,
        idSiswa,
      );

      if (scoreSubmittedToNilai) {
        print('Calculated score successfully submitted to nilai');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Quiz submitted successfully")),
        );
      } else {
        print('Failed to submit calculated score to nilai');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit calculated score to nilai'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Step 7: Clear saved quiz state
      await prefs.remove('quiz_state_${widget.idUjian}');

    } else {
      print('Failed to submit answers');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save answers to server'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('Error submitting answers: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isSaving = false;
    });
  }
}

  
  // Helper method to calculate total score
  Future<double> _calculateTotalScore() async {
    try {
      // Get the current user ID
      final prefs = await SharedPreferences.getInstance();
      int idSiswa = prefs.getInt('user_id') ?? 1;
      
      // Use the service to calculate the score based on correct answers
      return await _jawabanSiswaService.calculateScoreClientSide(
        widget.idUjian.toString(),
        idSiswa,
        questions,
        _selectedAnswers
      );
    } catch (e) {
      print('Error calculating score: $e');
      return 0.0;
    }
  }

  // Update the _navigateToHomeDetail method to call the API for password validation
  void _navigateToHomeDetail() {
    // Show password dialog
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        // Create a TextEditingController for the password field
        final TextEditingController passwordController = TextEditingController();
        bool obscurePassword = true; // For password visibility toggle
        bool isLoading = false; // For loading state
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Masukkan Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Masukkan password untuk keluar dari ujian'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final password = passwordController.text;
                    
                    if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password tidak boleh kosong'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Set loading state
                    setState(() {
                      isLoading = true;
                    });
                    
                    try {
                      // Call the API to validate the exit password
                      final response = await http.post(
                        Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/keluar-ujian/${widget.idUjian}'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'password_keluar': password}),
                      );
                      
                      // Check the response
                      if (response.statusCode == 200) {
                        // Password is correct, navigate back to IntroductionScreen
                        Navigator.of(context).pop(); // Close the dialog
                        Navigator.of(context).pop(); // Navigate back to previous screen (IntroductionScreen)
                      } else {
                        // Password is incorrect
                        setState(() {
                          isLoading = false;
                        });
                        
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password salah. Silakan coba lagi.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      // Handle network or other errors
                      setState(() {
                        isLoading = false;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show connectivity warning if offline
    if (!_isOnline && !_quizCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada koneksi internet. Jawaban akan disimpan secara lokal.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat soal ujian...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Belum ada soal yang dibuat untuk ujian ini',
            style: TextStyle(fontSize: 24),
          ),
        ),
      );
    }

    if (_quizCompleted) {
      return _buildCompletionScreen();
    }

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from closing the app
        _navigateToHomeDetail();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '${widget.gradeLevel} - ${widget.subject}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            // Connection status indicator
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off,
                color: _isOnline ? Colors.green : Colors.red,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.blue),
              onPressed: _toggleMenu,
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildMainContent(),
            if (_isMenuOpen) _buildMenuOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final question = questions[_currentQuestionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Soal ${_currentQuestionIndex + 1} dari ${questions.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Center(
                  child: Text(
                    _timerText, // Use the timer text here
                    style: TextStyle(
                      color: _remainingSeconds < 60 ? Colors.red : Colors.black, // Red when less than 1 minute
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (question['id_tipe_soal'] == 1) 
            _buildMultipleChoiceQuestion(question),
          if (question['id_tipe_soal'] == 2) 
            _buildTrueFalseQuestion(question),
          if (question['id_tipe_soal'] == 3) 
            _buildEssayQuestion(question),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Sebelumnya'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[200],
                    disabledForegroundColor: Colors.grey[400],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_currentQuestionIndex == questions.length - 1 ? 'Selesai' : 'Selanjutnya'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk soal pilihan ganda
  Widget _buildMultipleChoiceQuestion(Map<String, dynamic> question) {
    // Get the original jawaban list to extract the correct options
    final jawabanList = question['jawaban_list'] as List<dynamic>? ?? [];
    
    // Extract options from the jawaban list
    List<String> options = [];
    if (jawabanList.isNotEmpty) {
      options = jawabanList.map<String>((jawaban) {
        // Try different field names that might contain the answer text
        String optionText = jawaban['teks_jawaban']?.toString() ?? 
                           jawaban['jawaban']?.toString() ?? 
                           jawaban['text']?.toString() ?? 
                           'No option text';
        return optionText;
      }).toList();
      
      // Remove this line:
      // options.shuffle();
    } else {
      // Fallback to the options we already processed
      options = question['options'] as List<String>? ?? ['No options available'];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['question'] ?? 'No question text',
            style: const TextStyle(fontSize: 18),
          ),
          if (question['image_url'] != null && question['image_url'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Image.network(
                question['image_url'],
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text('Gambar tidak tersedia'),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final optionLetter = String.fromCharCode(97 + index); // a, b, c, d, ...
            final isSelected = _selectedAnswers[_currentQuestionIndex] == option;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => _handleAnswer(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$optionLetter. $option',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.blue),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Widget untuk soal benar/salah
  Widget _buildTrueFalseQuestion(Map<String, dynamic> question) {
    final soal = question['question'] ?? 'No question available';
    final options = question['options'] as List<String>? ?? ['Benar', 'Salah']; // Defaulting to True/False options if none

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display question text
          Text(
            soal,
            style: const TextStyle(fontSize: 18),
          ),

          // Display an image if available
          if (question['image'] != null && question['image'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Image.network(
                question['image'],
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text('Gambar tidak tersedia'),
                    ),
                  );
                },
              ),
            ),

          // Options for True/False answers (dynamic based on database)
          const SizedBox(height: 16),
          Row(
            children: [
              // Option for the first answer (display based on database values)
              Expanded(
                child: AspectRatio(
                  aspectRatio: 2.55,  // Ensures both options have equal width-to-height ratio
                  child: InkWell(
                    onTap: () => _handleAnswer(options[0]), // Handle dynamic 'option' answer
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedAnswers[_currentQuestionIndex] == options[0]
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: _selectedAnswers[_currentQuestionIndex] == options[0] ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          options[0],  // Display dynamic option text
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedAnswers[_currentQuestionIndex] == options[0]
                                ? Colors.blue
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Option for the second answer (display based on database values)
              Expanded(
                child: AspectRatio(
                  aspectRatio: 2.55,  // Ensures both options have equal width-to-height ratio
                  child: InkWell(
                    onTap: () => _handleAnswer(options[1]), // Handle dynamic 'option' answer
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedAnswers[_currentQuestionIndex] == options[1]
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: _selectedAnswers[_currentQuestionIndex] == options[1] ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          options[1],  // Display dynamic option text
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedAnswers[_currentQuestionIndex] == options[1]
                                ? Colors.blue
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget untuk soal esai
  Widget _buildEssayQuestion(Map<String, dynamic> question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['question'] ?? 'No question text',
            style: const TextStyle(fontSize: 18),
          ),
          if (question['image'] != null && question['image'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Image.network(
                question['image'],
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text('Gambar tidak tersedia'),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              _handleAnswer(value);
            },
            controller: TextEditingController(
              text: _selectedAnswers[_currentQuestionIndex] ?? '',
            ),
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Ketik jawaban Anda...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOverlay() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jumlah Soal (${questions.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _isMenuOpen = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem(Colors.white, 'Belum dijawab'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.green, 'Sudah dijawab'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.yellow, 'Dilihat belum dijawab'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    questions.length,
                    (index) {
                      final isAnswered = _selectedAnswers[index] != null;
                      final isCurrent = index == _currentQuestionIndex;
                      final isViewed = _viewedQuestions[index];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentQuestionIndex = index;
                            _viewedQuestions[index] = true;
                            _isMenuOpen = false;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isCurrent 
                                ? Colors.blue[100]
                                : isAnswered 
                                    ? Colors.green
                                    : isViewed
                                        ? Colors.yellow[100]
                                        : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent 
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: isCurrent ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent 
                                    ? Colors.blue 
                                    : isAnswered 
                                        ? Colors.white 
                                        : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Cek apakah semua soal sudah dijawab
                final allAnswered = !_selectedAnswers.contains(null);
                if (allAnswered) {
                  _submitAnswersAndShowResult();
                } else {
                  // Tampilkan dialog peringatan
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Perhatian'),
                        content: const Text('Masih ada soal yang belum dijawab. Apakah Anda yakin ingin menyelesaikan ujian?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _submitAnswersAndShowResult();
                            },
                            child: const Text('Ya, Selesaikan'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Selesaikan Ujian',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCompletionScreen() {
    // If still saving answers, show loading indicator
    if (_isSaving) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Menyimpan jawaban...'),
            ],
          ),
        ),
      );
    }

    // Hitung jumlah jawaban yang benar (untuk contoh saja)
    int answeredCount = _selectedAnswers.where((answer) => answer != null).length;
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 4),
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Selamat Anda Telah',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text(
              'Menyelesaikan Ujian',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text(
              'Mata Pelajaran: ${widget.subject}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Jumlah Soal: ${questions.length}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Soal Dijawab: $answeredCount dari ${questions.length}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _navigateToHomeDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
