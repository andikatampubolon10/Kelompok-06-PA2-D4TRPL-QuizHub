import 'package:flutter/material.dart';

class SubjectItem extends StatelessWidget {
  final String subject;
  final VoidCallback? onTap;

  const SubjectItem({
    super.key,
    required this.subject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Row(
              children: [
                const Icon(
                  Icons.book,
                  color: Color(0xFF0078D4),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF0078D4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
