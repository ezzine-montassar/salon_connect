import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileClientPage extends StatefulWidget {
  const ProfileClientPage({super.key});

  @override
  State<ProfileClientPage> createState() => _ProfileClientPageState();
}

class _ProfileClientPageState extends State<ProfileClientPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  final TextEditingController _nomController = TextEditingController();
  int _sexe = 0;

  @override
  void initState() {
    super.initState();
    _fetchClientData();
  }

  Future<void> _fetchClientData() async {
    if (currentUser == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('clients')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nomController.text = data['nom_cl'] ?? '';
          if (data['sexe_cl'] != null) {
            _sexe = data['sexe_cl'];
          }
        });
      }
    } catch (e) {
      debugPrint("Erreur : $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(currentUser!.uid)
          .update({'nom_cl': _nomController.text.trim(), 'sexe_cl': _sexe});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil mis à jour !"),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/loginClient',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  // Styles réutilisables pour le thème blanc
  final InputDecoration _whiteInputDecoration = const InputDecoration(
    labelStyle: TextStyle(color: Colors.white70),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white, width: 2),
    ),
    prefixIconColor: Colors.white,
    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: null,
      ),
      body: Stack(
        children: [
          // 1. L'IMAGE D'ARRIÈRE-PLAN
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              image: DecorationImage(
                image: AssetImage('lib/assets/profil_client.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 2. FILTRE SOMBRE
          Container(color: Colors.black.withOpacity(0.5)),

          // 3. LE CONTENU
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.account_circle,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),

                        // Email (Largeur normale)
                        Text(
                          currentUser?.email ?? "",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // --- SECTION FORMULAIRE RÉDUITE ---
                        Padding(
                          // C'EST ICI : Augmenter ce chiffre réduit la largeur des champs
                          padding: const EdgeInsets.symmetric(horizontal: 75.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // CHAMP : Nom du client
                              TextField(
                                controller: _nomController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _whiteInputDecoration.copyWith(
                                  labelText:
                                      "Nom", // Libellé raccourci pour la petite taille
                                  prefixIcon: const Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // CHAMP : Sexe
                              DropdownButtonFormField<int>(
                                initialValue: _sexe,
                                dropdownColor: Colors.grey[900],
                                style: const TextStyle(color: Colors.white),
                                decoration: _whiteInputDecoration.copyWith(
                                  labelText: "Sexe",
                                  prefixIcon: const Icon(Icons.wc),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 0,
                                    child: Text("Homme"),
                                  ),
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Text("Femme"),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _sexe = val ?? 0),
                              ),

                              const SizedBox(height: 40),

                              // BOUTON : Enregistrer
                              ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "Mettre à jour", // Texte raccourci
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // BOUTON : Déconnexion
                              OutlinedButton.icon(
                                onPressed: _logout,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                icon: const Icon(Icons.logout, size: 20),
                                label: const Text(
                                  "Déconnexion",
                                ), // Texte raccourci
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
