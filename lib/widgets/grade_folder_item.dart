import 'package:flutter/material.dart';

class GradeFolderItem extends StatelessWidget {
  final String grade;
  final VoidCallback onTap;

  const GradeFolderItem({
    super.key,
    required this.grade,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
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
                  Icons.folder,
                  color: Color(0xFF0078D4),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  grade,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
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
