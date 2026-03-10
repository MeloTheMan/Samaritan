/// Données médicales extraites du prompt utilisateur ou du bracelet
/// Structure simple et extensible
class MedicalData {
  // ===== DONNÉES VITALES =====
  final double? bodyTemperature; // °C
  final int? heartRate; // bpm
  final int? spo2; // % saturation oxygène
  final int? respiratoryRate; // respirations/min

  // ===== DONNÉES ENVIRONNEMENTALES =====
  final double? ambientTemperature; // °C
  final double? ambientHumidity; // %

  // ===== INDICATEURS D'ÉTAT =====
  // Conscience: "normal", "confus", "somnolent", "inconscient"
  final String consciousness;
  
  // Respiration: "normal", "difficile", "sifflante", "absente"
  final String breathing;
  
  // Parole: "normal", "difficile", "impossible"
  final String speech;
  
  // Mobilité: "normal", "faiblesse", "paralysie"
  final String mobility;

  // ===== ÉVÉNEMENTS =====
  final bool hasFallen; // Chute détectée
  final bool hasConvulsions; // Convulsions
  final bool hasSpasms; // Spasmes
  final bool isShivering; // Grelottements
  final bool hasBleeding; // Hémorragie
  final String? bleedingSeverity; // "léger", "modéré", "sévère", "artériel"
  final bool hasBurn; // Brûlure
  final String? burnDegree; // "1er", "2ème", "3ème"

  // ===== SYMPTÔMES ADDITIONNELS =====
  final bool hasChestPain; // Douleur thoracique
  final bool hasHeadache; // Mal de tête
  final String? headacheIntensity; // "léger", "modéré", "sévère", "insupportable"
  final bool hasDizziness; // Vertiges
  final bool hasNausea; // Nausées
  final bool hasVomiting; // Vomissements
  final bool hasAbdominalPain; // Douleur abdominale
  final bool hasSkinRash; // Éruption cutanée
  final bool hasSwelling; // Gonflement
  final String? swellingLocation; // "visage", "gorge", "langue", "lèvres", "généralisé"
  final bool hasCyanosis; // Peau/lèvres bleues
  final bool isPale; // Pâleur
  final bool hasColdSweats; // Sueurs froides

  // ===== MÉTADONNÉES =====
  final String dataSource; // "user_prompt" ou "bracelet"
  final DateTime timestamp;

