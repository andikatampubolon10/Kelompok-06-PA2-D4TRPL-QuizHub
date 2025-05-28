import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:cbt_app/screens/login_screen.dart';

class AuthService {
  // Login function
  Future<Map<String, String>?> loginUser(String email, String password) async {
    var url = Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/login');  // URL endpoint login

    var body = jsonEncode({
      'email': email,
      'password': password,
    });

    var headers = {
      'Content-Type': 'application/json',
    };

    try {
      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String token = data['token'];
        String idSiswa = data['id_siswa'].toString(); // Mengambil id_siswa dari respons

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('token', token);

        return {'token': token, 'idSiswa': idSiswa};  // Kembalikan token dan id_siswa
      } else {
        print("Login failed: ${response.body}");
        return null;  // Mengembalikan null jika login gagal
      }
    } catch (e) {
      print("Error: $e");
      return null;  // Mengembalikan null jika gagal menghubungi server
    }
  }

  // Sign out function
  Future<void> signOut(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');  // Remove the token

    // After clearing the session, navigate back to the login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),  // Assuming LoginScreen is your login page
      (Route<dynamic> route) => false,  // Remove all previous routes to prevent back navigation
    );
  }
}
