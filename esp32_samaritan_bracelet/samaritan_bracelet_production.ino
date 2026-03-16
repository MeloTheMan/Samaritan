/*
 * Samaritan Health Bracelet - Production Firmware v1.0
 * 
 * Firmware complet pour le bracelet de santé Samaritan avec capteurs réels.
 * 
 * Capteurs supportés (modulaires):
 * - MAX30102: Rythme cardiaque, SpO2, Température corporelle
 * - MPU6050: Accéléromètre/Gyroscope (détection de chute)
 * - DHT11: Température et humidité ambiantes
 * 
 * Modes de fonctionnement:
 * 1. MODE_OWNER: Connecté au téléphone du propriétaire (monitoring normal)
 * 2. MODE_INTERVENTION: Connecté au téléphone du secouriste (intervention)
 * 3. MODE_ALERT: Émission d'alerte d'urgence
 * 
 * Câblage:
 * - MAX30102: SDA→GPIO21, SCL→GPIO22, VCC→3.3V, GND→GND
 * - MPU6050:  SDA→GPIO21, SCL→GPIO22, VCC→3.3V, GND→GND, AD0→GND
 * - DHT11:    DATA→GPIO4, VCC→3.3V, GND→GND
 */

#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <DHT.h>
#include "MAX30105.h"
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <esp_wifi.h>

// ===== CONFIGURATION =====
#define DEVICE_NAME "Samaritan Bracelet"
#define FIRMWARE_VERSION "1.0.0"

// UUIDs BLE
#define SERVICE_UUID                     "0000180d-0000-1000-8000-00805f9b34fb"
#define VITAL_SIGNS_CHARACTERISTIC_UUID  "00002a37-0000-1000-8000-00805f9b34fb"
#define ALERT_CHARACTERISTIC_UUID        "00002a38-0000-1000-8000-00805f9b34fb"
#define COMMAND_CHARACTERISTIC_UUID      "00002a39-0000-1000-8000-00805f9b34fb"
#define STATUS_CHARACTERISTIC_UUID       "00002a3a-0000-1000-8000-00805f9b34fb"

// Broches
#define I2C_SDA 21
#define I2C_SCL 22
#define DHT_PIN 4
#define DHT_TYPE DHT11

// Modes de fonctionnement
enum OperationMode {
  MODE_OWNER,         // Connecté au propriétaire
  MODE_INTERVENTION,  // Connecté au secouriste
  MODE_ALERT          // Alerte active
};

// ===== INSTANCES =====
MAX30105 particleSensor;
Adafruit_MPU6050 mpu;
DHT dht(DHT_PIN, DHT_TYPE);

BLEServer* pServer = NULL;
BLECharacteristic* pVitalSignsChar = NULL;
BLECharacteristic* pAlertChar = NULL;
BLECharacteristic* pCommandChar = NULL;
BLECharacteristic* pStatusChar = NULL;

// ===== VARIABLES GLOBALES =====
bool deviceConnected = false;
bool oldDeviceConnected = false;
OperationMode currentMode = MODE_OWNER;
String connectedClientId = "";

// État des capteurs
bool max30102_available = false;
bool mpu6050_available = false;
bool dht11_available = false;

// Signes vitaux
float bodyTemperature = 0.0;
float ambientTemperature = 0.0;
float humidity = 0.0;
int heartRate = 0;
int oxygenSaturation = 0;
bool fallDetected = false;
bool suddenMovement = false;

// Détection de battements (MAX30102)
const byte RATE_SIZE = 4;
byte rates[RATE_SIZE];
byte rateSpot = 0;
long lastBeat = 0;
float beatsPerMinute = 0;
int beatAvg = 0;

// Variables pour détection de pics (remplace checkForBeat)
long irValuePrevious = 0;
long irValueCurrent = 0;
bool beatDetected = false;
const int BEAT_THRESHOLD = 1000;

