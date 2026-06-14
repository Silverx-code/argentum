// lib/screens/quiz/results_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../recovery/recovery_screen.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic>? results;
  const ResultsScreen({super.key, this.results});

  @override
  Widget build(BuildContext context) {
    final session = results?['session'] as Map<String, dynamic>?;
    final responses = (results?['responses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final summary = results?['performance_summary'] as Map<String, dynamic>? ?? {};
    final weakTopics = (results?['weak_topics'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final recoveryAvailable = results?['recovery_available'] as bool? ?? false;

    final score = (session?['score_percentage'] as num?)?.toDouble() ?? 0;
    final correct = session?['correct_answers'] as int? ?? 0;
    final total = session?['total_questions'] as int? ?? 0;
    final duration = session?['duration_seconds'] as int? ?? 0;

    final topicAccuracies = summary['average_accuracy_per_topic'] as Map<String, dynamic>? ?? {};

    Color scoreColor = score >= 75 ? AppColors.success : score >= 50 ? AppColors.warning : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(slivers: [

          // ── Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const MonoLabel('Test Complete'),
                const SizedBox(height: 4),
                const Text('Your Results',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
              ]),
            ),
          ),

          // ── Score Card ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.blueDark.withOpacity(0.5), AppColors.blueDarker.withOpacity(0.8)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.blue.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  const MonoLabel('Overall Score'),
                  const SizedBox(height: 8),
                  Text('${score.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900,
                          color: scoreColor, fontFamily: 'monospace', height: 1)),
                  const SizedBox(height: 8),
                  MonoLabel('$correct / $total Correct · ${_formatDuration(duration)}',
                      color: AppColors.textDim),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _ScoreBadge('Speed', _speedLabel(duration, total)),
                    const SizedBox(width: 8),
                    _ScoreBadge('Accuracy', _accuracyLabel(score)),
                    const SizedBox(width: 8),
                    _ScoreBadge('Grade', _gradeLabel(score)),
                  ]),
                ]),
              ),
            ),
          ),

          // ── Recovery CTA ────────────────────────────────────────
          if (recoveryAvailable)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RecoveryScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.error.withOpacity(0.12), AppColors.error.withOpacity(0.05)]),
                      border: Border.all(color: AppColors.error.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Text('🎯', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Start Recovery Test',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        MonoLabel(
                          weakTopics.isNotEmpty
                              ? '${weakTopics.map((w) => w['topic']).take(2).join(' + ')} · Focused 10Q'
                              : 'Targeted recovery session ready',
                          color: AppColors.error.withOpacity(0.8),
                        ),
                      ])),
                      Icon(Icons.arrow_forward_ios, color: AppColors.error, size: 14),
                    ]),
                  ),
                ),
              ),
            ),

          // ── Topic Breakdown ─────────────────────────────────────
          if (topicAccuracies.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: MonoLabel('Topic Breakdown')),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final entry = topicAccuracies.entries.elementAt(i);
                  final acc = (entry.value as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TopicRow(topic: entry.key, accuracy: acc),
                  );
                },
                childCount: topicAccuracies.length,
              )),
            ),
          ],

          // ── Question Review ─────────────────────────────────────
          if (responses.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: MonoLabel('Question Review')),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) => _ReviewItem(response: responses[i], index: i),
                childCount: responses.length,
              )),
            ),
          ],

          // ── Actions ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'New Test',
                  onPressed: () {
                    context.read<AppProvider>().clearSession();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12,
                          letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  String _formatDuration(int s) {
    final m = s ~/ 60; final sec = s % 60;
    return '${m}m ${sec.toString().padLeft(2, '0')}s';
  }

  String _speedLabel(int duration, int total) {
    if (total == 0) return '-';
    final perQ = duration / total;
    if (perQ < 20) return 'Fast';
    if (perQ < 40) return 'Good';
    return 'Slow';
  }

  String _accuracyLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  String _gradeLabel(double score) {
    if (score >= 90) return 'A';
    if (score >= 75) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label, value;
  const _ScoreBadge(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.08),
        border: Border.all(color: AppColors.blue.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        MonoLabel(label, fontSize: 7),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(
            fontSize: 11, color: AppColors.blue,
            fontFamily: 'monospace', fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String topic;
  final double accuracy;
  const _TopicRow({required this.topic, required this.accuracy});

  Color get _color => accuracy >= 75 ? AppColors.success : accuracy >= 50 ? AppColors.warning : AppColors.error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(topic, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary,
              fontFamily: 'monospace')),
          Text('${accuracy.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: _color, fontFamily: 'monospace')),
        ]),
        const SizedBox(height: 6),
        AccuracyBar(accuracy: accuracy),
      ]),
    );
  }
}

class _ReviewItem extends StatefulWidget {
  final Map<String, dynamic> response;
  final int index;
  const _ReviewItem({required this.response, required this.index});

  @override
  State<_ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<_ReviewItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.response;
    final isCorrect = r['is_correct'] as bool? ?? false;
    final color = isCorrect ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  size: 13, color: color)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('Q${widget.index + 1}: ${r['question_text'] ?? ''}',
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
            Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textDim, size: 16),
          ]),
          if (_expanded) ...[
            const SizedBox(height: 10),
            if (r['selected_answer'] != null)
              _ReviewRow('Your answer', r['selected_answer'] as String,
                  isCorrect ? AppColors.success : AppColors.error),
            _ReviewRow('Correct answer', r['correct_answer'] as String? ?? '', AppColors.success),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.04),
                border: Border.all(color: AppColors.blue.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(r['explanation'] as String? ?? '',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _ReviewRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        MonoLabel('$label: '),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value, style: TextStyle(fontSize: 10, color: color,
              fontFamily: 'monospace', fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
