# Salon Connect

**Salon Connect** est une solution mobile multi-plateforme (**Android / iOS**) développée avec **Flutter**.  
L’application facilite la mise en relation entre les **professionnels de la coiffure** et les **clients particuliers** en digitalisant le processus de **prise de rendez-vous**.

Ce projet démontre la mise en place d’une **architecture d’application moderne**, basée sur une **base de code unique** pour deux rôles utilisateurs distincts (Clients et Coiffeurs), appuyée par une infrastructure **Backend-as-a-Service (BaaS)** robuste via **Firebase**.

---

## 📌 Vue d’ensemble du projet

L’objectif principal de l’application est de **fluidifier la gestion des agendas** des salons de coiffure tout en offrant une **expérience de réservation simple et intuitive** aux utilisateurs.

L’application gère deux parcours utilisateurs distincts au sein de la même interface :

1. **Parcours Client**
   - Recherche de services
   - Visualisation des disponibilités
   - Prise de rendez-vous

2. **Parcours Coiffeur**
   - Gestion de l’agenda
   - Visualisation des demandes entrantes
   - Gestion du profil professionnel

---

## 🧱 Architecture Technique

Le projet suit une **architecture modulaire**, séparant clairement :

- la **couche Présentation (UI)**  
- la **logique métier et les services**

Cette organisation favorise la **maintenabilité**, la **lisibilité** et l’**évolutivité** du code.

### 📂 Structure des dossiers

L’organisation du code source dans le dossier `lib/` est la suivante :

```text
lib/
├── main.dart                # Point d'entrée de l'application et initialisation Firebase
├── firebase_options.dart    # Configuration Firebase générée automatiquement
├── pages/                   # Couche Présentation (Interface Utilisateur)
│   ├── home_page.dart       # Page d'accueil / Landing page
│   ├── home_client.dart     # Tableau de bord principal pour le Client
│   ├── home_coiff.dart      # Tableau de bord principal pour le Coiffeur
│   ├── login_client.dart    # Formulaire de connexion Client
│   ├── login_coiff.dart     # Formulaire de connexion Coiffeur
│   ├── signup_client.dart   # Inscription nouveau Client
│   ├── signup_coiff.dart    # Inscription nouveau Coiffeur
│   ├── profile_client.dart  # Gestion du profil Client
│   └── profile_coiff.dart   # Gestion du profil Coiffeur
└── services/                # Couche Logique & Données
    └── auth_service.dart    # Gestion centralisée de l'authentification (Firebase Auth)

## Backend et Services (Firebase)

L’application ne nécessite **aucun serveur traditionnel** (Node.js / PHP).  
Elle repose entièrement sur l’écosystème **Firebase**, garantissant :

- une synchronisation en temps réel
- une sécurité renforcée
- une scalabilité native

### 🔐 Authentification

- **Firebase Authentication**
- Gestion de l’inscription et de la connexion via **email / mot de passe**
- Gestion des sessions utilisateurs
- Distinction des rôles **Client / Coiffeur**
- Centralisation de la logique dans `auth_service.dart`

### 🗄️ Base de données

- **Cloud Firestore** (NoSQL orientée documents)

**Structure des données :**
- `clients` : données des utilisateurs clients
- `coiffeurs` : données des professionnels
- `rendez_vous` :
  - ID du client
  - ID du coiffeur
  - date et heure de réservation
  - état du rendez-vous

---

## ⚙️ Prérequis techniques

Avant de lancer le projet, assure-toi que ton environnement contient :

- **Flutter SDK** (version stable récente)
- **Dart SDK** (inclus avec Flutter)
- **Android Studio** ou **VS Code**
  - Extensions Flutter & Dart installées
- **Émulateur Android** ou **appareil physique** connecté en mode débogage USB

---

## 🚀 Installation et Démarrage

### 1️⃣ Clonage du dépôt

```bash
git clone https://github.com/VOTRE-USERNAME/salon-connect.git
cd salon-connect



