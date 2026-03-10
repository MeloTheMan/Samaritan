/// Résultat d'un diagnostic médical avec actions recommandées
class DiagnosticResult {
  final String id; // Identifiant unique du diagnostic
  final String name; // Nom du diagnostic (ex: "Arrêt Cardiaque")
  final String description; // Description détaillée
  final int confidenceScore; // Score de confiance 0-100%
  final String urgencyLevel; // "routine", "modéré", "urgent", "critique"
  final List<String> recommendedActions; // Actions à effectuer
  final String? relatedCourseId; // ID du cours associé (si existe)
  final List<String> warnings; // Avertissements importants
  final List<String>? followUpQuestions; // Questions de clarification

  const DiagnosticResult({
    required this.id,
    required this.name,
    required this.description,
    required this.confidenceScore,
    required this.urgencyLevel,
    required this.recommendedActions,
    this.relatedCourseId,
    this.warnings = const [],
    this.followUpQuestions,
  });

  /// Crée un résultat depuis un JSON (pour le moteur de règles)
  factory DiagnosticResult.fromJson(Map<String, dynamic> json, int score) {
    return DiagnosticResult(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      confidenceScore: score,
      urgencyLevel: json['urgency'] as String,
      recommendedActions: (json['actions'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      relatedCourseId: json['courseId'] as String?,
      warnings: json['warnings'] != null
          ? (json['warnings'] as List<dynamic>).map((e) => e.toString()).toList()
          : [],
      followUpQuestions: json['followUpQuestions'] != null
          ? (json['followUpQuestions'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
    );
  }

  /// Retourne true si c'est une urgence vitale
  bool get isCritical => urgencyLevel == "critique";

  /// Retourne true si nécessite une intervention urgente
  bool get isUrgent => urgencyLevel == "urgent" || urgencyLevel == "critique";

  /// Retourne un emoji selon le niveau d'urgence
  String get urgencyEmoji {
    switch (urgencyLevel) {
      case "critique":
        return "🚨";
      case "urgent":
        return "⚠️";
      case "modéré":
        return "⏰";
      case "routine":
        return "ℹ️";
      default:
        return "📋";
    }
  }

  /// Retourne une couleur selon le niveau d'urgence (pour l'UI)
  String get urgencyColor {
    switch (urgencyLevel) {
      case "critique":
        return "red";
      case "urgent":
        return "orange";
      case "modéré":
        return "yellow";
      case "routine":
        return "blue";
      default:
        return "grey";
    }
  }

  @override
  String toString() {
    return 'DiagnosticResult(name: $name, confidence: $confidenceScore%, urgency: $urgencyLevel)';
  }
}
