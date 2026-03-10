/*
 * Samaritan Health Bracelet - ESP32 Simulator (Version avancée)
 * 
 * Version améliorée avec modes de simulation et configuration personnalisable
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "config.h"

// Variables globales BLE
BLEServer* pServer = NULL;
BLECharacteristic* pVitalSignsCharacteristic = NULL;
BLECharacteristic* pCommandCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Variables de simulation
float temperature = TEMP_BASE;
int heartRate = HR_BASE;
int oxygenSaturation = SPO2_BASE;
bool fallDetected = false;
bool suddenMovement = false;
SimulationMode currentMode = DEFAULT_SIM_MODE;

// Paramètres
int measurementFrequency = DEFAULT_MEASUREMENT_FREQUENCY;
unsigned long lastMeasurement = 0;
int batteryLevel = 100;  // Simulation de batterie

// Forward declarations
void processCommand(String command);
const char* getModeString(SimulationMode mode);

// Callbacks BLE
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      #if DEBUG_ENABLED
      Serial.println("✅ Client connected");
      #endif
      #if LED_ENABLED
      digitalWrite(LED_PIN, HIGH);
      delay(100);
      digitalWrite(LED_PIN, LOW);
      #endif
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      #if DEBUG_ENABLED
      Serial.println("❌ Client disconnected");
      #endif
    }
};

class CommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String value = pCharacteristic->getValue().c_str();
      
      if (value.length() > 0) {
        #if DEBUG_ENABLED
        Serial.print("📨 Command received: ");
        Serial.println(value);
        #endif
        processCommand(value);
      }
    }
};

void setup() {
  #if DEBUG_ENABLED
  Serial.begin(SERIAL_BAUD_RATE);
  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║  Samaritan Bracelet Simulator v2.0   ║");
  Serial.println("╚════════════════════════════════════════╝\n");
  #endif

  // Configuration des pins
  #if LED_ENABLED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  #endif

  // Initialiser BLE
  BLEDevice::init(DEVICE_NAME);
  
  // Créer le serveur BLE
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Créer le service BLE
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Créer les caractéristiques
  pVitalSignsCharacteristic = pService->createCharacteristic(
                      VITAL_SIGNS_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
                    );
  pVitalSignsCharacteristic->addDescriptor(new BLE2902());

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
  
  #if DEBUG_ENABLED
  Serial.println("🔍 Device is now discoverable");
  Serial.printf("📱 Name: %s\n", DEVICE_NAME);
  Serial.printf("🔋 Battery: %d%%\n", batteryLevel);
  Serial.printf("⏱️  Frequency: %dms\n", measurementFrequency);
  Serial.printf("🎭 Mode: %s\n\n", getModeString(currentMode));
  #endif
}

void loop() {
  // Gérer la connexion/déconnexion
  handleConnection();

  // Envoyer les signes vitaux si connecté
  if (deviceConnected) {
    unsigned long currentMillis = millis();
    
    if (currentMillis - lastMeasurement >= measurementFrequency) {
      lastMeasurement = currentMillis;
      
      // Simuler les variations
      simulateVitalSigns();
      
      // Envoyer les données
      sendVitalSigns();
      
      // Simuler la décharge de la batterie
      if (random(0, 100) < 1) {  // 1% de chance par mesure
        batteryLevel = max(0, batteryLevel - 1);
      }
    }
  }
  
  delay(10);
}

void handleConnection() {
  if (!deviceConnected && oldDeviceConnected) {
    delay(BLE_RECONNECT_TIMEOUT);
    pServer->startAdvertising();
    #if DEBUG_ENABLED
    Serial.println("🔄 Restarting advertising");
    #endif
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}

void simulateVitalSigns() {
  // Ajuster les valeurs selon le mode
  switch (currentMode) {
    case SIM_MODE_NORMAL:
      temperature = TEMP_BASE + (random(-10, 10) / 10.0);
      heartRate = HR_BASE + random(-HR_VARIATION, HR_VARIATION);
      oxygenSaturation = SPO2_BASE + random(SPO2_VARIATION_MIN, SPO2_VARIATION_MAX);
      break;
      
    case SIM_MODE_STRESS:
      temperature = TEMP_BASE + 0.3 + (random(-5, 5) / 10.0);
      heartRate = 95 + random(-10, 20);
      oxygenSaturation = 97 + random(-2, 2);
      break;
      
    case SIM_MODE_SLEEP:
      temperature = TEMP_BASE - 0.3 + (random(-5, 5) / 10.0);
      heartRate = 60 + random(-5, 10);
      oxygenSaturation = 98 + random(-1, 2);
      break;
      
    case SIM_MODE_EXERCISE:
      temperature = TEMP_BASE + 0.8 + (random(-5, 10) / 10.0);
      heartRate = 130 + random(-20, 30);
      oxygenSaturation = 96 + random(-2, 3);
      break;
      
    case SIM_MODE_FEVER:
      temperature = 38.5 + (random(-10, 10) / 10.0);
      heartRate = 90 + random(-10, 20);
      oxygenSaturation = 97 + random(-2, 2);
      break;
  }
  
  // Limiter les valeurs
  temperature = constrain(temperature, 35.0, 42.0);
  heartRate = constrain(heartRate, 40, 200);
  oxygenSaturation = constrain(oxygenSaturation, 85, 100);
  
  // Simuler les événements
  fallDetected = random(0, 100) < FALL_PROBABILITY;
  suddenMovement = random(0, 100) < MOVEMENT_PROBABILITY;
  
  #if VERBOSE_OUTPUT && DEBUG_ENABLED
  Serial.printf("📊 Temp: %.1f°C | HR: %d BPM | SpO2: %d%% | Fall: %s | Move: %s | Batt: %d%%\n",
                temperature, heartRate, oxygenSaturation,
                fallDetected ? "⚠️" : "✓",
                suddenMovement ? "⚡" : "✓",
                batteryLevel);
  #endif
  
  if (fallDetected) {
    #if DEBUG_ENABLED
    Serial.println("🚨 FALL DETECTED!");
    #endif
    #if LED_ENABLED
    // Faire clignoter la LED rapidement
    for (int i = 0; i < 5; i++) {
      digitalWrite(LED_PIN, HIGH);
      delay(100);
      digitalWrite(LED_PIN, LOW);
      delay(100);
    }
    #endif
  }
}

void sendVitalSigns() {
  uint8_t data[BLE_DATA_BUFFER_SIZE];
  int index = 0;
  
  // Température (4 bytes)
  memcpy(&data[index], &temperature, sizeof(float));
  index += sizeof(float);
  
  // Fréquence cardiaque (4 bytes)
  memcpy(&data[index], &heartRate, sizeof(int));
  index += sizeof(int);
  
  // Saturation en oxygène (4 bytes)
  memcpy(&data[index], &oxygenSaturation, sizeof(int));
  index += sizeof(int);
  
  // Timestamp (4 bytes)
  unsigned long timestamp = millis();
  memcpy(&data[index], &timestamp, sizeof(unsigned long));
  index += sizeof(unsigned long);
  
  // Fall detected (1 byte)
  data[index++] = fallDetected ? 1 : 0;
  
  // Sudden movement (1 byte)
  data[index++] = suddenMovement ? 1 : 0;
  
  // Envoyer via BLE
  pVitalSignsCharacteristic->setValue(data, index);
  pVitalSignsCharacteristic->notify();
  
  #if LED_ENABLED
  // Clignoter brièvement la LED
  digitalWrite(LED_PIN, HIGH);
  delay(10);
  digitalWrite(LED_PIN, LOW);
  #endif
}

void processCommand(String command) {
  if (command.startsWith("FREQ:")) {
    String freqStr = command.substring(5);
    int newFreq = freqStr.toInt();
    if (newFreq >= MIN_MEASUREMENT_INTERVAL && newFreq <= MAX_MEASUREMENT_INTERVAL) {
      measurementFrequency = newFreq;
      #if DEBUG_ENABLED
      Serial.printf("⏱️  Frequency changed to: %d ms\n", measurementFrequency);
      #endif
    }
  }
  else if (command.startsWith("MODE:")) {
    String modeStr = command.substring(5);
    if (modeStr == "NORMAL") currentMode = SIM_MODE_NORMAL;
    else if (modeStr == "STRESS") currentMode = SIM_MODE_STRESS;
    else if (modeStr == "SLEEP") currentMode = SIM_MODE_SLEEP;
    else if (modeStr == "EXERCISE") currentMode = SIM_MODE_EXERCISE;
    else if (modeStr == "FEVER") currentMode = SIM_MODE_FEVER;
    #if DEBUG_ENABLED
    Serial.printf("🎭 Mode changed to: %s\n", getModeString(currentMode));
    #endif
  }
  else if (command == "RESET") {
    temperature = TEMP_BASE;
    heartRate = HR_BASE;
    oxygenSaturation = SPO2_BASE;
    fallDetected = false;
    suddenMovement = false;
    measurementFrequency = DEFAULT_MEASUREMENT_FREQUENCY;
    currentMode = DEFAULT_SIM_MODE;
    batteryLevel = 100;
    #if DEBUG_ENABLED
    Serial.println("🔄 Parameters reset to default");
    #endif
  }
  else if (command == "FALL") {
    fallDetected = true;
    #if DEBUG_ENABLED
    Serial.println("🚨 Fall simulation triggered");
    #endif
  }
  else if (command == "FIRMWARE") {
    #if DEBUG_ENABLED
    Serial.println("📦 Firmware update simulation started...");
    for (int i = 0; i <= 100; i += 10) {
      Serial.printf("⏳ Progress: %d%%\n", i);
      delay(500);
    }
    Serial.println("✅ Firmware update completed!");
    #endif
  }
  else if (command == "BATTERY") {
    batteryLevel = 100;
    #if DEBUG_ENABLED
    Serial.println("🔋 Battery recharged to 100%");
    #endif
  }
  else if (command == "STATUS") {
    #if DEBUG_ENABLED
    Serial.println("\n╔════════════════════════════════════════╗");
    Serial.println("║          DEVICE STATUS                ║");
    Serial.println("╠════════════════════════════════════════╣");
    Serial.printf("║ Temperature:    %.1f°C                \n", temperature);
    Serial.printf("║ Heart Rate:     %d BPM                \n", heartRate);
    Serial.printf("║ SpO2:           %d%%                  \n", oxygenSaturation);
    Serial.printf("║ Battery:        %d%%                  \n", batteryLevel);
    Serial.printf("║ Mode:           %s                    \n", getModeString(currentMode));
    Serial.printf("║ Frequency:      %dms                  \n", measurementFrequency);
    Serial.printf("║ Connected:      %s                    \n", deviceConnected ? "Yes" : "No");
    Serial.println("╚════════════════════════════════════════╝\n");
    #endif
  }
  else {
    #if DEBUG_ENABLED
    Serial.println("❓ Unknown command");
    #endif
  }
}

const char* getModeString(SimulationMode mode) {
  switch (mode) {
    case SIM_MODE_NORMAL: return "Normal";
    case SIM_MODE_STRESS: return "Stress";
    case SIM_MODE_SLEEP: return "Sleep";
    case SIM_MODE_EXERCISE: return "Exercise";
    case SIM_MODE_FEVER: return "Fever";
    default: return "Unknown";
  }
}
