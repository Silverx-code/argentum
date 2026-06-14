// lib/screens/tutor/tutor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});
  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final _api = ApiService();
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<TutorMessage> _messages = [];
  bool _loading = false;
  String? _lastModelUsed;
  List<Map<String, String>> _history = [];

  static const _quickPrompts = [
    'Explain this topic simply',
    'What exam questions are likely?',
    'Generate 3 harder questions',
    'Summarise my uploaded notes',
    'Why is this concept important?',
    'Connect this to other topics',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _loading) return;

    _controller.clear();
    setState(() {
      _messages.add(TutorMessage(role: 'user', content: text,
          timestamp: DateTime.now()));
      _loading = true;
    });
    _scrollToBottom();

    final prov = context.read<AppProvider>();
    final weakTopics = prov.weaknesses.take(2).map((w) => w.topic).join(', ');

    try {
      final resp = await _api.chatWithTutor(
        message: text,
        topicContext: prov.topics.isNotEmpty ? prov.topics.first.name : null,
        conversationHistory: _history,
      );

      final reply = resp['reply'] as String? ?? 'No response.';
      final model = resp['model_used'] as String? ?? '';

      _history.add({'role': 'user', 'content': text});
      _history.add({'role': 'assistant', 'content': reply});
      if (_history.length > 16) _history = _history.sublist(_history.length - 16);

      setState(() {
        _messages.add(TutorMessage(role: 'ai', content: reply,
            timestamp: DateTime.now()));
        _lastModelUsed = model;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(TutorMessage(
            role: 'ai',
            content: 'Connection error. Please try again.',
            timestamp: DateTime.now()));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(children: [
          const ArgentumLogo(size: 28),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI Tutor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            if (_lastModelUsed != null)
              MonoLabel(
                _lastModelUsed!.contains('gpt-4o-mini') ? 'GPT-4o Mini' : 'GPT-4o · Advanced',
                color: _lastModelUsed!.contains('gpt-4o-mini')
                    ? AppColors.blue : AppColors.warning,
                fontSize: 7,
              ),
          ]),
          const Spacer(),
          if (_messages.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() {
                _messages.clear();
                _history.clear();
                _lastModelUsed = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const MonoLabel('Clear', fontSize: 8),
              ),
            ),
        ]),
      ),
      body: Column(children: [
        // ── Chat area ────────────────────────────────────────────
        Expanded(
          child: _messages.isEmpty
              ? _WelcomeView(onTap: _send)
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _messages.length) return const _TypingBubble();
                    return _ChatBubble(message: _messages[i]);
                  },
                ),
        ),

        // ── Quick prompts ────────────────────────────────────────
        if (_messages.isEmpty)
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _send(_quickPrompts[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.blue.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: MonoLabel(_quickPrompts[i], color: AppColors.blue, fontSize: 8),
                ),
              ),
            ),
          ),

        // ── Input bar ────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.blue.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                maxLines: 3, minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Ask anything about your notes…',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textDim),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _loading ? null : () => _send(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _loading
                      ? AppColors.blueDark.withOpacity(0.3)
                      : AppColors.blueDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.blue.withOpacity(0.4)),
                ),
                child: _loading
                    ? const Center(child: SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 16),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final void Function(String) onTap;
  const _WelcomeView({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ArgentumLogo(size: 60),
          const SizedBox(height: 16),
          const Text('Argentum Tutor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Powered by GPT-4o',
              style: TextStyle(fontSize: 11, color: AppColors.textDim,
                  fontFamily: 'monospace')),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.blue.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(children: [
              _CapabilityRow('📖', 'Explain concepts from your notes'),
              SizedBox(height: 8),
              _CapabilityRow('❓', 'Generate practice questions'),
              SizedBox(height: 8),
              _CapabilityRow('🎯', 'Predict likely exam topics'),
              SizedBox(height: 8),
              _CapabilityRow('🧠', 'Deep explanations via GPT-4o'),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  final String icon, text;
  const _CapabilityRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 14)),
    const SizedBox(width: 10),
    Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

class _ChatBubble extends StatelessWidget {
  final TutorMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const ArgentumLogo(size: 26),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.blueDark.withOpacity(0.6)
                    : AppColors.surface,
                border: Border.all(
                    color: isUser
                        ? AppColors.blue.withOpacity(0.3)
                        : AppColors.border),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 12,
                  color: isUser ? Colors.white : AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        const ArgentumLogo(size: 26),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(
                      0.3 + (i == 1 ? _anim.value * 0.7 : 0)),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
        ),
      ]),
    );
  }
}
