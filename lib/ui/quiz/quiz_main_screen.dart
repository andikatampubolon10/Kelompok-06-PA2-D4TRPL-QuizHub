import 'package:flutter/material.dart';
import 'soal1.dart';
import 'soal2.dart';

class QuizMainScreen extends StatefulWidget {
  final String quizTitle;

  const QuizMainScreen({super.key, required this.quizTitle});

  @override
  State<QuizMainScreen> createState() => _QuizMainScreenState();
}

class _QuizMainScreenState extends State<QuizMainScreen> {
  int currentSoalIndex = 0;

  void _changeSoal(int newIndex) {
    setState(() {
      currentSoalIndex = newIndex;
    });
  }

  List<Widget> _buildSoalScreens() {
    return [
      Soal1Screen(
        quizTitle: widget.quizTitle,
        onNext: () => _changeSoal(1),
      ),
      Soal2Screen(
        quizTitle: widget.quizTitle,
        onBack: () => _changeSoal(0),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final soalScreens = _buildSoalScreens();

    return Scaffold(
      body: soalScreens[currentSoalIndex],
    );
  }
}
