import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class SignupCoiffPage extends StatefulWidget {
  const SignupCoiffPage({super.key});

  @override
  State<SignupCoiffPage> createState() => _SignupCoiffPageState();
}

class _SignupCoiffPageState extends State<SignupCoiffPage> {
  final AuthService _authService = AuthService();

  // Contrôleurs Texte
  final brandController = TextEditingController(); // brand_coiff
  final addressController = TextEditingController(); // NOUVEAU : adresse_coiff
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Variables pour les données spécifiques
  int _speciality = 1; // 1=Homme, 2=Femme, 3=Mixte (Par défaut Homme)
  final List<int> _selectedDays = []; // Array pour les jours
  RangeValues _selectedHours = const RangeValues(
    9,
    18,
  ); // Array pour heures [9, 18]

  bool _isLoading = false;

  @override
  void dispose() {
    brandController.dispose();
    addressController.dispose(); // NOUVEAU : Dispose address
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    // 1. Validations
    if (brandController.text.isEmpty ||
        addressController.text.isEmpty || // NOUVEAU : Validation adresse
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Remplissez tous les champs texte."),
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
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sélectionnez au moins un jour de travail."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Création Auth et Users Collection (via le Service existant)
      String? error = await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: brandController.text
            .trim(), // On utilise le Brand comme nom dans 'users'
        role: 'coiffeur',
      );

      if (error != null) {
        throw Exception(error); // Si erreur auth, on arrête
      }

      // 3. Récupération de l'UID
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Erreur lors de la récupération de l'utilisateur.");
      }

      // 4. Préparation des données Coiffeur
      Map<String, dynamic> coiffeurData = {
        "id_coiff": user.uid,
        "email": emailController.text.trim(),
        "brand_coiff": brandController.text.trim(),
        "addresse_coiff": addressController.text
            .trim(), // NOUVEAU : Ajout adresse_coiff
        "speciality_coiff": _speciality, // Number
        "jours": _selectedDays, // Array of Number
        "heures": [
          _selectedHours.start.round(),
          _selectedHours.end.round(),
        ], // Array [début, fin]
        "created_at": FieldValue.serverTimestamp(),
      };

      // 5. Écriture dans la collection 'coiffeurs'
      await FirebaseFirestore.instance
          .collection('coiffeurs')
          .doc(user.uid)
          .set(coiffeurData);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compte Coiffeur créé avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, "/homeCoiffeur");
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

  // Widget helper pour les jours
  Widget _buildDayChip(String label, int value) {
    bool isSelected = _selectedDays.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected ? _selectedDays.remove(value) : _selectedDays.add(value);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Important avec le ScrollView
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, "/"),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("lib/assets/bg3_coiff.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.25)),

          // Formulaire
          Align(
            alignment: Alignment.topRight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 185,
                bottom: 110,
              ), // Ajusté pour le scroll
              child: Container(
                margin: const EdgeInsets.only(right: 35, bottom: 20),
                width: 280, // Un peu plus large pour les jours
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                    0.5,
                  ), // Un peu plus sombre pour la lisibilité
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Création Salon",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Brand Name
                    TextField(
                      controller: brandController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "Brand",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // NOUVEAU : Champ Adresse
                    TextField(
                      controller: addressController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "Adresse",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Speciality Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _speciality,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 0,
                              child: Text(
                                "Spécialité: Homme",
                                style: TextStyle(
                                  fontSize: 14,
                                ), // Taille modifiée ici
                              ),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                "Spécialité: Femme",
                                style: TextStyle(
                                  fontSize: 14,
                                ), // Taille modifiée ici
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                "Spécialité: Mixte",
                                style: TextStyle(
                                  fontSize: 14,
                                ), // Taille modifiée ici
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _speciality = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Jours de travail
                    const Text(
                      "Jours de travail :",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      children: [
                        _buildDayChip("L", 1),
                        _buildDayChip("Ma", 2),
                        _buildDayChip("Me", 3),
                        _buildDayChip("J", 4),
                        _buildDayChip("V", 5),
                        _buildDayChip("S", 6),
                        _buildDayChip("D", 7),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Heures
                    Text(
                      "Horaires: ${_selectedHours.start.round()}h - ${_selectedHours.end.round()}h",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.grey,
                        thumbColor: Colors.blueAccent,
                        overlayColor: Colors.blueAccent.withOpacity(0.2),
                        valueIndicatorColor: Colors.blueAccent,
                      ),
                      child: RangeSlider(
                        values: _selectedHours,
                        min: 0,
                        max: 24,
                        divisions: 24,
                        labels: RangeLabels(
                          "${_selectedHours.start.round()}h",
                          "${_selectedHours.end.round()}h",
                        ),
                        onChanged: (values) =>
                            setState(() => _selectedHours = values),
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Email & Passwords
                    TextField(
                      controller: emailController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "Email",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "Confirmer MDP",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BOUTON SIGNUP
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                "Créer le Salon",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, "/loginCoiffeur"),
                        child: const Text(
                          "Déjà un compte ?",
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
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
