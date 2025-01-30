# Meal Tracker 🍽️

**Meal Tracker** est une application Android développée avec Flutter, conçue pour aider les utilisateurs à suivre leur alimentation, gérer leur poids, et obtenir des recommandations personnalisées en fonction de leur Indice de Masse Corporelle (IMC).  

## Fonctionnalités Principales 🚀

### 1. **Connexion et Inscription**
- **Page de Connexion** : Les utilisateurs peuvent se connecter en entrant leur e-mail et mot de passe.
- **Création de Compte** : Les nouveaux utilisateurs peuvent s'inscrire avec un mot de passe sécurisé (minimum 6 caractères).

### 2. **Profil Utilisateur**
- Affiche les informations principales :
  - **IMC** avec interprétation (sous-poids, poids normal, surpoids, obésité).
  - Taille et poids de l'utilisateur.
  - **Seuil de calories journalier** recommandé.
- Possibilité de mettre à jour le poids, la taille et le seuil de calories.

### 3. **Calcul de l'IMC**
- Bouton "Calculer l'IMC" pour entrer la taille et le poids.
- L'IMC est automatiquement calculé et mis à jour.
- Mise à jour du seuil de calories journalier selon les données saisies.

### 4. **Menu de Navigation**
- Un menu en bas de l'application donne accès à :
  - **Repas** : Historique des repas.
  - **Statistiques** : Analyse des calories consommées.
  - **Recommandations** : Conseils alimentaires personnalisés.
  - **Chat** : Chatbot intelligent (nécessite une connexion Internet).

### 5. **Historique des Repas**
- Historique complet des repas ajoutés par l'utilisateur.
- Fonctionnalités :
  - Ajouter un repas avec une photo (depuis la galerie ou la caméra).
  - Modifier ou supprimer un repas existant.
- Affichage détaillé pour chaque repas.

### 6. **Statistiques**
- Suivi graphique des calories consommées au fil du temps (journalier, hebdomadaire, mensuel).
- Calcul des moyennes et alertes en cas de dépassement du seuil de calories.
- Notifications en cas de dépassement des calories autorisées.

### 7. **Recommandations**
- Propositions de repas adaptées à l'IMC :
  - **Insuffisance pondérale** : Repas riches en calories.
  - **Surpoids** : Repas équilibrés et faibles en calories.

### 8. **Chatbot Intelligent**
- Chatbot intégré pour poser des questions et obtenir des réponses instantanées.
- Fonctionne uniquement en ligne.

## Technologies Utilisées 🛠️
- **Framework** : Flutter
- **Langage** : Dart
- **Base de données locale** : SQLite (pour un accès hors ligne).
- **Notifications** : Firebase Cloud Messaging (FCM) pour les alertes.

