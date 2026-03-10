/*
 * Samaritan Health Bracelet - ESP32 Simulator
 * 
 * Ce firmware simule un bracelet de santé connecté qui envoie des données vitales
 * via Bluetooth Low Energy (BLE) à l'application Samaritan.
 * 
 * Fonctionnalités:
 * - Connexion BLE
 * - Envoi de signes vitaux simulés (température, fréquence cardiaque, SpO2)
 * - Détection de chute simulée
 * - Réception de commandes
 * - Configuration des paramètres
 * 
 * Matériel requis: ESP32 (4MB Flash, Dual-core, 240MHz)
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// UUIDs pour les services et caractéristiques BLE
#define SERVICE_UUID                     "0000180d-0000-1000-8000-00805f9b34fb"
#define VITAL_SIGNS_CHARACTERISTIC_UUID  "00002a37-0000-1000-8000-00805f9b34fb"
#define COMMAND_CHARACTERISTIC_UUID      "00002a38-0000-1000-8000-00805f9b34fb"

// Nom du dispositif
#define DEVICE_NAME "Samaritan Bracelet"

// Variables globales
BLEServer* pServer = NULL;
BLECharacteristic* pVitalSignsCharacteristic = NULL;
BLECharacteristic* pCommandCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Paramètres de simulation
float temperature = 36.5;
int heartRate = 75;
int oxygenSaturation = 98;
bool fallDetected = false;
bool suddenMovement = false;

// Paramètres de configuration
int measurementFrequency = 1000; // ms
unsigned long lastMeasurement = 0;

// Forward declarations
void processCommand(String command);

// Callbacks pour la connexion BLE
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Client connected");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Client disconnected");
    }
};

// Callbacks pour les commandes reçues
class CommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String value = pCharacteristic->getValue().c_str();
      
      if (value.length() > 0) {
        Serial.println("Command received:");
        Serial.println(value);
        
        // Traiter les commandes
        processCommand(value);
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Starting Samaritan Bracelet Simulator...");

  // Initialiser BLE
  BLEDevice::init(DEVICE_NAME);
  
  // Créer le serveur BLE
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Créer le service BLE
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Créer la caractéristique pour les signes vitaux (notify)
  pVitalSignsCharacteristic = pService->createCharacteristic(
                      VITAL_SIGNS_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pVitalSignsCharacteristic->addDescriptor(new BLE2902());

  // Créer la caractéristique pour les commandes (write)
  pCommandCharacteristic = pService->createCharacteristic(
                      COMMAND_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_WRITE
                    );
  pCommandCharacteristic->setCallbacks(new CommandCallbacks());

  // Démarrer le service
  pService->start();

  // Démarrer l'advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  
  Serial.println("Waiting for a client connection...");
  Serial.println("Device is now discoverable as: " + String(DEVICE_NAME));
}

void loop() {
  // Gérer la connexion/déconnexion
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // Donner le temps au stack BLE de se préparer
    pServer->startAdvertising(); // Redémarrer l'advertising
    Serial.println("Start advertising");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Envoyer les signes vitaux si connecté
  if (deviceConnected) {
    unsigned long currentMillis = millis();
    
    if (currentMillis - lastMeasurement >= measurementFrequency) {
      lastMeasurement = currentMillis;
      
      // Simuler les variations des signes vitaux
      simulateVitalSigns();
      
      // Envoyer les données
      sendVitalSigns();
    }
  }
  
  delay(10);
}

void simulateVitalSigns() {
  // Simuler la température (36.0 - 37.5°C avec variations)
  temperature = 36.5 + (random(-10, 10) / 10.0);
  
  // Simuler la fréquence cardiaque (60-100 BPM avec variations)
  heartRate = 75 + random(-15, 15);
  
  // Simuler la saturation en oxygène (95-100%)
  oxygenSaturation = 98 + random(-3, 2);
  
  // Simuler occasionnellement une chute (1% de chance)
  if (random(0, 100) < 1) {
    fallDetected = true;
    Serial.println("⚠️ FALL DETECTED!");
  } else {
    fallDetected = false;
  }
  
  // Simuler un mouvement brusque (5% de chance)
  suddenMovement = random(0, 100) < 5;
  
  // Afficher les valeurs
  Serial.printf("Temp: %.1f°C | HR: %d BPM | SpO2: %d%% | Fall: %s | Movement: %s\n",
                temperature, heartRate, oxygenSaturation,
                fallDetected ? "YES" : "NO",
                suddenMovement ? "YES" : "NO");
}

void sendVitalSigns() {
  // Format des données: température(float) + heartRate(int) + oxygenSaturation(int) + 
  // timestamp(long) + fallDetected(bool) + suddenMovement(bool)
  
  uint8_t data[20];
  int index = 0;
  
  // Température (4 bytes - float)
  memcpy(&data[index], &temperature, sizeof(float));
  index += sizeof(float);
  
  // Fréquence cardiaque (4 bytes - int)
  memcpy(&data[index], &heartRate, sizeof(int));
  index += sizeof(int);
  
  // Saturation en oxygène (4 bytes - int)
  memcpy(&data[index], &oxygenSaturation, sizeof(int));
  index += sizeof(int);
  
  // Timestamp (4 bytes - unsigned long)
  unsigned long timestamp = millis();
  memcpy(&data[index], &timestamp, sizeof(unsigned long));
  index += sizeof(unsigned long);
  
  // Fall detected (1 byte - bool)
  data[index++] = fallDetected ? 1 : 0;
  
  // Sudden movement (1 byte - bool)
  data[index++] = suddenMovement ? 1 : 0;
  
  // Envoyer via BLE
  pVitalSignsCharacteristic->setValue(data, index);
  pVitalSignsCharacteristic->notify();
}

void processCommand(String command) {
  // Commandes possibles:
  // "FREQ:xxxx" - Changer la fréquence de mesure (en ms)
  // "RESET" - Réinitialiser les paramètres
  // "FALL" - Simuler une chute
  // "FIRMWARE" - Simuler une mise à jour firmware
  
  if (command.startsWith("FREQ:")) {
    // Extraire la fréquence
    String freqStr = command.substring(5);
    int newFreq = freqStr.toInt();
    if (newFreq >= 100 && newFreq <= 60000) {
      measurementFrequency = newFreq;
      Serial.printf("Measurement frequency changed to: %d ms\n", measurementFrequency);
    }
  }
  else if (command == "RESET") {
    // Réinitialiser les paramètres
    temperature = 36.5;
    heartRate = 75;
    oxygenSaturation = 98;
    fallDetected = false;
    suddenMovement = false;
    measurementFrequency = 1000;
    Serial.println("Parameters reset to default");
  }
  else if (command == "FALL") {
    // Simuler une chute
    fallDetected = true;
    Serial.println("Fall simulation triggered");
  }
  else if (command == "FIRMWARE") {
    // Simuler une mise à jour firmware
    Serial.println("Firmware update simulation started...");
    for (int i = 0; i <= 100; i += 10) {
      Serial.printf("Firmware update progress: %d%%\n", i);
      delay(500);
    }
    Serial.println("Firmware update completed!");
  }
  else {
    Serial.println("Unknown command");
  }
}
