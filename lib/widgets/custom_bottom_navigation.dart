import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      notchMargin: 8,
      shape: const CircularNotchedRectangle(), // Allows for FAB notch
      color: Colors.white,
      elevation: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('assets/images/latsol.png', 0),
            _buildNavItem('assets/images/raport.png', 1),
            _buildNavItem('assets/images/home.png', 2),
            _buildNavItem('assets/images/course.png', 3),
            _buildNavItem('assets/images/profile.png', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String imagePath, int index) {
    final bool isSelected = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () {
          onTap(index); // Pass index to update the current page in PageView
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              color: isSelected ? const Color(0xFF0078D4) : Colors.grey, // Highlight selected item
              width: 28,  // Adjust width for better visibility
              height: 28, // Adjust height for better visibility
            ),
            const SizedBox(height: 4),  // Add space between icon and label
            Text(
              _getLabel(index),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF0078D4) : Colors.grey, // Text color matches the icon color
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get corresponding label for each tab
  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'Latihan';
      case 1:
        return 'Raport';
      case 2:
        return 'Home';
      case 3:
        return 'Course';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }
}
