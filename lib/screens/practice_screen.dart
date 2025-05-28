import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../widgets/question_widget.dart';
import '../widgets/progress_bar.dart';

class PracticeScreen extends StatefulWidget {
  final String subject;
  final int gradeLevel;

  const PracticeScreen({
    super.key,
    required this.subject,
    required this.gradeLevel,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  late List<Question> questions;
  int currentQuestionIndex = 0;
  Map<String, String> userAnswers = {};
  bool isAnswerSubmitted = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    questions = QuestionRepository().getQuestionsForSubjectAndGrade(
      widget.subject,
      widget.gradeLevel,
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleAnswer(String questionId, String answerId) {
    if (!isAnswerSubmitted) {
      setState(() {
        userAnswers[questionId] = answerId;
        isAnswerSubmitted = true;
      });
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      _animationController.reverse().then((_) {
        setState(() {
          currentQuestionIndex++;
          isAnswerSubmitted = userAnswers.containsKey(questions[currentQuestionIndex].id);
        });
        _animationController.forward();
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      _animationController.reverse().then((_) {
        setState(() {
          currentQuestionIndex--;
          isAnswerSubmitted = userAnswers.containsKey(questions[currentQuestionIndex].id);
        });
        _animationController.forward();
      });
    }
  }

  void _showCompletionDialog() {
    int correctAnswers = 0;
    for (var question in questions) {
      if (userAnswers[question.id] == question.correctAnswer) {
        correctAnswers++;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Latihan Selesai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Skor Anda: $correctAnswers dari ${questions.length}'),
            const SizedBox(height: 16),
            Text(
              correctAnswers == questions.length
                  ? 'Sempurna! Semua benar.'
                  : correctAnswers >= questions.length / 2
                      ? 'Bagus! Terus berlatih.'
                      : 'Tetap semangat berlatih!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to subject screen
            },
            child: const Text('Kembali ke Mata Pelajaran'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentQuestionIndex = 0;
                userAnswers.clear();
                isAnswerSubmitted = false;
              });
              _animationController.reset();
              _animationController.forward();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0078D4),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subject,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Keluar dari Latihan?'),
                content: const Text('Progres latihan Anda tidak akan disimpan.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0078D4),
                    ),
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFF0078D4),
        elevation: 0,
      ),
      body: questions.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                ProgressBar(
                  currentQuestion: currentQuestionIndex + 1,
                  totalQuestions: questions.length,
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _animation,
                    child: QuestionWidget(
                      question: questions[currentQuestionIndex],
                      selectedAnswer: userAnswers[questions[currentQuestionIndex].id],
                      isAnswerSubmitted: isAnswerSubmitted,
                      onAnswerSelected: (answerId) => _handleAnswer(
                        questions[currentQuestionIndex].id,
                        answerId,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: currentQuestionIndex > 0 ? _previousQuestion : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Sebelumnya'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0078D4),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: isAnswerSubmitted ? _nextQuestion : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          currentQuestionIndex < questions.length - 1
                              ? 'Selanjutnya'
                              : 'Selesai',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0078D4),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.book_outlined,
            size: 64,
            color: Color(0xFF0078D4),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada soal latihan untuk ${widget.subject} Kelas ${widget.gradeLevel}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Silakan pilih mata pelajaran lain',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0078D4),
            ),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}
