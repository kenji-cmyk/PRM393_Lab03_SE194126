import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'report_service.dart';

const maxFirestoreReportBytes = 5 * 1024 * 1024;
const firestoreReportChunkBytes = 256 * 1024;
const maxFirestoreReportChunks = 20;

class StoredReportMetadata {
  const StoredReportMetadata({required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;
}

/// Storage seam for deterministic owner, cancellation and integrity tests.
abstract interface class PrivateReportStore {
  String createId();
  Future<void> save(
    String uid,
    String id,
    List<Uint8List> chunks,
    int sizeBytes,
  );
  Future<Map<String, dynamic>?> readMetadata(String uid, String id);
  Future<Map<String, dynamic>?> readChunk(String uid, String id, int index);
  Future<List<StoredReportMetadata>> listMetadata(String uid);
}

class FirebasePrivateReportStore implements PrivateReportStore {
  FirebasePrivateReportStore(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _reports(String uid) =>
      firestore.collection('users').doc(uid).collection('reports');

  @override
  String createId() => firestore.collection('_reportIds').doc().id;

  @override
  Future<void> save(
    String uid,
    String id,
    List<Uint8List> chunks,
    int sizeBytes,
  ) async {
    final report = _reports(uid).doc(id);
    final batch = firestore.batch();
    batch.set(report, {
      'id': id,
      'version': 1,
      'contentType': 'application/pdf',
      'sizeBytes': sizeBytes,
      'chunkSize': firestoreReportChunkBytes,
      'chunkCount': chunks.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
    for (var index = 0; index < chunks.length; index++) {
      batch.set(report.collection('chunks').doc('$index'), {
        'index': index,
        'data': Blob(chunks[index]),
      });
    }
    // At most 21 writes / 5 MiB raw payload, below the 10 MiB commit limit.
    await batch.commit();
  }

  @override
  Future<Map<String, dynamic>?> readMetadata(String uid, String id) async =>
      (await _reports(uid).doc(id).get(const GetOptions(source: Source.server)))
          .data();

  @override
  Future<Map<String, dynamic>?> readChunk(
    String uid,
    String id,
    int index,
  ) async =>
      (await _reports(uid)
              .doc(id)
              .collection('chunks')
              .doc('$index')
              .get(const GetOptions(source: Source.server)))
          .data();

  @override
  Future<List<StoredReportMetadata>> listMetadata(String uid) async {
    final snapshot = await _reports(uid)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get(const GetOptions(source: Source.server));
    return [
      for (final document in snapshot.docs)
        StoredReportMetadata(id: document.id, data: document.data()),
    ];
  }
}

/// Private PDF archive using only Firebase Auth and Firestore Spark.
///
/// A committed write cannot be canceled by the Firestore client. Cancellation
/// discards its result; the complete private report may still be saved. Another
/// upload is blocked until the original commit settles, including after timeout.
class FirestoreReportService implements ReportService, ReportArchive {
  FirestoreReportService({
    required this.uid,
    required this.currentUserId,
    PrivateReportStore? store,
    FirebaseFirestore? firestore,
    ReportService? pdf,
    this.timeout = const Duration(seconds: 30),
  }) : _store =
           store ??
           FirebasePrivateReportStore(firestore ?? FirebaseFirestore.instance),
       _pdf = pdf ?? PdfReportService();

  final String uid;
  final String? Function() currentUserId;
  final PrivateReportStore _store;
  final ReportService _pdf;
  final Duration timeout;
  Future<void>? _pendingUpload;
  int _generation = 0;

  static final _idPattern = RegExp(r'^[A-Za-z0-9]{20}$');

  void _requireOwner() {
    if (uid.isEmpty ||
        uid.length > 128 ||
        uid.trim() != uid ||
        RegExp(r'[\s/\x00-\x1f\x7f]').hasMatch(uid) ||
        currentUserId() != uid) {
      throw const ReportStorageException(
        'Phiên đăng nhập đã thay đổi. Vui lòng mở lại báo cáo.',
      );
    }
  }

  void _requireCurrent(int generation) {
    _requireOwner();
    if (generation != _generation) throw const ReportCancelled();
  }

  bool _isPdf(List<int> bytes) =>
      bytes.length >= 5 &&
      bytes[0] == 37 &&
      bytes[1] == 80 &&
      bytes[2] == 68 &&
      bytes[3] == 70 &&
      bytes[4] == 45;

  UploadedReport _locator(String id) => UploadedReport(
    path: 'users/$uid/reports/$id',
    storageUri: 'firestore://users/$uid/reports/$id',
  );

  String _reportId(UploadedReport report) {
    final prefix = 'users/$uid/reports/';
    if (!report.path.startsWith(prefix)) {
      throw const ReportStorageException(
        'Báo cáo không thuộc tài khoản hiện tại.',
      );
    }
    final id = report.path.substring(prefix.length);
    if (!_idPattern.hasMatch(id) ||
        report.storageUri != 'firestore://${report.path}') {
      throw const ReportStorageException('Vị trí báo cáo không hợp lệ.');
    }
    return id;
  }

  @override
  Future<Uint8List> generate(ReportData data) async {
    _requireOwner();
    final generation = _generation;
    final bytes = await _pdf.generate(data);
    _requireCurrent(generation);
    if (bytes.length > maxFirestoreReportBytes) {
      throw const ReportStorageException(
        'Báo cáo vượt giới hạn 5 MiB. Hãy giảm số bữa ăn trong báo cáo.',
      );
    }
    return bytes;
  }

  @override
  Future<UploadedReport> upload(
    Uint8List bytes,
    void Function(double) progress,
  ) async {
    _requireOwner();
    if (_pendingUpload != null) {
      throw const ReportStorageException(
        'Báo cáo trước vẫn đang được xử lý. Vui lòng đợi rồi thử lại.',
      );
    }
    if (bytes.length > maxFirestoreReportBytes || !_isPdf(bytes)) {
      throw const ReportStorageException(
        'PDF không hợp lệ hoặc vượt giới hạn 5 MiB.',
      );
    }
    final generation = ++_generation;
    final id = _store.createId();
    if (!_idPattern.hasMatch(id)) {
      throw const ReportStorageException(
        'Không tạo được mã báo cáo. Vui lòng thử lại.',
      );
    }
    final copied = Uint8List.fromList(bytes);
    final chunks = <Uint8List>[
      for (
        var start = 0;
        start < copied.length;
        start += firestoreReportChunkBytes
      )
        Uint8List.sublistView(
          copied,
          start,
          (start + firestoreReportChunkBytes).clamp(0, copied.length),
        ),
    ];
    _requireCurrent(generation);
    progress(0);
    _requireCurrent(generation);
    final operation = _store.save(uid, id, chunks, copied.length);
    _pendingUpload = operation;
    void settled() {
      if (identical(_pendingUpload, operation)) _pendingUpload = null;
    }

    // Keep a handler attached even when timeout/cancel discards the result.
    unawaited(
      operation.then<void>(
        (_) => settled(),
        onError: (Object _, StackTrace _) => settled(),
      ),
    );
    try {
      await operation.timeout(timeout);
      _requireCurrent(generation);
      progress(1);
      _requireCurrent(generation);
      return _locator(id);
    } on TimeoutException {
      throw const ReportStorageException(
        'Chưa xác nhận được lưu báo cáo. Yêu cầu đã gửi có thể vẫn hoàn tất; hãy kiểm tra lịch sử trước khi thử lại.',
      );
    }
  }

  _Manifest _manifest(String id, Map<String, dynamic>? data) {
    const keys = {
      'id',
      'version',
      'contentType',
      'sizeBytes',
      'chunkSize',
      'chunkCount',
      'createdAt',
    };
    if (!_idPattern.hasMatch(id) ||
        data == null ||
        data.keys.toSet().difference(keys).isNotEmpty ||
        data.keys.length != keys.length ||
        data['id'] != id ||
        data['version'] is! int ||
        data['version'] != 1 ||
        data['contentType'] != 'application/pdf' ||
        data['chunkSize'] is! int ||
        data['chunkSize'] != firestoreReportChunkBytes ||
        data['sizeBytes'] is! int ||
        data['chunkCount'] is! int ||
        data['createdAt'] is! Timestamp) {
      throw const ReportStorageException('Báo cáo lưu trữ không hợp lệ.');
    }
    final size = data['sizeBytes'] as int;
    final count = data['chunkCount'] as int;
    if (size < 5 ||
        size > maxFirestoreReportBytes ||
        count < 1 ||
        count > maxFirestoreReportChunks ||
        count !=
            (size + firestoreReportChunkBytes - 1) ~/
                firestoreReportChunkBytes) {
      throw const ReportStorageException(
        'Kích thước báo cáo lưu trữ không hợp lệ.',
      );
    }
    return _Manifest(size, count, (data['createdAt'] as Timestamp).toDate());
  }

  @override
  Future<Uint8List> download(UploadedReport report) async {
    _requireOwner();
    final generation = _generation;
    final id = _reportId(report);
    try {
      final metadata = await _store.readMetadata(uid, id).timeout(timeout);
      _requireCurrent(generation);
      final manifest = _manifest(id, metadata);
      final chunks = await Future.wait([
        for (var index = 0; index < manifest.chunkCount; index++)
          _readChunk(id, index, generation),
      ]).timeout(timeout);
      _requireCurrent(generation);
      final result = Uint8List(manifest.sizeBytes);
      var offset = 0;
      for (var index = 0; index < chunks.length; index++) {
        final data = chunks[index];
        if (data == null ||
            data.length != 2 ||
            data['index'] is! int ||
            data['index'] != index ||
            data['data'] is! Blob) {
          throw const ReportStorageException(
            'Báo cáo thiếu dữ liệu hoặc đã bị thay đổi.',
          );
        }
        final bytes = (data['data'] as Blob).bytes;
        final expected = index == chunks.length - 1
            ? manifest.sizeBytes - index * firestoreReportChunkBytes
            : firestoreReportChunkBytes;
        if (bytes.length != expected) {
          throw const ReportStorageException('Dữ liệu PDF không đầy đủ.');
        }
        result.setRange(offset, offset + bytes.length, bytes);
        offset += bytes.length;
      }
      if (!_isPdf(result)) {
        throw const ReportStorageException(
          'Dữ liệu lưu trữ không phải PDF hợp lệ.',
        );
      }
      _requireCurrent(generation);
      return result;
    } on TimeoutException {
      throw const ReportStorageException(
        'Tải báo cáo quá lâu. Hãy kiểm tra kết nối và thử lại.',
      );
    }
  }

  Future<Map<String, dynamic>?> _readChunk(
    String id,
    int index,
    int generation,
  ) async {
    _requireCurrent(generation);
    final chunk = await _store.readChunk(uid, id, index);
    _requireCurrent(generation);
    return chunk;
  }

  @override
  Future<List<SavedReport>> listRecent() async {
    _requireOwner();
    final generation = _generation;
    try {
      final documents = await _store.listMetadata(uid).timeout(timeout);
      _requireCurrent(generation);
      final reports = <SavedReport>[];
      for (final document in documents.take(10)) {
        try {
          final metadata = _manifest(document.id, document.data);
          reports.add(
            SavedReport(
              report: _locator(document.id),
              createdAt: metadata.createdAt,
              sizeBytes: metadata.sizeBytes,
            ),
          );
        } on ReportStorageException {
          // A malformed legacy document is not an openable PDF report.
        }
      }
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(reports);
    } on TimeoutException {
      throw const ReportStorageException(
        'Chưa tải được lịch sử báo cáo. Hãy kiểm tra kết nối và thử lại.',
      );
    }
  }

  @override
  Future<void> cancel() async {
    ++_generation;
  }

  @override
  Future<void> open(Uint8List bytes) async {
    _requireOwner();
    await _pdf.open(bytes);
    _requireOwner();
  }
}

class _Manifest {
  const _Manifest(this.sizeBytes, this.chunkCount, this.createdAt);
  final int sizeBytes;
  final int chunkCount;
  final DateTime createdAt;
}
