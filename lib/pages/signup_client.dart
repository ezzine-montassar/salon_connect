import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class SignupClientPage extends StatefulWidget {
  const SignupClientPage({super.key});

  @override
  State<SignupClientPage> createState() => _SignupClientPageState();
}

class _SignupClientPageState extends State<SignupClientPage> {
  late VideoPlayerController _videoController;
  final AuthService _authService = AuthService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  int _sexe = 0; // 0 = Homme, 1 = Femme
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset("lib/assets/bg2_client.mp4")
      ..initialize().then((_) {
        _videoController.setVolume(0);
        _videoController.setLooping(true);
        _videoController.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Les mots de passe ne correspondent pas."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? error = await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        role: 'client',
      );

      if (error != null) throw Exception(error);

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Erreur utilisateur introuvable.");

      Map<String, dynamic> clientData = {
        "id_client": user.uid,
        "email": emailController.text.trim(),
        "nom_cl": nameController.text.trim(),
        "sexe_cl": _sexe,
        "created_at": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('clients')
          .doc(user.uid)
          .set(clientData);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compte Client créé avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, "/homeClient");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper pour réduire la répétition du style des inputs
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14), // Police plus petite
      filled: true,
      fillColor: Colors.white,
      isDense: true, // Réduit la hauteur interne
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ), // Padding réduit
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // Rayon légèrement réduit
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, "/"),
          ),
        ),
      ),

      body: Stack(
        children: [
          // Video Background
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(color: Colors.black),

          // Dark Overlay
          Container(color: Colors.black.withOpacity(0.4)),

          // Formulaire Compact
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 80, bottom: 20),
              child: Container(
                width: 300, // Largeur réduite (était 330)
                padding: const EdgeInsets.all(20), // Padding réduit (était 25)
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.60),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Inscription Client",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20, // Taille réduite (était 22)
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _buildInputDecoration("Nom complet"),
                    ),
                    const SizedBox(height: 8), // Espace réduit (était 10)
                    // SÉLECTEUR DE SEXE COMPACT
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              Radio<int>(
                                value: 0,
                                groupValue: _sexe,
                                onChanged: (val) =>
                                    setState(() => _sexe = val!),
                                activeColor: Colors.black,
                                visualDensity: VisualDensity
                                    .compact, // Réduit la taille du rond
                              ),
                              const Text(
                                "Homme",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Radio<int>(
                                value: 1,
                                groupValue: _sexe,
                                onChanged: (val) =>
                                    setState(() => _sexe = val!),
                                activeColor: Colors.black,
                                visualDensity: VisualDensity.compact,
                              ),
                              const Text(
                                "Femme",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: emailController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _buildInputDecoration("Email"),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: _buildInputDecoration("Mot de passe"),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: _buildInputDecoration("Confirmer MDP"),
                    ),
                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 40, // Hauteur réduite (était 45)
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                "Créer",
                                style: TextStyle(
                                  fontSize: 16,
                                ), // Taille réduite (était 18)
                              ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, "/loginClient"),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        "Déjà un compte ?",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
