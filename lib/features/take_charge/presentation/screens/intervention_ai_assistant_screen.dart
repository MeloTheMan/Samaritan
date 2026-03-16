import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_state.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_event.dart';
import '../../../ai_assistant/presentation/widgets/chat_message_widget.dart';
import '../../../device/domain/entities/vital_signs.dart';
import '../../domain/entities/take_charge_session.dart';

/// Écran d'assistant IA intégré dans l'intervention
/// Prend automatiquement en compte les signes vitaux actuels
class InterventionAIAssistantScreen extends StatefulWidget {
  final TakeChargeSession session;

  const InterventionAIAssistantScreen({
    super.key,
    required this.session,
  });

  @override
  State<InterventionAIAssistantScreen> createState() =>
      _InterventionAIAssistantScreenState();
}

class _InterventionAIAssistantScreenState
    extends State<InterventionAIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Envoyer automatiquement les signes vitaux au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendInitialVitalSigns();
    });
  }

  void _sendInitialVitalSigns() {
    if (widget.session.vitalSignsHistory.isEmpty) return;

    final vitalSigns = widget.session.vitalSignsHistory.last;
    final message = _buildVitalSignsMessage(vitalSigns);

    context.read<AIAssistantBloc>().add(SendMessage(message));
  }

  String _buildVitalSignsMessage(VitalSigns vitalSigns) {
    final parts = <String>[];

    parts.add('Signes vitaux actuels de la victime:');
    parts.add('Température: ${vitalSigns.temperature.toStringAsFixed(1)}°C');
    parts.add('Fréquence cardiaque: ${vitalSigns.heartRate} BPM');
    parts.add('SpO2: ${vitalSigns.oxygenSaturation}%');

    if (vitalSigns.fallDetected) {
      parts.add('⚠️ Chute détectée');
    }

    if (vitalSigns.suddenMovement) {
      parts.add('⚠️ Mouvement brusque détecté');
    }

    return parts.join('\n');
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Construire le message avec contexte des signes vitaux
    final contextualMessage = _buildContextualMessage(message);

    context.read<AIAssistantBloc>().add(SendMessage(contextualMessage));
    _messageController.clear();

    // Scroll vers le bas
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _buildContextualMessage(String userMessage) {
    if (widget.session.vitalSignsHistory.isEmpty) {
      return userMessage;
    }

    final vitalSigns = widget.session.vitalSignsHistory.last;
    
    // Ajouter le contexte des signes vitaux au message
    return '''$userMessage

[Contexte - Signes vitaux actuels:
- Température: ${vitalSigns.temperature.toStringAsFixed(1)}°C
- FC: ${vitalSigns.heartRate} BPM
- SpO2: ${vitalSigns.oxygenSaturation}%${vitalSigns.fallDetected ? '\n- Chute détectée' : ''}${vitalSigns.suddenMovement ? '\n- Mouvement brusque' : ''}]''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant IA - Intervention'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AIAssistantBloc>().add(const ClearConversation());
              _sendInitialVitalSigns();
            },
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Bandeau d'information sur les signes vitaux
          if (widget.session.vitalSignsHistory.isNotEmpty)
            _buildVitalSignsBanner(),

          // Messages
          Expanded(
            child: BlocBuilder<AIAssistantBloc, AIAssistantState>(
              builder: (context, state) {
                if (state is AIAssistantInitial) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is AIAssistantLoaded) {
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Analyse des signes vitaux en cours...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      return ChatMessageWidget(
                        message: state.messages[index],
                      );
                    },
                  );
                }

                return const Center(
                  child: Text('État inconnu'),
                );
              },
            ),
          ),

          // Questions rapides
          _buildQuickQuestions(),

          // Zone de saisie
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildVitalSignsBanner() {
    final vitalSigns = widget.session.vitalSignsHistory.last;
    final hasAlert = vitalSigns.temperature < 35 ||
        vitalSigns.temperature > 40 ||
        vitalSigns.heartRate < 40 ||
        vitalSigns.heartRate > 150 ||
        vitalSigns.oxygenSaturation < 90 ||
        vitalSigns.fallDetected;

    return Container(
      padding: const EdgeInsets.all(12),
      color: hasAlert ? Colors.red.shade50 : Colors.blue.shade50,
      child: Row(
        children: [
          Icon(
            hasAlert ? Icons.warning : Icons.monitor_heart,
            color: hasAlert ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signes vitaux en temps réel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasAlert ? Colors.red.shade900 : Colors.blue.shade900,
                  ),
                ),
                Text(
                  '${vitalSigns.temperature.toStringAsFixed(1)}°C • ${vitalSigns.heartRate} BPM • ${vitalSigns.oxygenSaturation}% SpO2',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasAlert ? Colors.red.shade700 : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickQuestionChip('Que faire en priorité ?'),
            const SizedBox(width: 8),
            _buildQuickQuestionChip('Quels sont les risques ?'),
            const SizedBox(width: 8),
            _buildQuickQuestionChip('Dois-je appeler le 15 ?'),
            const SizedBox(width: 8),
            _buildQuickQuestionChip('Comment surveiller ?'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestionChip(String question) {
    return ActionChip(
      label: Text(question),
      onPressed: () {
        _messageController.text = question;
        _sendMessage();
      },
      avatar: const Icon(Icons.help_outline, size: 18),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Posez une question sur la situation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
