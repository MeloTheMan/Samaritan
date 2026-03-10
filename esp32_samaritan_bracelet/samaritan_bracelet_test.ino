/*
 * Samaritan Health Bracelet - Test Firmware
 * 
 * Firmware de test pour valider le module d'intervention complet.
 * Simule différents scénarios d'urgence avec des données synthétiques.
 * 
 * Scénarios de test:
 * 1. État stable (baseline)
 * 2. Hypothermie critique
 * 3. Hyperthermie sévère
 * 4. Bradycardie critique
 * 5. Tachycardie sévère
 * 6. Hypoxie sévère
 * 7. Chute avec traumatisme
 * 8. Arrêt cardiaque simulé
 * 9. Amélioration progressive
 * 10. Dégradation progressive
 * 
 * Commandes:
 * - "SCENARIO:X" (X = 1-10) : Activer un scénario
 * - "AUTO" : Mode automatique (cycle tous les scénarios)
 * - "ALERT" : Émettre une alerte d'urgence
 * - "HANDLED" : Marquer comme pris en charge
 * - "END" : Terminer l'intervention
 * - "RESET" : Retour à l'état stable
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// UUIDs BLE
#define SERVICE_UUID                     "0000180d-0000-1000-8000-00805f9b34fb"
#define VITAL_SIGNS_CHARACTERISTIC_UUID  "00002a37-0000-1000-8000-00805f9b34fb"
#define ALERT_CHARACTERISTIC_UUID        "00002a38-0000-1000-8000-00805f9b34fb"
#define COMMAND_CHARACTERISTIC_UUID      "00002a39-0000-1000-8000-00805f9b34fb"

#define DEVICE_NAME "Samaritan Test"

// Variables BLE
BLEServer* pServer = NULL;
BLECharacteristic* pVitalSignsCharacteristic = NULL;
BLECharacteristic* pAlertCharacteristic = NULL;
BLECharacteristic* pCommandCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Scénarios de test
enum TestScenario {
  STABLE = 1,           // État stable
  HYPOTHERMIA,          // Hypothermie critique
  HYPERTHERMIA,         // Hyperthermie sévère
  BRADYCARDIA,          // Bradycardie critique
  TACHYCARDIA,          // Tachycardie sévère
  HYPOXIA,              // Hypoxie sévère
  FALL_TRAUMA,          // Chute avec traumatisme
  CARDIAC_ARREST,       // Arrêt cardiaque
  IMPROVING,            // Amélioration progressive
  DETERIORATING         // Dégradation progressive
};

// État actuel
TestScenario currentScenario = STABLE;
bool autoMode = false;
bool alertActive = false;
bool isHandled = false;
int scenarioDuration = 0;
unsigned long scenarioStartTime = 0;

// Signes vitaux
float temperature = 36.5;
int heartRate = 75;
int oxygenSaturation = 98;
bool fallDetected = false;
bool suddenMovement = false;

// Timing
unsigned long lastMeasurement = 0;
unsigned long lastScenarioChange = 0;
const int measurementInterval = 1000; // 1 seconde
const int scenarioChangeInterval = 30000; // 30 secondes en mode auto

// Forward declarations
void processCommand(String command);
void applyScenario(TestScenario scenario);
void sendVitalSigns();
void sendAlert();
void printScenarioInfo();

// Callbacks BLE
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("✓ Client connected");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      isHandled = false;
      Serial.println("✗ Client disconnected");
    }
};

class CommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String value = pCharacteristic->getValue().c_str();
      if (value.length() > 0) {
        processCommand(value);
      }
    }
};

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n╔════════════════════════════════════════════╗");
  Serial.println("║  Samaritan Bracelet - Test Firmware       ║");
  Serial.println("║  Module d'Intervention - Validation       ║");
  Serial.println("╚════════════════════════════════════════════╝\n");

  // Initialiser BLE
  BLEDevice::init(DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Créer le service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Caractéristique signes vitaux (notify)
  pVitalSignsCharacteristic = pService->createCharacteristic(
                      VITAL_SIGNS_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
                    );
  pVitalSignsCharacteristic->addDescriptor(new BLE2902());

  // Caractéristique alertes (notify)
  pAlertCharacteristic = pService->createCharacteristic(
                      ALERT_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
                    );
  pAlertCharacteristic->addDescriptor(new BLE2902());

  // Caractéristique commandes (write)
  pCommandCharacteristic = pService->createCharacteristic(
                      COMMAND_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_WRITE
                    );
  pCommandCharacteristic->setCallbacks(new CommandCallbacks());

  pService->start();

  // Démarrer advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  
  Serial.println("📡 Device discoverable as: " + String(DEVICE_NAME));
  Serial.println("⏳ Waiting for connection...\n");
  
  printCommands();
}

void loop() {
  // Gérer reconnexion
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("📡 Restarting advertising");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    Serial.println("✓ Ready to test intervention module\n");
  }

  // Lire les commandes depuis Serial Monitor
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim(); // Enlever les espaces et retours à la ligne
    if (command.length() > 0) {
      processCommand(command);
    }
  }

  // Mode automatique: changer de scénario toutes les 30s
  if (autoMode) {
    unsigned long currentMillis = millis();
    if (currentMillis - lastScenarioChange >= scenarioChangeInterval) {
      lastScenarioChange = currentMillis;
      int nextScenario = (int)currentScenario + 1;
      if (nextScenario > DETERIORATING) nextScenario = STABLE;
      currentScenario = (TestScenario)nextScenario;
      applyScenario(currentScenario);
    }
  }

  // Envoyer les signes vitaux (même sans connexion BLE pour les tests)
  unsigned long currentMillis = millis();
  if (currentMillis - lastMeasurement >= measurementInterval) {
    lastMeasurement = currentMillis;
    
    // Appliquer le scénario actuel
    applyScenario(currentScenario);
    
    // Envoyer les données si connecté
    if (deviceConnected) {
      sendVitalSigns();
    } else {
      // Afficher quand même dans Serial pour les tests
      Serial.printf("📊 [%s] Temp: %.1f°C | HR: %3d BPM | SpO2: %3d%% | Fall: %s | Move: %s",
                    getScenarioName(currentScenario),
                    temperature, heartRate, oxygenSaturation,
                    fallDetected ? "✓" : "✗",
                    suddenMovement ? "✓" : "✗");
      
      if (isHandled) {
        Serial.print(" | 🏥 HANDLED");
      } else if (alertActive) {
        Serial.print(" | 🚨 ALERT");
      }
      
      Serial.println();
    }
    
    scenarioDuration++;
  }
  
  delay(10);
}

void applyScenario(TestScenario scenario) {
  switch (scenario) {
    case STABLE:
      // État stable - valeurs normales
      temperature = 36.5 + (random(-5, 5) / 10.0);
      heartRate = 75 + random(-5, 5);
      oxygenSaturation = 98 + random(-1, 2);
      fallDetected = false;
      suddenMovement = false;
      break;
      
    case HYPOTHERMIA:
      // Hypothermie critique < 35°C
      temperature = 34.0 + (random(-10, 5) / 10.0);
      heartRate = 50 + random(-10, 5);
      oxygenSaturation = 92 + random(-3, 3);
      fallDetected = false;
      suddenMovement = false;
      break;
      
    case HYPERTHERMIA:
      // Hyperthermie sévère > 40°C
      temperature = 40.5 + (random(-5, 10) / 10.0);
      heartRate = 110 + random(-10, 20);
      oxygenSaturation = 94 + random(-2, 3);
      fallDetected = false;
      suddenMovement = true;
      break;
      
    case BRADYCARDIA:
      // Bradycardie critique < 40 BPM
      temperature = 36.0 + (random(-5, 5) / 10.0);
      heartRate = 35 + random(-5, 5);
      oxygenSaturation = 93 + random(-3, 3);
      fallDetected = false;
      suddenMovement = false;
      break;
      
    case TACHYCARDIA:
      // Tachycardie sévère > 140 BPM
      temperature = 37.5 + (random(-5, 10) / 10.0);
      heartRate = 145 + random(-5, 15);
      oxygenSaturation = 95 + random(-2, 3);
      fallDetected = false;
      suddenMovement = true;
      break;
      
    case HYPOXIA:
      // Hypoxie sévère < 90%
      temperature = 36.0 + (random(-5, 5) / 10.0);
      heartRate = 95 + random(-10, 15);
      oxygenSaturation = 85 + random(-5, 5);
      fallDetected = false;
      suddenMovement = false;
      break;
      
    case FALL_TRAUMA:
      // Chute avec traumatisme
      temperature = 36.0 + (random(-10, 5) / 10.0);
      heartRate = 90 + random(-10, 20);
      oxygenSaturation = 93 + random(-3, 3);
      fallDetected = true;
      suddenMovement = true;
      break;
      
    case CARDIAC_ARREST:
      // Arrêt cardiaque simulé
      temperature = 35.0 + (random(-10, 5) / 10.0);
      heartRate = 25 + random(-10, 10);
      oxygenSaturation = 75 + random(-10, 5);
      fallDetected = true;
      suddenMovement = false;
      break;
      
    case IMPROVING:
      // Amélioration progressive
      temperature = 36.0 + (scenarioDuration * 0.05);
      heartRate = 50 + (scenarioDuration * 2);
      oxygenSaturation = 85 + (scenarioDuration * 1);
      if (temperature > 36.5) temperature = 36.5;
      if (heartRate > 75) heartRate = 75;
      if (oxygenSaturation > 98) oxygenSaturation = 98;
      fallDetected = false;
      suddenMovement = false;
      break;
      
    case DETERIORATING:
      // Dégradation progressive
      temperature = 37.0 - (scenarioDuration * 0.05);
      heartRate = 80 - (scenarioDuration * 2);
      oxygenSaturation = 98 - (scenarioDuration * 1);
      if (temperature < 34.0) temperature = 34.0;
      if (heartRate < 30) heartRate = 30;
      if (oxygenSaturation < 80) oxygenSaturation = 80;
      fallDetected = scenarioDuration > 10;
      suddenMovement = false;
      break;
  }
  
  // Limiter les valeurs
  if (temperature < 30.0) temperature = 30.0;
  if (temperature > 42.0) temperature = 42.0;
  if (heartRate < 20) heartRate = 20;
  if (heartRate > 200) heartRate = 200;
  if (oxygenSaturation < 70) oxygenSaturation = 70;
  if (oxygenSaturation > 100) oxygenSaturation = 100;
}

void sendVitalSigns() {
  uint8_t data[20];
  int index = 0;
  
  // Température (4 bytes)
  memcpy(&data[index], &temperature, sizeof(float));
  index += sizeof(float);
  
  // Fréquence cardiaque (4 bytes)
  memcpy(&data[index], &heartRate, sizeof(int));
  index += sizeof(int);
  
  // Saturation oxygène (4 bytes)
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
  
  pVitalSignsCharacteristic->setValue(data, index);
  pVitalSignsCharacteristic->notify();
  
  // Afficher les valeurs
  Serial.printf("📊 [%s] Temp: %.1f°C | HR: %3d BPM | SpO2: %3d%% | Fall: %s | Move: %s",
                getScenarioName(currentScenario),
                temperature, heartRate, oxygenSaturation,
                fallDetected ? "✓" : "✗",
                suddenMovement ? "✓" : "✗");
  
  if (isHandled) {
    Serial.print(" | 🏥 HANDLED");
  } else if (alertActive) {
    Serial.print(" | 🚨 ALERT");
  }
  
  Serial.println();
}

void sendAlert() {
  // Format: AlertType(1) + DeviceID(16) + VitalSigns(12) + Timestamp(8)
  uint8_t alertData[37];
  int index = 0;
  
  // Alert type (1 byte) - 0x01 = urgence
  alertData[index++] = 0x01;
  
  // Device ID (16 bytes) - UUID simulé
  uint8_t deviceId[16] = {0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0,
                          0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88};
  memcpy(&alertData[index], deviceId, 16);
  index += 16;
  
  // Vital signs (12 bytes)
  memcpy(&alertData[index], &temperature, sizeof(float));
  index += sizeof(float);
  memcpy(&alertData[index], &heartRate, sizeof(int));
  index += sizeof(int);
  memcpy(&alertData[index], &oxygenSaturation, sizeof(int));
  index += sizeof(int);
  
  // Timestamp (8 bytes)
  unsigned long long timestamp = millis();
  memcpy(&alertData[index], &timestamp, sizeof(unsigned long long));
  index += sizeof(unsigned long long);
  
  pAlertCharacteristic->setValue(alertData, index);
  pAlertCharacteristic->notify();
  
  alertActive = true;
  Serial.println("\n🚨 EMERGENCY ALERT SENT!");
  printScenarioInfo();
}

void processCommand(String command) {
  Serial.println("\n📥 Command: " + command);
  
  if (command.startsWith("SCENARIO:")) {
    int scenario = command.substring(9).toInt();
    if (scenario >= 1 && scenario <= 10) {
      currentScenario = (TestScenario)scenario;
      scenarioDuration = 0;
      scenarioStartTime = millis();
      autoMode = false;
      Serial.println("✓ Scenario changed to: " + String(getScenarioName(currentScenario)));
      printScenarioInfo();
    }
  }
  else if (command == "AUTO") {
    autoMode = !autoMode;
    lastScenarioChange = millis();
    Serial.println(autoMode ? "✓ Auto mode ON" : "✓ Auto mode OFF");
  }
  else if (command == "ALERT") {
    sendAlert();
  }
  else if (command == "HANDLED") {
    isHandled = true;
    alertActive = false;
    Serial.println("✓ Marked as HANDLED by volunteer");
  }
  else if (command == "END") {
    isHandled = false;
    alertActive = false;
    currentScenario = STABLE;
    scenarioDuration = 0;
    Serial.println("✓ Intervention ENDED - Reset to stable");
  }
  else if (command == "RESET") {
    currentScenario = STABLE;
    autoMode = false;
    alertActive = false;
    isHandled = false;
    scenarioDuration = 0;
    Serial.println("✓ System RESET");
  }
  else {
    Serial.println("✗ Unknown command");
    printCommands();
  }
}

const char* getScenarioName(TestScenario scenario) {
  switch (scenario) {
    case STABLE: return "STABLE";
    case HYPOTHERMIA: return "HYPOTHERMIA";
    case HYPERTHERMIA: return "HYPERTHERMIA";
    case BRADYCARDIA: return "BRADYCARDIA";
    case TACHYCARDIA: return "TACHYCARDIA";
    case HYPOXIA: return "HYPOXIA";
    case FALL_TRAUMA: return "FALL+TRAUMA";
    case CARDIAC_ARREST: return "CARDIAC_ARREST";
    case IMPROVING: return "IMPROVING";
    case DETERIORATING: return "DETERIORATING";
    default: return "UNKNOWN";
  }
}

void printScenarioInfo() {
  Serial.println("\n╔════════════════════════════════════════════╗");
  Serial.printf("║ Scenario: %-32s ║\n", getScenarioName(currentScenario));
  Serial.println("╠════════════════════════════════════════════╣");
  
  switch (currentScenario) {
    case STABLE:
      Serial.println("║ État stable - Valeurs normales            ║");
      Serial.println("║ Pronostic attendu: STABLE                 ║");
      break;
    case HYPOTHERMIA:
      Serial.println("║ Hypothermie critique < 35°C                ║");
      Serial.println("║ Pronostic attendu: CRITICAL                ║");
      break;
    case HYPERTHERMIA:
      Serial.println("║ Hyperthermie sévère > 40°C                 ║");
      Serial.println("║ Pronostic attendu: CRITICAL                ║");
      break;
    case BRADYCARDIA:
      Serial.println("║ Bradycardie critique < 40 BPM              ║");
      Serial.println("║ Pronostic attendu: CRITICAL                ║");
      break;
    case TACHYCARDIA:
      Serial.println("║ Tachycardie sévère > 140 BPM               ║");
      Serial.println("║ Pronostic attendu: CRITICAL                ║");
      break;
    case HYPOXIA:
      Serial.println("║ Hypoxie sévère < 90%                       ║");
      Serial.println("║ Pronostic attendu: CRITICAL                ║");
      break;
    case FALL_TRAUMA:
      Serial.println("║ Chute détectée + traumatisme               ║");
      Serial.println("║ Pronostic attendu: MODERATE/SERIOUS        ║");
      break;
    case CARDIAC_ARREST:
      Serial.println("║ Arrêt cardiaque simulé                     ║");
      Serial.println("║ Pronostic attendu: CRITICAL                ║");
      break;
    case IMPROVING:
      Serial.println("║ Amélioration progressive des signes        ║");
      Serial.println("║ Pronostic: CRITICAL → STABLE               ║");
      break;
    case DETERIORATING:
      Serial.println("║ Dégradation progressive                    ║");
      Serial.println("║ Pronostic: STABLE → CRITICAL               ║");
      break;
  }
  
  Serial.println("╚════════════════════════════════════════════╝\n");
}

void printCommands() {
  Serial.println("\n╔════════════════════════════════════════════╗");
  Serial.println("║           Available Commands               ║");
  Serial.println("╠════════════════════════════════════════════╣");
  Serial.println("║ SCENARIO:X  - Set scenario (1-10)          ║");
  Serial.println("║ AUTO        - Toggle auto mode             ║");
  Serial.println("║ ALERT       - Send emergency alert         ║");
  Serial.println("║ HANDLED     - Mark as handled              ║");
  Serial.println("║ END         - End intervention             ║");
  Serial.println("║ RESET       - Reset to stable              ║");
  Serial.println("╚════════════════════════════════════════════╝\n");
}
