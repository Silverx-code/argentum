// lib/screens/quiz/test_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'quiz_screen.dart';

class TestSetupScreen extends StatefulWidget {
  final String? initialMode;
  const TestSetupScreen({super.key, this.initialMode});

  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  String _mode = 'timed';
  String? _selectedTopic;
  int _questionCount = 10;
  String? _difficulty;
  bool _loading = false;

  static const _modes = [
    (id: 'practice',    icon: '📖', label: 'Practice',    sub: 'No timer · instant feedback'),
    (id: 'timed',       icon: '⏱',  label: 'Timed Test',  sub: '60s per question · exam mode'),
    (id: 'speed_drill', icon: '⚡', label: 'Speed Drill', sub: '10s per question · rapid fire'),
  ];

  static const _difficulties = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) _mode = widget.initialMode!;
  }

  @override
  Widget build(BuildContext context) {
    final topics = context.watch<AppProvider>().topics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textSecondary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Test', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Mode Selection
            const MonoLabel('Test Mode'),
            const SizedBox(height: 10),
            ...(_modes.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _mode = m.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _mode == m.id ? AppColors.blue.withValues(alpha:0.08) : AppColors.surface,
                    border: Border.all(
                        color: _mode == m.id ? AppColors.blue.withValues(alpha:0.4) : AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Text(m.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.label, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: _mode == m.id ? AppColors.blue : AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      MonoLabel(m.sub),
                    ])),
                    if (_mode == m.id)
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.blue, borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                  ]),
                ),
              ),
            ))),

            const SizedBox(height: 20),

            // Topic filter
            const MonoLabel('Topic (Optional)'),
            const SizedBox(height: 10),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedTopic,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceLight,
                  hint: const Text('All topics', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                  items: [
                    const DropdownMenuItem(value: null,
                        child: Text('All topics', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    ...topics.map((t) => DropdownMenuItem(value: t.name,
                        child: Text(t.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)))),
                  ],
                  onChanged: (v) => setState(() => _selectedTopic = v),
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDim),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Difficulty filter
            const MonoLabel('Difficulty (Optional)'),
            const SizedBox(height: 10),
            Row(children: [
              _DiffChip(label: 'Any', selected: _difficulty == null,
                  onTap: () => setState(() => _difficulty = null)),
              const SizedBox(width: 8),
              ..._difficulties.map((d) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _DiffChip(
                  label: d[0].toUpperCase() + d.substring(1),
                  selected: _difficulty == d,
                  color: d == 'easy' ? AppColors.success : d == 'hard' ? AppColors.error : AppColors.warning,
                  onTap: () => setState(() => _difficulty = d),
                ),
              )),
            ]),

            const SizedBox(height: 20),

            // Question count
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const MonoLabel('Questions'),
              MonoLabel('$_questionCount', color: AppColors.blue, fontSize: 10),
            ]),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.blue,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.blue,
                overlayColor: AppColors.blue.withValues(alpha:0.1),
              ),
              child: Slider(
                value: _questionCount.toDouble(),
                min: 5, max: 30, divisions: 5,
                onChanged: (v) => setState(() => _questionCount = v.round()),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              MonoLabel('5', fontSize: 8),
              MonoLabel('30', fontSize: 8),
            ]),

            const SizedBox(height: 32),

            PrimaryButton(
              label: 'Start ${_modeLabel(_mode)}',
              loading: _loading,
              onPressed: _startTest,
            ),

            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  String _modeLabel(String m) {
    switch (m) {
      case 'practice':    return 'Practice';
      case 'speed_drill': return 'Speed Drill';
      default:            return 'Timed Test';
    }
  }

  Future<void> _startTest() async {
    setState(() => _loading = true);
    final ok = await context.read<AppProvider>().startTest(
      mode: _mode,
      topicFilter: _selectedTopic,
      questionCount: _questionCount,
      difficulty: _difficulty,
    );
    setState(() => _loading = false);

    if (!mounted) return;
    if (ok) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => QuizScreen(mode: _mode)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No questions available. Upload and process study materials first.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _DiffChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _DiffChip({required this.label, required this.selected,
      this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.blue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha:0.12) : AppColors.surface,
          border: Border.all(color: selected ? c.withValues(alpha:0.4) : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, fontFamily: 'monospace',
                color: selected ? c : AppColors.textDim,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      ),
    );
  }
}
