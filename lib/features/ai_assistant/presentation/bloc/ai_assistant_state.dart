import 'package:equatable/equatable.dart';
import '../../domain/entities/diagnostic_result.dart';

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
  final List<DiagnosticResult>? currentDiagnostics;

  const AIAssistantLoaded({
    required this.messages,
    this.currentDiagnostics,
  });

  @override
  List<Object?> get props => [messages, currentDiagnostics];

  AIAssistantLoaded copyWith({
    List<ChatMessage>? messages,
    List<DiagnosticResult>? currentDiagnostics,
  }) {
    return AIAssistantLoaded(
      messages: messages ?? this.messages,
      currentDiagnostics: currentDiagnostics ?? this.currentDiagnostics,
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
  final List<DiagnosticResult>? diagnostics;
  final List<String>? suggestedQuestions;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.diagnostics,
    this.suggestedQuestions,
  });

  @override
  List<Object?> get props => [id, content, isUser, timestamp, diagnostics, suggestedQuestions];
}
