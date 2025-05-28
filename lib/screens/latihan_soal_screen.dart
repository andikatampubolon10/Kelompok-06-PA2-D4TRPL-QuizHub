import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/services/jawaban_siswa_latihan_service.dart'; 

class LatihanSoalScreen extends StatefulWidget {
  final String title;
  final String subject;
  final int gradeLevel;
  final String idLatihan;
  final int? idSiswa;
  final bool showAnswers; // New parameter to control whether to show answers
  final List<String?>? studentAnswers; // Student's answers for review mode

  const LatihanSoalScreen({
    Key? key,
    required this.title,
    required this.subject,
    required this.gradeLevel,
    required this.idLatihan,
    this.idSiswa,
    this.showAnswers = false, // Default to false
    this.studentAnswers, // Default to null
  }) : super(key: key);

  @override
  State<LatihanSoalScreen> createState() => _LatihanSoalScreenState();
}

class _LatihanSoalScreenState extends State<LatihanSoalScreen> {
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> questions = [];
  late List<String?> _selectedAnswers;
  bool _isMenuOpen = false;
  bool _quizCompleted = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSaving = false;
  double _score = 0.0; // Store the calculated score
  double _maxScore = 0.0; // Maximum possible score

  // Create an instance of the JawabanSiswaService
  final JawabanSiswaService _jawabanSiswaService = JawabanSiswaService();

  // Menambahkan status soal yang sudah dilihat
  late List<bool> _viewedQuestions;

