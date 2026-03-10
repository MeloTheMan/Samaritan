# Installation des Bibliothèques - Bracelet Samaritan

## Bibliothèques Requises

Pour que le code de test fonctionne, tu dois installer les bibliothèques suivantes dans l'IDE Arduino.

---

## Installation via le Gestionnaire de Bibliothèques Arduino

### Méthode
1. Ouvrir l'IDE Arduino
2. Aller dans **Sketch → Include Library → Manage Libraries...**
3. Rechercher et installer chaque bibliothèque listée ci-dessous

---

## 1. MAX30102 (Rythme Cardiaque et SpO2)

### Bibliothèque : SparkFun MAX3010x Pulse and Proximity Sensor Library

**Nom exact** : `SparkFun MAX3010x Pulse and Proximity Sensor Library`  
**Auteur** : SparkFun Electronics  
**Version** : 1.1.2 ou supérieure

#### Installation
```
Gestionnaire de bibliothèques → Rechercher "MAX30105" → Installer
```

#### Fichiers inclus
- `MAX30105.h` - Driver principal
- `heartRate.h` - Algorithme de détection de battements

---

## 2. MPU6050 (Accéléromètre et Gyroscope)

### Bibliothèque : Adafruit MPU6050

**Nom exact** : `Adafruit MPU6050`  
**Auteur** : Adafruit  
**Version** : 2.2.4 ou supérieure

#### Installation
```
Gestionnaire de bibliothèques → Rechercher "Adafruit MPU6050" → Installer
```

Cette bibliothèque installera automatiquement les dépendances :
- `Adafruit Unified Sensor`
- `Adafruit Bus IO`

---

## 3. DHT11 (Température et Humidité)

### Bibliothèque : DHT sensor library

**Nom exact** : `DHT sensor library`  
**Auteur** : Adafruit  
**Version** : 1.4.4 ou supérieure

#### Installation
```
Gestionnaire de bibliothèques → Rechercher "DHT sensor library" → Installer
```

Cette bibliothèque installera automatiquement :
- `Adafruit Unified Sensor` (si pas déjà installé)

---

## 4. Wire (I2C) - Incluse par défaut

La bibliothèque `Wire.h` est incluse avec l'ESP32 Arduino Core, pas besoin de l'installer.

---

## Configuration de l'ESP32 dans Arduino IDE

### Si ce n'est pas déjà fait

1. **Ajouter l'URL du gestionnaire de cartes ESP32**
   - Aller dans **File → Preferences**
   - Dans "Additional Board Manager URLs", ajouter :
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```

2. **Installer le support ESP32**
   - Aller dans **Tools → Board → Boards Manager**
   - Rechercher "ESP32"
   - Installer "esp32 by Espressif Systems" (version 2.0.0 ou supérieure)

3. **Sélectionner la carte**
   - **Tools → Board → ESP32 Arduino → ESP32 Dev Module**
   - Ou sélectionner ton modèle spécifique d'ESP32

---

## Résumé des Bibliothèques

| Bibliothèque | Capteur | Auteur | Commande de recherche |
|--------------|---------|--------|----------------------|
| SparkFun MAX3010x | MAX30102 | SparkFun | "MAX30105" |
| Adafruit MPU6050 | MPU6050 | Adafruit | "Adafruit MPU6050" |
| DHT sensor library | DHT11 | Adafruit | "DHT sensor library" |
| Wire | I2C | Arduino | (incluse) |

---

## Vérification de l'Installation

### Méthode 1 : Via l'IDE
1. Aller dans **Sketch → Include Library**
2. Vérifier que les bibliothèques apparaissent dans la liste

### Méthode 2 : Compilation
1. Ouvrir `sensors_test.ino`
2. Cliquer sur **Verify/Compile** (✓)
3. Si aucune erreur de bibliothèque manquante, c'est bon !

---

## Dépannage

### Erreur : "MAX30105.h: No such file or directory"
→ Installer `SparkFun MAX3010x Pulse and Proximity Sensor Library`

### Erreur : "Adafruit_MPU6050.h: No such file or directory"
→ Installer `Adafruit MPU6050`

### Erreur : "DHT.h: No such file or directory"
→ Installer `DHT sensor library` par Adafruit

### Erreur : "Adafruit_Sensor.h: No such file or directory"
→ Installer `Adafruit Unified Sensor`

### Erreur de compilation ESP32
→ Vérifier que le support ESP32 est installé via le Boards Manager

---

## Configuration du Moniteur Série

Pour voir les résultats du test :

1. Téléverser le code sur l'ESP32
2. Ouvrir le moniteur série : **Tools → Serial Monitor**
3. Configurer la vitesse : **115200 baud**
4. Sélectionner "Both NL & CR" ou "Newline"

---

## Prochaines Étapes

Une fois toutes les bibliothèques installées :

1. ✅ Câbler les capteurs selon `WIRING_GUIDE.md`
2. ✅ Ouvrir `sensors_test.ino`
3. ✅ Sélectionner la carte ESP32 et le port COM
4. ✅ Téléverser le code
5. ✅ Ouvrir le moniteur série (115200 baud)
6. ✅ Observer les résultats du test

