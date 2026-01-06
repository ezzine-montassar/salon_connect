import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeClientPage extends StatefulWidget {
  const HomeClientPage({super.key});

  @override
  State<HomeClientPage> createState() => _HomeClientPageState();
}

class _HomeClientPageState extends State<HomeClientPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _nomClient = "Client";

  // Contrôleurs de recherche
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // --- AJOUT : Variable et options pour la spécialité ---
  int? _selectedSpeciality;
  final List<Map<String, dynamic>> _specialityOptions = [
    {'label': 'Homme', 'value': 0},
    {'label': 'Femme', 'value': 1},
    {'label': 'Mixte', 'value': 2},
  ];

  // État de l'interface
  bool _isLoading = false;
  List<DocumentSnapshot> _foundCoiffeurs = [];
  DocumentSnapshot? _selectedCoiffeur;
  DateTime _bookingDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _fetchClientInfo();
  }

  Future<void> _fetchClientInfo() async {
    if (currentUser != null) {
      try {
        var doc = await FirebaseFirestore.instance
            .collection('clients')
            .doc(currentUser!.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _nomClient = doc.get('nom_cl') ?? "Mon Compte";
          });
        }
      } catch (e) {
        debugPrint("Erreur recup client: $e");
      }
    }
  }

  // --- 1. RECHERCHE ---
  Future<void> _searchCoiffeurs() async {
    FocusScope.of(context).unfocus();

    // Vérification : on doit avoir au moins un critère (Nom, Ville ou Spécialité)
    if (_brandController.text.isEmpty &&
        _addressController.text.isEmpty &&
        _selectedSpeciality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer un critère de recherche"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Query query = FirebaseFirestore.instance.collection('coiffeurs');

    // Priorité aux filtres texte pour la requête Firebase
    if (_brandController.text.isNotEmpty) {
      query = query.where(
        'brand_coiff',
        isEqualTo: _brandController.text.trim(),
      );
    } else if (_addressController.text.isNotEmpty) {
      query = query.where(
        'addresse_coiff',
        isEqualTo: _addressController.text.trim(),
      );
    }
    // Si on a que la spécialité, on récupère tout pour filtrer ensuite (ou on pourrait faire un where ici)
    // Pour simplifier avec vos index existants, on garde la logique de filtrage local si pas de texte.

    try {
      QuerySnapshot snapshot = await query.get();
      List<DocumentSnapshot> results = snapshot.docs;

      // --- MODIFICATION : Filtrage local pour la spécialité ---
      if (_selectedSpeciality != null) {
        results = results.where((doc) {
          try {
            // Récupération sécurisée du champ 'speciality_coiff'
            final data = doc.data() as Map<String, dynamic>;

            // Si le champ n'existe pas, on met -1 par défaut
            int coiffSpec = data.containsKey('speciality_coiff')
                ? (data['speciality_coiff'] ?? -1)
                : -1;

            // Logique de filtrage :
            // Si je cherche Homme (0) -> Je veux les salons Homme (0) OU Mixte (2)
            // Si je cherche Femme (1) -> Je veux les salons Femme (1) OU Mixte (2)
            // Si je cherche Mixte (2) -> Je veux Mixte (2)
            if (_selectedSpeciality == 2) {
              return coiffSpec == 2;
            } else {
              return coiffSpec == _selectedSpeciality || coiffSpec == 2;
            }
          } catch (e) {
            return false;
          }
        }).toList();
      }

      if (mounted) {
        setState(() {
          _foundCoiffeurs = results;
          _selectedCoiffeur = null;

          if (_brandController.text.isNotEmpty && results.length == 1) {
            _selectedCoiffeur = results.first;
          }

          if (results.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Aucun coiffeur trouvé avec ces critères."),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Erreur recherche: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la recherche: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- 2. RÉSERVATION ---
  Future<void> _bookSlot(DateTime dateHeure) async {
    if (_selectedCoiffeur == null || currentUser == null) return;

    try {
      await FirebaseFirestore.instance.collection('rendez_vous').add({
        'id_cl': currentUser!.uid,
        'nom_cl': _nomClient,
        'id_coiff': _selectedCoiffeur!.id,
        'brand_coiff': _selectedCoiffeur!.get('brand_coiff'),
        'date_heure': Timestamp.fromDate(dateHeure),
        'statut': 0, // 0 = En attente
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Demande envoyée ! En attente de confirmation."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _selectedCoiffeur = null;
          _brandController.clear();
          _addressController.clear();
          _selectedSpeciality = null; // Reset spec
          _foundCoiffeurs = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur réservation: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color beigeBarColor = const Color(0xFF4A3B32);
    final Color darkBrownColor = const Color(0xFF4A3B32);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: beigeBarColor,
        elevation: 4,
        automaticallyImplyLeading: false,
        titleSpacing: 35.0,
        title: Image.asset(
          'lib/assets/logo_blanc.png',
          height: 50,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 40.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profileClient'),
              child: Chip(
                backgroundColor: Colors.white.withOpacity(0.8),
                avatar: const Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.black54,
                ),
                label: Text(
                  _nomClient,
                  style: TextStyle(
                    color: darkBrownColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // 1. IMAGE D'ARRIÈRE-PLAN
          Positioned.fill(
            child: Image.asset(
              "lib/assets/bg_home_client.png",
              fit: BoxFit.cover,
            ),
          ),

          // 2. FILTRE NOIR
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          // 3. CONTENU DÉFILANT
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // --- MES RDV ---
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Mes Rendez-vous",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildUpcomingAppointments(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- RECHERCHE ---
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Trouver un coiffeur",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Champ NOM
                        TextField(
                          controller: _brandController,
                          decoration: InputDecoration(
                            labelText: "Par nom du salon",
                            prefixIcon: const Icon(Icons.store),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            "- OU -",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Champ VILLE
                        TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: "Par ville",
                            prefixIcon: const Icon(Icons.location_on),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // --- AJOUT : Champ SPÉCIALITÉ ---
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Spécialité',
                            prefixIcon: const Icon(
                              Icons.wc,
                            ), // Icone Homme/Femme
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // Bouton pour effacer le filtre si sélectionné
                            suffixIcon: _selectedSpeciality != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _selectedSpeciality = null;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          value: _selectedSpeciality,
                          items: _specialityOptions.map((option) {
                            return DropdownMenuItem<int>(
                              value: option['value'] as int,
                              child: Text(option['label'] as String),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedSpeciality = newValue;
                            });
                          },
                        ),

                        // ---------------------------------
                        const SizedBox(height: 15),

                        // Bouton Rechercher
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkBrownColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isLoading ? null : _searchCoiffeurs,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Rechercher",
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- RÉSULTATS ---
                  if (_selectedCoiffeur != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: _buildBookingInterface(_selectedCoiffeur!),
                    )
                  else if (_foundCoiffeurs.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _foundCoiffeurs.length,
                      itemBuilder: (context, index) {
                        var coiff = _foundCoiffeurs[index];
                        var data = coiff.data() as Map<String, dynamic>;

                        // Récupération spécialité pour affichage
                        int spec = data['speciality_coiff'] ?? -1;
                        String specText = "Non spécifié";
                        if (spec == 0) specText = "Homme";
                        if (spec == 1) specText = "Femme";
                        if (spec == 2) specText = "Mixte";

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: beigeBarColor,
                              child: const Icon(Icons.cut, color: Colors.white),
                            ),
                            title: Text(
                              data['brand_coiff'] ?? "Salon",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['addresse_coiff'] ??
                                      data['adresse'] ??
                                      "Adresse non spécifiée",
                                ),
                                Text(
                                  "Spécialité : $specText",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              setState(() {
                                _selectedCoiffeur = coiff;
                                _bookingDate = DateTime.now();
                              });
                            },
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STREAM DES RDV ---
  Widget _buildUpcomingAppointments() {
    if (currentUser == null) return const Text("Veuillez vous connecter.");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rendez_vous')
          .where('id_cl', isEqualTo: currentUser!.uid)
          .where('date_heure', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date_heure')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // ... (votre code d'erreur existant) ...
          return const SizedBox(); // Simplifié pour l'exemple
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "Aucun rendez-vous à venir.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // --- CHANGEMENT 1 : HAUTEUR FIXE DE LA SECTION ---
        // J'ai réduit la hauteur de 120 à 100 pour que ce soit plus compact
        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              Timestamp? ts = data['date_heure'] as Timestamp?;
              if (ts == null) return const SizedBox();
              DateTime date = ts.toDate();

              var rawStatut = data['statut'];
              int statut = 0;
              if (rawStatut is int)
                statut = rawStatut;
              else if (rawStatut is String)
                statut = int.tryParse(rawStatut) ?? 0;

              bool isConfirmed = (statut == 1);
              // Couleurs (inchangées)
              Color bg = isConfirmed
                  ? Colors.green.shade100
                  : Colors.orange.shade100;
              Color borderC = isConfirmed ? Colors.green : Colors.orange;
              Color textC = isConfirmed
                  ? Colors.green.shade900
                  : Colors.orange.shade900;
              String statusTxt = isConfirmed ? "Confirmé" : "En attente";
              IconData statusIcon = isConfirmed
                  ? Icons.check_circle
                  : Icons.hourglass_empty;

              return Container(
                // --- CHANGEMENT 2 : LARGEUR FIXE DE LA CARTE ---
                // J'ai réduit la largeur de 180 à 150
                width: 175,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(
                  10,
                ), // Padding légèrement réduit (était 12)
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderC.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment
                      .spaceAround, // Répartit l'espace verticalement
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM HH:mm').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textC,
                            fontSize: 14, // Taille de police réduite (était 16)
                          ),
                        ),
                        // --- CHANGEMENT 3 : TAILLE DE L'ICÔNE RÉDUITE ---
                        Icon(
                          statusIcon,
                          size: 16,
                          color: borderC,
                        ), // (était 18)
                      ],
                    ),
                    Text(
                      data['brand_coiff'] ?? "Salon",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 13, // Optionnel : adapter la police
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusTxt.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9, // Police réduite (était 10)
                          fontWeight: FontWeight.bold,
                          color: textC,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- CALENDRIER 1 AN ---
  // --- CALENDRIER 1 AN (MODIFIÉ) ---
  Widget _buildBookingInterface(DocumentSnapshot coiffeurDoc) {
    Map<String, dynamic> data = coiffeurDoc.data() as Map<String, dynamic>;

    // Récupération des jours travaillés (ex: [1, 2, 3, 4, 5])
    List<dynamic> jours = data['jours'] ?? [1, 2, 3, 4, 5, 6];
    List<dynamic> heures = data['heures'] ?? [9, 19];

    // On convertit la liste brute en liste d'entiers pour être sûr (1=Lundi, 7=Dimanche)
    List<int> workingDaysInt = jours
        .map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF4A3B32)),
                  onPressed: () => setState(() => _selectedCoiffeur = null),
                ),
                Expanded(
                  child: Text(
                    "Réserver chez ${data['brand_coiff']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF4A3B32),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- CALENDRIER ---
          TableCalendar(
            locale: 'fr_FR',
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _bookingDate,
            currentDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
            rowHeight: 45,
            daysOfWeekHeight: 30,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Color(0xFF4A3B32),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Color(0xFFC49A6C),
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Color(0xFFC49A6C),
              ),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFC49A6C),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFFC49A6C).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFF4A3B32),
                fontWeight: FontWeight.bold,
              ),
              outsideDaysVisible: false,
            ),

            // --- C'EST ICI QUE LA COULEUR DES JOURS (LUN, MAR...) CHANGE ---
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text = DateFormat.E('fr_FR').format(day);
                final cleanText = text.replaceAll('.', '').toUpperCase();

                // Vérifie si ce jour de la semaine (ex: Lundi=1) est dans la liste du coiffeur
                bool isWorkingDay = workingDaysInt.contains(day.weekday);

                return Center(
                  child: Text(
                    cleanText,
                    style: TextStyle(
                      // VERT si travaille, NOIR si ne travaille pas
                      color: isWorkingDay ? Colors.green : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),

            selectedDayPredicate: (day) => isSameDay(_bookingDate, day),
            onDaySelected: (selectedDay, focusedDay) =>
                setState(() => _bookingDate = selectedDay),
          ),

          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),

          _buildSlotsGrid(coiffeurDoc.id, jours, heures),
        ],
      ),
    );
  }

  // --- GÉNÉRATION DES CRÉNEAUX ---
  // --- GÉNÉRATION DES CRÉNEAUX (CORRIGÉ) ---
  Widget _buildSlotsGrid(
    String coiffId,
    List<dynamic> jours,
    List<dynamic> heures,
  ) {
    // 1. Vérification des jours d'ouverture
    List<int> joursInt = jours
        .map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 1)
        .toList();

    if (!joursInt.contains(_bookingDate.weekday)) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.block, color: Colors.grey),
            Text(
              "Le salon est fermé ce jour.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 2. Définition du début et fin de la journée sélectionnée
    DateTime startOfDay = DateTime(
      _bookingDate.year,
      _bookingDate.month,
      _bookingDate.day,
      0,
      0,
    );
    DateTime endOfDay = DateTime(
      _bookingDate.year,
      _bookingDate.month,
      _bookingDate.day,
      23,
      59,
    );

    // 3. Récupération des RDV existants pour ne pas afficher les créneaux pris
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rendez_vous')
          .where('id_coiff', isEqualTo: coiffId)
          .where(
            'date_heure',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'date_heure',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .orderBy('date_heure')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        // Stocke les heures déjà prises dans un Set pour vérification rapide
        Set<String> takenTimes = {};
        for (var doc in snapshot.data!.docs) {
          // .toDate() convertit le Timestamp UTC de Firebase en Heure Locale du téléphone
          DateTime d = (doc['date_heure'] as Timestamp).toDate();
          takenTimes.add("${d.hour}:${d.minute.toString().padLeft(2, '0')}");
        }

        List<Widget> slots = [];

        // Récupération heures ouverture/fermeture (ex: 9h - 19h)
        int startH = (heures.isNotEmpty && heures[0] is int) ? heures[0] : 9;
        int endH = (heures.length > 1 && heures[1] is int) ? heures[1] : 19;

        // Variable qui va parcourir la journée
        DateTime current = DateTime(
          _bookingDate.year,
          _bookingDate.month,
          _bookingDate.day,
          startH,
          0,
        );

        // Date limite (heure de fin)
        DateTime limit = DateTime(
          _bookingDate.year,
          _bookingDate.month,
          _bookingDate.day,
          endH,
          0,
        );

        // --- BOUCLE DE CRÉATION DES BOUTONS ---
        while (current.isBefore(limit)) {
          int h = current.hour;
          int m = current.minute;
          String key = "$h:${m.toString().padLeft(2, '0')}";

          bool isTaken = takenTimes.contains(key);
          bool isPast = current.isBefore(DateTime.now());

          // --- CORRECTIF IMPORTANT ICI ---
          // On crée une variable 'slotTime' qui est une COPIE de 'current'
          // C'est cette variable qu'on passera au bouton.
          // Ainsi, même si 'current' change après, 'slotTime' reste figé pour ce bouton.
          final DateTime slotTime = current;

          slots.add(
            InkWell(
              // On utilise slotTime ici au lieu de current
              onTap: (!isTaken && !isPast)
                  ? () => _showConfirmDialog(slotTime)
                  : null,
              child: Container(
                width: 80,
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isTaken
                      ? Colors.red.shade100
                      : (isPast ? Colors.grey.shade200 : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (!isTaken && !isPast)
                        ? const Color(0xFFC49A6C)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    key,
                    style: TextStyle(
                      color: isTaken
                          ? Colors.red
                          : (isPast ? Colors.grey : Colors.black87),
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );

          // On avance de 30 minutes pour le prochain tour de boucle
          current = current.add(const Duration(minutes: 30));
        }

        return Wrap(alignment: WrapAlignment.center, children: slots);
      },
    );
  }

  void _showConfirmDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la réservation"),
        content: Text(
          "Voulez-vous réserver pour le ${DateFormat('dd/MM à HH:mm').format(date)} ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bookSlot(date);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC49A6C),
            ),
            child: const Text(
              "Confirmer",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
