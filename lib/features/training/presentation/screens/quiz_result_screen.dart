import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/quiz.dart';
import '../bloc/training_bloc.dart';
import '../bloc/training_event.dart';

class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final Map<int, int> userAnswers;
  final int score;
  final int totalQuestions;
  final bool passed;
  final String courseTitle;
  final String courseId;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.userAnswers,
    required this.score,
    required this.totalQuestions,
    required this.passed,
    required this.courseTitle,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / totalQuestions * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats du Quiz'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Result card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      passed ? Icons.check_circle : Icons.cancel,
                      size: 80,
                      color: passed ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      passed ? 'Félicitations !' : 'Pas encore réussi',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: passed ? Colors.green : Colors.red,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      courseTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          'Score',
                          '$score/$totalQuestions',
                          Icons.star,
                        ),
                        _buildStatItem(
                          context,
                          'Pourcentage',
                          '$percentage%',
                          Icons.percent,
                        ),
                        _buildStatItem(
                          context,
                          'Requis',
                          '${quiz.passingScore}%',
                          Icons.flag,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Review section
            Text(
              'Révision des réponses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Questions review
            ...List.generate(quiz.questions.length, (index) {
              final question = quiz.questions[index];
              final userAnswer = userAnswers[index];
              final isCorrect = userAnswer == question.correctAnswerIndex;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCorrect ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question.question,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (userAnswer != null) ...[
                        Text(
                          'Votre réponse:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Text(question.options[userAnswer]),
                        ),
                      ],
                      if (!isCorrect) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Bonne réponse:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            question.options[question.correctAnswerIndex],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                question.explanation,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                // Bouton Marquer comme complété
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: passed
                        ? () {
                            final bloc = getIt<TrainingBloc>();
                            bloc.add(MarkCourseCompleted(courseId));
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cours marqué comme complété !'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            // Retourner à la page principale des cours
                            Navigator.popUntil(context, (route) => route.isFirst);
                          }
                        : null,
                    icon: Icon(passed ? Icons.check_circle : Icons.lock),
                    label: Text(
                      passed
                          ? 'Marquer comme complété'
                          : 'Score insuffisant pour valider',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: passed ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Boutons Retour et Réessayer
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Retour au cours'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                    if (!passed) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // The quiz screen will be reopened
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
