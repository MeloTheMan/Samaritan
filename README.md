# Samaritan Health Assistant

Application mobile complète d'assistance médicale d'urgence avec bracelet connecté, destinée à former et assister les secouristes bénévoles.

## 📋 Vue d'ensemble

Samaritan est une solution complète comprenant :
- **Application mobile Flutter** : Formation, assistance IA, gestion d'interventions
- **Bracelet connecté ESP32** : Surveillance des signes vitaux en temps réel
- **Système d'alerte** : Détection automatique des situations d'urgence

## ✨ Fonctionnalités principales

### 📱 Application Mobile

#### 1. Module de Formation
- Cours interactifs sur les premiers secours
- Quiz d'évaluation avec suivi de progression
- Catégories : Urgences vitales, Traumatismes, Pédiatrie, etc.
- Médias riches (images, vidéos, animations)

#### 2. Assistant IA Médical
- Diagnostic basé sur les symptômes
- Recommandations de soins personnalisées
- Moteur de règles médicales
- Traitement du langage naturel
- Questions de suivi intelligentes

#### 3. Gestion du Bracelet
- Connexion Bluetooth automatique
- Dashboard de santé en temps réel
- Surveillance des signes vitaux :
  - Température corporelle
  - Fréquence cardiaque
  - Saturation en oxygène (SpO2)
  - Détection de chute
- Historique et graphiques

#### 4. Système d'Alerte d'Urgence
- Écoute passive des alertes BLE
- Détection automatique des situations critiques
- Localisation de la victime
- Navigation vers la victime

#### 5. Module d'Intervention
- Prise en charge guidée
- Pronostic vital automatique
- Recommandations de soins en temps réel
- Diagnostic automatique basé sur les signes vitaux
- Assistant IA intégré avec contexte
- Enregistrement des actions effectuées
- Rapport d'intervention complet

#### 6. Mode Démonstration
- Test sans bracelet physique
- Dashboard de santé simulé
- Scénarios d'intervention prédéfinis :
  - Hypothermie + Bradycardie
  - Hyperthermie + Tachycardie
  - Chute + Hypoxie
- Données réalistes en temps réel

### 🔧 Bracelet Connecté ESP32

#### Capteurs Supportés
- **MAX30102** : Fréquence cardiaque, SpO2, Température corporelle
- **MPU6050** : Accéléromètre/Gyroscope (détection de chute)
- **DHT11** : Température et humidité ambiantes

#### Modes de Fonctionnement
1. **MODE_OWNER** : Connecté au propriétaire (monitoring normal)
2. **MODE_INTERVENTION** : Connecté au secouriste (intervention)
3. **MODE_ALERT** : Émission d'alerte d'urgence

#### Fonctionnalités
- Détection automatique des situations critiques
- Émission d'alertes via BLE Advertising
- Transmission des signes vitaux en temps réel
- Détection de chute avec confirmation
- Calibration de la température
- Architecture modulaire (capteurs optionnels)

## 🏗️ Architecture

### Application Mobile

```
lib/
├── core/                          # Fonctionnalités transversales
│   ├── di/                        # Injection de dépendances
│   ├── services/                  # Services globaux
│   │   ├── demo_service.dart      # Service de démonstration
│   │   ├── permission_service.dart
│   │   └── encryption_service.dart
│   └── utils/                     # Utilitaires
│
├── features/                      # Modules fonctionnels
│   ├── training/                  # Module de formation
│   │   ├── domain/                # Entités et logique métier
│   │   ├── data/                  # Repositories et sources de données
│   │   └── presentation/          # UI et BLoC
│   │
│   ├── ai_assistant/              # Assistant IA
│   │   ├── domain/
│   │   │   └── services/
│   │   │       ├── natural_language_processor.dart
│   │   │       ├── rule_evaluator.dart
│   │   │       └── response_generator.dart
│   │   └── presentation/
│   │
│   ├── device/                    # Gestion du bracelet
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       ├── vital_signs.dart
│   │   │       └── wearable_device.dart
│   │   ├── data/
│   │   │   └── services/
│   │   │       └── bluetooth_service.dart
│   │   └── presentation/
│   │       └── screens/
│   │           ├── health_dashboard_screen.dart
│   │           └── demo_health_dashboard_screen.dart
│   │
│   ├── alert/                     # Système d'alerte
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── emergency_alert.dart
│   │   ├── data/
│   │   │   └── services/
│   │   │       └── alert_listener_service.dart
│   │   └── presentation/
│   │       └── screens/
│   │           ├── alert_notification_screen.dart
│   │           └── demo_alert_screen.dart
│   │
│   └── take_charge/               # Module d'intervention
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── take_charge_session.dart
│       │   │   ├── prognosis.dart
│       │   │   └── care_action.dart
│       │   └── services/
│       │       └── vital_signs_analyzer.dart
│       └── presentation/
│           └── screens/
│               ├── take_charge_screen.dart
│               ├── demo_take_charge_screen.dart
│               └── intervention_ai_assistant_screen.dart
│
└── assets/
    ├── courses/                   # Contenu de formation
    └── ai/                        # Arbre de décision médical
```

