import 'package:flutter/material.dart';
import 'package:cbt_app/services/auth_services.dart';  // Make sure to import your AuthService
import 'main_screen.dart'; // Ganti dengan path yang benar

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage = ''; // To store the error message

  // Fungsi login
  void _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    setState(() {
      _isLoading = true;  // Start loading
    });

    try {
      Map<String, String>? result = await AuthService().loginUser(email, password);

      if (result != null) {
        String idSiswa = result['idSiswa']!;  // Ambil idSiswa dari result

        // After successful login, navigate to MainScreen with idSiswa
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(idSiswa: idSiswa),  // Pass idSiswa here
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() { 
        _errorMessage = 'Login failed. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;  // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2C8A), // Dark Purple
              Color(0xFF4F88C9), // Light Blue
            ],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 3,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo QuizHub
                Image.asset(
                  'assets/images/logo.jpg', // <- Ensure the logo file exists
                  height: 100,
                ),
                const SizedBox(height: 24),
                // TextField NIS
                _buildTextField(
                  hintText: 'Nomor Induk Siswa',
                  icon: Icons.person_outline,
                  obscureText: false,
                ),
                const SizedBox(height: 16),
                // TextField Password
                _buildTextField(
                  hintText: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _login,  // Call login function on press
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0078D4), // Blue color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()  // Show loading spinner if loading
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              ),
                          ),
                  ),
                ),
                if (_errorMessage != null && _errorMessage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,  // Display error message
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hintText, required IconData icon, required bool obscureText}) {
    return TextField(
      obscureText: obscureText,
      controller: obscureText ? _passwordController : _emailController,  // Ensure the right controller is used
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        suffixIcon: Icon(icon, color: Colors.black54),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black45),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
