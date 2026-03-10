# Samaritan Bracelet - ESP32 Simulator

Firmware de simulation pour bracelet de santé Samaritan sur ESP32.

## Matériel requis

- ESP32 (4MB Flash, Dual-core, 240MHz)
- Câble USB pour la programmation
- (Optionnel) LED et résistance pour indication visuelle

## Installation

### 1. Installer Arduino IDE

Téléchargez et installez Arduino IDE depuis [arduino.cc](https://www.arduino.cc/en/software)

### 2. Ajouter le support ESP32

1. Ouvrez Arduino IDE
2. Allez dans `Fichier` > `Préférences`
3. Dans "URL de gestionnaire de cartes supplémentaires", ajoutez:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Allez dans `Outils` > `Type de carte` > `Gestionnaire de cartes`
5. Recherchez "esp32" et installez "esp32 by Espressif Systems"

### 3. Installer les bibliothèques nécessaires

Les bibliothèques BLE sont incluses avec le package ESP32, aucune installation supplémentaire n'est nécessaire.

### 4. Configuration de la carte

1. Connectez votre ESP32 via USB
2. Dans Arduino IDE, sélectionnez:
   - `Outils` > `Type de carte` > `ESP32 Arduino` > `ESP32 Dev Module`
   - `Outils` > `Port` > Sélectionnez le port COM de votre ESP32
   - `Outils` > `Upload Speed` > `115200`
   - `Outils` > `Flash Frequency` > `80MHz`
   - `Outils` > `Flash Size` > `4MB (32Mb)`
   - `Outils` > `Partition Scheme` > `Default 4MB with spiffs`

### 5. Téléverser le firmware

1. Ouvrez le fichier `samaritan_bracelet.ino`
2. Cliquez sur le bouton "Téléverser" (flèche vers la droite)
3. Attendez la fin du téléversement

## Utilisation

### Démarrage

1. Après le téléversement, ouvrez le moniteur série (`Outils` > `Moniteur série`)
2. Réglez la vitesse à `115200 baud`
3. Vous devriez voir:
   ```
   Starting Samaritan Bracelet Simulator...
   Waiting for a client connection...
   Device is now discoverable as: Samaritan Bracelet
   ```

### Connexion depuis l'application

1. Ouvrez l'application Samaritan sur votre téléphone
2. Allez dans l'onglet "Bracelet"
3. Appuyez sur "Connecter un bracelet"
4. Sélectionnez "Samaritan Bracelet" dans la liste
5. Attendez la connexion

### Données simulées

Le bracelet envoie automatiquement des données toutes les secondes:

- **Température**: 36.0 - 37.5°C (variations aléatoires)
- **Fréquence cardiaque**: 60 - 100 BPM (variations aléatoires)
- **Saturation en oxygène**: 95 - 100% (variations aléatoires)
- **Détection de chute**: Simulée aléatoirement (1% de chance)
- **Mouvement brusque**: Simulé aléatoirement (5% de chance)

### Commandes disponibles

Vous pouvez envoyer des commandes depuis l'application:

- `FREQ:xxxx` - Change la fréquence de mesure (en ms, entre 100 et 60000)
- `RESET` - Réinitialise les paramètres par défaut
- `FALL` - Simule une chute immédiate
- `FIRMWARE` - Simule une mise à jour firmware

## Personnalisation

### Modifier les valeurs simulées

Dans la fonction `simulateVitalSigns()`, vous pouvez ajuster:

```cpp
// Plage de température
temperature = 36.5 + (random(-10, 10) / 10.0);  // 35.5 - 37.5°C

// Plage de fréquence cardiaque
heartRate = 75 + random(-15, 15);  // 60 - 90 BPM

// Plage de saturation en oxygène
oxygenSaturation = 98 + random(-3, 2);  // 95 - 100%
```

### Modifier la fréquence d'envoi

Changez la valeur de `measurementFrequency`:

```cpp
int measurementFrequency = 1000; // 1000ms = 1 seconde
```

### Ajouter une LED d'indication

Ajoutez ce code pour faire clignoter une LED lors de l'envoi de données:

```cpp
#define LED_PIN 2  // LED intégrée sur la plupart des ESP32

void setup() {
  // ... code existant ...
  pinMode(LED_PIN, OUTPUT);
}

void sendVitalSigns() {
  digitalWrite(LED_PIN, HIGH);
  // ... code existant ...
  digitalWrite(LED_PIN, LOW);
}
```

## Dépannage

### L'ESP32 n'est pas détecté

- Vérifiez que le câble USB supporte les données (pas seulement la charge)
- Installez les drivers CH340 ou CP2102 selon votre ESP32
- Essayez un autre port USB

### Le téléversement échoue

- Maintenez le bouton BOOT enfoncé pendant le téléversement
- Réduisez la vitesse de téléversement à 921600 ou 460800

### Le bracelet n'apparaît pas dans le scan

- Vérifiez que le Bluetooth est activé sur votre téléphone
- Redémarrez l'ESP32
- Vérifiez le moniteur série pour les messages d'erreur

### Les données ne sont pas reçues

- Vérifiez que la connexion BLE est établie (message "Client connected")
- Vérifiez les UUIDs dans le code Flutter correspondent à ceux de l'ESP32
- Redémarrez l'application et l'ESP32

## Format des données BLE

Les données sont envoyées dans un tableau de 20 bytes:

| Offset | Type | Description |
|--------|------|-------------|
| 0-3 | float | Température (°C) |
| 4-7 | int | Fréquence cardiaque (BPM) |
| 8-11 | int | Saturation en oxygène (%) |
| 12-15 | unsigned long | Timestamp (ms) |
| 16 | bool | Chute détectée (0/1) |
| 17 | bool | Mouvement brusque (0/1) |

## Améliorations futures

- Ajouter de vrais capteurs (MAX30102 pour SpO2/HR, MLX90614 pour température)
- Implémenter l'accéléromètre pour la détection de chute réelle
- Ajouter un écran OLED pour afficher les données
- Implémenter le mode économie d'énergie
- Ajouter un bouton SOS

## Licence

Ce firmware est fourni à des fins éducatives et de développement.
