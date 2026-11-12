import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/services/firestore_report_service.dart';
import 'package:vetalife/services/report_service.dart';

const _id = 'abcdefghijklmnopqrst';

Uint8List _pdf([int size = 32]) {
  final bytes = Uint8List(size);
  bytes.setRange(0, 5, [37, 80, 68, 70, 45]);
  return bytes;
}

class _Store implements PrivateReportStore {
  Map<String, dynamic>? metadata;
  final chunks = <int, Map<String, dynamic>>{};
  List<StoredReportMetadata>? listed;
  final reads = <String>[];
  final writes = <String>[];
  Completer<void>? savePending;
  Completer<Map<String, dynamic>?>? metadataPending;
  Completer<List<StoredReportMetadata>>? listPending;
  int saves = 0;

  @override
  String createId() => _id;

  @override
  Future<void> save(
    String uid,
    String id,
    List<Uint8List> parts,
    int sizeBytes,
  ) async {
    saves++;
    writes.add(uid);
    metadata = {
      'id': id,
      'version': 1,
      'contentType': 'application/pdf',
      'sizeBytes': sizeBytes,
      'chunkSize': firestoreReportChunkBytes,
      'chunkCount': parts.length,
      'createdAt': Timestamp.fromDate(DateTime(2026, 11, 12)),
    };
    for (var index = 0; index < parts.length; index++) {
      chunks[index] = {'index': index, 'data': Blob(parts[index])};
    }
    if (savePending != null) await savePending!.future;
  }

  @override
  Future<Map<String, dynamic>?> readMetadata(String uid, String id) async {
    reads.add('$uid/$id');
    return metadataPending == null ? metadata : await metadataPending!.future;
  }

  @override
  Future<Map<String, dynamic>?> readChunk(
    String uid,
    String id,
    int index,
  ) async {
    reads.add('$uid/$id/$index');
    return chunks[index];
  }

  @override
  Future<List<StoredReportMetadata>> listMetadata(String uid) async {
    reads.add('$uid/list');
    if (listPending != null) return await listPending!.future;
    return listed ??
        [if (metadata != null) StoredReportMetadata(id: _id, data: metadata!)];
  }
}