  @override
  void initState() {
    super.initState();
    _saveUserIdIfProvided();
    _loadQuestions();
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
      // Use the updated service method to get questions and answers
      final soalDenganJawaban = await _jawabanSiswaService.getSoalWithJawabanByLatihanId(widget.idLatihan);

      if (soalDenganJawaban == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load questions';
          _isLoading = false;
        });
        return;
      }

      // Debug: Print the raw data to see its structure
      print("Soal dengan jawaban: $soalDenganJawaban");

      // Transform the data to the format needed by the app
      List<Map<String, dynamic>> formattedQuestions = [];
      double maxPossibleScore = 0.0;

      for (var item in soalDenganJawaban) {
        // Extract soal and jawaban from the new API response format
        final soal = item['soal'] ?? {};
        final jawabanList = item['jawaban'] as List<dynamic>? ?? [];

        // Debug: Print the jawaban list for this question
        print("Question ID: ${soal['id_soal']}, Jawaban: $jawabanList");

        // Safely extract id_tipe_soal with a default value
        final idTipeSoal = soal['id_tipe_soal'] ?? 1;
        final idSoal = soal['id_soal']?.toString() ?? '';
        
        // Extract nilai_per_soal with a default value of 1.0
        final nilaiPerSoal = double.tryParse(soal['nilai_per_soal']?.toString() ?? '1.0') ?? 1.0;
        
        // Add to max possible score
        maxPossibleScore += nilaiPerSoal;

        // Determine question type based on id_tipe_soal
        String questionType;
        List<String> options = [];
        String? correctAnswer;
        int? correctAnswerId;

        switch (idTipeSoal) {
          case 1: // Multiple Choice
            questionType = 'multiple_choice';
            // Extract answer options from jawabanList with null safety
            if (jawabanList.isNotEmpty) {
              options = jawabanList.map<String>((jawaban) {
                return jawaban['jawaban']?.toString() ?? 'No option text';
              }).toList();
              
              // Find the correct answer based on the 'benar' field
              for (var jawaban in jawabanList) {
                if (jawaban['benar'] == true || jawaban['benar'] == 1) {
                  correctAnswer = jawaban['jawaban']?.toString() ?? 'No option text';
                  correctAnswerId = jawaban['id_jawaban_soal'];
                  break;
                }
              }
              
              // Shuffle options once when loading
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
              
              // Find the correct answer based on the 'benar' field
              for (var jawaban in jawabanList) {
                if (jawaban['benar'] == true || jawaban['benar'] == 1) {
                  correctAnswer = jawaban['jawaban']?.toString() ?? 'No option text';
                  correctAnswerId = jawaban['id_jawaban_soal'];
                  break;
                }
              }
            } else {
              options = ['Benar', 'Salah']; // fallback default
              print("Warning: No answer options found for True/False question $idSoal");
            }
            break;

          case 3: // Essay
            questionType = 'essay';
            // For essay, we might have a model answer
            if (jawabanList.isNotEmpty) {
              for (var jawaban in jawabanList) {
                if (jawaban['benar'] == true || jawaban['benar'] == 1) {
                  correctAnswer = jawaban['jawaban']?.toString() ?? 'No model answer available';
                  correctAnswerId = jawaban['id_jawaban_soal'];
                  break;
                }
              }
            }
            break;
          default:
            questionType = 'multiple_choice';
        }

        // Safely access all fields with null checks and default values
        formattedQuestions.add({
          'id': idSoal,
          'question': soal['soal']?.toString() ?? 'No question text',
          'image': soal['gambar_soal']?.toString(), // Can be null
          'options': options,
          'type': questionType,
          'id_tipe_soal': idTipeSoal,
          'jawaban_list': jawabanList, // Store the original jawaban list for reference
          'soal': soal, // Store the original soal object for reference
          'correct_answer': correctAnswer, // Store the correct answer
          'correct_answer_id': correctAnswerId, // Store the correct answer ID
          'nilai_per_soal': nilaiPerSoal, // Store the score value for this question
        });
      }

      setState(() {
        questions = formattedQuestions;
        _maxScore = maxPossibleScore;
        
        // If we're in review mode, use the provided answers
        if (widget.showAnswers && widget.studentAnswers != null) {
          _selectedAnswers = List<String?>.from(widget.studentAnswers!);
        } else {
          _selectedAnswers = List<String?>.filled(questions.length, null);
        }
        
        _viewedQuestions = List<bool>.filled(questions.length, false);
        _viewedQuestions[0] = true; // Mark the first question as viewed
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
      print("Failed to load questions: $e");
    }
  }

  void _handleAnswer(String answer) {
    // Only allow changing answers if not in review mode
    if (!widget.showAnswers) {
      setState(() {
        _selectedAnswers[_currentQuestionIndex] = answer;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _viewedQuestions[_currentQuestionIndex] = true; // Menandai soal telah dilihat
      });
    } else {
      // Jika sudah di soal terakhir, tampilkan dialog konfirmasi
      if (!widget.showAnswers) {
        _showConfirmationDialog();
      } else {
        // In review mode, just go back to the result screen
        Navigator.of(context).pop();
      }
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selesaikan Latihan?'),
          content: const Text('Apakah Anda yakin ingin menyelesaikan latihan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _calculateScoreAndShowResult();
              },
              child: const Text('Ya, Selesaikan'),
            ),
          ],
        );
      },
    );
  }

  // Calculate score and show result screen
  void _calculateScoreAndShowResult() {
    setState(() {
      _isSaving = true;
    });

    // Calculate the score based on nilai_per_soal
    double totalScore = 0.0;

    for (int i = 0; i < questions.length; i++) {
      if (_selectedAnswers[i] != null) {
        String? correctAnswer = questions[i]['correct_answer'];
        double nilaiPerSoal = questions[i]['nilai_per_soal'] ?? 1.0;
        
        if (correctAnswer != null && _selectedAnswers[i] == correctAnswer) {
          totalScore += nilaiPerSoal;
        }
      }
    }

    // Calculate percentage score
    double scorePercentage = _maxScore > 0 
        ? (totalScore / _maxScore) * 100 
        : 0;

    setState(() {
      _score = totalScore;
      _quizCompleted = true;
      _isSaving = false;
    });
  }

  void _navigateToHomeDetail() {
    Navigator.of(context).pop();
  }

  void _viewAnswers() {
    // Navigate to a new instance of LatihanSoalScreen with showAnswers=true
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LatihanSoalScreen(
          title: widget.title,
          subject: widget.subject,
          gradeLevel: widget.gradeLevel,
          idLatihan: widget.idLatihan,
          idSiswa: widget.idSiswa,
          showAnswers: true,
          studentAnswers: _selectedAnswers,
        ),
      ),
    );
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Memuat soal latihan...'),
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
            'Tidak ada soal tersedia',
            style: TextStyle(fontSize: 24),
          ),
        ),
      );
    }

    if (_quizCompleted) {
      return _buildCompletionScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.showAnswers)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Mode Review',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
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
    );
  }

  Widget _buildMainContent() {
    final question = questions[_currentQuestionIndex];
    final correctAnswer = question['correct_answer'];
    final nilaiPerSoal = question['nilai_per_soal'] ?? 1.0;

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
              const Spacer(),
              if (widget.showAnswers)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'Jawaban & Pembahasan',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (!widget.showAnswers)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Nilai: $nilaiPerSoal poin',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (question['id_tipe_soal'] == 1) 
            _buildMultipleChoiceQuestion(question),
          if (question['id_tipe_soal'] == 2) 
            _buildTrueFalseQuestion(question),
          if (question['id_tipe_soal'] == 3) 
            _buildEssayQuestion(question),
            
          // Show correct answer in review mode
          if (widget.showAnswers && correctAnswer != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jawaban Benar:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(correctAnswer),
                  const SizedBox(height: 16),
                  const Text(
                    'Pembahasan:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question['soal']?['pembahasan']?.toString() ?? 
                    'Tidak ada pembahasan untuk soal ini.',
                  ),
                ],
              ),
            ),
            
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
                  label: Text(_currentQuestionIndex == questions.length - 1 
                      ? (widget.showAnswers ? 'Selesai' : 'Selesai') 
                      : 'Selanjutnya'),
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
    final correctAnswer = question['correct_answer'];
    
    // Extract options from the jawaban list
    List<String> options = [];
    if (jawabanList.isNotEmpty) {
      options = jawabanList.map<String>((jawaban) {
        // Try different field names that might contain the answer text
        String optionText = jawaban['jawaban']?.toString() ?? 
                           'No option text';
        return optionText;
      }).toList();
    } else {
      // Fallback to the options we already processed
      final questionOptions = question['options'];
      if (questionOptions is List<dynamic>) {
        options = questionOptions.map((opt) => opt.toString()).toList();
      } else if (questionOptions is List<String>) {
        options = questionOptions;
      } else {
        options = ['No options available'];
      }
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
            question['question']?.toString() ?? 'No question text',
            style: const TextStyle(fontSize: 18),
          ),
          if (question['image'] != null && question['image'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Image.network(
                question['image'].toString(),
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
            final isCorrect = option == correctAnswer;

            // Determine the border color based on review mode and correctness
            Color? borderColor;
            if (widget.showAnswers) {
              if (isSelected && isCorrect) {
                borderColor = Colors.green;
              } else if (isSelected && !isCorrect) {
                borderColor = Colors.red;
              } else if (isCorrect) {
                borderColor = Colors.green;
              } else {
                borderColor = null;
              }
            } else {
              borderColor = isSelected ? Colors.blue : null;
            }

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
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 2)
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
                            color: widget.showAnswers && isCorrect ? Colors.green : null,
                          ),
                        ),
                      ),
                      if (isSelected && !widget.showAnswers)
                        const Icon(Icons.check_circle, color: Colors.blue),
                      if (widget.showAnswers && isSelected && isCorrect)
                        const Icon(Icons.check_circle, color: Colors.green),
                      if (widget.showAnswers && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: Colors.red),
                      if (widget.showAnswers && !isSelected && isCorrect)
                        const Icon(Icons.check_circle_outline, color: Colors.green),
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
    final soal = question['question']?.toString() ?? 'No question available';
    final correctAnswer = question['correct_answer'];
    
    // Safely extract options
    List<String> options = [];
    final questionOptions = question['options'];
    if (questionOptions is List<dynamic>) {
      options = questionOptions.map((opt) => opt.toString()).toList();
    } else if (questionOptions is List<String>) {
      options = questionOptions;
    } else {
      options = ['Benar', 'Salah']; // Default options
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
                question['image'].toString(),
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
                          color: _getBorderColor(options[0], correctAnswer),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              options[0],  // Display dynamic option text
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getTextColor(options[0], correctAnswer),
                              ),
                            ),
                            if (widget.showAnswers && options[0] == correctAnswer)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                              ),
                          ],
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
                    onTap: () => _handleAnswer(options.length > 1 ? options[1] : 'Salah'), // Handle dynamic 'option' answer
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getBorderColor(options.length > 1 ? options[1] : 'Salah', correctAnswer),
                          width: _selectedAnswers[_currentQuestionIndex] == (options.length > 1 ? options[1] : 'Salah') ? 2 : 1,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              options.length > 1 ? options[1] : 'Salah',  // Display dynamic option text
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getTextColor(options.length > 1 ? options[1] : 'Salah', correctAnswer),
                              ),
                            ),
                            if (widget.showAnswers && (options.length > 1 ? options[1] : 'Salah') == correctAnswer)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                              ),
                          ],
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

  // Helper method to get border color based on review mode and correctness
  Color _getBorderColor(String option, String? correctAnswer) {
    if (widget.showAnswers) {
      if (_selectedAnswers[_currentQuestionIndex] == option && option == correctAnswer) {
        return Colors.green;
      } else if (_selectedAnswers[_currentQuestionIndex] == option && option != correctAnswer) {
        return Colors.red;
      } else if (option == correctAnswer) {
        return Colors.green;
      } else {
        return Colors.grey.shade300;
      }
    } else {
      return _selectedAnswers[_currentQuestionIndex] == option ? Colors.blue : Colors.grey.shade300;
    }
  }

  // Helper method to get text color based on review mode and correctness
  Color _getTextColor(String option, String? correctAnswer) {
    if (widget.showAnswers) {
      if (option == correctAnswer) {
        return Colors.green;
      } else if (_selectedAnswers[_currentQuestionIndex] == option && option != correctAnswer) {
        return Colors.red;
      } else {
        return Colors.black;
      }
    } else {
      return _selectedAnswers[_currentQuestionIndex] == option ? Colors.blue : Colors.black;
    }
  }

  // Widget untuk soal esai
  Widget _buildEssayQuestion(Map<String, dynamic> question) {
    final correctAnswer = question['correct_answer'];
    
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
            question['question']?.toString() ?? 'No question text',
            style: const TextStyle(fontSize: 18),
          ),
          if (question['image'] != null && question['image'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Image.network(
                question['image'].toString(),
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
            readOnly: widget.showAnswers, // Make read-only in review mode
            decoration: InputDecoration(
              hintText: widget.showAnswers ? 'Jawaban Anda' : 'Ketik jawaban Anda...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: widget.showAnswers ? Colors.grey.shade100 : Colors.white,
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
            if (!widget.showAnswers)
              ElevatedButton(
                onPressed: () {
                  // Cek apakah semua soal sudah dijawab
                  final allAnswered = !_selectedAnswers.contains(null);
                  if (allAnswered) {
                    _calculateScoreAndShowResult();
                  } else {
                    // Tampilkan dialog peringatan
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Perhatian'),
                          content: const Text('Masih ada soal yang belum dijawab. Apakah Anda yakin ingin menyelesaikan latihan?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _calculateScoreAndShowResult();
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
                  'Selesaikan Latihan',
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
              Text('Menghitung hasil...'),
            ],
          ),
        ),
      );
    }

    // Calculate statistics
    int totalQuestions = questions.length;
    int answeredCount = _selectedAnswers.where((answer) => answer != null).length;
    
    // Calculate percentage score
    double scorePercentage = _maxScore > 0 
        ? (_score / _maxScore) * 100 
        : 0;
    
    // Determine grade based on percentage score
    String grade;
    if (scorePercentage >= 90) {
      grade = 'A';
    } else if (scorePercentage >= 80) {
      grade = 'B';
    } else if (scorePercentage >= 70) {
      grade = 'C';
    } else if (scorePercentage >= 60) {
      grade = 'D';
    } else {
      grade = 'E';
    }
    
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
              'Menyelesaikan Latihan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text(
              'Mata Pelajaran: ${widget.subject}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Jumlah Soal: $totalQuestions',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Soal Dijawab: $answeredCount dari $totalQuestions',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Score display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'Nilai Anda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          '${_score.toStringAsFixed(1)}/${_maxScore.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          grade,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${scorePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // View answers button
            ElevatedButton.icon(
              onPressed: _viewAnswers,
              icon: const Icon(Icons.visibility),
              label: const Text('Lihat Jawaban'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Back to home button
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
