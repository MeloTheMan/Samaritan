# Guide du Firmware de Production - Bracelet Samaritan

## Vue d'ensemble

Ce firmware est la version de production complète du bracelet Samaritan. Il intègre tous les capteurs réels et implémente la logique complète de fonctionnement avec l'application mobile.

## Caractéristiques Principales

### Architecture Modulaire
- Chaque capteur peut être débranché sans affecter le fonctionnement global
- Le bracelet détecte automatiquement les capteurs disponibles au démarrage
- Les données manquantes sont marquées comme nulles/indisponibles

### Modes de Fonctionnement

**1. MODE_OWNER (Mode Propriétaire)**
- Le bracelet est connecté au téléphone de son propriétaire
- Envoi continu des signes vitaux pour monitoring
- Visible dans la section "Gestion du Bracelet" de l'app
- Détection automatique des conditions critiques

**2. MODE_ALERT (Mode Alerte)**
- Déclenché automatiquement en cas de condition critique
- Émission d'une alerte d'urgence via BLE
- Visible par tous les secouristes à proximité
- Timeout de 5 minutes si non pris en charge

**3. MODE_INTERVENTION (Mode Intervention)**
- Activé quand un secouriste prend en charge la victime
- Le bracelet se déconnecte du téléphone du propriétaire
- Se connecte au téléphone du secouriste
- Affichage en temps réel dans le module "Interventions"
- Retour automatique en MODE_OWNER à la fin

## Capteurs Supportés

### MAX30102 (Rythme Cardiaque, SpO2, Température)
- **Adresse I2C**: 0x57
- **Données fournies**:
  - Fréquence cardiaque (BPM)
  - Saturation en oxygène (%)
  - Température corporelle (°C)
- **Calibration**: Offset de température ajustable (défaut: 6.5°C)
- **Détection**: Nécessite un doigt sur le capteur (IR > 50000)

### MPU6050 (Accéléromètre + Gyroscope)
- **Adresse I2C**: 0x68
- **Données fournies**:
  - Détection de chute
  - Détection de mouvement brusque
- **Seuils**:
  - Chute: > 25 m/s² ou < 2 m/s²
  - Confirmation: 2 secondes après détection
  - Mouvement brusque: > 5 rad/s

### DHT11 (Température et Humidité Ambiantes)
- **Broche**: GPIO 4
- **Données fournies**:
  - Température ambiante (°C)
  - Humidité relative (%)
- **Fréquence**: Lecture toutes les 5 secondes

## Protocole de Communication BLE

### Service UUID
```
0000180d-0000-1000-8000-00805f9b34fb
```

### Caractéristiques

#### 1. Vital Signs (00002a37) - NOTIFY
Format des données (27 bytes):
```
[0-3]   : Température corporelle (float)
[4-7]   : Fréquence cardiaque (int)
[8-11]  : Saturation oxygène (int)
[12-15] : Timestamp (unsigned long)
[16]    : Chute détectée (bool)
[17]    : Mouvement brusque (bool)
[18-21] : Température ambiante (float)
[22-25] : Humidité (float)
[26]    : Statut capteurs (byte)
```

Statut capteurs (bit flags):
- Bit 0: MAX30102 disponible
- Bit 1: MPU6050 disponible
- Bit 2: DHT11 disponible

#### 2. Alert (00002a38) - NOTIFY
Format des données (38 bytes):
```
[0]     : Type d'alerte (0x01 = urgence)
[1-16]  : Device ID (16 bytes)
[17-20] : Température (float)
[21-24] : Fréquence cardiaque (int)
[25-28] : Saturation oxygène (int)
[29-36] : Timestamp (unsigned long long)
[37]    : Statut capteurs (byte)
```

#### 3. Command (00002a39) - WRITE
Commandes supportées:
- `TAKE_CHARGE`: Démarrer une intervention
- `END_INTERVENTION`: Terminer l'intervention
- `ACKNOWLEDGE_ALERT`: Reconnaître l'alerte
- `CANCEL_ALERT`: Annuler l'alerte (fausse alerte)
- `CALIBRATE_TEMP:X.X`: Calibrer l'offset de température
- `STATUS`: Demander le statut actuel
- `RESET`: Réinitialiser le système

