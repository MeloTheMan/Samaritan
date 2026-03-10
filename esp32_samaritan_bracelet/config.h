/*
 * Configuration du bracelet Samaritan
 * 
 * Modifiez ces valeurs pour personnaliser le comportement du bracelet
 */

#ifndef CONFIG_H
#define CONFIG_H

// ========== CONFIGURATION BLE ==========
#define DEVICE_NAME "Samaritan Bracelet"
#define SERVICE_UUID "0000180d-0000-1000-8000-00805f9b34fb"
#define VITAL_SIGNS_CHARACTERISTIC_UUID "00002a37-0000-1000-8000-00805f9b34fb"
#define COMMAND_CHARACTERISTIC_UUID "00002a38-0000-1000-8000-00805f9b34fb"

// ========== PARAMÈTRES DE SIMULATION ==========

// Fréquence de mesure par défaut (en millisecondes)
#define DEFAULT_MEASUREMENT_FREQUENCY 1000  // 1 seconde

// Plages de valeurs pour la température (en °C)
#define TEMP_BASE 36.5
#define TEMP_VARIATION 1.0  // ±1.0°C

// Plages de valeurs pour la fréquence cardiaque (en BPM)
#define HR_BASE 75
#define HR_VARIATION 15  // ±15 BPM

// Plages de valeurs pour la saturation en oxygène (en %)
#define SPO2_BASE 98
#define SPO2_VARIATION_MIN -3
#define SPO2_VARIATION_MAX 2

// Probabilités d'événements (en %)
#define FALL_PROBABILITY 1  // 1% de chance de chute par mesure
#define MOVEMENT_PROBABILITY 5  // 5% de chance de mouvement brusque

// ========== CONFIGURATION MATÉRIELLE ==========

// Pin de la LED d'indication (optionnel)
#define LED_PIN 2  // LED intégrée sur la plupart des ESP32
#define LED_ENABLED true  // Mettre à false pour désactiver la LED

// Pin du bouton SOS (optionnel)
// #define SOS_BUTTON_PIN 0  // Décommenter pour activer
// #define SOS_BUTTON_ENABLED false

// ========== CONFIGURATION DEBUG ==========

// Activer les messages de debug sur le port série
#define DEBUG_ENABLED true

// Vitesse du port série
#define SERIAL_BAUD_RATE 115200

// Afficher les valeurs détaillées
#define VERBOSE_OUTPUT true

// ========== MODES DE SIMULATION ==========

// Mode de simulation des valeurs
typedef enum {
  SIM_MODE_NORMAL,      // Valeurs normales avec petites variations
  SIM_MODE_STRESS,      // Simule un état de stress (HR élevé)
  SIM_MODE_SLEEP,       // Simule le sommeil (HR bas, temp basse)
  SIM_MODE_EXERCISE,    // Simule l'exercice (HR très élevé)
  SIM_MODE_FEVER        // Simule de la fièvre (temp élevée)
} SimulationMode;

// Mode par défaut
#define DEFAULT_SIM_MODE SIM_MODE_NORMAL

// ========== PARAMÈTRES AVANCÉS ==========

// Intervalle minimum entre deux mesures (ms)
#define MIN_MEASUREMENT_INTERVAL 100

// Intervalle maximum entre deux mesures (ms)
#define MAX_MEASUREMENT_INTERVAL 60000

// Taille du buffer de données BLE
#define BLE_DATA_BUFFER_SIZE 20

// Timeout de reconnexion BLE (ms)
#define BLE_RECONNECT_TIMEOUT 500

#endif // CONFIG_H
