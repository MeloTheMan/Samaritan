import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bloc/ai_assistant_state.dart';
import 'diagnosis_card_widget.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    print('🟢 [ChatMessageWidget] Affichage message: isUser=${message.isUser}, content="${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}..."');
    print('🟢 [ChatMessageWidget] Diagnostics: ${message.diagnostics?.length ?? 0}, Questions: ${message.suggestedQuestions?.length ?? 0}');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.psychology,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                
                // Afficher les diagnostics si présents
                if (message.diagnostics != null && message.diagnostics!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...message.diagnostics!.map((diagnostic) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: DiagnosisCardWidget(diagnostic: diagnostic),
                      )),
                ],
                
                // Afficher les questions suggérées
                if (message.suggestedQuestions != null &&
                    message.suggestedQuestions!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: message.suggestedQuestions!.map((question) {
                      return ActionChip(
                        label: Text(question),
                        onPressed: () {
                          // TODO: Envoyer la question
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
