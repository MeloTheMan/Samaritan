# Guide de Câblage - Bracelet Samaritan

## Vue d'ensemble

Ce document décrit le câblage exact pour connecter les trois capteurs à l'ESP32.

## Schéma de Connexion I2C

Tous les capteurs utilisent le bus I2C, ce qui permet de les connecter en parallèle sur les mêmes broches SDA et SCL.

### Broches I2C de l'ESP32
- **SDA (Data)** : GPIO 21
- **SCL (Clock)** : GPIO 22
- **VCC** : 3.3V (utiliser la broche 3V3 de l'ESP32)
- **GND** : Ground

---

## 1. MAX30102 (Rythme Cardiaque, SpO2, Température)

### Adresse I2C
- **0x57** (adresse par défaut)

### Câblage

```
MAX30102          ESP32
--------          -----
VIN       ----→   3.3V
GND       ----→   GND
SDA       ----→   GPIO 21 (SDA)
SCL       ----→   GPIO 22 (SCL)
INT       ----→   (optionnel, non utilisé pour les tests)
```

### Notes importantes
- Le MAX30102 fonctionne en 3.3V (ne PAS utiliser 5V)
- Certains modules ont des résistances pull-up intégrées
- Si tu as plusieurs capteurs I2C sans pull-up, ajoute des résistances de 4.7kΩ entre SDA/SCL et 3.3V

---

## 2. MPU6050 (Accéléromètre + Gyroscope)

### Adresse I2C
- **0x68** (si AD0 est à GND)
- **0x69** (si AD0 est à VCC)

### Câblage

```
MPU6050           ESP32
-------           -----
VCC       ----→   3.3V
GND       ----→   GND
SDA       ----→   GPIO 21 (SDA)
SCL       ----→   GPIO 22 (SCL)
AD0       ----→   GND (pour adresse 0x68)
INT       ----→   (optionnel, non utilisé pour les tests)
```

### Notes importantes
- Le MPU6050 peut fonctionner en 3.3V ou 5V (utiliser 3.3V pour compatibilité ESP32)
- La broche AD0 détermine l'adresse I2C
- Laisser AD0 non connecté ou à GND pour l'adresse 0x68

---

## 3. DHT11 (Température et Humidité Ambiantes)

### Type de connexion
- **Digital Pin** (pas I2C)

### Câblage

```
DHT11             ESP32
-----             -----
VCC       ----→   3.3V (ou 5V si disponible)
GND       ----→   GND
DATA      ----→   GPIO 4
```

### Notes importantes
- Le DHT11 n'utilise PAS le bus I2C, il a son propre protocole
- Une résistance pull-up de 10kΩ entre DATA et VCC est recommandée (souvent intégrée sur les modules)
- Le DHT11 peut fonctionner en 3.3V mais est plus stable en 5V

---

## Schéma de Connexion Complet

```
                    ESP32
                 ┌─────────┐
                 │         │
    3.3V ────────┤ 3V3     │
                 │         │
    GND ─────────┤ GND     │
                 │         │
    I2C SDA ─────┤ GPIO 21 │────┬────┬──── MAX30102 (SDA)
                 │         │    │    │
                 │         │    │    └──── MPU6050 (SDA)
                 │         │    │
    I2C SCL ─────┤ GPIO 22 │────┼────┬──── MAX30102 (SCL)
                 │         │    │    │
                 │         │    │    └──── MPU6050 (SCL)
                 │         │    │
    DHT11 ───────┤ GPIO 4  │    │
                 │         │    │
                 └─────────┘    │
                                │
                         [Pull-up 4.7kΩ]
                                │
                              3.3V
```

---

## Résumé des Connexions

| Capteur    | VCC   | GND | SDA/Data  | SCL       | Autres |
|------------|-------|-----|-----------|-----------|--------|
| MAX30102   | 3.3V  | GND | GPIO 21   | GPIO 22   | -      |
| MPU6050    | 3.3V  | GND | GPIO 21   | GPIO 22   | AD0→GND|
| DHT11      | 3.3V  | GND | GPIO 4    | -         | -      |

---

## Vérification du Câblage

### Test de continuité
1. Vérifier que tous les VCC sont connectés à 3.3V
2. Vérifier que tous les GND sont connectés ensemble
3. Vérifier que SDA des capteurs I2C sont sur GPIO 21
4. Vérifier que SCL des capteurs I2C sont sur GPIO 22
5. Vérifier que DHT11 DATA est sur GPIO 4

### Scan I2C
Après câblage, utiliser le code de test pour scanner le bus I2C.
Vous devriez voir :
- **0x57** : MAX30102
- **0x68** : MPU6050

---

## Dépannage

### Aucun capteur détecté sur I2C
- Vérifier les connexions SDA/SCL
- Vérifier l'alimentation 3.3V
- Ajouter des résistances pull-up (4.7kΩ) si nécessaire
- Vérifier que les capteurs ne sont pas endommagés

### DHT11 ne répond pas
- Vérifier la connexion DATA sur GPIO 4
- Vérifier l'alimentation
- Attendre 2 secondes entre les lectures
- Vérifier la résistance pull-up (10kΩ recommandé)

### Conflit d'adresse I2C
- Si deux capteurs ont la même adresse, modifier l'adresse de l'un d'eux
- Pour le MPU6050, connecter AD0 à VCC pour changer l'adresse à 0x69

---

## Alimentation et Consommation

| Capteur    | Tension | Courant (typ) | Courant (max) |
|------------|---------|---------------|---------------|
| MAX30102   | 3.3V    | 600µA         | 50mA          |
| MPU6050    | 3.3V    | 3.9mA         | 10mA          |
| DHT11      | 3.3V    | 0.5mA         | 2.5mA         |
| **Total**  | -       | ~5mA          | ~63mA         |

L'ESP32 peut fournir jusqu'à 40mA par broche GPIO et 500mA total sur 3.3V, donc l'alimentation est suffisante.

---

## Prochaines Étapes

1. Câbler les capteurs selon ce schéma
2. Téléverser le code de test `sensors_test.ino`
3. Ouvrir le moniteur série (115200 baud)
4. Vérifier que tous les capteurs sont détectés
5. Observer les données en temps réel

