// lib/screens/quiz/quiz_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  final String mode;
  const QuizScreen({super.key, required this.mode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  String? _selected;
  String? _confidence;
  AnswerResult? _result;
  bool _submitting = false;
  bool _showExplanation = false;

  Timer? _timer;
  int _secondsLeft = 60;
  int _totalSeconds = 60;
  late AnimationController _timerAnim;

  @override
  void initState() {
    super.initState();
    _timerAnim = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupTimer());
  }

  void _setupTimer() {
    final session = context.read<AppProvider>().activeSession;
    final question = context.read<AppProvider>().currentQuestion;
    if (session == null || question == null) return;

    if (widget.mode == 'practice') return; // no timer in practice

    _totalSeconds = question.timeAllocationSeconds;
    _secondsLeft = _totalSeconds;
    context.read<AppProvider>().markQuestionStart();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.mode == 'practice') return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          t.cancel();
          _autoSubmit();
        }
      });
    });
  }

  void _autoSubmit() {
    if (_result != null) return;
    _submitAnswer(_selected ?? 'A'); // auto-submit on timeout
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnim.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer(String answer) async {
    if (_submitting || _result != null) return;
    _timer?.cancel();
    setState(() => _submitting = true);

    final result = await context.read<AppProvider>().submitAnswer(
      answer, confidence: _confidence);

    setState(() {
      _submitting = false;
      _result = result;
      _selected = answer;
      if (widget.mode == 'practice') _showExplanation = true;
    });
  }

  void _next() async {
    final prov = context.read<AppProvider>();
    if (prov.isLastQuestion) {
      final results = await prov.completeTest();
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => ResultsScreen(results: results)));
      return;
    }
    prov.advanceToNextQuestion();
    setState(() {
      _selected = null;
      _confidence = null;
      _result = null;
      _showExplanation = false;
      _submitting = false;
    });
    _setupTimer();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final question = prov.currentQuestion;

    if (question == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    final timerRatio = _totalSeconds > 0 ? _secondsLeft / _totalSeconds : 1.0;
    final timerColor = timerRatio > 0.5 ? AppColors.blue
        : timerRatio > 0.25 ? AppColors.warning : AppColors.error;

    return WillPopScope(
      onWillPop: () => _confirmAbandon(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(children: [
            // ── Top bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                // Timer
                if (widget.mode != 'practice')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: timerColor.withOpacity(0.1),
                      border: Border.all(color: timerColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 14, fontFamily: 'monospace',
                          color: timerColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                const Spacer(),
                MonoLabel('${prov.currentQuestionIndex + 1} / ${prov.sessionQuestions.length}'),
                const SizedBox(width: 10),
                DifficultyBadge(question.difficulty),
              ]),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (prov.currentQuestionIndex + 1) / prov.sessionQuestions.length,
                  minHeight: 3,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                ),
              ),
            ),

            // Timer bar
            if (widget.mode != 'practice')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: timerRatio.clamp(0, 1),
                    minHeight: 2,
                    backgroundColor: Colors.white.withOpacity(0.04),
                    valueColor: AlwaysStoppedAnimation(timerColor),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Topic tag
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: MonoLabel(
                  '${question.topic}${question.subtopic != null ? " · ${question.subtopic}" : ""}',
                  color: AppColors.blue,
                  fontSize: 9,
                ),
              ),
            ),

            // ── Question ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SurfaceCard(
                    borderColor: AppColors.blue.withOpacity(0.1),
                    child: Text(question.questionText,
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600, height: 1.6)),
                  ),
                  const SizedBox(height: 14),

                  // Options
                  ...(['A', 'B', 'C', 'D'].map((letter) {
                    final text = question.optionFor(letter);
                    final isSelected = _selected == letter;
                    final isCorrect = _result != null && letter == _result!.correctAnswer;
                    final isWrong = _result != null && isSelected && !_result!.isCorrect;

                    Color borderColor = AppColors.border;
                    Color bgColor = AppColors.surface;
                    Color textColor = AppColors.textSecondary;

                    if (isCorrect) { borderColor = AppColors.success.withOpacity(0.5); bgColor = AppColors.success.withOpacity(0.06); textColor = AppColors.success; }
                    else if (isWrong) { borderColor = AppColors.error.withOpacity(0.5); bgColor = AppColors.error.withOpacity(0.06); textColor = AppColors.error; }
                    else if (isSelected && _result == null) { borderColor = AppColors.blue.withOpacity(0.5); bgColor = AppColors.blue.withOpacity(0.07); textColor = AppColors.blue; }

                    return GestureDetector(
                      onTap: _result == null ? () => setState(() => _selected = letter) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: isCorrect ? AppColors.success.withOpacity(0.2)
                                  : isSelected ? AppColors.blue.withOpacity(0.15)
                                  : Colors.white.withOpacity(0.04),
                              border: Border.all(color: isCorrect ? AppColors.success
                                  : isSelected ? AppColors.blue : AppColors.border),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Center(child: Text(letter,
                                style: TextStyle(fontSize: 10, fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                    color: isCorrect ? AppColors.success
                                        : isSelected ? AppColors.blue : AppColors.textDim))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(text,
                              style: TextStyle(fontSize: 12, color: textColor, height: 1.4))),
                        ]),
                      ),
                    );
                  })),

                  // Confidence selector (before submit)
                  if (_result == null && _selected != null) ...[
                    const SizedBox(height: 12),
                    const MonoLabel('How confident?'),
                    const SizedBox(height: 8),
                    Row(children: [
                      _ConfidenceChip('Low', _confidence == 'low', () => setState(() => _confidence = 'low'), AppColors.error),
                      const SizedBox(width: 6),
                      _ConfidenceChip('Medium', _confidence == 'medium', () => setState(() => _confidence = 'medium'), AppColors.warning),
                      const SizedBox(width: 6),
                      _ConfidenceChip('High', _confidence == 'high', () => setState(() => _confidence = 'high'), AppColors.success),
                    ]),
                  ],

                  // Explanation
                  if (_showExplanation && _result != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withOpacity(0.05),
                        border: Border.all(color: AppColors.blue.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        MonoLabel('✦ Explanation', color: AppColors.blue),
                        const SizedBox(height: 8),
                        Text(_result!.explanation,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6)),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 80), // space for bottom bar
                ]),
              ),
            ),
          ]),
        ),

        // ── Bottom action bar ──────────────────────────────────────
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: _result == null
              ? PrimaryButton(
                  label: 'Submit Answer',
                  loading: _submitting,
                  onPressed: _selected != null ? () => _submitAnswer(_selected!) : null,
                )
              : Row(children: [
                  if (widget.mode == 'practice' && !_showExplanation)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showExplanation = true),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.blue.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Explain ✦',
                            style: TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  if (widget.mode == 'practice' && !_showExplanation) const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppColors.blue.withOpacity(0.4))),
                      ),
                      child: Text(
                        prov.isLastQuestion ? 'See Results →' : 'Next →',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ]),
        ),
      ),
    );
  }

  Future<bool> _confirmAbandon() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Abandon Test?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Your progress won\'t be saved.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continue', style: TextStyle(color: AppColors.blue))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Abandon', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      context.read<AppProvider>().clearSession();
      return true;
    }
    return false;
  }
}

class _ConfidenceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _ConfidenceChip(this.label, this.selected, this.onTap, this.color);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : AppColors.surface,
        border: Border.all(color: selected ? color.withOpacity(0.4) : AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontFamily: 'monospace',
              color: selected ? color : AppColors.textDim,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
    ),
  );
}
