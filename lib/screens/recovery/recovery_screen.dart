// lib/screens/recovery/recovery_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../quiz/quiz_screen.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadWeaknesses();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textSecondary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recovery',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.blue,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.blue,
          unselectedLabelColor: AppColors.textDim,
          labelStyle: const TextStyle(
              fontSize: 9, fontFamily: 'monospace',
              fontWeight: FontWeight.w700, letterSpacing: 1),
          tabs: const [
            Tab(text: 'WEAK AREAS'),
            Tab(text: 'MASTERY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _WeakAreasTab(
            suggestions: prov.suggestedRecovery,
            weaknesses: prov.weaknesses,
            starting: _starting,
            onStart: _startRecovery,
          ),
          _MasteryTab(),
        ],
      ),
    );
  }

  Future<void> _startRecovery(String topic) async {
    setState(() => _starting = true);
    final ok = await context.read<AppProvider>().startTest(
      mode: 'recovery',
      topicFilter: topic,
      questionCount: 10,
    );
    setState(() => _starting = false);
    if (!mounted) return;
    if (ok) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const QuizScreen(mode: 'recovery')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No questions found for this topic.'),
        backgroundColor: AppColors.error,
      ));
    }
  }
}

class _WeakAreasTab extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final List<Weakness> weaknesses;
  final bool starting;
  final Future<void> Function(String) onStart;

  const _WeakAreasTab({
    required this.suggestions,
    required this.weaknesses,
    required this.starting,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    if (weaknesses.isEmpty && suggestions.isEmpty) {
      return const _EmptyState(
        icon: '🎉',
        title: 'No Weak Areas',
        sub: 'Complete some tests first.\nYour weak topics will appear here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (suggestions.isNotEmpty) ...[
          const MonoLabel('Suggested Recovery Sessions'),
          const SizedBox(height: 10),
          ...suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecoveryCard(
              topic: s['topic'] as String,
              accuracy: (s['accuracy'] as num).toDouble(),
              message: s['message'] as String? ?? '',
              onStart: starting ? null : () => onStart(s['topic'] as String),
            ),
          )),
          const SizedBox(height: 16),
        ],

        if (weaknesses.isNotEmpty) ...[
          const MonoLabel('All Weak Topics'),
          const SizedBox(height: 10),
          ...weaknesses.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _WeaknessRow(weakness: w,
                onStart: starting ? null : () => onStart(w.topic)),
          )),
        ],
      ],
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final String topic;
  final double accuracy;
  final String message;
  final VoidCallback? onStart;

  const _RecoveryCard({
    required this.topic,
    required this.accuracy,
    required this.message,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.error.withValues(alpha:0.08),
          AppColors.error.withValues(alpha:0.03),
        ]),
        border: Border.all(color: AppColors.error.withValues(alpha:0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🎯', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(topic, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            MonoLabel('${accuracy.toStringAsFixed(0)}% accuracy · Recovery needed',
                color: AppColors.error, fontSize: 8),
          ])),
        ]),
        const SizedBox(height: 12),
        AccuracyBar(accuracy: accuracy),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(
            fontSize: 11, color: AppColors.textDim, height: 1.5)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha:0.15),
              foregroundColor: AppColors.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.error.withValues(alpha:0.3)),
              ),
            ),
            child: onStart == null
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: AppColors.error, strokeWidth: 2))
                : const Text('START RECOVERY SESSION',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
          ),
        ),
      ]),
    );
  }
}

class _WeaknessRow extends StatelessWidget {
  final Weakness weakness;
  final VoidCallback? onStart;
  const _WeaknessRow({required this.weakness, this.onStart});

  @override
  Widget build(BuildContext context) {
    final acc = weakness.accuracy * 100;
    final color = acc >= 55 ? AppColors.warning : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: color.withValues(alpha:0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(weakness.topic,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          AccuracyBar(accuracy: acc, height: 3),
          const SizedBox(height: 4),
          MonoLabel('${acc.toStringAsFixed(0)}% · ${weakness.totalAttempts} attempts',
              color: color, fontSize: 8),
        ])),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onStart,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.08),
              border: Border.all(color: color.withValues(alpha:0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: MonoLabel('Fix →', color: color, fontSize: 9),
          ),
        ),
      ]),
    );
  }
}

class _MasteryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Load mastery from API via provider
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService().getMastery(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.blue));
        }
        final masteryList = snap.data ?? [];
        if (masteryList.isEmpty) {
          return const _EmptyState(
            icon: '🏆',
            title: 'No Mastery Records',
            sub: 'Complete tests on a topic 3 times\nwith 85%+ accuracy to master it.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MonoLabel('Mastery Progress'),
            const SizedBox(height: 4),
            const Text(
              '85% accuracy × 3 consecutive sessions = Mastered',
              style: TextStyle(fontSize: 11, color: AppColors.textDim, height: 1.5),
            ),
            const SizedBox(height: 16),
            ...masteryList.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MasteryCard(data: m),
            )),
          ],
        );
      },
    );
  }
}

class _MasteryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MasteryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isMastered = data['is_mastered'] as bool? ?? false;
    final sessions = data['consecutive_sessions_above_threshold'] as int? ?? 0;
    final topic = data['topic'] as String;
    final history = (data['accuracy_history'] as List?)?.cast<num>() ?? [];

    final color = isMastered ? AppColors.success : AppColors.blue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: color.withValues(alpha:isMastered ? 0.3 : 0.1)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(isMastered ? '🏆' : '📈', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(topic, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            MonoLabel(
              isMastered ? 'Mastered ✓' : '$sessions / 3 sessions at 85%+',
              color: color, fontSize: 8,
            ),
          ])),
          if (isMastered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha:0.1),
                border: Border.all(color: AppColors.success.withValues(alpha:0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const MonoLabel('MASTERED', color: AppColors.success, fontSize: 7),
            ),
        ]),
        const SizedBox(height: 10),
        // Session dots
        Row(children: [
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: i < sessions
                    ? color.withValues(alpha:0.15)
                    : Colors.white.withValues(alpha:0.03),
                border: Border.all(color: i < sessions
                    ? color.withValues(alpha:0.4) : AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Icon(
                i < sessions ? Icons.check : Icons.remove,
                size: 14,
                color: i < sessions ? color : AppColors.textDim,
              )),
            ),
          )),
          const SizedBox(width: 8),
          MonoLabel('${3 - sessions} more session${3 - sessions == 1 ? "" : "s"} needed',
              fontSize: 8, color: AppColors.textDim),
        ]),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: [
            const MonoLabel('Accuracy trend: ', fontSize: 8),
            ...history.takeLast(5).map((h) => Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: (h.toDouble() >= 0.85 ? AppColors.success : AppColors.warning)
                    .withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${(h.toDouble() * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.w700,
                    color: h.toDouble() >= 0.85 ? AppColors.success : AppColors.warning,
                  )),
            )),
          ]),
        ],
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String icon, title, sub;
  const _EmptyState({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(sub, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.6)),
      ]),
    ),
  );
}

// Extension for takeLast
extension TakeLast<T> on List<T> {
  List<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}