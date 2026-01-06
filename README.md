# [Nom de ton Application] - Salon Connect

Application mobile de réservation de coiffure développée avec **Flutter** et **Firebase**.
Elle permet de mettre en relation les clients et les coiffeurs avec une gestion de profil distincte.

## 📱 Fonctionnalités

* **Authentification** : Connexion/Inscription via Email (Firebase Auth).
* **Rôles Utilisateurs** :
    * 💇‍♂️ **Espace Coiffeur** : Gestion de profil, visualisation des rendez-vous (`home_coiff.dart`).
    * 👤 **Espace Client** : Recherche de salon, prise de rendez-vous (`home_client.dart`).
* **Base de données** : Stockage des utilisateurs et réservations en temps réel (Firestore).

## 🛠 Tech Stack

* **Frontend** : Flutter (Dart)
* **Backend** : Firebase (Auth, Firestore)
* **Architecture** : MVC (Model-View-Controller) ou Service-Oriented (selon ton code)

## 🚀 Installation & Démarrage

1.  **Cloner le projet**
    ```bash
    git clone [https://github.com/ton-username/ton-projet.git](https://github.com/ton-username/ton-projet.git)
    ```

2.  **Installer les dépendances**
    ```bash
    flutter pub get
    ```

3.  **Lancer l'application**
    ```bash
    flutter run
    ```

## 📂 Structure du projet

* `lib/pages/` : Contient les interfaces (Login, Home, Profil).
* `lib/services/` : Logique backend (AuthService, FirebaseOptions).