#### 4. Status (00002a3a) - READ + NOTIFY
Format des données (20 bytes):
```
[0]     : Mode (0=OWNER, 1=INTERVENTION, 2=ALERT)
[1]     : Alerte active (bool)
[2]     : Alerte reconnue (bool)
[3]     : Statut capteurs (byte)
[4-19]  : Version firmware (16 chars)
```

## Conditions d'Alerte Automatique

Le bracelet déclenche automatiquement une alerte si:
- Température < 35°C (hypothermie)
- Température > 40°C (hyperthermie)
- Fréquence cardiaque < 40 BPM (bradycardie)
- Fréquence cardiaque > 150 BPM (tachycardie)
- Saturation oxygène < 90% (hypoxie)
- Chute détectée et confirmée

## Flux de Fonctionnement

### Scénario Normal
```
1. Bracelet en MODE_OWNER
2. Connexion au téléphone du propriétaire
3. Envoi des signes vitaux toutes les secondes
4. Monitoring continu des conditions critiques
```

### Scénario d'Urgence
```
1. Détection d'une condition critique
2. Passage en MODE_ALERT
3. Émission d'alerte via BLE
4. Attente de prise en charge (timeout 5 min)
5. Secouriste envoie TAKE_CHARGE
6. Passage en MODE_INTERVENTION
7. Déconnexion du téléphone propriétaire
8. Connexion au téléphone secouriste
9. Envoi continu des signes vitaux au secouriste
10. Secouriste envoie END_INTERVENTION
11. Déconnexion du secouriste
12. Retour en MODE_OWNER
13. Reconnexion au propriétaire
```

## Calibration de la Température Corporelle

La température corporelle est calculée à partir du capteur interne du MAX30102:

```
Température corporelle = Température MAX30102 + Offset
```

**Offset par défaut**: 6.5°C

**Procédure de calibration**:
1. Mesurer la température avec un thermomètre médical
2. Lire la température du bracelet
3. Calculer: Offset = Temp_réelle - Temp_bracelet
4. Envoyer: `CALIBRATE_TEMP:X.X`

## Gestion de l'Énergie

### Consommation Typique
- MAX30102: ~600µA (idle), ~50mA (mesure)
- MPU6050: ~3.9mA
- DHT11: ~0.5mA
- ESP32 BLE: ~40mA (actif), ~10µA (deep sleep)

### Optimisations
- Lecture DHT11 toutes les 5s (au lieu de 1s)
- MAX30102 en mode low-power entre mesures
- Possibilité d'ajouter un mode deep sleep (futur)

## Dépannage

### Aucun capteur détecté
- Vérifier le câblage I2C (SDA, SCL)
- Vérifier l'alimentation 3.3V
- Ajouter des résistances pull-up si nécessaire

### Température corporelle incorrecte
- Vérifier que le doigt est bien placé
- Attendre 30-60s de stabilisation
- Calibrer l'offset si nécessaire

### Fausses détections de chute
- Ajuster FALL_THRESHOLD et IMPACT_THRESHOLD
- Augmenter FALL_CONFIRMATION_DELAY
- Vérifier le montage du MPU6050

### Connexion BLE instable
- Réduire la distance
- Vérifier les interférences WiFi
- Redémarrer le bracelet

## Mise à Jour Firmware

Pour téléverser ce firmware:
1. Installer les bibliothèques (voir LIBRARIES_SETUP.md)
2. Câbler les capteurs (voir WIRING_GUIDE.md)
3. Sélectionner la carte ESP32 Dev Module
4. Sélectionner le port COM
5. Téléverser

## Logs Série

Le bracelet affiche des logs détaillés sur le port série (115200 baud):
- Détection des capteurs au démarrage
- Scan I2C
- Connexions/déconnexions BLE
- Signes vitaux en temps réel
- Alertes et changements de mode
- Commandes reçues

## Sécurité

- Les données sont transmises en clair via BLE (à sécuriser en production)
- Pas d'authentification BLE (à ajouter en production)
- Device ID basé sur l'adresse MAC (unique par ESP32)

## Prochaines Améliorations

- [ ] Chiffrement des données BLE
- [ ] Authentification par code PIN
- [ ] Mode deep sleep pour économie d'énergie
- [ ] Stockage local des données (SD card)
- [ ] Algorithme SpO2 plus précis
- [ ] Détection d'arythmie cardiaque
- [ ] Vibration pour alertes locales
- [ ] LED de statut