  MedicalData({
    // Données vitales
    this.bodyTemperature,
    this.heartRate,
    this.spo2,
    this.respiratoryRate,
    
    // Données environnementales
    this.ambientTemperature,
    this.ambientHumidity,
    
    // Indicateurs d'état
    this.consciousness = "normal",
    this.breathing = "normal",
    this.speech = "normal",
    this.mobility = "normal",
    
    // Événements
    this.hasFallen = false,
    this.hasConvulsions = false,
    this.hasSpasms = false,
    this.isShivering = false,
    this.hasBleeding = false,
    this.bleedingSeverity,
    this.hasBurn = false,
    this.burnDegree,
    
    // Symptômes additionnels
    this.hasChestPain = false,
    this.hasHeadache = false,
    this.headacheIntensity,
    this.hasDizziness = false,
    this.hasNausea = false,
    this.hasVomiting = false,
    this.hasAbdominalPain = false,
    this.hasSkinRash = false,
    this.hasSwelling = false,
    this.swellingLocation,
    this.hasCyanosis = false,
    this.isPale = false,
    this.hasColdSweats = false,
    
    // Métadonnées
    this.dataSource = "user_prompt",
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Constructeur const pour les tests
  const MedicalData.constant({
    this.bodyTemperature,
    this.heartRate,
    this.spo2,
    this.respiratoryRate,
    this.ambientTemperature,
    this.ambientHumidity,
    this.consciousness = "normal",
    this.breathing = "normal",
    this.speech = "normal",
    this.mobility = "normal",
    this.hasFallen = false,
    this.hasConvulsions = false,
    this.hasSpasms = false,
    this.isShivering = false,
    this.hasBleeding = false,
    this.bleedingSeverity,
    this.hasBurn = false,
    this.burnDegree,
    this.hasChestPain = false,
    this.hasHeadache = false,
    this.headacheIntensity,
    this.hasDizziness = false,
    this.hasNausea = false,
    this.hasVomiting = false,
    this.hasAbdominalPain = false,
    this.hasSkinRash = false,
    this.hasSwelling = false,
    this.swellingLocation,
    this.hasCyanosis = false,
    this.isPale = false,
    this.hasColdSweats = false,
    this.dataSource = "user_prompt",
    required this.timestamp,
  });

  /// Fusionne les données du bracelet avec les données du prompt
  /// Les données du bracelet ont la priorité
  MedicalData mergeWithBracelet(MedicalData braceletData) {
    return MedicalData(
      // Prioriser les données vitales du bracelet
      bodyTemperature: braceletData.bodyTemperature ?? bodyTemperature,
      heartRate: braceletData.heartRate ?? heartRate,
      spo2: braceletData.spo2 ?? spo2,
      respiratoryRate: braceletData.respiratoryRate ?? respiratoryRate,
      ambientTemperature: braceletData.ambientTemperature ?? ambientTemperature,
      ambientHumidity: braceletData.ambientHumidity ?? ambientHumidity,
      
      // Prioriser les événements du bracelet
      hasFallen: braceletData.hasFallen || hasFallen,
      hasConvulsions: braceletData.hasConvulsions || hasConvulsions,
      hasSpasms: braceletData.hasSpasms || hasSpasms,
      isShivering: braceletData.isShivering || isShivering,
      
      // Garder les données du prompt pour le reste
      consciousness: consciousness,
      breathing: breathing,
      speech: speech,
      mobility: mobility,
      hasBleeding: hasBleeding,
      bleedingSeverity: bleedingSeverity,
      hasBurn: hasBurn,
      burnDegree: burnDegree,
      hasChestPain: hasChestPain,
      hasHeadache: hasHeadache,
      headacheIntensity: headacheIntensity,
      hasDizziness: hasDizziness,
      hasNausea: hasNausea,
      hasVomiting: hasVomiting,
      hasAbdominalPain: hasAbdominalPain,
      hasSkinRash: hasSkinRash,
      hasSwelling: hasSwelling,
      swellingLocation: swellingLocation,
      hasCyanosis: hasCyanosis,
      isPale: isPale,
      hasColdSweats: hasColdSweats,
      
      dataSource: "bracelet_merged",
      timestamp: DateTime.now(),
    );
  }

  /// Convertit en Map pour l'évaluation des règles
  Map<String, dynamic> toMap() {
    return {
      'bodyTemperature': bodyTemperature,
      'heartRate': heartRate,
      'spo2': spo2,
      'respiratoryRate': respiratoryRate,
      'ambientTemperature': ambientTemperature,
      'ambientHumidity': ambientHumidity,
      'consciousness': consciousness,
      'breathing': breathing,
      'speech': speech,
      'mobility': mobility,
      'hasFallen': hasFallen,
      'hasConvulsions': hasConvulsions,
      'hasSpasms': hasSpasms,
      'isShivering': isShivering,
      'hasBleeding': hasBleeding,
      'bleedingSeverity': bleedingSeverity,
      'hasBurn': hasBurn,
      'burnDegree': burnDegree,
      'hasChestPain': hasChestPain,
      'hasHeadache': hasHeadache,
      'headacheIntensity': headacheIntensity,
      'hasDizziness': hasDizziness,
      'hasNausea': hasNausea,
      'hasVomiting': hasVomiting,
      'hasAbdominalPain': hasAbdominalPain,
      'hasSkinRash': hasSkinRash,
      'hasSwelling': hasSwelling,
      'swellingLocation': swellingLocation,
      'hasCyanosis': hasCyanosis,
      'isPale': isPale,
      'hasColdSweats': hasColdSweats,
      'dataSource': dataSource,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer('MedicalData(');
    final data = toMap();
    final nonNullData = data.entries
        .where((e) => e.value != null && e.value != false && e.value != 'normal')
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    buffer.write(nonNullData);
    buffer.write(')');
    return buffer.toString();
  }
}
