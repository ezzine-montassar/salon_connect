import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Vos imports existants
import 'pages/home_page.dart';
import 'pages/login_client.dart';
import 'pages/login_coiff.dart';
import 'pages/signup_coiff.dart';
import 'pages/signup_client.dart';
import 'pages/home_client.dart';
import 'pages/home_coiff.dart';

// --- NOUVEAUX IMPORTS (Indispensables pour la navigation) ---
// Si ces lignes sont rouges, c'est que vous n'avez pas encore créé les fichiers.
// Pas de panique, je vous donne le code de ces fichiers juste après.
import 'pages/profile_client.dart';
import 'pages/profile_coiff.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SalonConnectApp());
}

class SalonConnectApp extends StatelessWidget {
  const SalonConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salon Connect',
      debugShowCheckedModeBanner: false,

      // THEME GLOBAL
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF7E9D5),
        primaryColor: const Color(0xFFC49A6C),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC49A6C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 3,
            foregroundColor: Colors.white,
          ),
        ),
      ),

      // ROUTES
      routes: {
        '/': (context) => const HomePage(),

        // Routes Client
        '/loginClient': (context) => const LoginClientPage(),
        '/signupClient': (context) => const SignupClientPage(),
        '/homeClient': (context) => const HomeClientPage(),
        '/profileClient': (context) => const ProfileClientPage(), // <--- AJOUTÉ
        // Routes Coiffeur
        '/loginCoiffeur': (context) => const LoginCoiffPage(),
        '/signupCoiffeur': (context) => const SignupCoiffPage(),
        '/homeCoiffeur': (context) => const HomeCoiffeurPage(),
        '/profileCoiffeur': (context) =>
            const ProfileCoiffPage(), // <--- AJOUTÉ
      },
    );
  }
}