// Détection de chute (MPU6050)
float accelMagnitude = 0;
float gyroMagnitude = 0;
const float FALL_THRESHOLD = 20.0;  // m/s²
const float IMPACT_THRESHOLD = 25.0;
unsigned long fallDetectedTime = 0;
const unsigned long FALL_CONFIRMATION_DELAY = 2000; // 2 secondes

// Timing
unsigned long lastVitalSignsSent = 0;
unsigned long lastSensorRead = 0;
unsigned long lastAlertCheck = 0;
unsigned long lastAdvertisingUpdate = 0;
const int VITAL_SIGNS_INTERVAL = 1000;    // 1 seconde
const int SENSOR_READ_INTERVAL = 100;     // 100ms
const int ALERT_CHECK_INTERVAL = 5000;    // 5 secondes
const int ADVERTISING_UPDATE_INTERVAL = 2000; // 2 secondes

// Alerte
bool alertActive = false;
bool alertAcknowledged = false;
unsigned long alertStartTime = 0;
const unsigned long ALERT_TIMEOUT = 300000; // 5 minutes

// Calibration température corporelle
const float TEMP_OFFSET = 6.5; // Offset typique MAX30102
float tempCalibrationOffset = TEMP_OFFSET;

// Device ID unique
String deviceId = "";

// ===== FORWARD DECLARATIONS =====
void sendStatusUpdate();
void processCommand(String command);
void scanI2C();
void initSensors();
void initBLE();
void printSensorStatus();
void printBanner();
void readSensors();
void sendVitalSigns();
void checkAlertConditions();
void triggerAlert(String reason);
void sendAlert();
void handleBLEConnection();
const char* getModeString();

