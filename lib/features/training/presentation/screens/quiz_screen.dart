import 'package:flutter/material.dart';
import '../../domain/entities/quiz.dart';
import '../widgets/quiz_question_widget.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final String courseTitle;
  final String courseId;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.courseTitle,
    required this.courseId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _userAnswers = {};

  void _answerQuestion(int selectedIndex) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = selectedIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _submitQuiz() {
    // Calculate score
    int correctAnswers = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_userAnswers[i] == widget.quiz.questions[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }

    final percentage = (correctAnswers / widget.quiz.questions.length * 100).round();
    final passed = percentage >= widget.quiz.passingScore;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          quiz: widget.quiz,
          userAnswers: _userAnswers,
          score: correctAnswers,
          totalQuestions: widget.quiz.questions.length,
          passed: passed,
          courseTitle: widget.courseTitle,
          courseId: widget.courseId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == widget.quiz.questions.length - 1;
    final hasAnswered = _userAnswers.containsKey(_currentQuestionIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.courseTitle}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            minHeight: 6,
          ),

          // Question counter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Score minimum: ${widget.quiz.passingScore}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),

          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: QuizQuestionWidget(
                question: question,
                selectedAnswer: _userAnswers[_currentQuestionIndex],
                onAnswerSelected: _answerQuestion,
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Précédent'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                Expanded(
                  child: isLastQuestion
                      ? ElevatedButton.icon(
                          onPressed: hasAnswered ? _submitQuiz : null,
                          icon: const Icon(Icons.check),
                          label: const Text('Terminer'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: hasAnswered ? _nextQuestion : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Suivant'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
