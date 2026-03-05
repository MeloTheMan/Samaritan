import 'package:equatable/equatable.dart';
import '../../domain/entities/diagnosis.dart';

abstract class AIAssistantState extends Equatable {
  const AIAssistantState();

  @override
  List<Object?> get props => [];
}

class AIAssistantInitial extends AIAssistantState {
  const AIAssistantInitial();
}

class AIAssistantLoading extends AIAssistantState {
  const AIAssistantLoading();
}

class AIAssistantLoaded extends AIAssistantState {
  final List<ChatMessage> messages;
  final List<Diagnosis>? currentDiagnoses;

  const AIAssistantLoaded({
    required this.messages,
    this.currentDiagnoses,
  });

  @override
  List<Object?> get props => [messages, currentDiagnoses];

  AIAssistantLoaded copyWith({
    List<ChatMessage>? messages,
    List<Diagnosis>? currentDiagnoses,
  }) {
    return AIAssistantLoaded(
      messages: messages ?? this.messages,
      currentDiagnoses: currentDiagnoses ?? this.currentDiagnoses,
    );
  }
}

class AIAssistantError extends AIAssistantState {
  final String message;

  const AIAssistantError(this.message);

  @override
  List<Object?> get props => [message];
}

// Message de chat
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<Diagnosis>? diagnoses;
  final List<String>? suggestedQuestions;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.diagnoses,
    this.suggestedQuestions,
  });

  @override
  List<Object?> get props => [id, content, isUser, timestamp, diagnoses, suggestedQuestions];
}
