// lib/screens/dashboard/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../settings/settings_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _topicBreakdown = [];
  List<Map<String, dynamic>> _weeklyProgress = [];
  List<Map<String, dynamic>> _learningGraph = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getStats(),
        _api.getTopicBreakdown(),
        _api.getWeeklyProgress(),
        _api.getLearningGraph(),
      ]);
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _topicBreakdown = ((results[1] as Map<String, dynamic>)['topics'] as List?)
                ?.cast<Map<String, dynamic>>() ?? [];
        _weeklyProgress = ((results[2] as Map<String, dynamic>)['weeks'] as List?)
                ?.cast<Map<String, dynamic>>() ?? [];
        _learningGraph = results[3] as List<Map<String, dynamic>>;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      setState(() { _loading = false; _error = 'Failed to load progress data. Check your connection.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.blue,
        backgroundColor: AppColors.surface,
        onRefresh: _load,
        child: CustomScrollView(slivers: [

          // ── Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MonoLabel('Analytics'),
                    SizedBox(height: 4),
                    Text('Your Progress', style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                  ]),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_outlined,
                          color: AppColors.textDim, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off, color: AppColors.textDim, size: 40),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.textDim,
                        fontFamily: 'monospace'), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _load,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const MonoLabel('Tap to Retry', color: AppColors.blue),
                      ),
                    ),
                  ]),
                ),
              ),
            )
          else ...[

            // ── All-time stats ───────────────────────────────────
            if (_stats != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _AllTimeStats(stats: _stats!),
                ),
              ),

            // ── Weekly score chart ───────────────────────────────
            if (_weeklyProgress.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _WeeklyChart(weeks: _weeklyProgress),
                ),
              ),

            // ── Topic breakdown ──────────────────────────────────
            if (_topicBreakdown.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: MonoLabel('Topic Mastery Map'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TopicBreakdownRow(data: _topicBreakdown[i]),
                  ),
                  childCount: _topicBreakdown.length,
                )),
              ),
            ],

            // ── Learning graph nodes ─────────────────────────────
            if (_learningGraph.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: MonoLabel('Learning Graph · Intelligence Layer'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LearningGraphCard(node: _learningGraph[i]),
                  ),
                  childCount: _learningGraph.length,
                )),
              ),
            ],
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),
      ),
    );
  }
}

class _AllTimeStats extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _AllTimeStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (label: 'Accuracy', value: '${stats['overall_accuracy_percent'] ?? 0}%',
          color: AppColors.success),
      (label: 'Sessions', value: '${stats['total_sessions'] ?? 0}',
          color: AppColors.blue),
      (label: 'Study hrs', value: '${stats['total_study_hours'] ?? 0}',
          color: AppColors.warning),
      (label: 'Streak', value: '${stats['streak_count'] ?? 0}🔥',
          color: AppColors.error),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const MonoLabel('All-Time Stats'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha:0.08),
            border: Border.all(color: AppColors.blue.withValues(alpha:0.15)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: MonoLabel(stats['rank_label'] as String? ?? 'Student',
              color: AppColors.blue, fontSize: 8),
        ),
      ]),
      const SizedBox(height: 10),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
        children: items.map((item) => Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: item.color.withValues(alpha:0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item.value, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900,
                color: item.color, fontFamily: 'monospace')),
            const SizedBox(height: 4),
            MonoLabel(item.label, fontSize: 7),
          ]),
        )).toList(),
      ),
    ]);
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeks;
  const _WeeklyChart({required this.weeks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const MonoLabel('Score Trend · Last 4 Weeks'),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha:0.04), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      if (i < 0 || i >= weeks.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(weeks[i]['week_start'] as String? ?? '',
                            style: const TextStyle(fontSize: 7,
                                color: AppColors.textDim, fontFamily: 'monospace')),
                      );
                    },
                    interval: 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (val, _) => Text(
                        '${val.toInt()}%',
                        style: const TextStyle(fontSize: 7, color: AppColors.textDim,
                            fontFamily: 'monospace')),
                    interval: 25,
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 0, maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: weeks.asMap().entries.map((e) => FlSpot(
                      e.key.toDouble(),
                      (e.value['avg_score'] as num?)?.toDouble() ?? 0)).toList(),
                  isCurved: true,
                  color: AppColors.blue,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3, color: AppColors.blue,
                        strokeWidth: 1.5, strokeColor: AppColors.background),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [AppColors.blue.withValues(alpha:0.15),
                        AppColors.blue.withValues(alpha:0)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _TopicBreakdownRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TopicBreakdownRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final acc = (data['accuracy'] as num?)?.toDouble();
    final isMastered = data['is_mastered'] as bool? ?? false;
    final status = data['status'] as String? ?? 'not_attempted';
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: statusColor.withValues(alpha:0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(data['topic'] as String? ?? '',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            if (isMastered) const ArgTag('Mastered', color: AppColors.success),
          ]),
          const SizedBox(height: 6),
          if (acc != null) AccuracyBar(accuracy: acc, height: 3),
          const SizedBox(height: 4),
          Row(children: [
            if (acc != null)
              MonoLabel('${acc.toStringAsFixed(0)}% · ', color: statusColor, fontSize: 7),
            MonoLabel('${data['total_attempts'] ?? 0} attempts', fontSize: 7),
          ]),
        ])),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: MonoLabel(status.replaceAll('_', ' '), color: statusColor, fontSize: 7),
        ),
      ]),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'mastered':      return AppColors.success;
      case 'strong':        return AppColors.success;
      case 'improving':     return AppColors.blue;
      case 'weak':          return AppColors.error;
      default:              return AppColors.textDim;
    }
  }
}

class _LearningGraphCard extends StatelessWidget {
  final Map<String, dynamic> node;
  const _LearningGraphCard({required this.node});

  @override
  Widget build(BuildContext context) {
    final velocity = (node['learning_velocity'] as num?)?.toDouble() ?? 0;
    final gap = (node['confidence_gap'] as num?)?.toDouble() ?? 0;
    final misconception = node['misconception_pattern'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.blue.withValues(alpha:0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(node['topic'] as String? ?? '',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          MonoLabel('${node['total_questions_seen'] ?? 0}Q seen', fontSize: 7),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          if (velocity != 0)
            _GraphChip(
              label: velocity > 0 ? '+${velocity.toStringAsFixed(0)}% / session' : '${velocity.toStringAsFixed(0)}% / session',
              color: velocity > 0 ? AppColors.success : AppColors.error,
              icon: velocity > 0 ? '↑' : '↓',
            ),
          if (gap > 0.2)
            _GraphChip(
              label: 'Confidence gap: ${(gap * 100).toStringAsFixed(0)}%',
              color: AppColors.warning,
              icon: '⚠',
            ),
          if (misconception != null)
            _GraphChip(
              label: 'Often picks $misconception',
              color: AppColors.error,
              icon: '✗',
            ),
          if (node['fatigue_detected'] == true)
            const _GraphChip(label: 'Fatigue detected', color: AppColors.warning, icon: '😓'),
        ]),
      ]),
    );
  }
}

class _GraphChip extends StatelessWidget {
  final String label, icon;
  final Color color;
  const _GraphChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha:0.08),
      border: Border.all(color: color.withValues(alpha:0.2)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: TextStyle(fontSize: 8, color: color)),
      const SizedBox(width: 4),
      MonoLabel(label, color: color, fontSize: 7),
    ]),
  );
}
