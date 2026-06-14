// lib/services/file_storage_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class UploadedFile {
  final String   id;
  final String   userId;
  final String   fileName;
  final String   fileUrl;
  final String   fileType;
  final int      fileSize;
  final String   storagePath;
  final String   processingStatus;  // pending | processing | done | error
  final int?     questionsGenerated;
  final DateTime uploadedAt;

  const UploadedFile({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.storagePath,
    required this.processingStatus,
    this.questionsGenerated,
    required this.uploadedAt,
  });

  factory UploadedFile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UploadedFile(
      id:                 doc.id,
      userId:             d['userId']             as String,
      fileName:           d['fileName']           as String,
      fileUrl:            d['fileUrl']            as String,
      fileType:           d['fileType']           as String,
      fileSize:           d['fileSize']           as int,
      storagePath:        d['storagePath']        as String,
      processingStatus:   d['processingStatus']   as String,
      questionsGenerated: d['questionsGenerated'] as int?,
      uploadedAt:         (d['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId':             userId,
    'fileName':           fileName,
    'fileUrl':            fileUrl,
    'fileType':           fileType,
    'fileSize':           fileSize,
    'storagePath':        storagePath,
    'processingStatus':   processingStatus,
    'questionsGenerated': questionsGenerated,
    'uploadedAt':         Timestamp.fromDate(uploadedAt),
  };
}

class FileStorageService {
  final FirebaseStorage   _storage = FirebaseStorage.instance;
  final FirebaseFirestore  _db     = FirebaseFirestore.instance;
  final FirebaseAuth       _auth   = FirebaseAuth.instance;
  final _uuid = const Uuid();

  String get _uid => _auth.currentUser!.uid;

  // ── Allowed extensions ─────────────────────────────────────────────────
  static const allowedExtensions = ['pdf', 'pptx', 'ppt', 'docx', 'doc', 'jpg', 'jpeg', 'png'];

  // ── Pick file from device ──────────────────────────────────────────────
  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type:                 FileType.custom,
      allowedExtensions:    allowedExtensions,
      withData:             false,
      withReadStream:       false,
      allowMultiple:        false,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single;
  }

  // ── Upload file to Firebase Storage ───────────────────────────────────
  //
  // Returns a [Stream<UploadTask>] so the UI can show live progress.
  // Call .snapshot to get bytes transferred.
  //
  Future<UploadedFile> uploadFile({
    required PlatformFile   pickedFile,
    required void Function(double progress) onProgress,
  }) async {
    final file        = File(pickedFile.path!);
    final ext         = path.extension(pickedFile.name).toLowerCase().replaceAll('.', '');
    final mimeType    = lookupMimeType(pickedFile.path!) ?? 'application/octet-stream';
    final fileId      = _uuid.v4();
    final storagePath = 'users/$_uid/uploads/$fileId.$ext';

    // 1. Upload to Firebase Storage
    final ref      = _storage.ref(storagePath);
    final metadata = SettableMetadata(
      contentType:  mimeType,
      customMetadata: {
        'originalName': pickedFile.name,
        'uploadedBy':   _uid,
      },
    );

    final task = ref.putFile(file, metadata);

    // Stream progress to UI
    task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    // Wait for upload to complete
    final snapshot = await task;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // 2. Save metadata to Firestore
    final uploadedFile = UploadedFile(
      id:               fileId,
      userId:           _uid,
      fileName:         pickedFile.name,
      fileUrl:          downloadUrl,
      fileType:         ext.toUpperCase(),
      fileSize:         pickedFile.size,
      storagePath:      storagePath,
      processingStatus: 'pending',
      uploadedAt:       DateTime.now(),
    );

    await _db.collection('files').doc(fileId).set(uploadedFile.toFirestore());

    return uploadedFile;
  }

  // ── Get all files for current user ────────────────────────────────────
  Stream<List<UploadedFile>> getUserFiles() {
    return _db
        .collection('files')
        .where('userId', isEqualTo: _uid)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(UploadedFile.fromFirestore).toList());
  }

  // ── Delete file ────────────────────────────────────────────────────────
  Future<void> deleteFile(UploadedFile file) async {
    // Delete from Storage
    await _storage.ref(file.storagePath).delete();
    // Delete metadata from Firestore
    await _db.collection('files').doc(file.id).delete();
  }

  // ── Get total storage used (bytes) ────────────────────────────────────
  Future<int> getTotalStorageUsed() async {
    final snap = await _db
        .collection('files')
        .where('userId', isEqualTo: _uid)
        .get();
    return snap.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['fileSize'] as int?) ?? 0),
    );
  }

  // ── Format file size for display ──────────────────────────────────────
  static String formatFileSize(int bytes) {
    if (bytes < 1024)                  return '${bytes} B';
    if (bytes < 1024 * 1024)           return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
