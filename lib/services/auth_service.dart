import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- INSCRIPTION (SIGNUP) ---
  // On garde votre logique, elle est très bien.
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'client' ou 'coiffeur'
  }) async {
    try {
      // 1. Créer l'utilisateur Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Enregistrer ses infos dans Firestore (collection users)
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'email': email,
          'name': name,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null; // Succès
    } on FirebaseAuthException catch (e) {
      return _translateError(e.code);
    } catch (e) {
      return "Une erreur inconnue est survenue.";
    }
  }

  // --- CONNEXION (LOGIN) ---
  // MODIFICATION ICI : expectedRole devient optionnel (String?)
  // Cela corrige l'erreur "Required named parameter..."
  Future<String?> signIn({
    required String email,
    required String password,
    String? expectedRole,
  }) async {
    try {
      // 1. Connexion Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Vérification du rôle (seulement si un rôle est demandé)
      if (result.user != null && expectedRole != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();

        if (doc.exists) {
          String userRole = doc.get('role');
          if (userRole != expectedRole) {
            // Mauvais rôle
            await signOut(); // On utilise la nouvelle fonction signOut
            return "Accès refusé : Ce compte n'est pas un compte $expectedRole.";
          }
        }
      }
      // Si expectedRole est null, on laisse passer (la vérification se fera dans la page UI)
      return null;
    } on FirebaseAuthException catch (e) {
      return _translateError(e.code);
    } catch (e) {
      return "Erreur de connexion : ${e.toString()}";
    }
  }

  // --- DECONNEXION (SIGNOUT) ---
  // AJOUT ICI : Corrige l'erreur "Method 'signOut' isn't defined"
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Petit utilitaire pour traduire les erreurs
  String _translateError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return "Cet email est déjà utilisé.";
      case 'invalid-email':
        return "L'adresse email n'est pas valide.";
      case 'weak-password':
        return "Le mot de passe est trop faible.";
      case 'user-not-found':
        return "Aucun utilisateur trouvé avec cet email.";
      case 'wrong-password':
        return "Mot de passe incorrect.";
      case 'invalid-credential':
        return "Email ou mot de passe incorrect.";
      default:
        return "Erreur d'authentification ($code).";
    }
  }
}
