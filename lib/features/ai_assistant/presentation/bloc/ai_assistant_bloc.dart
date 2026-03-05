import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/services/rule_engine.dart';
import '../../domain/services/symptom_extractor.dart';
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';

@injectable
class AIAssistantBloc extends Bloc<AIAssistantEvent, AIAssistantState> {
  final RuleEngine ruleEngine;
  final SymptomExtractor symptomExtractor;
  final Uuid uuid = const Uuid();

  AIAssistantBloc({
    required this.ruleEngine,
    required this.symptomExtractor,
  }) : super(const AIAssistantInitial()) {
    on<SendMessage>(_onSendMessage);
    on<AnalyzeSymptoms>(_onAnalyzeSymptoms);
    on<ClearConversation>(_onClearConversation);
    on<SelectQuickQuestion>(_onSelectQuickQuestion);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AIAssistantState> emit,
  ) async {
    try {
      print('🔵 [AIAssistantBloc] Début _onSendMessage: "${event.message}"');
      
      final currentState = state;
      final messages = currentState is AIAssistantLoaded 
          ? List<ChatMessage>.from(currentState.messages) 
          : <ChatMessage>[];

      // Ajouter le message de l'utilisateur
      final userMessage = ChatMessage(
        id: uuid.v4(),
        content: event.message,
        isUser: true,
        timestamp: DateTime.now(),
      );
      messages.add(userMessage);
      print('🔵 [AIAssistantBloc] Message utilisateur ajouté, total: ${messages.length}');

      // Émettre l'état avec le message utilisateur
      emit(AIAssistantLoaded(messages: messages));
      print('🔵 [AIAssistantBloc] État émis avec message utilisateur');

      // Petit délai pour que l'UI se mette à jour
      await Future.delayed(const Duration(milliseconds: 100));

      // Extraire les symptômes du message
      print('🔵 [AIAssistantBloc] Extraction des symptômes...');
      final symptoms = symptomExtractor.extractFromText(event.message);
      print('🔵 [AIAssistantBloc] Symptômes extraits: ${symptoms.toMap()}');

      // Analyser avec le moteur de règles
      print('🔵 [AIAssistantBloc] Initialisation du moteur de règles...');
      await ruleEngine.initialize();
      print('🔵 [AIAssistantBloc] Évaluation des symptômes...');
      final diagnoses = await ruleEngine.evaluate(symptoms: symptoms);
      print('🔵 [AIAssistantBloc] Diagnostics trouvés: ${diagnoses.length}');

      // Générer la réponse
      String responseContent;
      List<String>? suggestedQuestions;

      if (diagnoses.isNotEmpty) {
        print('🔵 [AIAssistantBloc] Génération de réponse avec diagnostic');
        final primaryDiagnosis = diagnoses.first;
        responseContent = _generateDiagnosisResponse(primaryDiagnosis, diagnoses);
        
        // Suggérer des questions complémentaires
        suggestedQuestions = ruleEngine.getSuggestedQuestions(symptoms);
      } else {
        print('🔵 [AIAssistantBloc] Génération de réponse sans diagnostic');
        responseContent = _generateNoMatchResponse(symptoms);
        suggestedQuestions = ruleEngine.getSuggestedQuestions(symptoms);
      }

      print('🔵 [AIAssistantBloc] Réponse générée (${responseContent.length} caractères)');
      print('🔵 [AIAssistantBloc] Contenu: ${responseContent.substring(0, responseContent.length > 100 ? 100 : responseContent.length)}...');

      // Ajouter la réponse de l'assistant
      final assistantMessage = ChatMessage(
        id: uuid.v4(),
        content: responseContent,
        isUser: false,
        timestamp: DateTime.now(),
        diagnoses: diagnoses.isNotEmpty ? diagnoses : null,
        suggestedQuestions: suggestedQuestions,
      );
      messages.add(assistantMessage);
      print('🔵 [AIAssistantBloc] Message assistant ajouté, total: ${messages.length}');

      // Émettre l'état final avec la réponse
      emit(AIAssistantLoaded(
        messages: messages,
        currentDiagnoses: diagnoses.isNotEmpty ? diagnoses : null,
      ));
      print('🔵 [AIAssistantBloc] État final émis avec ${messages.length} messages');
    } catch (e, stackTrace) {
      print('🔴 [AIAssistantBloc] ERREUR: $e');
      print('🔴 [AIAssistantBloc] Stack trace: $stackTrace');
      
      // En cas d'erreur, afficher un message d'erreur
      final currentState = state;
      final messages = currentState is AIAssistantLoaded 
          ? List<ChatMessage>.from(currentState.messages) 
          : <ChatMessage>[];
      
      messages.add(ChatMessage(
        id: uuid.v4(),
        content: 'Désolé, une erreur s\'est produite lors de l\'analyse: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
      emit(AIAssistantLoaded(messages: messages));
    }
  }

  Future<void> _onAnalyzeSymptoms(
    AnalyzeSymptoms event,
    Emitter<AIAssistantState> emit,
  ) async {
    emit(const AIAssistantLoading());

    await ruleEngine.initialize();
    final diagnoses = await ruleEngine.evaluate(symptoms: event.symptoms);

    final messages = <ChatMessage>[
      ChatMessage(
        id: uuid.v4(),
        content: 'Analyse des symptômes en cours...',
        isUser: false,
        timestamp: DateTime.now(),
        diagnoses: diagnoses,
      ),
    ];

    emit(AIAssistantLoaded(
      messages: messages,
      currentDiagnoses: diagnoses,
    ));
  }

  Future<void> _onClearConversation(
    ClearConversation event,
    Emitter<AIAssistantState> emit,
  ) async {
    emit(const AIAssistantInitial());
  }

  Future<void> _onSelectQuickQuestion(
    SelectQuickQuestion event,
    Emitter<AIAssistantState> emit,
  ) async {
    add(SendMessage(event.question));
  }

  String _generateDiagnosisResponse(Diagnosis primary, List<Diagnosis> all) {
    final buffer = StringBuffer();

    // Diagnostic principal
    buffer.writeln('🔍 Analyse terminée\n');
    buffer.writeln('**${primary.condition}**');
    buffer.writeln('Confiance: ${primary.confidence}%');
    buffer.writeln('Urgence: ${_getUrgencyText(primary.urgency)}\n');
    buffer.writeln(primary.description);

    // Actions recommandées
    if (primary.actions.isNotEmpty) {
      buffer.writeln('\n📋 Actions recommandées:');
      for (final action in primary.actions) {
        if (action.type == ActionType.emergency_call) {
          buffer.writeln('\n🚨 ${action.message}');
        } else if (action.type == ActionType.protocol && action.steps != null) {
          buffer.writeln('\n${action.title}:');
          for (var i = 0; i < action.steps!.length; i++) {
            buffer.writeln('${i + 1}. ${action.steps![i]}');
          }
        }
      }
    }

    // Avertissements
    if (primary.warnings.isNotEmpty) {
      buffer.writeln('\n⚠️ Avertissements:');
      for (final warning in primary.warnings) {
        buffer.writeln('• $warning');
      }
    }

    // Autres diagnostics possibles
    if (all.length > 1) {
      buffer.writeln('\n🔎 Autres possibilités:');
      for (var i = 1; i < all.length && i < 3; i++) {
        buffer.writeln('• ${all[i].condition} (${all[i].confidence}%)');
      }
    }

    return buffer.toString();
  }

  String _generateNoMatchResponse(symptoms) {
    return '''
Je n'ai pas pu identifier de diagnostic spécifique avec les informations fournies.

Pour vous aider au mieux, pourriez-vous préciser:
• Vos symptômes principaux
• Depuis quand ils ont commencé
• Leur intensité

Si vous pensez qu'il s'agit d'une urgence, appelez immédiatement le 15 (SAMU) ou le 112.
''';
  }

  String _getUrgencyText(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.immediate:
        return '🚨 IMMÉDIATE';
      case UrgencyLevel.urgent:
        return '⚠️ URGENTE';
      case UrgencyLevel.moderate:
        return '⏰ Modérée';
      case UrgencyLevel.routine:
        return 'ℹ️ Routine';
    }
  }
}
