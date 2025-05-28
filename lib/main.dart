import 'package:flutter/material.dart';
// import 'ui/login.dart'; // Ganti dengan path yang benar
// import 'ui/home.dart'; // Ganti dengan path yang benar
import 'ui/latsol.dart';
import 'ui/profil.dart';
import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Set halaman awal
      routes: {
        '/login': (context) => LoginScreen(), // Halaman login
        // '/home1': (context) => HomeScreen1(),
        '/latihansoal': (context) => BukuPage(),
        '/profil': (context) {
          final idSiswa = ModalRoute.of(context)!.settings.arguments as String;
          return Profil(idSiswa: idSiswa);
        },
        
        '/home': (context) {
          // Mengambil idSiswa sebagai parameter dari navigasi sebelumnya
          final idSiswa = ModalRoute.of(context)!.settings.arguments as String;
          return HomeScreen(idSiswa: idSiswa); // Mengirim idSiswa ke HomeScreen
        },

        '/main': (context) {
          // Mengambil idSiswa sebagai parameter dari navigasi sebelumnya
          final idSiswa = ModalRoute.of(context)!.settings.arguments as String;
          return MainScreen(idSiswa: idSiswa); // Mengirim idSiswa ke HomeScreen
        },
         // Halaman utama setelah login
      },
    );
  }
}
