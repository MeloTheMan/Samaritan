import 'package:flutter/material.dart';

class QuickQuestionsWidget extends StatelessWidget {
  final Function(String) onQuestionSelected;

  const QuickQuestionsWidget({
    super.key,
    required this.onQuestionSelected,
  });

  static const List<Map<String, dynamic>> _questions = [
    {
      'icon': Icons.favorite,
      'text': 'Que faire en cas d\'arrêt cardiaque?',
      'color': Colors.red,
    },
    {
      'icon': Icons.psychology,
      'text': 'Comment reconnaître un AVC?',
      'color': Colors.purple,
    },
    {
      'icon': Icons.air,
      'text': 'Que faire si quelqu\'un s\'étouffe?',
      'color': Colors.blue,
    },
    {
      'icon': Icons.local_fire_department,
      'text': 'Comment traiter une brûlure?',
      'color': Colors.orange,
    },
    {
      'icon': Icons.healing,
      'text': 'Que faire en cas d\'hémorragie?',
      'color': Colors.red,
    },
    {
      'icon': Icons.thermostat,
      'text': 'Symptômes de coup de chaleur?',
      'color': Colors.deepOrange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _questions.map((question) {
        return InkWell(
          onTap: () => onQuestionSelected(question['text'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (question['color'] as Color).withOpacity(0.1),
              border: Border.all(
                color: (question['color'] as Color).withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  question['icon'] as IconData,
                  size: 20,
                  color: question['color'] as Color,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    question['text'] as String,
                    style: TextStyle(
                      color: question['color'] as Color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
