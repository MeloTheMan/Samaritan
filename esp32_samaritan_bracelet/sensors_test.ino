/*
 * Test des Capteurs - Bracelet Samaritan
 * 
 * Ce code teste individuellement chaque capteur :
 * - MAX30102 (Rythme cardiaque, SpO2, Température)
 * - MPU6050 (Accéléromètre, Gyroscope)
 * - DHT11 (Température et Humidité ambiantes)
 * 
 * Câblage :
 * - MAX30102 : SDA→GPIO21, SCL→GPIO22, VCC→3.3V, GND→GND
 * - MPU6050  : SDA→GPIO21, SCL→GPIO22, VCC→3.3V, GND→GND, AD0→GND
 * - DHT11    : DATA→GPIO4, VCC→3.3V, GND→GND
 */

#include <Wire.h>
#include <DHT.h>

// Bibliothèques pour MAX30102
#include "MAX30105.h"
#include "heartRate.h"

// Bibliothèque pour MPU6050
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// ===== CONFIGURATION DES BROCHES =====
#define I2C_SDA 21
#define I2C_SCL 22
#define DHT_PIN 4

// ===== CONFIGURATION DHT11 =====
#define DHT_TYPE DHT11

// ===== INSTANCES DES CAPTEURS =====
MAX30105 particleSensor;
Adafruit_MPU6050 mpu;
DHT dht(DHT_PIN, DHT_TYPE);

// ===== VARIABLES DE STATUT =====
bool max30102_available = false;
bool mpu6050_available = false;
bool dht11_available = false;

// ===== VARIABLES POUR MAX30102 =====
const byte RATE_SIZE = 4;
byte rates[RATE_SIZE];
byte rateSpot = 0;
long lastBeat = 0;
float beatsPerMinute;
int beatAvg;

void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n\n");
  Serial.println("╔════════════════════════════════════════╗");
  Serial.println("║   TEST DES CAPTEURS - SAMARITAN        ║");
  Serial.println("╚════════════════════════════════════════╝");
  Serial.println();
  
  // Initialisation I2C
  Wire.begin(I2C_SDA, I2C_SCL);
  Serial.println("→ Bus I2C initialisé (SDA=21, SCL=22)");
  Serial.println();
  
  // Scan I2C
  scanI2C();
  Serial.println();
  
  // Test de chaque capteur
  testMAX30102();
  Serial.println();
  
  testMPU6050();
  Serial.println();
  
  testDHT11();
  Serial.println();
  
  // Résumé
  printSummary();
  Serial.println();
  
  Serial.println("═══════════════════════════════════════");
  Serial.println("  DÉBUT DE LA LECTURE EN CONTINU");
  Serial.println("═══════════════════════════════════════");
  Serial.println();
}

void loop() {
  static unsigned long lastUpdate = 0;
  unsigned long currentMillis = millis();
  
  // Mise à jour toutes les 2 secondes
  if (currentMillis - lastUpdate >= 2000) {
    lastUpdate = currentMillis;
    
    Serial.println("\n─────────────────────────────────────");
    Serial.print("Temps: ");
    Serial.print(currentMillis / 1000);
    Serial.println(" secondes");
    Serial.println("─────────────────────────────────────");
    
    readAllSensors();
  }
  
  // Lecture continue du MAX30102 pour la détection de battements
  if (max30102_available) {
    readHeartRate();
  }
  
  delay(10);
}

