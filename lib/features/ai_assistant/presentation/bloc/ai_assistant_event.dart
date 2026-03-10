import 'package:equatable/equatable.dart';

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

class ClearConversation extends AIAssistantEvent {
  const ClearConversation();
}

class SelectQuickQuestion extends AIAssistantEvent {
  final String question;

  const SelectQuickQuestion(this.question);

  @override
  List<Object?> get props => [question];
}
