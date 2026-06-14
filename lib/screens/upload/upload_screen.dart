// lib/screens/upload/upload_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  bool _uploading = false;
  String? _uploadError;
  String? _processingFileId;
  String _processingStatus = '';
  late AnimationController _pulseCtrl;
  Timer? _pollTimer;

  static const _allowedExtensions = ['pdf', 'docx', 'pptx', 'ppt', 'jpg', 'jpeg', 'png'];

  static const _fileTypeInfo = {
    'pdf':  (icon: '📄', label: 'PDF Document'),
    'docx': (icon: '📝', label: 'Word Document'),
    'pptx': (icon: '📊', label: 'PowerPoint'),
    'ppt':  (icon: '📊', label: 'PowerPoint'),
    'jpg':  (icon: '🖼', label: 'Image'),
    'jpeg': (icon: '🖼', label: 'Image'),
    'png':  (icon: '🖼', label: 'Image'),
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AppProvider>().loadFiles());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    setState(() { _uploadError = null; });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    if (picked.path == null) return;

    final file = File(picked.path!);
    final sizeMb = await file.length() / (1024 * 1024);
    if (sizeMb > 25) {
      setState(() => _uploadError = 'File too large. Max 25MB.');
      return;
    }

    setState(() => _uploading = true);

    try {
      final data = await _api.uploadFile(file, picked.name);
      final record = UploadedFileRecord.fromJson(data);
      if (!mounted) return;
      context.read<AppProvider>().addFile(record);
      _startPolling(record.id);
      setState(() {
        _uploading = false;
        _processingFileId = record.id;
        _processingStatus = 'Processing your notes…';
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _uploadError = 'Upload failed. Check your connection.';
      });
    }
  }

  void _startPolling(String fileId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final data = await _api.getFileStatus(fileId);
        final status = data['status'] as String;
        final topic = data['topic_name'] as String?;
        final count = data['questions_generated'] as int? ?? 0;

        if (!mounted) return;
        context.read<AppProvider>().updateFileStatus(fileId, status,
            topicName: topic, questionsGenerated: count);

        if (status == 'ready') {
          _pollTimer?.cancel();
          setState(() {
            _processingFileId = null;
            _processingStatus = '';
          });
          _showSuccess(topic ?? 'Your topic', count);
        } else if (status == 'failed') {
          _pollTimer?.cancel();
          setState(() {
            _processingFileId = null;
            _processingStatus = '';
            _uploadError = data['processing_error'] as String? ?? 'Processing failed.';
          });
        } else {
          setState(() {
            _processingStatus = status == 'processing'
                ? 'Generating questions…'
                : 'Analysing content…';
          });
        }
      } catch (_) {}
    });
  }

  void _showSuccess(String topic, int count) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('✅  ', style: TextStyle(fontSize: 16)),
        Expanded(child: Text('$topic · $count questions ready',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
      ]),
      backgroundColor: AppColors.success.withOpacity(0.9),
      duration: const Duration(seconds: 4),
    ));
    context.read<AppProvider>().loadTopics();
  }

  @override
  Widget build(BuildContext context) {
    final files = context.watch<AppProvider>().files;

    return SafeArea(
      child: CustomScrollView(slivers: [
        // ── Header ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const MonoLabel('Step 1 of 2'),
              const SizedBox(height: 4),
              const Text('Upload Notes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text(
                'Upload lecture notes and Argentum AI will generate exam-quality questions automatically.',
                style: TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.6),
              ),
            ]),
          ),
        ),

        // ── Drop Zone ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _uploading || _processingFileId != null ? null : _pickAndUpload,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(
                      color: _processingFileId != null
                          ? AppColors.blue.withOpacity(0.3 + _pulseCtrl.value * 0.3)
                          : AppColors.blue.withOpacity(0.15),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _uploading
                      ? const Center(child: Column(
                          mainAxisSize: MainAxisSize.min, children: [
                            CircularProgressIndicator(color: AppColors.blue, strokeWidth: 2),
                            SizedBox(height: 12),
                            MonoLabel('Uploading…', color: AppColors.blue),
                          ]))
                      : _processingFileId != null
                          ? _ProcessingView(
                              status: _processingStatus,
                              pulseValue: _pulseCtrl.value,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue.withOpacity(0.08),
                                    border: Border.all(color: AppColors.blue.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.upload_file_rounded,
                                      color: AppColors.blue, size: 26),
                                ),
                                const SizedBox(height: 12),
                                const Text('Tap to upload',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                const MonoLabel('PDF · DOCX · PPTX · Images · Max 25MB'),
                              ],
                            ),
                ),
              ),
            ),
          ),
        ),

        // ── Error ────────────────────────────────────────────────
        if (_uploadError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  border: Border.all(color: AppColors.error.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_uploadError!,
                      style: const TextStyle(fontSize: 11, color: AppColors.error,
                          fontFamily: 'monospace'))),
                ]),
              ),
            ),
          ),

        // ── Supported formats chips ──────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Wrap(spacing: 8, runSpacing: 6,
              children: _fileTypeInfo.entries.take(5).map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.value.icon, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 5),
                  MonoLabel(e.value.label, fontSize: 8),
                ]),
              )).toList(),
            ),
          ),
        ),

        // ── Files List ───────────────────────────────────────────
        if (files.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: MonoLabel('Uploaded Files'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FileCard(file: files[i], onDelete: () async {
                  await _api.deleteFile(files[i].id);
                  if (ctx.mounted) ctx.read<AppProvider>().loadFiles();
                }),
              ),
              childCount: files.length,
            )),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ]),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  final String status;
  final double pulseValue;
  const _ProcessingView({required this.status, required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
        width: 52, height: 52,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 52 + pulseValue * 10,
            height: 52 + pulseValue * 10,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.05 + pulseValue * 0.05),
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          const ArgentumLogo(size: 40),
        ]),
      ),
      const SizedBox(height: 12),
      Text(status, style: TextStyle(
          fontSize: 12, color: AppColors.blue.withOpacity(0.8 + pulseValue * 0.2),
          fontFamily: 'monospace', fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const MonoLabel('This may take 30–60 seconds', fontSize: 8),
    ]);
  }
}

class _FileCard extends StatelessWidget {
  final UploadedFileRecord file;
  final VoidCallback onDelete;
  const _FileCard({required this.file, required this.onDelete});

  static const _icons = {
    'pdf':  '📄', 'docx': '📝', 'pptx': '📊',
    'ppt':  '📊', 'image': '🖼',
  };

  Color get _statusColor {
    switch (file.status) {
      case 'ready':      return AppColors.success;
      case 'failed':     return AppColors.error;
      case 'processing':
      case 'uploaded':   return AppColors.warning;
      default:           return AppColors.textDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: _statusColor.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Text(_icons[file.fileType] ?? '📁', style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(file.originalFilename,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Row(children: [
            if (file.topicName != null) ...[
              MonoLabel(file.topicName!, color: AppColors.blue, fontSize: 8),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: MonoLabel(file.status, color: _statusColor, fontSize: 7),
            ),
            if (file.isReady) ...[
              const SizedBox(width: 8),
              MonoLabel('${file.questionsGenerated}Q generated',
                  color: AppColors.success, fontSize: 7),
            ],
          ]),
        ])),
        if (file.isProcessing)
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(color: AppColors.warning, strokeWidth: 1.5),
          )
        else
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 14),
            ),
          ),
      ]),
    );
  }
}