void main() {
  test('private upload splits PDF, copies input and round-trips only the current owner', () async {
    final store = _Store();
    String? currentUid = 'alice';
    final service = FirestoreReportService(
      uid: 'alice',
      currentUserId: () => currentUid,
      store: store,
    );
    final bytes = _pdf(firestoreReportChunkBytes + 13);
    final values = <double>[];
    final report = await service.upload(bytes, values.add);
    bytes[5] = 255;
    expect(store.metadata!['chunkCount'], 2);
    expect(
      (store.chunks[0]!['data'] as Blob).bytes.length,
      firestoreReportChunkBytes,
    );
    expect((store.chunks[1]!['data'] as Blob).bytes.length, 13);
    expect(report.path, 'users/alice/reports/$_id');
    expect(report.storageUri, 'firestore://users/alice/reports/$_id');
    expect(values, [0, 1]);
    final downloaded = await service.download(report);
    expect(downloaded.length, bytes.length);
    expect(downloaded[5], 0);
    expect(store.writes, ['alice']);
    expect(store.reads.every((path) => path.startsWith('alice/')), isTrue);
    currentUid = 'bob';
    await expectLater(
      service.download(report),
      throwsA(isA<ReportStorageException>()),
    );
  });

  test(
    'invalid, oversized and cross-owner requests never write or read storage',
    () async {
      final store = _Store();
      final service = FirestoreReportService(
        uid: 'alice',
        currentUserId: () => 'alice',
        store: store,
      );
      for (final bytes in [
        Uint8List(0),
        Uint8List(8),
        _pdf(maxFirestoreReportBytes + 1),
      ]) {
        await expectLater(
          service.upload(bytes, (_) {}),
          throwsA(isA<ReportStorageException>()),
        );
      }
      expect(store.saves, 0);
      for (final report in [
        const UploadedReport(
          path: 'users/bob/reports/$_id',
          storageUri: 'firestore://users/bob/reports/$_id',
        ),
        const UploadedReport(
          path: 'users/alice/reports/../$_id',
          storageUri: 'firestore://users/alice/reports/../$_id',
        ),
        const UploadedReport(
          path: 'users/alice/reports/$_id',
          storageUri: 'https://attacker.invalid/report',
        ),
      ]) {
        await expectLater(
          service.download(report),
          throwsA(isA<ReportStorageException>()),
        );
      }
      expect(store.reads, isEmpty);
    },
  );

  test('canceled late commit cannot return success or permit a second pending upload', () async {
    final store = _Store()..savePending = Completer<void>();
    final service = FirestoreReportService(
      uid: 'alice',
      currentUserId: () => 'alice',
      store: store,
    );
    final progress = <double>[];
    final first = service.upload(_pdf(), progress.add);
    final canceled = expectLater(first, throwsA(isA<ReportCancelled>()));
    await service.cancel();
    await expectLater(
      service.upload(_pdf(), (_) {}),
      throwsA(isA<ReportStorageException>()),
    );
    expect(store.saves, 1);
    store.savePending!.complete();
    await canceled;
    expect(progress, [0]);
    store.savePending = null;
    await service.upload(_pdf(), (_) {});
    expect(store.saves, 2);
  });

  test(
    'timeout leaves upload locked until its submitted commit settles',
    () async {
      final store = _Store()..savePending = Completer<void>();
      final service = FirestoreReportService(
        uid: 'alice',
        currentUserId: () => 'alice',
        store: store,
        timeout: const Duration(milliseconds: 5),
      );
      await expectLater(
        service.upload(_pdf(), (_) {}),
        throwsA(isA<ReportStorageException>()),
      );
      await expectLater(
        service.upload(_pdf(), (_) {}),
        throwsA(isA<ReportStorageException>()),
      );
      expect(store.saves, 1);
      store.savePending!.complete();
      await Future<void>.delayed(Duration.zero);
      store.savePending = null;
      await service.upload(_pdf(), (_) {});
      expect(store.saves, 2);
    },
  );

  test(
    'switching owner during progress or pending storage prevents stale success',
    () async {
      final store = _Store();
      String? currentUid = 'alice';
      final service = FirestoreReportService(
        uid: 'alice',
        currentUserId: () => currentUid,
        store: store,
      );
      await expectLater(
        service.upload(_pdf(), (_) {
          currentUid = 'bob';
        }),
        throwsA(isA<ReportStorageException>()),
      );
      expect(store.saves, 0);
      currentUid = 'alice';
      store.savePending = Completer<void>();
      final first = service.upload(_pdf(), (_) {});
      final changed = expectLater(
        first,
        throwsA(isA<ReportStorageException>()),
      );
      currentUid = null;
      store.savePending!.complete();
      await changed;
    },
  );

  test(
    'download rejects missing, reordered, oversized and incomplete chunks',
    () async {
      final store = _Store();
      final service = FirestoreReportService(
        uid: 'alice',
        currentUserId: () => 'alice',
        store: store,
      );
      final report = await service.upload(_pdf(), (_) {});
      final valid = Map<String, dynamic>.from(store.chunks[0]!);
      for (final invalid in <Map<String, dynamic>?>[
        null,
        {'index': 1, 'data': Blob(_pdf())},
        {'index': 0.0, 'data': Blob(_pdf())},
        {'index': 0, 'data': Blob(_pdf(31))},
        {'index': 0, 'data': Blob(_pdf(33))},
        {'index': 0, 'data': Uint8List(32)},
        {'index': 0, 'data': Blob(Uint8List(32))},
      ]) {
        if (invalid == null) {
          store.chunks.remove(0);
        } else {
          store.chunks[0] = invalid;
        }
        await expectLater(
          service.download(report),
          throwsA(isA<ReportStorageException>()),
        );
      }
      store.chunks[0] = valid;
      expect(await service.download(report), _pdf());
    },
  );

  test(
    'manifest validation rejects bogus count and size before reading chunks',
    () async {
      final store = _Store();
      final service = FirestoreReportService(
        uid: 'alice',
        currentUserId: () => 'alice',
        store: store,
      );
      final report = await service.upload(_pdf(), (_) {});
      final valid = Map<String, dynamic>.from(store.metadata!);
      for (final patch in [
        {'chunkCount': 21},
        {'chunkCount': 2},
        {'sizeBytes': 0},
        {'sizeBytes': maxFirestoreReportBytes + 1},
        {'id': 'different'},
        {'createdAt': 'not-a-timestamp'},
        {'extra': 'private'},
        {'chunkSize': 1},
        {'version': 1.0},
        {'chunkSize': 262144.0},
      ]) {
        store.metadata = {...valid, ...patch};
        store.reads.clear();
        await expectLater(
          service.download(report),
          throwsA(isA<ReportStorageException>()),
        );
        expect(store.reads, ['alice/$_id']);
      }
    },
  );

  test('history uses owner locators and drops invalid manifests', () async {
    final store = _Store();
    final service = FirestoreReportService(
      uid: 'alice',
      currentUserId: () => 'alice',
      store: store,
    );
    final report = await service.upload(_pdf(), (_) {});
    store.listed = [
      StoredReportMetadata(id: _id, data: store.metadata!),
      const StoredReportMetadata(id: 'malformed', data: {}),
      StoredReportMetadata(
        id: 'ABCDEFGHIJKLMNOPQRST',
        data: {...store.metadata!, 'id': 'not-the-document-id'},
      ),
    ];
    final history = await service.listRecent();
    expect(history.length, 1);
    expect(history.single.report.path, report.path);
    expect(history.single.createdAt, DateTime(2026, 11, 12));
    expect(history.single.sizeBytes, 32);
    expect(store.reads, ['alice/list']);
  });

  test(
    'owner switch during history and metadata reads discards old account data',
    () async {
      final store = _Store();
      String? currentUid = 'alice';
      final service = FirestoreReportService(
        uid: 'alice',
        currentUserId: () => currentUid,
        store: store,
      );
      final report = await service.upload(_pdf(), (_) {});
      store.listPending = Completer<List<StoredReportMetadata>>();
      final history = service.listRecent();
      final staleHistory = expectLater(
        history,
        throwsA(isA<ReportStorageException>()),
      );
      currentUid = 'bob';
      store.listPending!.complete([
        StoredReportMetadata(id: _id, data: store.metadata!),
      ]);
      await staleHistory;
      currentUid = 'alice';
      store.metadataPending = Completer<Map<String, dynamic>?>();
      final download = service.download(report);
      final staleDownload = expectLater(
        download,
        throwsA(isA<ReportStorageException>()),
      );
      currentUid = 'bob';
      store.metadataPending!.complete(store.metadata);
      await staleDownload;
    },
  );
}