// ===== CALLBACKS BLE =====
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t *param) {
      deviceConnected = true;
      
      // Récupérer l'adresse du client
      char clientAddr[18];
      sprintf(clientAddr, "%02X:%02X:%02X:%02X:%02X:%02X",
              param->connect.remote_bda[0], param->connect.remote_bda[1],
              param->connect.remote_bda[2], param->connect.remote_bda[3],
              param->connect.remote_bda[4], param->connect.remote_bda[5]);
      connectedClientId = String(clientAddr);
      
      Serial.println("✓ Client connected: " + connectedClientId);
      sendStatusUpdate();
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("✗ Client disconnected");
      
      // Si on était en mode intervention, revenir en mode owner
      if (currentMode == MODE_INTERVENTION) {
        Serial.println("→ Returning to OWNER mode");
        currentMode = MODE_OWNER;
        alertActive = false;
        alertAcknowledged = false;
      }
      
      connectedClientId = "";
      
      // Redémarrer l'advertising
      delay(500);
      pServer->startAdvertising();
      Serial.println("📡 Advertising restarted");
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

// ===== SETUP =====
void setup() {
  Serial.begin(115200);
  delay(2000);
  
  printBanner();
  
  // Générer un ID unique basé sur l'adresse MAC
  uint8_t mac[6];
  esp_wifi_get_mac(WIFI_IF_STA, mac);
  char macStr[18];
  sprintf(macStr, "%02X%02X%02X%02X%02X%02X", 
          mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
  deviceId = String(macStr);
  Serial.println("Device ID: " + deviceId);
  Serial.println();
  
  // Initialiser I2C
  Wire.begin(I2C_SDA, I2C_SCL);
  Serial.println("→ I2C initialized (SDA=21, SCL=22)");
  
  // Scanner le bus I2C
  scanI2C();
  Serial.println();
  
  // Initialiser les capteurs
  initSensors();
  Serial.println();
  
  // Initialiser BLE
  initBLE();
  Serial.println();
  
  printSensorStatus();
  Serial.println();
  
  Serial.println("═══════════════════════════════════════");
  Serial.println("  BRACELET READY - Waiting for connection");
  Serial.println("═══════════════════════════════════════\n");
}

// ===== LOOP PRINCIPAL =====
void loop() {
  unsigned long currentMillis = millis();
  
  // Gérer la reconnexion BLE
  handleBLEConnection();
  
  // Lire les capteurs
  if (currentMillis - lastSensorRead >= SENSOR_READ_INTERVAL) {
    lastSensorRead = currentMillis;
    readSensors();
  }
  
  // Envoyer les signes vitaux
  if (deviceConnected && (currentMillis - lastVitalSignsSent >= VITAL_SIGNS_INTERVAL)) {
    lastVitalSignsSent = currentMillis;
    sendVitalSigns();
  }
  
  // Vérifier les conditions d'alerte
  if (currentMillis - lastAlertCheck >= ALERT_CHECK_INTERVAL) {
    lastAlertCheck = currentMillis;
    checkAlertConditions();
  }
  
  // Mettre à jour l'advertising périodiquement
  if (currentMillis - lastAdvertisingUpdate >= ADVERTISING_UPDATE_INTERVAL) {
    lastAdvertisingUpdate = currentMillis;
    updateAdvertising();
  }
  
  // Gérer le timeout d'alerte
  if (alertActive && !alertAcknowledged) {
    if (currentMillis - alertStartTime >= ALERT_TIMEOUT) {
      Serial.println("⚠ Alert timeout - resetting");
      alertActive = false;
    }
  }
  
  delay(10);
}

// ===== INITIALISATION BLE =====
void initBLE() {
  Serial.println("┌─────────────────────────────────────┐");
  Serial.println("│  INITIALIZING BLE                   │");
  Serial.println("└─────────────────────────────────────┘");
  
  BLEDevice::init(DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());
  
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // Caractéristique signes vitaux (notify)
  pVitalSignsChar = pService->createCharacteristic(
    VITAL_SIGNS_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pVitalSignsChar->addDescriptor(new BLE2902());
  
  // Caractéristique alertes (notify)
  pAlertChar = pService->createCharacteristic(
    ALERT_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pAlertChar->addDescriptor(new BLE2902());
  
  // Caractéristique commandes (write)
  pCommandChar = pService->createCharacteristic(
    COMMAND_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  pCommandChar->setCallbacks(new CommandCallbacks());
  
  // Caractéristique statut (read + notify)
  pStatusChar = pService->createCharacteristic(
    STATUS_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pStatusChar->addDescriptor(new BLE2902());
  
  pService->start();
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  BLEDevice::startAdvertising();
  
  // Mettre à jour l'advertising avec les données initiales
  updateAdvertising();
  
  Serial.println("  ✓ BLE initialized");
  Serial.println("  → Service UUID: " + String(SERVICE_UUID));
  Serial.println("  → Device name: " + String(DEVICE_NAME));
}

// ===== INITIALISATION CAPTEURS =====
void initSensors() {
  Serial.println("┌─────────────────────────────────────┐");
  Serial.println("│  INITIALIZING SENSORS               │");
  Serial.println("└─────────────────────────────────────┘");
  
  // MAX30102
  if (particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    Serial.println("  ✓ MAX30102 detected");
    
    byte ledBrightness = 60;
    byte sampleAverage = 4;
    byte ledMode = 2;
    int sampleRate = 100;
    int pulseWidth = 411;
    int adcRange = 4096;
    
    particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
    particleSensor.setPulseAmplitudeRed(0x0A);
    particleSensor.setPulseAmplitudeGreen(0);
    
    max30102_available = true;
  } else {
    Serial.println("  ✗ MAX30102 not found (HR/SpO2/Temp will be unavailable)");
    max30102_available = false;
  }
  
  // MPU6050
  if (mpu.begin()) {
    Serial.println("  ✓ MPU6050 detected");
    
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    
    mpu6050_available = true;
  } else {
    Serial.println("  ✗ MPU6050 not found (Fall detection will be unavailable)");
    mpu6050_available = false;
  }
  
  // DHT11
  dht.begin();
  delay(2000);
  
  float testTemp = dht.readTemperature();
  float testHum = dht.readHumidity();
  
  if (!isnan(testTemp) && !isnan(testHum)) {
    Serial.println("  ✓ DHT11 detected");
    dht11_available = true;
  } else {
    Serial.println("  ✗ DHT11 not found (Ambient temp/humidity will be unavailable)");
    dht11_available = false;
  }
}

// ===== LECTURE DES CAPTEURS =====
void readSensors() {
  // MAX30102 - Lecture continue pour détection battements
  if (max30102_available) {
    long irValue = particleSensor.getIR();
    
    if (irValue > 50000) {
      // Doigt détecté - Détection de battement par analyse de pics
      if (irValue > irValuePrevious + BEAT_THRESHOLD && !beatDetected) {
        // Montée détectée
        beatDetected = true;
      } else if (irValue < irValueCurrent - BEAT_THRESHOLD && beatDetected) {
        // Descente après montée = battement!
        beatDetected = false;
        
        long delta = millis() - lastBeat;
        lastBeat = millis();
        
        // Ignorer les battements trop rapprochés (< 300ms = > 200 BPM)
        if (delta > 300) {
          beatsPerMinute = 60000.0 / delta;
          
          if (beatsPerMinute < 200 && beatsPerMinute > 30) {
            rates[rateSpot++] = (byte)beatsPerMinute;
            rateSpot %= RATE_SIZE;
            
            // Calculer la moyenne
            beatAvg = 0;
            int validCount = 0;
            for (byte x = 0; x < RATE_SIZE; x++) {
              if (rates[x] > 0) {
                beatAvg += rates[x];
                validCount++;
              }
            }
            if (validCount > 0) {
              beatAvg /= validCount;
            }
          }
        }
      }
      
      irValuePrevious = irValueCurrent;
      irValueCurrent = irValue;
      
      // Utiliser beatAvg si disponible, sinon beatsPerMinute instantané
      if (beatAvg > 0) {
        heartRate = beatAvg;
      } else if (beatsPerMinute > 30 && beatsPerMinute < 200) {
        heartRate = (int)beatsPerMinute;
      }
      
      // SpO2 (calcul simplifié basé sur ratio Red/IR)
      long redValue = particleSensor.getRed();
      if (redValue > 0 && irValue > 0) {
        float ratio = (float)redValue / (float)irValue;
        oxygenSaturation = (int)(110 - 25 * ratio);
        if (oxygenSaturation > 100) oxygenSaturation = 100;
        if (oxygenSaturation < 70) oxygenSaturation = 70;
      }
      
      // Température corporelle
      float rawTemp = particleSensor.readTemperature();
      bodyTemperature = rawTemp + tempCalibrationOffset;
      
    } else {
      // Pas de doigt détecté - réinitialiser après 5 secondes
      static unsigned long lastFingerDetected = 0;
      if (lastFingerDetected == 0) {
        lastFingerDetected = millis();
      }
      
      if (millis() - lastFingerDetected > 5000) {
        if (heartRate > 0) {
          heartRate = 0;
          beatAvg = 0;
          beatsPerMinute = 0;
          for (byte x = 0; x < RATE_SIZE; x++) {
            rates[x] = 0;
          }
          rateSpot = 0;
          beatDetected = false;
          irValuePrevious = 0;
          irValueCurrent = 0;
        }
      }
      
      // Réinitialiser le timer quand un doigt est détecté
      if (irValue > 50000) {
        lastFingerDetected = millis();
      }
    }
  }
  
  // MPU6050 - Détection de chute
  if (mpu6050_available) {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    
    // Calculer la magnitude de l'accélération
    accelMagnitude = sqrt(
      a.acceleration.x * a.acceleration.x +
      a.acceleration.y * a.acceleration.y +
      a.acceleration.z * a.acceleration.z
    );
    
    // Calculer la magnitude du gyroscope
    gyroMagnitude = sqrt(
      g.gyro.x * g.gyro.x +
      g.gyro.y * g.gyro.y +
      g.gyro.z * g.gyro.z
    );
    
    // Détection de chute
    if (accelMagnitude > IMPACT_THRESHOLD || accelMagnitude < 2.0) {
      if (!fallDetected) {
        fallDetectedTime = millis();
        fallDetected = true;
        Serial.println("⚠ FALL DETECTED!");
      }
    } else if (fallDetected && (millis() - fallDetectedTime > FALL_CONFIRMATION_DELAY)) {
      // Confirmer la chute après le délai
      if (accelMagnitude < FALL_THRESHOLD) {
        // Chute confirmée (personne au sol)
        Serial.println("🚨 FALL CONFIRMED!");
      } else {
        // Fausse alerte
        fallDetected = false;
      }
    }
    
    // Détection de mouvement brusque
    suddenMovement = (gyroMagnitude > 5.0);
  }
  
  // DHT11 - Température et humidité ambiantes (lecture moins fréquente)
  static unsigned long lastDHTRead = 0;
  if (dht11_available && (millis() - lastDHTRead > 5000)) {
    lastDHTRead = millis();
    
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    
    if (!isnan(temp) && !isnan(hum)) {
      ambientTemperature = temp;
      humidity = hum;
    }
  }
}

// ===== ENVOI DES SIGNES VITAUX =====
void sendVitalSigns() {
  // Format: temp(4) + HR(4) + SpO2(4) + timestamp(4) + fall(1) + movement(1) + 
  //         ambientTemp(4) + humidity(4) + sensors(1)
  uint8_t data[27];
  int index = 0;
  
  // Température corporelle (4 bytes)
  float tempToSend = max30102_available ? bodyTemperature : 0.0;
  memcpy(&data[index], &tempToSend, sizeof(float));
  index += sizeof(float);
  
  // Fréquence cardiaque (4 bytes)
  int hrToSend = max30102_available ? heartRate : 0;
  memcpy(&data[index], &hrToSend, sizeof(int));
  index += sizeof(int);
  
  // Saturation oxygène (4 bytes)
  int spo2ToSend = max30102_available ? oxygenSaturation : 0;
  memcpy(&data[index], &spo2ToSend, sizeof(int));
  index += sizeof(int);
  
  // Timestamp (4 bytes)
  unsigned long timestamp = millis();
  memcpy(&data[index], &timestamp, sizeof(unsigned long));
  index += sizeof(unsigned long);
  
  // Fall detected (1 byte)
  data[index++] = (mpu6050_available && fallDetected) ? 1 : 0;
  
  // Sudden movement (1 byte)
  data[index++] = (mpu6050_available && suddenMovement) ? 1 : 0;
  
  // Température ambiante (4 bytes)
  float ambTempToSend = dht11_available ? ambientTemperature : 0.0;
  memcpy(&data[index], &ambTempToSend, sizeof(float));
  index += sizeof(float);
  
  // Humidité (4 bytes)
  float humToSend = dht11_available ? humidity : 0.0;
  memcpy(&data[index], &humToSend, sizeof(float));
  index += sizeof(float);
  
  // Statut des capteurs (1 byte: bit0=MAX30102, bit1=MPU6050, bit2=DHT11)
  uint8_t sensorStatus = 0;
  if (max30102_available) sensorStatus |= 0x01;
  if (mpu6050_available) sensorStatus |= 0x02;
  if (dht11_available) sensorStatus |= 0x04;
  data[index++] = sensorStatus;
  
  pVitalSignsChar->setValue(data, index);
  pVitalSignsChar->notify();
  
  // Log
  Serial.printf("[%s] Temp: %.1f°C | HR: %3d | SpO2: %3d%% | Fall: %s | Amb: %.1f°C/%.0f%%\n",
                getModeString(),
                tempToSend, hrToSend, spo2ToSend,
                (mpu6050_available && fallDetected) ? "✓" : "✗",
                ambTempToSend, humToSend);
}

// ===== VÉRIFICATION CONDITIONS D'ALERTE =====
void checkAlertConditions() {
  if (alertActive || currentMode == MODE_INTERVENTION) {
    return; // Déjà en alerte ou en intervention
  }
  
  bool criticalCondition = false;
  String alertReason = "";
  
  // IMPORTANT: Ne vérifier les conditions critiques QUE si un doigt est détecté
  // Cela évite les fausses alertes et l'interférence avec le service d'alerte de l'app
  bool fingerDetected = false;
  
  if (max30102_available) {
    long irValue = particleSensor.getIR();
    fingerDetected = (irValue > 50000); // Seuil de détection de doigt
    
    // Ne vérifier les signes vitaux que si un doigt est détecté
    if (fingerDetected) {
      if (bodyTemperature < 35.0) {
        criticalCondition = true;
        alertReason = "Hypothermia";
      } else if (bodyTemperature > 40.0) {
        criticalCondition = true;
        alertReason = "Hyperthermia";
      } else if (heartRate < 40 && heartRate > 0) {
        criticalCondition = true;
        alertReason = "Bradycardia";
      } else if (heartRate > 150) {
        criticalCondition = true;
        alertReason = "Tachycardia";
      } else if (oxygenSaturation < 90 && oxygenSaturation > 0) {
        criticalCondition = true;
        alertReason = "Hypoxia";
      }
    }
  }
  
  // La détection de chute nécessite aussi un doigt détecté pour confirmer
  if (mpu6050_available && fallDetected && fingerDetected) {
    criticalCondition = true;
    alertReason = "Fall Detected";
  }
  
  if (criticalCondition) {
    Serial.println("⚠️ Critical condition detected with finger present");
    triggerAlert(alertReason);
  }
}

void triggerAlert(String reason) {
  alertActive = true;
  alertAcknowledged = false;
  alertStartTime = millis();
  currentMode = MODE_ALERT;
  
  Serial.println("\n🚨🚨🚨 EMERGENCY ALERT 🚨🚨🚨");
  Serial.println("Reason: " + reason);
  Serial.println("Time: " + String(millis() / 1000) + "s");
  
  // Mettre à jour l'advertising pour inclure l'alerte
  updateAdvertising();
  
  sendAlert();
  sendStatusUpdate();
}

// ===== MISE À JOUR DE L'ADVERTISING =====
void updateAdvertising() {
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->stop();
  
  // Créer les manufacturer data avec l'état d'alerte
  // Format: CompanyID(2) + AlertFlag(1) + HeartRate(1) + SpO2(1) + Temp(1) + Fall(1)
  // Le CompanyID sera extrait automatiquement par setManufacturerData()
  String manufacturerData = "";
  manufacturerData += (char)0xFF;  // Company ID low byte
  manufacturerData += (char)0xFF;  // Company ID high byte
  manufacturerData += (char)(alertActive ? 0xFF : 0x00);  // Alert flag
  manufacturerData += (char)((uint8_t)heartRate);
  manufacturerData += (char)((uint8_t)oxygenSaturation);
  manufacturerData += (char)((uint8_t)bodyTemperature);
  manufacturerData += (char)(fallDetected ? 0x01 : 0x00);  // Fall flag
  
  BLEAdvertisementData advertisementData;
  advertisementData.setName(DEVICE_NAME);
  advertisementData.setManufacturerData(manufacturerData);
  
  pAdvertising->setAdvertisementData(advertisementData);
  
  // Ajouter le service UUID dans le scan response
  BLEAdvertisementData scanResponse;
  scanResponse.setCompleteServices(BLEUUID(SERVICE_UUID));
  pAdvertising->setScanResponseData(scanResponse);
  
  pAdvertising->start();
  
  if (alertActive) {
    Serial.println("📡 Advertising updated with ALERT flag");
  }
}

// ===== ENVOI D'ALERTE =====
void sendAlert() {
  // Format: AlertType(1) + DeviceID(16) + VitalSigns(12) + Timestamp(8) + Sensors(1)
  uint8_t alertData[38];
  int index = 0;
  
  // Alert type (1 byte) - 0x01 = urgence critique
  alertData[index++] = 0x01;
  
  // Device ID (16 bytes) - Convertir deviceId en bytes
  uint8_t deviceIdBytes[16] = {0};
  for (int i = 0; i < 16 && i < deviceId.length() / 2; i++) {
    String byteStr = deviceId.substring(i * 2, i * 2 + 2);
    deviceIdBytes[i] = (uint8_t)strtol(byteStr.c_str(), NULL, 16);
  }
  memcpy(&alertData[index], deviceIdBytes, 16);
  index += 16;
  
  // Vital signs (12 bytes)
  float tempToSend = max30102_available ? bodyTemperature : 0.0;
  memcpy(&alertData[index], &tempToSend, sizeof(float));
  index += sizeof(float);
  
  int hrToSend = max30102_available ? heartRate : 0;
  memcpy(&alertData[index], &hrToSend, sizeof(int));
  index += sizeof(int);
  
  int spo2ToSend = max30102_available ? oxygenSaturation : 0;
  memcpy(&alertData[index], &spo2ToSend, sizeof(int));
  index += sizeof(int);
  
  // Timestamp (8 bytes)
  unsigned long long timestamp = millis();
  memcpy(&alertData[index], &timestamp, sizeof(unsigned long long));
  index += sizeof(unsigned long long);
  
  // Sensor status (1 byte)
  uint8_t sensorStatus = 0;
  if (max30102_available) sensorStatus |= 0x01;
  if (mpu6050_available) sensorStatus |= 0x02;
  if (dht11_available) sensorStatus |= 0x04;
  alertData[index++] = sensorStatus;
  
  pAlertChar->setValue(alertData, index);
  pAlertChar->notify();
  
  Serial.println("📡 Alert sent via BLE");
}

// ===== TRAITEMENT DES COMMANDES =====
void processCommand(String command) {
  Serial.println("\n📥 Command received: " + command);
  
  if (command == "TAKE_CHARGE") {
    // Un secouriste prend en charge
    if (alertActive) {
      alertAcknowledged = true;
      currentMode = MODE_INTERVENTION;
      
      Serial.println("✓ Intervention started");
      Serial.println("→ Mode: INTERVENTION");
      Serial.println("→ Rescuer connected: " + connectedClientId);
      
      sendStatusUpdate();
    }
  }
  else if (command == "END_INTERVENTION") {
    // Fin de l'intervention
    if (currentMode == MODE_INTERVENTION) {
      currentMode = MODE_OWNER;
      alertActive = false;
      alertAcknowledged = false;
      fallDetected = false;
      
      Serial.println("✓ Intervention ended");
      Serial.println("→ Returning to OWNER mode");
      
      sendStatusUpdate();
      
      // Se déconnecter pour permettre la reconnexion au propriétaire
      if (deviceConnected) {
        pServer->disconnect(pServer->getConnId());
      }
    }
  }
  else if (command == "ACKNOWLEDGE_ALERT") {
    // Alerte reconnue (mais pas encore prise en charge)
    if (alertActive) {
      alertAcknowledged = true;
      Serial.println("✓ Alert acknowledged");
      sendStatusUpdate();
    }
  }
  else if (command == "CANCEL_ALERT") {
    // Annuler l'alerte (fausse alerte)
    alertActive = false;
    alertAcknowledged = false;
    fallDetected = false;
    currentMode = MODE_OWNER;
    
    Serial.println("✓ Alert cancelled");
    
    // Mettre à jour l'advertising pour retirer l'alerte
    updateAdvertising();
    
    sendStatusUpdate();
  }
  else if (command.startsWith("CALIBRATE_TEMP:")) {
    // Calibrer la température corporelle
    String offsetStr = command.substring(15);
    float newOffset = offsetStr.toFloat();
    if (newOffset >= 0 && newOffset <= 15) {
      tempCalibrationOffset = newOffset;
      Serial.printf("✓ Temperature offset set to: %.1f°C\n", tempCalibrationOffset);
    }
  }
  else if (command == "STATUS") {
    // Demander le statut
    sendStatusUpdate();
  }
  else if (command == "RESET") {
    // Réinitialiser
    alertActive = false;
    alertAcknowledged = false;
    fallDetected = false;
    currentMode = MODE_OWNER;
    Serial.println("✓ System reset");
    
    // Mettre à jour l'advertising
    updateAdvertising();
    
    sendStatusUpdate();
  }
  else {
    Serial.println("✗ Unknown command");
  }
}

// ===== ENVOI DU STATUT =====
void sendStatusUpdate() {
  // Format: mode(1) + alertActive(1) + alertAck(1) + sensors(1) + firmware(16)
  uint8_t statusData[20];
  int index = 0;
  
  // Mode de fonctionnement (1 byte)
  statusData[index++] = (uint8_t)currentMode;
  
  // Alert active (1 byte)
  statusData[index++] = alertActive ? 1 : 0;
  
  // Alert acknowledged (1 byte)
  statusData[index++] = alertAcknowledged ? 1 : 0;
  
  // Sensor status (1 byte)
  uint8_t sensorStatus = 0;
  if (max30102_available) sensorStatus |= 0x01;
  if (mpu6050_available) sensorStatus |= 0x02;
  if (dht11_available) sensorStatus |= 0x04;
  statusData[index++] = sensorStatus;
  
  // Firmware version (16 bytes)
  char fwVersion[16] = {0};
  strncpy(fwVersion, FIRMWARE_VERSION, 15);
  memcpy(&statusData[index], fwVersion, 16);
  index += 16;
  
  pStatusChar->setValue(statusData, index);
  pStatusChar->notify();
  
  Serial.println("📊 Status update sent");
}

// ===== GESTION CONNEXION BLE =====
void handleBLEConnection() {
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}

// ===== FONCTIONS UTILITAIRES =====
void scanI2C() {
  Serial.println("┌─────────────────────────────────────┐");
  Serial.println("│  I2C BUS SCAN                       │");
  Serial.println("└─────────────────────────────────────┘");
  
  byte error, address;
  int deviceCount = 0;
  
  for (address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    
    if (error == 0) {
      Serial.print("  ✓ Device at 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      Serial.print(" - ");
      
      switch (address) {
        case 0x57: Serial.println("MAX30102"); break;
        case 0x68: Serial.println("MPU6050"); break;
        case 0x69: Serial.println("MPU6050 (AD0=HIGH)"); break;
        default: Serial.println("Unknown"); break;
      }
      deviceCount++;
    }
  }
  
  if (deviceCount == 0) {
    Serial.println("  ✗ No I2C devices found");
  } else {
    Serial.printf("  → Total: %d device(s)\n", deviceCount);
  }
}

void printSensorStatus() {
  Serial.println("╔════════════════════════════════════════╗");
  Serial.println("║  SENSOR STATUS                         ║");
  Serial.println("╠════════════════════════════════════════╣");
  Serial.printf("║ MAX30102 (HR/SpO2/Temp): %-13s ║\n", max30102_available ? "✓ AVAILABLE" : "✗ UNAVAILABLE");
  Serial.printf("║ MPU6050 (Fall detect):   %-13s ║\n", mpu6050_available ? "✓ AVAILABLE" : "✗ UNAVAILABLE");
  Serial.printf("║ DHT11 (Ambient):         %-13s ║\n", dht11_available ? "✓ AVAILABLE" : "✗ UNAVAILABLE");
  Serial.println("╚════════════════════════════════════════╝");
  
  int activeCount = (max30102_available ? 1 : 0) + 
                    (mpu6050_available ? 1 : 0) + 
                    (dht11_available ? 1 : 0);
  Serial.printf("→ %d/3 sensors operational\n", activeCount);
  
  if (activeCount == 0) {
    Serial.println("⚠ WARNING: No sensors available - bracelet in degraded mode");
  }
}

const char* getModeString() {
  switch (currentMode) {
    case MODE_OWNER: return "OWNER";
    case MODE_INTERVENTION: return "INTERVENTION";
    case MODE_ALERT: return "ALERT";
    default: return "UNKNOWN";
  }
}

void printBanner() {
  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║   SAMARITAN HEALTH BRACELET            ║");
  Serial.println("║   Production Firmware v" FIRMWARE_VERSION "           ║");
  Serial.println("╚════════════════════════════════════════╝");
  Serial.println();
}
