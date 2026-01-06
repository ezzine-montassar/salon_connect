import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class LoginCoiffPage extends StatefulWidget {
  const LoginCoiffPage({super.key});

  @override
  State<LoginCoiffPage> createState() => _LoginCoiffPageState();
}

class _LoginCoiffPageState extends State<LoginCoiffPage> {
  final AuthService _authService = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // ... (Votre logique reste identique) ...
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer email et mot de passe."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? error = await _authService.signIn(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (error != null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot coiffDoc = await FirebaseFirestore.instance
          .collection('coiffeurs')
          .doc(uid)
          .get();

      if (!coiffDoc.exists) {
        await _authService.signOut();
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Accès refusé. Ce compte n'est pas un compte Coiffeur.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/homeCoiffeur");
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de vérification: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. LE STACK EN PREMIER (Comme pour la page Client)
    return Stack(
      children: [
        // --- COUCHE 1 : IMAGE D'ARRIÈRE-PLAN (FIXE) ---
        Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("lib/assets/bg_coiff.png"), // Votre image
              fit: BoxFit.cover, // Remplit tout l'écran
            ),
          ),
        ),

        // --- COUCHE 2 : FILTRE SOMBRE ---
        // Permet de lire le texte blanc sur l'image
        Container(color: Colors.black.withOpacity(0.4)),

        // --- COUCHE 3 : LE CONTENU (DYNAMIQUE) ---
        Scaffold(
          backgroundColor: Colors.transparent, // Fond transparent obligatoire
          resizeToAvoidBottomInset:
              true, // Le formulaire remonte quand le clavier sort
          // AppBar transparente pour le bouton retour
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, "/"),
              ),
            ),
          ),

          // Le corps centré et scrollable
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                    0.60,
                  ), // Fond du formulaire semi-transparent
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Prend juste la hauteur nécessaire
                  children: [
                    const Text(
                      "Espace Coiffeur",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Champ Email
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: Colors.white10, // Légèrement transparent
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Champ Mot de passe
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Bouton de connexion
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              Colors.black, // Texte noir sur bouton blanc
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Se connecter",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Lien Créer un compte
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, "/signupCoiffeur"),
                      child: const Text(
                        "Créer un compte professionnel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
