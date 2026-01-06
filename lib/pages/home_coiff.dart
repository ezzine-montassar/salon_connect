import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomeCoiffeurPage extends StatefulWidget {
  const HomeCoiffeurPage({super.key});

  @override
  State<HomeCoiffeurPage> createState() => _HomeCoiffeurPageState();
}

class _HomeCoiffeurPageState extends State<HomeCoiffeurPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- VARIABLES D'ÉTAT ---
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
  }

  // --- 1. DIALOGUE CONFIRMATION ---
  void _showConfirmationDialog(String docId, String clientName, String heure) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Rdv de $heure", style: const TextStyle(fontSize: 16)),
        content: Text(
          "Client : $clientName\n\nConfirmer ce rendez-vous ?",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('rendez_vous')
                  .doc(docId)
                  .update({'statut': 1});
            },
            child: const Text(
              "Accepter",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color beigeColor = const Color(0xFFE9CCA1);
    final Color darkBrownColor = const Color(0xFF4A3B32);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Non connecté")));
    }

    // --- STREAMBUILDER ---
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coiffeurs')
          .doc(currentUser!.uid)
          .snapshots(),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Erreur de chargement")),
          );
        }
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data =
            profileSnapshot.data!.data() as Map<String, dynamic>? ?? {};

        final String brandName = data['brand_coiff'] ?? 'Mon Salon';
        // Récupération des jours travaillés
        final List<int> joursTravail = data['jours'] != null
            ? List<int>.from(data['jours'])
            : [];

        int heureDebut = 9;
        int heureFin = 19;
        if (data['heures'] != null && (data['heures'] as List).length >= 2) {
          heureDebut = data['heures'][0];
          heureFin = data['heures'][1];
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.white.withOpacity(0.8),
            elevation: 4,
            automaticallyImplyLeading: false,
            centerTitle: false,
            titleSpacing: 35.0,
            title: Image.asset(
              'lib/assets/logo_rb.png',
              height: 50,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 40.0),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profileCoiffeur'),
                  child: Chip(
                    backgroundColor: beigeColor,
                    avatar: const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.black54,
                    ),
                    label: Text(
                      brandName,
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
              // FOND FIXE
              Container(
                height: double.infinity,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7E9D5),
                  image: DecorationImage(
                    image: AssetImage("lib/assets/bg_home_coiff.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // CONTENU SCROLLABLE & CENTRÉ
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // --- PLANNING (HAUT) ---
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white70,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(25),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 15.0,
                                        bottom: 5,
                                        left: 15,
                                        right: 15,
                                      ),
                                      child: Text(
                                        "Planning du ${DateFormat('EEEE d MMM', 'fr_FR').format(_selectedDay)}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    _buildSlotsGrid(
                                      joursTravail,
                                      heureDebut,
                                      heureFin,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // --- CALENDRIER (BAS) ---
                              // <--- MODIFICATION ICI : On passe la liste 'joursTravail'
                              _buildCalendarCard(joursTravail),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET CALENDRIER ---
  // <--- MODIFICATION ICI : On accepte le paramètre List<int> joursTravail
  Widget _buildCalendarCard(List<int> joursTravail) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 45),
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: TableCalendar(
        locale: 'fr_FR',
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        currentDay: DateTime.now(),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
        rowHeight: 40,
        daysOfWeekHeight: 25,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            size: 20,
            color: Color(0xFFC49A6C),
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            size: 20,
            color: Color(0xFFC49A6C),
          ),
          headerPadding: EdgeInsets.symmetric(vertical: 5),
        ),
        calendarBuilders: CalendarBuilders(
          // <--- MODIFICATION ICI : Gestion de la couleur des jours (LUN, MAR...)
          dowBuilder: (context, day) {
            final text = DateFormat.E('fr_FR').format(day);
            final cleanText = text.replaceAll('.', '').toUpperCase();

            // On vérifie si ce jour (1=Lundi, 7=Dimanche) est dans la liste des jours travaillés
            final bool isOpen = joursTravail.contains(day.weekday);

            return Center(
              child: Text(
                cleanText,
                style: TextStyle(
                  // VERT si ouvert, NOIR si fermé
                  color: isOpen ? Colors.green : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFC49A6C),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
          todayBuilder: (context, day, focusedDay) {
            return Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFC49A6C).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Color(0xFF4A3B32),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            return Center(
              child: Text(
                '${day.day}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          outsideBuilder: (context, day, focusedDay) => const SizedBox.shrink(),
          disabledBuilder: (context, day, focusedDay) =>
              const SizedBox.shrink(),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(
            color: Colors.redAccent,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          defaultTextStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
      ),
    );
  }

  // --- GRILLE DES CRÉNEAUX DYNAMIQUE ---
  Widget _buildSlotsGrid(List<int> joursTravail, int heureDebut, int heureFin) {
    if (!joursTravail.contains(_selectedDay.weekday)) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.block, size: 30, color: Colors.grey),
            SizedBox(height: 5),
            Text("Fermé", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    final startOfDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      0,
      0,
    );
    final endOfDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      23,
      59,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rendez_vous')
          .where('id_coiff', isEqualTo: currentUser?.uid)
          .where('date_heure', isGreaterThanOrEqualTo: startOfDay)
          .where('date_heure', isLessThanOrEqualTo: endOfDay)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Erreur");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        Map<String, DocumentSnapshot> appointmentsMap = {};
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          Timestamp ts = data['date_heure'];
          DateTime date = ts.toDate();
          String key = "${date.hour}:${date.minute}";
          appointmentsMap[key] = doc;
        }

        List<Widget> slotWidgets = [];
        for (int h = heureDebut; h < heureFin; h++) {
          slotWidgets.add(_buildSingleSlot(h, 0, appointmentsMap));
          slotWidgets.add(_buildSingleSlot(h, 30, appointmentsMap));
        }

        if (slotWidgets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Aucun créneau configuré"),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            if (constraints.maxWidth > 600) {
              crossAxisCount = 5;
            } else if (constraints.maxWidth > 400)
              crossAxisCount = 3;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.8,
              children: slotWidgets,
            );
          },
        );
      },
    );
  }

  Widget _buildSingleSlot(
    int hour,
    int minute,
    Map<String, DocumentSnapshot> appointmentsMap,
  ) {
    String key = "$hour:$minute";
    DocumentSnapshot? rdvDoc = appointmentsMap[key];

    String statusLabel = "Libre";
    Color bgColor = Colors.white;
    Color textColor = Colors.black87;
    bool isClickable = false;
    String? docId;
    String clientName = "";

    if (rdvDoc != null) {
      Map<String, dynamic> data = rdvDoc.data() as Map<String, dynamic>;
      var rawStatut = data['statut'];
      int statut = -1;
      if (rawStatut is int) statut = rawStatut;
      if (rawStatut is String) statut = int.tryParse(rawStatut) ?? -1;

      clientName = data['nom_cl'] ?? '?';
      docId = rdvDoc.id;

      if (statut == 0) {
        statusLabel = "Attente";
        bgColor = Colors.orange.shade200;
        textColor = Colors.black;
        isClickable = true;
      } else if (statut == 1) {
        statusLabel = "Confirmé";
        bgColor = Colors.green.shade400;
        textColor = Colors.white;
        isClickable = false;
      }
    }

    String timeStr =
        "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        boxShadow: [
          if (rdvDoc != null)
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (rdvDoc != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    clientName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF47392A),
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ] else ...[
                Text(
                  "Dispo",
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isClickable && docId != null) {
      return GestureDetector(
        onTap: () => _showConfirmationDialog(docId!, clientName, timeStr),
        child: content,
      );
    }
    return content;
  }
}
