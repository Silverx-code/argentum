// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart' as ap;
import '../../services/paystack_service.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();
  final _paystack = PaystackService();
  Map<String, dynamic>? _stats;
  String _currentPlan = 'starter';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _paystack.initialize();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _loading = false); return; }
    try {
      final results = await Future.wait([
        _api.getStats(),
        _paystack.getUserPlan(user.uid),
      ]);
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _currentPlan = results[1] as String;
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textSecondary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ── Profile card ─────────────────────────────────
                _ProfileCard(
                  user: auth.user,
                  stats: _stats,
                  currentPlan: _currentPlan,
                ),
                const SizedBox(height: 20),

                // ── Subscription plans ────────────────────────────
                const MonoLabel('Subscription'),
                const SizedBox(height: 10),
                ...PaystackService.plans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlanCard(
                    plan: plan,
                    isActive: _currentPlan == plan.id,
                    onSubscribe: plan.amountKobo == 0 ? null : () => _subscribe(plan),
                  ),
                )),

                const SizedBox(height: 20),

                // ── Account settings ──────────────────────────────
                const MonoLabel('Account'),
                const SizedBox(height: 10),
                _SettingsItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () => _showEditProfile(context, auth.user),
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.security_outlined,
                  label: 'Privacy & Data',
                  sub: 'Your data stays private',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.delete_outline,
                  label: 'Delete Account',
                  color: AppColors.error,
                  onTap: () => _confirmDelete(context),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('SIGN OUT',
                        style: TextStyle(fontSize: 10, letterSpacing: 2,
                            fontWeight: FontWeight.w700)),
                    onPressed: () => auth.signOut(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: MonoLabel('Argentum AI v1.0.0 · From Notes to Mastery.', fontSize: 7)),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Future<void> _subscribe(Plan plan) async {
    final success = await _paystack.subscribe(context, plan);
    if (!mounted) return;
    if (success) {
      setState(() => _currentPlan = plan.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${plan.name} activated!'),
        backgroundColor: AppColors.success,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Payment cancelled or failed.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _showEditProfile(BuildContext context, UserModel? user) {
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Edit Profile', style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: const TextStyle(color: AppColors.textDim, fontSize: 11),
              filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Save Changes',
            onPressed: () async {
              await _api.updateProfile(name: nameCtrl.text.trim());
              Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Delete Account?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            'All your data, questions, and progress will be permanently deleted.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.blue))),
          TextButton(
            onPressed: () async {
              await _api.deleteAccount();
              if (ctx.mounted) Navigator.pop(ctx);
              context.read<ap.AuthProvider>().signOut();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final Map<String, dynamic>? stats;
  final String currentPlan;
  const _ProfileCard({this.user, this.stats, required this.currentPlan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blueDarker.withOpacity(0.6), AppColors.surface],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.blue.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.blue.withOpacity(0.15),
          child: Text(
            (user?.displayName ?? 'S')[0].toUpperCase(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                color: AppColors.blue),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.displayName ?? 'Student',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(user?.email ?? '',
              style: const TextStyle(fontSize: 10, color: AppColors.textDim,
                  fontFamily: 'monospace')),
          const SizedBox(height: 6),
          Row(children: [
            _PlanBadge(currentPlan),
            const SizedBox(width: 8),
            if (stats != null)
              MonoLabel(stats!['rank_label'] as String? ?? '', color: AppColors.blue, fontSize: 7),
          ]),
        ])),
      ]),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String plan;
  const _PlanBadge(this.plan);

  @override
  Widget build(BuildContext context) {
    final color = plan == 'elite' ? AppColors.warning
        : plan == 'pro' ? AppColors.blue : AppColors.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: MonoLabel(plan.toUpperCase(), color: color, fontSize: 7),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isActive;
  final VoidCallback? onSubscribe;
  const _PlanCard({required this.plan, required this.isActive, this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    final isPopular = plan.isPopular;
    final borderColor = isActive
        ? AppColors.success
        : isPopular
            ? AppColors.blue.withOpacity(0.3)
            : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(plan.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary, letterSpacing: 1)),
          const Spacer(),
          if (isPopular && !isActive)
            const ArgTag('POPULAR', color: AppColors.blue),
          if (isActive)
            const ArgTag('ACTIVE', color: AppColors.success),
        ]),
        const SizedBox(height: 4),
        Text(plan.price,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900,
                color: isActive ? AppColors.success : AppColors.textPrimary,
                fontFamily: 'monospace')),
        const SizedBox(height: 10),
        ...plan.features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Icon(Icons.check_circle_outline, size: 12,
                color: isActive ? AppColors.success : AppColors.blue),
            const SizedBox(width: 6),
            Text(f, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        )),
        if (onSubscribe != null && !isActive) ...[
          const SizedBox(height: 12),
          PrimaryButton(label: 'Subscribe · ${plan.price}', onPressed: onSubscribe),
        ],
      ]),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final Color? color;
  final VoidCallback onTap;
  const _SettingsItem({
    required this.icon, required this.label,
    this.sub, this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w600)),
            if (sub != null) ...[
              const SizedBox(height: 2),
              MonoLabel(sub!, fontSize: 8),
            ],
          ])),
          Icon(Icons.chevron_right, color: AppColors.textDim, size: 16),
        ]),
      ),
    );
  }
}

// deleteAccount() is defined in api_service.dart as ApiServiceAccount extension