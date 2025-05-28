  import 'package:flutter/material.dart';

  class CustomBottomNavigation extends StatelessWidget {
    final int currentIndex;
    final Function(int)? onTap;

    const CustomBottomNavigation({
      super.key,
      required this.currentIndex,
      this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      return BottomAppBar(
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
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
            if (onTap != null) {
              onTap!(index);
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                color: isSelected ? const Color(0xFF0078D4) : Colors.grey,
                width: 24, // Ukuran gambar
                height: 24,
              ),
            ],
          ),
        ),
      );
    }
  }
