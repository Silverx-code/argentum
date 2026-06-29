// lib/screens/home/home_screen.dart
// Full dashboard - replaced from base
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_provider.dart' as ap;
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../quiz/test_setup_screen.dart';
import '../upload/upload_screen.dart';
import '../recovery/recovery_screen.dart';
import '../tutor/tutor_screen.dart';
import '../dashboard/progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadDashboard();
      context.read<AppProvider>().loadTopics();
      context.read<AppProvider>().loadWeaknesses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardPage(),
      const TestSetupScreen(),
      const UploadScreen(),
      const ProgressScreen(),
      const TutorScreen(),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _navIndex, children: pages),
      bottomNavigationBar: ArgNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final auth = context.watch<ap.AuthProvider>();
    final dash = prov.dashboard;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.blue,
        backgroundColor: AppColors.surface,
        onRefresh: () => context.read<AppProvider>().loadDashboard(),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const MonoLabel('Welcome back'),
                  const SizedBox(height: 4),
                  Text(
                    auth.user?.displayName.split(' ').first ?? 'Student',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary, letterSpacing: 0.5),
                  ),
                ]),
                Row(children: [
                  if ((dash?.streakCount ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha:0.1),
                        border: Border.all(color: AppColors.blue.withValues(alpha:0.2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        MonoLabel('${dash!.streakCount} day streak', color: AppColors.blue, fontSize: 9),
                      ]),
                    ),
                  const SizedBox(width: 8),
                  const ArgentumLogo(size: 36),
                ]),
              ]),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(children: [
                _StatCard(value: '${dash?.totalQuestionsAnswered ?? 0}', label: 'Questions'),
                const SizedBox(width: 8),
                _StatCard(value: '${(dash?.overallAccuracy ?? 0).toStringAsFixed(0)}%', label: 'Avg Score'),
                const SizedBox(width: 8),
                _StatCard(value: '${prov.topics.length}', label: 'Subjects'),
              ]),
            ),
          ),

          // Recovery alert
          if ((dash?.recoverySessionsAvailable ?? 0) > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoveryScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.error.withValues(alpha:0.12), AppColors.error.withValues(alpha:0.06)]),
                      border: Border.all(color: AppColors.error.withValues(alpha:0.25)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Text('🎯', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Recovery Sessions Ready', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        MonoLabel('${dash!.recoverySessionsAvailable} weak topics detected', color: AppColors.error.withValues(alpha:0.8)),
                      ])),
                      const Icon(Icons.chevron_right, color: AppColors.error, size: 18),
                    ]),
                  ),
                ),
              ),
            ),

          // Upload CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SurfaceCard(
                borderColor: AppColors.blue.withValues(alpha:0.2),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen())),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha:0.12),
                      border: Border.all(color: AppColors.blue.withValues(alpha:0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.blue, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Upload Study Material', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    SizedBox(height: 2),
                    MonoLabel('PDF · DOCX · PPT · Images'),
                  ])),
                  const Icon(Icons.chevron_right, color: AppColors.blue, size: 18),
                ]),
              ),
            ),
          ),

          // Weak areas
          if (prov.weaknesses.isNotEmpty) ...[
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: const MonoLabel('Weak Areas · Focus Here', color: AppColors.textDim),
            )),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final w = prov.weaknesses[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TopicBar(name: w.topic, accuracy: w.accuracy * 100),
                  );
                },
                childCount: prov.weaknesses.length.clamp(0, 3),
              )),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          // Quick actions grid
          const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: MonoLabel('Quick Start'),
          )),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _QuickAction(icon: '⚡', label: 'Speed Drill', sub: '30Q · 5 MIN', color: AppColors.warning,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestSetupScreen(initialMode: 'speed_drill')))),
                _QuickAction(icon: '⏱', label: 'Timed Test', sub: 'Exam Mode', color: AppColors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestSetupScreen(initialMode: 'timed')))),
                _QuickAction(icon: '🎯', label: 'Recovery', sub: 'Weak Topics', color: AppColors.error,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoveryScreen()))),
                _QuickAction(icon: '✦', label: 'AI Tutor', sub: 'Ask Anything', color: const Color(0xFF7CC8FF),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorScreen()))),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.5),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value; final String label;
  const _StatCard({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface, border: Border.all(color: AppColors.blue.withValues(alpha:0.1)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.blue, fontFamily: 'monospace')),
        const SizedBox(height: 2),
        MonoLabel(label, fontSize: 7),
      ]),
    ),
  );
}

class _TopicBar extends StatelessWidget {
  final String name; final double accuracy;
  const _TopicBar({required this.name, required this.accuracy});
  Color get _color => accuracy >= 75 ? AppColors.success : accuracy >= 50 ? AppColors.warning : AppColors.error;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(name, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace')),
      Text('${accuracy.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: _color, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
    ]),
    const SizedBox(height: 5),
    AccuracyBar(accuracy: accuracy),
  ]);
}

class _QuickAction extends StatelessWidget {
  final String icon, label, sub; final Color color; final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface, border: Border.all(color: color.withValues(alpha:0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        MonoLabel(sub, fontSize: 8),
      ]),
    ),
  );
}
