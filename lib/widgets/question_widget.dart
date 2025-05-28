import 'package:flutter/material.dart';
import '../models/question_model.dart';

class QuestionWidget extends StatelessWidget {
  final Question question;
  final String? selectedAnswer;
  final bool isAnswerSubmitted;
  final Function(String) onAnswerSelected;

  const QuestionWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    required this.isAnswerSubmitted,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Question image if available
          if (question.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                question.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Options
          ...question.options.map((option) => _buildOptionItem(option)),
          
          // Explanation (shown after answering)
          if (isAnswerSubmitted) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penjelasan:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.explanation,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionItem(Option option) {
    bool isSelected = selectedAnswer == option.id;
    bool isCorrect = question.correctAnswer == option.id;
    
    // Determine the option's color based on selection and submission status
    Color backgroundColor;
    Color borderColor;
    
    if (isAnswerSubmitted) {
      if (isSelected && isCorrect) {
        // Correct answer selected
        backgroundColor = Colors.green.shade100;
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        // Wrong answer selected
        backgroundColor = Colors.red.shade100;
        borderColor = Colors.red;
      } else if (isCorrect) {
        // Correct answer not selected
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
      } else {
        // Neither selected nor correct
        backgroundColor = Colors.white;
        borderColor = Colors.grey.shade300;
      }
    } else {
      // Not submitted yet
      backgroundColor = isSelected ? const Color(0xFFE3F2FD) : Colors.white;
      borderColor = isSelected ? const Color(0xFF0078D4) : Colors.grey.shade300;
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: InkWell(
        onTap: isAnswerSubmitted ? null : () => onAnswerSelected(option.id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF0078D4) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0078D4) : Colors.grey.shade400,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Center(
                        child: Text(
                          option.id,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.text,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              if (isAnswerSubmitted && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green),
              if (isAnswerSubmitted && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
