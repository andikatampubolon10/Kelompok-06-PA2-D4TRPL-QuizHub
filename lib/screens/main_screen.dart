import 'package:flutter/material.dart';
import 'grade_selection_screen.dart';
import 'raport_course_screen.dart';
import 'home_screen.dart'; // Import HomeScreen
import 'course_categories_screen.dart';
import 'kurikulum_latihan_soal_screen.dart';
import 'profile_screen.dart';
import 'course_list_screen.dart';
import '../widgets/custom_bottom_navigation.dart'; // Import your custom bottom navigation widget

class MainScreen extends StatefulWidget {
  final String idSiswa; // Make sure to pass id_siswa to the MainScreen

  const MainScreen({super.key, required this.idSiswa}); // Pass id_siswa when calling MainScreen

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Default page is HomeScreen
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index; // Update the current index
    });
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index; // Update the current index when page changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to change pages
        children: [
          KurikulumLatihanSoalScreen(), // Your Grade Selection screen
          RaportCourseScreen(idSiswa: widget.idSiswa), // Your Raport Course screen
          HomeScreen(idSiswa: widget.idSiswa), // Pass idSiswa to HomeScreen
          CourseListScreen(idSiswa: widget.idSiswa), // Your Course Category screen
          ProfileScreen(idSiswa: widget.idSiswa), // Your Profile screen
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavTapped, // Pass the onTap callback to the navigation bar
      ),
    );
  }
}
