import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/services/natural_language_processor.dart';
import '../../domain/services/rule_evaluator.dart';
import '../../domain/services/response_generator.dart';
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';

@injectable
class AIAssistantBloc extends Bloc<AIAssistantEvent, AIAssistantState> {
  final NaturalLanguageProcessor nlp;
  final RuleEvaluator evaluator;
  final ResponseGenerator responseGenerator;
  final Uuid uuid = const Uuid();

  AIAssistantBloc({
    required this.nlp,
    required this.evaluator,
    required this.responseGenerator,
  }) : super(const AIAssistantInitial()) {
    on<SendMessage>(_onSendMessage);
    on<ClearConversation>(_onClearConversation);
    on<SelectQuickQuestion>(_onSelectQuickQuestion);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AIAssistantState> emit,
  ) async {
    try {
      print('🔵 [AIAssistantBloc] Message reçu: "${event.message}"');
      
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

      // Émettre l'état avec le message utilisateur
      emit(AIAssistantLoaded(messages: messages));

      // Petit délai pour l'UI
      await Future.delayed(const Duration(milliseconds: 100));

      // Étape 1: Extraire les données médicales du texte
      print('🔵 [AIAssistantBloc] Extraction des données médicales...');
      final medicalData = nlp.extractFromText(event.message);
      print('🔵 [AIAssistantBloc] Données extraites: $medicalData');

      // Étape 2: Évaluer avec le moteur de règles
      print('🔵 [AIAssistantBloc] Évaluation des règles...');
      await evaluator.initialize();
      final diagnostics = await evaluator.evaluate(medicalData);
      print('🔵 [AIAssistantBloc] ${diagnostics.length} diagnostic(s) trouvé(s)');

      // Étape 3: Obtenir les questions de suivi
      final suggestedQuestions = evaluator.getSuggestedQuestions(medicalData);

      // Étape 4: Générer la réponse naturelle
      print('🔵 [AIAssistantBloc] Génération de la réponse...');
      final responseContent = responseGenerator.generateResponse(
        diagnostics: diagnostics,
        data: medicalData,
        suggestedQuestions: suggestedQuestions,
      );

      // Ajouter la réponse de l'assistant
      final assistantMessage = ChatMessage(
        id: uuid.v4(),
        content: responseContent,
        isUser: false,
        timestamp: DateTime.now(),
        diagnostics: diagnostics.isNotEmpty ? diagnostics : null,
        suggestedQuestions: suggestedQuestions,
      );
      messages.add(assistantMessage);

      // Émettre l'état final
      emit(AIAssistantLoaded(
        messages: messages,
        currentDiagnostics: diagnostics.isNotEmpty ? diagnostics : null,
      ));
      
      print('🔵 [AIAssistantBloc] Réponse envoyée avec succès');
    } catch (e, stackTrace) {
      print('🔴 [AIAssistantBloc] ERREUR: $e');
      print('🔴 [AIAssistantBloc] Stack: $stackTrace');
      
      final currentState = state;
      final messages = currentState is AIAssistantLoaded 
          ? List<ChatMessage>.from(currentState.messages) 
          : <ChatMessage>[];
      
      messages.add(ChatMessage(
        id: uuid.v4(),
        content: responseGenerator.generateErrorMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
      emit(AIAssistantLoaded(messages: messages));
    }
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
}
