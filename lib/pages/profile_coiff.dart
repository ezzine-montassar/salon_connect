import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileCoiffPage extends StatefulWidget {
  const ProfileCoiffPage({super.key});

  @override
  State<ProfileCoiffPage> createState() => _ProfileCoiffPageState();
}

class _ProfileCoiffPageState extends State<ProfileCoiffPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  // --- PALETTE DE COULEURS ---
  final Color _primaryColor = const Color(0xFF2C2C2C);
  final Color _accentColor = const Color(0xFFB71C1C);
  final Color _surfaceColor = Colors.white.withOpacity(0.92);

  // Contrôleurs
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // --- NOUVEAU : Variable pour la Spécialité ---
  int? _selectedSpeciality; // Stocke 0, 1 ou 2

  final List<Map<String, dynamic>> _specialityOptions = [
    {'label': 'Homme', 'value': 0},
    {'label': 'Femme', 'value': 1},
    {'label': 'Mixte', 'value': 2},
  ];
  // ---------------------------------------------

  // Variables horaires
  int _heureDebut = 9;
  int _heureFin = 18;
  List<int> _joursTravail = [];

  final List<String> _joursSemaine = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 1. CHARGER LES DONNÉES
  Future<void> _fetchUserData() async {
    if (currentUser == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('coiffeurs')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _brandController.text = data['brand_coiff'] ?? '';
          _addressController.text = data['addresse_coiff'] ?? '';

          // --- RECUPERATION DE LA SPECIALITE ---
          if (data['speciality_coiff'] != null) {
            _selectedSpeciality = data['speciality_coiff'];
          }
          // -------------------------------------

          if (data['jours'] != null) {
            _joursTravail = List<int>.from(data['jours']);
          }
          if (data['heures'] != null && (data['heures'] as List).length >= 2) {
            _heureDebut = data['heures'][0];
            _heureFin = data['heures'][1];
          }
        });
      }
    } catch (e) {
      debugPrint("Erreur de chargement: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. SAUVEGARDER
  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('coiffeurs')
          .doc(currentUser!.uid)
          .update({
            'brand_coiff': _brandController.text.trim(),
            'addresse_coiff': _addressController.text.trim(),
            // --- ENREGISTREMENT DE LA SPECIALITE ---
            'speciality_coiff': _selectedSpeciality,
            // ---------------------------------------
            'heures': [_heureDebut, _heureFin],
            'jours': _joursTravail,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profil mis à jour avec succès !"),
            backgroundColor: _primaryColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. LOGOUT
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/loginCoiffeur', // Assurez-vous que cette route existe
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- ARRIÈRE-PLAN ---
        Positioned(
          top: -30,
          left: 0,
          right: 0,
          bottom: 0,
          child: Image.asset('lib/assets/profil_coiff.png', fit: BoxFit.cover),
        ),

        // --- CONTENU SCROLLABLE ---
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(color: Colors.white),
            title: null,
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: 150,
                    left: 20,
                    right: 20,
                    bottom: 30,
                  ),
                  child: Column(
                    children: [
                      // --- CARTE DE PROFIL ---
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Avatar
                            Center(
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundColor: Colors.grey[200],
                                    child: Icon(
                                      Icons.store_mall_directory,
                                      size: 50,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                currentUser?.email ?? "",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Divider(height: 40, thickness: 1),

                            // Formulaire
                            _buildSectionTitle("Identité du Salon"),
                            _buildTextField(
                              "Nom commercial",
                              _brandController,
                              Icons.cut,
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              "Adresse complète",
                              _addressController,
                              Icons.location_on,
                            ),
                            const SizedBox(height: 15),

                            // --- NOUVEAU CHAMP SPÉCIALITÉ ---
                            DropdownButtonFormField<int>(
                              value: _selectedSpeciality,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: "Spécialité",
                                labelStyle: TextStyle(color: Colors.grey[600]),
                                prefixIcon: Icon(
                                  Icons.people,
                                  color: _primaryColor,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: _specialityOptions.map((option) {
                                return DropdownMenuItem<int>(
                                  value: option['value'],
                                  child: Text(option['label']),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedSpeciality = val;
                                });
                              },
                              validator: (val) =>
                                  val == null ? "Choix requis" : null,
                            ),

                            // --------------------------------
                            const SizedBox(height: 30),
                            _buildSectionTitle("Plages Horaires"),

                            // Heures
                            Row(
                              children: [
                                Expanded(
                                  child: _buildHourDropdown(
                                    "Ouverture",
                                    _heureDebut,
                                    (val) => setState(() => _heureDebut = val!),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 20,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: _primaryColor,
                                  ),
                                ),
                                Expanded(
                                  child: _buildHourDropdown(
                                    "Fermeture",
                                    _heureFin,
                                    (val) => setState(() => _heureFin = val!),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),
                            _buildSectionTitle("Jours d'ouverture"),

                            // Chips Jours
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: List.generate(_joursSemaine.length, (
                                index,
                              ) {
                                int dayValue = index + 1;
                                bool isSelected = _joursTravail.contains(
                                  dayValue,
                                );
                                return FilterChip(
                                  label: Text(_joursSemaine[index]),
                                  selected: isSelected,
                                  selectedColor: _primaryColor,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: Colors.grey[200],
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (bool selected) {
                                    setState(() {
                                      selected
                                          ? _joursTravail.add(dayValue)
                                          : _joursTravail.remove(dayValue);
                                      _joursTravail.sort();
                                    });
                                  },
                                );
                              }),
                            ),

                            const SizedBox(height: 40),

                            // Bouton Sauvegarder
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  "ENREGISTRER",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bouton Déconnexion
                      TextButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          "Se déconnecter",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: _accentColor.withOpacity(0.9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // --- WIDGETS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: _accentColor),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: _primaryColor),
        filled: true,
        fillColor: Colors.grey[100],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildHourDropdown(
    String label,
    int value,
    ValueChanged<int?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: _primaryColor),
              items: List.generate(24, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(
                    "${index.toString().padLeft(2, '0')}:00",
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