### Firmware ESP32

```
esp32_samaritan_bracelet/
├── samaritan_bracelet_production.ino  # Firmware de production
├── config.h                           # Configuration
├── sensors_test.ino                   # Test des capteurs
├── heartrate_simple_test.ino          # Test du rythme cardiaque
├── alert_advertising_test_v5.ino      # Test des alertes
├── WIRING_GUIDE.md                    # Guide de câblage
├── LIBRARIES_SETUP.md                 # Installation des bibliothèques
├── TEST_GUIDE.md                      # Guide de test
└── PRODUCTION_FIRMWARE_GUIDE.md       # Guide du firmware
```

## 🚀 Installation

### Prérequis

- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / Xcode
- Arduino IDE 2.0+ (pour le firmware)
- ESP32 Dev Board
- Capteurs (MAX30102, MPU6050, DHT11)

### Application Mobile

```bash
# Cloner le repository
git clone https://github.com/votre-repo/samaritan.git
cd samaritan

# Installer les dépendances
flutter pub get

# Générer les fichiers
flutter pub run build_runner build --delete-conflicting-outputs

# Lancer l'application
flutter run
```

### Firmware ESP32

1. **Installer les bibliothèques** (voir `esp32_samaritan_bracelet/LIBRARIES_SETUP.md`)
   - SparkFun MAX3010x Pulse and Proximity Sensor Library
   - Adafruit MPU6050
   - DHT sensor library
   - ESP32 BLE Arduino

2. **Câbler les capteurs** (voir `esp32_samaritan_bracelet/WIRING_GUIDE.md`)

3. **Téléverser le firmware**
   ```
   Ouvrir: esp32_samaritan_bracelet/samaritan_bracelet_production.ino
   Board: ESP32 Dev Module
   Upload Speed: 921600
   ```

## 📖 Guides de Démarrage

### Démarrage Rapide - Mode Démo

Pour tester l'application sans bracelet :

1. Lancer l'application
2. Aller dans **"Bracelet"** → **"Mode Démo"**
3. Explorer le dashboard avec données simulées
4. Aller dans **"Interventions"** → **"Intervention de démo"**
5. Choisir un scénario et tester le processus complet

### Démarrage avec Bracelet

1. Assembler et câbler le bracelet (voir guides)
2. Téléverser le firmware de production
3. Lancer l'application mobile
4. Aller dans **"Bracelet"** → **"Connecter un bracelet"**
5. Scanner et se connecter au bracelet "Samaritan"
6. Accéder au dashboard de santé

### Tester le Système d'Alerte

1. Avoir 2 bracelets ou 1 bracelet + mode démo
2. Sur le bracelet : simuler une situation critique
3. Sur l'app : aller dans **"Interventions"**
4. L'alerte apparaît automatiquement
5. Cliquer sur **"Aller vers la victime"**
6. Suivre le processus d'intervention guidée

## 🧪 Tests

### Tests Unitaires

```bash
# Lancer tous les tests
flutter test

# Tests spécifiques
flutter test test/rule_evaluator_test.dart
flutter test test/response_generator_test.dart
```