// ===== SCAN I2C =====
void scanI2C() {
  Serial.println("┌─────────────────────────────────────┐");
  Serial.println("│  SCAN DU BUS I2C                    │");
  Serial.println("└─────────────────────────────────────┘");
  
  byte error, address;
  int deviceCount = 0;
  
  for (address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    
    if (error == 0) {
      Serial.print("  ✓ Périphérique trouvé à 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      Serial.print(" - ");
      
      // Identification du périphérique
      switch (address) {
        case 0x57:
          Serial.println("MAX30102");
          break;
        case 0x68:
          Serial.println("MPU6050");
          break;
        case 0x69:
          Serial.println("MPU6050 (AD0=HIGH)");
          break;
        default:
          Serial.println("Inconnu");
      }
      deviceCount++;
    }
  }
  
  if (deviceCount == 0) {
    Serial.println("  ✗ Aucun périphérique I2C détecté");
  } else {
    Serial.print("  → Total: ");
    Serial.print(deviceCount);
    Serial.println(" périphérique(s)");
  }
}

// ===== TEST MAX30102 =====
void testMAX30102() {
  Serial.println("┌─────────────────────────────────────┐");
  Serial.println("│  TEST MAX30102                      │");
  Serial.println("└─────────────────────────────────────┘");
  
  if (particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    Serial.println("  ✓ MAX30102 détecté");
    
    // Configuration du capteur
    byte ledBrightness = 60;
    byte sampleAverage = 4;
    byte ledMode = 2; // Mode Red + IR pour SpO2
    int sampleRate = 100;
    int pulseWidth = 411;
    int adcRange = 4096;
    
    particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
    particleSensor.setPulseAmplitudeRed(0x0A);
    particleSensor.setPulseAmplitudeGreen(0);
    
    // Test de lecture de température
    float temperature = particleSensor.readTemperature();
    Serial.print("  → Température interne: ");
    Serial.print(temperature);
    Serial.println(" °C");
    
    // Vérification de la présence d'un doigt
    long irValue = particleSensor.getIR();
    Serial.print("  → Valeur IR: ");
    Serial.println(irValue);
    
    if (irValue < 50000) {
      Serial.println("  ⚠ Aucun doigt détecté sur le capteur");
    } else {
      Serial.println("  ✓ Doigt détecté");
    }
    
    max30102_available = true;
  } else {
    Serial.println("  ✗ MAX30102 non détecté");
    Serial.println("  → Vérifier le câblage (SDA, SCL, VCC, GND)");
    Serial.println("  → Adresse I2C attendue: 0x57");
    max30102_available = false;
  }
}

// ===== TEST MPU6050 =====
void testMPU6050() {
  Serial.println("┌─────────────────────────────────────┐");
  Serial.println("│  TEST MPU6050                       │");
  Serial.println("└─────────────────────────────────────┘");
  
  if (mpu.begin()) {
    Serial.println("  ✓ MPU6050 détecté");
    
    // Configuration
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    
    Serial.print("  → Plage accéléromètre: ±");
    switch (mpu.getAccelerometerRange()) {
      case MPU6050_RANGE_2_G: Serial.println("2G"); break;
      case MPU6050_RANGE_4_G: Serial.println("4G"); break;
      case MPU6050_RANGE_8_G: Serial.println("8G"); break;
      case MPU6050_RANGE_16_G: Serial.println("16G"); break;
    }
    
    Serial.print("  → Plage gyroscope: ±");
    switch (mpu.getGyroRange()) {
      case MPU6050_RANGE_250_DEG: Serial.println("250°/s"); break;
      case MPU6050_RANGE_500_DEG: Serial.println("500°/s"); break;
      case MPU6050_RANGE_1000_DEG: Serial.println("1000°/s"); break;
      case MPU6050_RANGE_2000_DEG: Serial.println("2000°/s"); break;
    }
    
    // Test de lecture
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    
    Serial.print("  → Température: ");
    Serial.print(temp.temperature);
    Serial.println(" °C");
    
    mpu6050_available = true;
  } else {
    Serial.println("  ✗ MPU6050 non détecté");
    Serial.println("  → Vérifier le câblage (SDA, SCL, VCC, GND)");
    Serial.println("  → Vérifier que AD0 est connecté à GND");
    Serial.println("  → Adresse I2C attendue: 0x68");
    mpu6050_available = false;
  }
}

// ===== TEST DHT11 =====
void testDHT11() {
  Serial.println("┌─────────────────────────────────────┐");
  Serial.println("│  TEST DHT11                         │");
  Serial.println("└─────────────────────────────────────┘");
  
  dht.begin();
  delay(2000); // DHT11 nécessite un délai au démarrage
  
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("  ✗ DHT11 non détecté ou erreur de lecture");
    Serial.println("  → Vérifier le câblage (DATA→GPIO4, VCC, GND)");
    Serial.println("  → Vérifier la résistance pull-up (10kΩ)");
    Serial.println("  → Attendre 2 secondes entre les lectures");
    dht11_available = false;
  } else {
    Serial.println("  ✓ DHT11 détecté");
    Serial.print("  → Température: ");
    Serial.print(temperature);
    Serial.println(" °C");
    Serial.print("  → Humidité: ");
    Serial.print(humidity);
    Serial.println(" %");
    dht11_available = true;
  }
}

