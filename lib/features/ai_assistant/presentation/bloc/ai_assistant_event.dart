import 'package:equatable/equatable.dart';
import '../../domain/entities/symptoms.dart';

abstract class AIAssistantEvent extends Equatable {
  const AIAssistantEvent();

  @override
  List<Object?> get props => [];
}

class SendMessage extends AIAssistantEvent {
  final String message;

  const SendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class AnalyzeSymptoms extends AIAssistantEvent {
  final Symptoms symptoms;

  const AnalyzeSymptoms(this.symptoms);

  @override
  List<Object?> get props => [symptoms];
}

class ClearConversation extends AIAssistantEvent {
  const ClearConversation();
}

class SelectQuickQuestion extends AIAssistantEvent {
  final String question;

  const SelectQuickQuestion(this.question);

  @override
  List<Object?> get props => [question];
}