### Tests du Firmware

Voir les sketches de test dans `esp32_samaritan_bracelet/` :
- `sensors_test.ino` : Test de tous les capteurs
- `heartrate_simple_test.ino` : Test du rythme cardiaque
- `alert_advertising_test_v5.ino` : Test des alertes BLE

## 📚 Documentation Technique

### Documents Disponibles

- `DEMO_MODE_IMPLEMENTATION.md` : Implémentation du mode démo
- `AI_ASSISTANT_INTERVENTION_INTEGRATION.md` : Intégration de l'IA
- `ALERT_SYSTEM_FINAL.md` : Système d'alerte
- `FIRMWARE_APP_INTEGRATION_SUMMARY.md` : Intégration firmware/app
- `BLUETOOTH_CONNECTION_FIXES.md` : Corrections Bluetooth
- `HIVE_TYPEID_REGISTRY.md` : Registre des types Hive

### Architecture Technique

**Clean Architecture** avec séparation en couches :
- **Domain** : Entités et logique métier
- **Data** : Repositories et sources de données
- **Presentation** : UI avec pattern BLoC

**Gestion d'état** : flutter_bloc

**Persistance** : Hive (base de données locale)

**Communication BLE** : flutter_blue_plus

**Injection de dépendances** : get_it + injectable

## 🔧 Configuration

### Variables d'Environnement

Aucune variable d'environnement requise pour le moment.

### Paramètres du Bracelet

Modifiables dans `esp32_samaritan_bracelet/config.h` :
- Nom du device
- UUIDs des services BLE
- Seuils d'alerte
- Intervalles de mesure

## 🤝 Contribution

### Standards de Code

- **Dart** : Suivre les conventions Effective Dart
- **C++/Arduino** : Style Google C++
- **Commits** : Messages descriptifs en français
- **Branches** : feature/nom-fonctionnalite

### Workflow

1. Fork le projet
2. Créer une branche feature
3. Commiter les changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 👥 Auteurs

- **Équipe Samaritan** - Développement initial

## 🙏 Remerciements

- Communauté Flutter
- Bibliothèques open source utilisées
- Professionnels de santé pour les conseils médicaux

## 📞 Support

Pour toute question ou problème :
- Ouvrir une issue sur GitHub
- Consulter la documentation dans `/docs`
- Vérifier les guides de dépannage

## 🗺️ Roadmap

### Version Actuelle (1.0.0)
- ✅ Formation interactive
- ✅ Assistant IA médical
- ✅ Bracelet connecté
- ✅ Système d'alerte
- ✅ Module d'intervention
- ✅ Mode démonstration

### Prochaines Versions

**v1.1.0**
- [ ] Géolocalisation précise
- [ ] Appel automatique aux urgences
- [ ] Historique des interventions
- [ ] Synchronisation cloud

**v1.2.0**
- [ ] Mode multi-secouristes
- [ ] Chat entre secouristes
- [ ] Partage de position en temps réel
- [ ] Protocoles avancés

**v2.0.0**
- [ ] Machine learning pour diagnostics
- [ ] Télémédecine intégrée
- [ ] Certification officielle
- [ ] Support iOS complet

## ⚠️ Avertissements

**IMPORTANT** : Cette application est un outil d'assistance et de formation. Elle ne remplace pas :
- Une formation officielle aux premiers secours
- L'avis d'un professionnel de santé
- L'appel aux services d'urgence (15, 18, 112)

En cas d'urgence vitale, appelez toujours les secours professionnels.

## 🔒 Sécurité et Confidentialité

- Les données de santé sont stockées localement
- Chiffrement des données sensibles
- Pas de transmission de données personnelles
- Conformité RGPD (à venir)

## 📊 Statistiques du Projet

- **Langage principal** : Dart (Flutter)
- **Firmware** : C++ (Arduino)
- **Lignes de code** : ~15,000+
- **Modules** : 6 principaux
- **Tests** : Unitaires et d'intégration

---

**Fait avec ❤️ pour sauver des vies**