// ===== RÉSUMÉ =====
void printSummary() {
  Serial.println("╔════════════════════════════════════════╗");
  Serial.println("║  RÉSUMÉ DES CAPTEURS                   ║");
  Serial.println("╚════════════════════════════════════════╝");
  
  Serial.print("  MAX30102 (HR/SpO2/Temp): ");
  Serial.println(max30102_available ? "✓ OK" : "✗ ABSENT");
  
  Serial.print("  MPU6050 (Mouvement):     ");
  Serial.println(mpu6050_available ? "✓ OK" : "✗ ABSENT");
  
  Serial.print("  DHT11 (Temp/Humidité):   ");
  Serial.println(dht11_available ? "✓ OK" : "✗ ABSENT");
  
  Serial.println();
  int activeCount = (max30102_available ? 1 : 0) + 
                    (mpu6050_available ? 1 : 0) + 
                    (dht11_available ? 1 : 0);
  Serial.print("  → ");
  Serial.print(activeCount);
  Serial.println("/3 capteurs fonctionnels");
}

// ===== LECTURE DE TOUS LES CAPTEURS =====
void readAllSensors() {
  // MAX30102
  if (max30102_available) {
    Serial.println("\n📊 MAX30102:");
    
    long irValue = particleSensor.getIR();
    long redValue = particleSensor.getRed();
    float temperature = particleSensor.readTemperature();
    
    Serial.print("  IR: ");
    Serial.print(irValue);
    Serial.print(" | Red: ");
    Serial.print(redValue);
    Serial.print(" | Temp: ");
    Serial.print(temperature);
    Serial.println(" °C");
    
    if (irValue < 50000) {
      Serial.println("  ⚠ Placez votre doigt sur le capteur");
    } else {
      Serial.print("  BPM: ");
      Serial.print(beatsPerMinute);
      Serial.print(" | Avg: ");
      Serial.println(beatAvg);
    }
  }
  
  // MPU6050
  if (mpu6050_available) {
    Serial.println("\n📊 MPU6050:");
    
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    
    Serial.print("  Accel (m/s²): X=");
    Serial.print(a.acceleration.x, 2);
    Serial.print(" Y=");
    Serial.print(a.acceleration.y, 2);
    Serial.print(" Z=");
    Serial.println(a.acceleration.z, 2);
    
    Serial.print("  Gyro (rad/s): X=");
    Serial.print(g.gyro.x, 2);
    Serial.print(" Y=");
    Serial.print(g.gyro.y, 2);
    Serial.print(" Z=");
    Serial.println(g.gyro.z, 2);
    
    Serial.print("  Temp: ");
    Serial.print(temp.temperature);
    Serial.println(" °C");
  }
  
  // DHT11
  if (dht11_available) {
    Serial.println("\n📊 DHT11:");
    
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    
    if (!isnan(temperature) && !isnan(humidity)) {
      Serial.print("  Température: ");
      Serial.print(temperature);
      Serial.println(" °C");
      Serial.print("  Humidité: ");
      Serial.print(humidity);
      Serial.println(" %");
    } else {
      Serial.println("  ✗ Erreur de lecture");
    }
  }
}

// ===== LECTURE DU RYTHME CARDIAQUE =====
void readHeartRate() {
  long irValue = particleSensor.getIR();
  
  if (irValue > 50000) {
    if (checkForBeat(irValue)) {
      long delta = millis() - lastBeat;
      lastBeat = millis();
      
      beatsPerMinute = 60 / (delta / 1000.0);
      
      if (beatsPerMinute < 255 && beatsPerMinute > 20) {
        rates[rateSpot++] = (byte)beatsPerMinute;
        rateSpot %= RATE_SIZE;
        
        beatAvg = 0;
        for (byte x = 0; x < RATE_SIZE; x++) {
          beatAvg += rates[x];
        }
        beatAvg /= RATE_SIZE;
      }
    }
  }
}
