import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Initialisation de la vidéo
    _controller = VideoPlayerController.asset("lib/assets/home_page_bg.mp4")
      ..initialize().then((_) {
        // Une fois la vidéo chargée, on rafraîchit l'écran pour l'afficher
        setState(() {});
      });

    _controller.setLooping(true); // La vidéo tourne en boucle
    _controller.setVolume(0.0); // Couper le son (optionnel)
    _controller.play(); // Lancer la lecture
  }

  @override
  void dispose() {
    _controller.dispose(); // Très important pour libérer la mémoire
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On enlève la couleur de fond car la vidéo va couvrir l'écran
      body: Stack(
        children: [
          // COUCHE 1 : La Vidéo en arrière-plan
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit
                    .cover, // La vidéo couvre tout l'écran sans déformation
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            // Un fond noir ou une couleur d'attente pendant le chargement de la vidéo
            Container(color: Colors.black),

          // Optionnel : Un filtre sombre pour que le texte reste lisible sur la vidéo
          Container(color: Colors.black.withOpacity(0.3)),

          // COUCHE 2 : Le contenu (Boutons)
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // On a supprimé le Logo et le Texte comme demandé

                    // BUTTON CLIENT
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent, // Fond transparent
                          shadowColor: Colors.transparent, // Pas d'ombre
                          side: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ), // Contour blanc
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, "/loginClient");
                        },
                        child: const Text(
                          "Réserver",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white, // Texte blanc
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BUTTON COIFFEUR
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent, // Fond transparent
                          shadowColor: Colors.transparent,
                          side: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ), // Contour blanc
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, "/loginCoiffeur");
                        },
                        child: const Text(
                          "Gérer votre espace",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white, // Texte blanc
                            fontWeight: FontWeight.w600,
                          ),
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
