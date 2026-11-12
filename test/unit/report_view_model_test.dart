import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetalife/models/habit_goal.dart';
import 'package:vetalife/models/lesson.dart';
import 'package:vetalife/models/meal.dart';
import 'package:vetalife/models/user_profile.dart';
import 'package:vetalife/services/report_service.dart';
import 'package:vetalife/viewmodels/report_view_model.dart';

ReportData _data() => ReportData(
  profile: UserProfile(
    displayName: 'Nguyễn Ánh',
    birthDate: DateTime(2000, 2, 29),
    weightKg: 60,
    heightCm: 170,
    goal: HabitGoal.readDaily,
  ),
  meals: const [],
  progress: const [],
);

class _Reports implements ReportService {
  int uploads = 0;
  int downloads = 0;
  int opened = 0;
  int cancellations = 0;
  bool fail = false;
  Completer<UploadedReport>? pending;
  final bytes = Uint8List.fromList([37, 80, 68, 70]);
  @override
  Future<Uint8List> generate(ReportData data) async => bytes;
  @override
  Future<UploadedReport> upload(
    Uint8List bytes,
    void Function(double) progress,
  ) async {
    uploads++;
    progress(.5);
    if (fail) throw StateError('offline');
    if (pending != null) return pending!.future;
    return const UploadedReport(
      path: 'reports/owner/1.pdf',
      storageUri: 'gs://bucket/reports/owner/1.pdf',
    );
  }

  @override
  Future<void> cancel() async {
    cancellations++;
  }

  @override
  Future<Uint8List> download(UploadedReport report) async {
    downloads++;
    return bytes;
  }

  @override
  Future<void> open(Uint8List bytes) async {
    opened++;
  }
}

SavedReport _saved(String id) => SavedReport(
  report: UploadedReport(
    path: 'users/owner/reports/$id',
    storageUri: 'firestore://users/owner/reports/$id',
  ),
  createdAt: DateTime.utc(2026, 11, 12, 8, 30),
  sizeBytes: 4096,
);

class _ArchiveReports extends _Reports implements ReportArchive {
  int listings = 0;
  bool failHistory = false;
  List<SavedReport> reports = [_saved('one')];
  final List<Completer<List<SavedReport>>> queuedHistory = [];
  Completer<Uint8List>? pendingDownload;
  ReportStorageException? uploadFailure;

  @override
  Future<UploadedReport> upload(
    Uint8List bytes,
    void Function(double) progress,
  ) async {
    if (uploadFailure != null) throw uploadFailure!;
    return super.upload(bytes, progress);
  }

  @override
  Future<List<SavedReport>> listRecent() async {
    listings++;
    if (failHistory) throw StateError('offline');
    if (queuedHistory.isNotEmpty) return queuedHistory.removeAt(0).future;
    return reports;
  }

  @override
  Future<Uint8List> download(UploadedReport report) async {
    downloads++;
    return pendingDownload == null ? bytes : pendingDownload!.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'uncertain save preserves safe storage explanation and refreshes archive',
    () async {
      const explanation =
          'Chưa xác nhận được lưu báo cáo. Yêu cầu đã gửi có thể vẫn được lưu.';
      final service = _ArchiveReports()
        ..uploadFailure = const ReportStorageException(explanation);
      final vm = ReportViewModel(
        service: service,
        snapshot: () async => _data(),
        isPreview: false,
      );
      await vm.generate();
      await Future<void>.delayed(Duration.zero);
      expect(vm.errorMessage, explanation);
      expect(vm.uploaded, isNull);
      expect(vm.canOpen, isFalse);
      expect(service.listings, 1);
      expect(vm.history, hasLength(1));
      vm.dispose();
    },
  );
  test('cloud archive loads, reports load errors separately and refreshes after save', () async {
    final service = _ArchiveReports();
    final vm = ReportViewModel(
      service: service,
      snapshot: () async => _data(),
      isPreview: false,
    );
    await vm.loadHistory();
    expect(vm.history.single.report.path, endsWith('/one'));
    service.failHistory = true;
    await vm.loadHistory();
    expect(vm.historyError, isNotNull);
    expect(vm.errorMessage, isNull);
    expect(vm.history.length, 1);
    service.failHistory = false;
    service.reports = [_saved('two')];
    await vm.generate();
    await Future<void>.delayed(Duration.zero);
    expect(vm.history.single.report.path, endsWith('/two'));
    expect(vm.historyError, isNull);
    expect(service.listings, 3);
    vm.dispose();
  });
  test(
    'preview does not request cloud archive even when service supports it',
    () async {
      final service = _ArchiveReports();
      final vm = ReportViewModel(
        service: service,
        snapshot: () async => _data(),
        isPreview: true,
      );
      await vm.loadHistory();
      await vm.generate();
      expect(vm.supportsHistory, isFalse);
      expect(service.listings, 0);
      vm.dispose();
    },
  );
  test(
    'newer archive response wins and disposal clears late private results',
    () async {
      final first = Completer<List<SavedReport>>();
      final second = Completer<List<SavedReport>>();
      final service = _ArchiveReports()..queuedHistory.addAll([first, second]);
      final vm = ReportViewModel(
        service: service,
        snapshot: () async => _data(),
        isPreview: false,
      );
      final oldRequest = vm.loadHistory();
      final newRequest = vm.loadHistory();
      second.complete([_saved('new')]);
      await newRequest;
      first.complete([_saved('old')]);
      await oldRequest;
      expect(vm.history.single.report.path, endsWith('/new'));
      final late = Completer<List<SavedReport>>();
      service.queuedHistory.add(late);
      final pending = vm.loadHistory();
      vm.dispose();
      late.complete([_saved('private')]);
      await pending;
      expect(vm.history, isEmpty);
    },
  );
  test(
    'opening saved PDF blocks generation and ignores download after disposal',
    () async {
      final service = _ArchiveReports()
        ..pendingDownload = Completer<Uint8List>();
      final vm = ReportViewModel(
        service: service,
        snapshot: () async => _data(),
        isPreview: false,
      );
      await vm.loadHistory();
      final opening = vm.openSaved(vm.history.single);
      expect(vm.isOpening, isTrue);
      await vm.generate();
      await vm.openSaved(vm.history.single);
      expect(service.uploads, 0);
      expect(service.downloads, 1);
      vm.dispose();
      service.pendingDownload!.complete(service.bytes);
      await opening;
      expect(service.opened, 0);
    },
  );
  test('cloud cancellation states possible late save and discards late upload success', () async {
    final service = _ArchiveReports()..pending = Completer<UploadedReport>();
    final vm = ReportViewModel(
      service: service,
      snapshot: () async => _data(),
      isPreview: false,
    );
    final operation = vm.generate();
    await Future<void>.delayed(Duration.zero);
    await vm.cancel();
    expect(vm.message, contains('có thể vẫn được lưu'));
    service.pending!.complete(
      const UploadedReport(path: 'late', storageUri: 'late'),
    );
    await operation;
    expect(vm.uploaded, isNull);
    expect(vm.canOpen, isFalse);
    vm.dispose();
  });
  test('preview generates and opens locally without cloud upload', () async {
    final service = _Reports();
    final vm = ReportViewModel(
      service: service,
      snapshot: () async => _data(),
      isPreview: true,
    );
    await vm.generate();
    expect(vm.canOpen, isTrue);
    expect(vm.uploaded, isNull);
    expect(service.uploads, 0);
    await vm.open();
    expect(service.downloads, 0);
    expect(service.opened, 1);
    vm.dispose();
  });
  test(
    'cloud open downloads with authentication and emits successful events',
    () async {
      final service = _Reports();
      final events = <String>[];
      final vm = ReportViewModel(
        service: service,
        snapshot: () async => _data(),
        isPreview: false,
        onEvent: events.add,
      );
      await vm.generate();
      expect(vm.uploaded?.storageUri, startsWith('gs://'));
      expect(vm.progress, .5);
      await vm.open();
      expect(service.downloads, 1);
      expect(events, ['report_generated', 'report_uploaded', 'report_opened']);
      vm.dispose();
    },
  );
  test(
    'failed upload shows error and permits retry without stale success',
    () async {
      final service = _Reports()..fail = true;
      final vm = ReportViewModel(
        service: service,
        snapshot: () async => _data(),
        isPreview: false,
      );
      await vm.generate();
      expect(vm.errorMessage, isNotNull);
      expect(vm.canOpen, isFalse);
      expect(vm.uploaded, isNull);
      service.fail = false;
      await vm.generate();
      expect(vm.errorMessage, isNull);
      expect(vm.canOpen, isTrue);
      vm.dispose();
    },
  );
  test('cancel while snapshot loads prevents generation and upload', () async {
    final service = _Reports();
    final snapshot = Completer<ReportData>();
    final vm = ReportViewModel(
      service: service,
      snapshot: () => snapshot.future,
      isPreview: false,
    );
    final operation = vm.generate();
    await vm.cancel();
    snapshot.complete(_data());
    await operation;
    expect(service.uploads, 0);
    expect(vm.canOpen, isFalse);
    expect(vm.isBusy, isFalse);
    vm.dispose();
  });
  test('dispose and cancellation ignore late upload responses', () async {
    final service = _Reports()..pending = Completer<UploadedReport>();
    final vm = ReportViewModel(
      service: service,
      snapshot: () async => _data(),
      isPreview: false,
    );
    final operation = vm.generate();
    await Future<void>.delayed(Duration.zero);
    expect(service.uploads, 1);
    vm.dispose();
    service.pending!.complete(
      const UploadedReport(path: 'old-owner', storageUri: 'gs://old-owner'),
    );
    await operation;
    expect(vm.uploaded, isNull);
    expect(vm.canOpen, isFalse);
    expect(service.cancellations, 1);
  });
  test('duplicate requests do not upload twice', () async {
    final service = _Reports()..pending = Completer<UploadedReport>();
    final vm = ReportViewModel(
      service: service,
      snapshot: () async => _data(),
      isPreview: false,
    );
    final operation = vm.generate();
    await Future<void>.delayed(Duration.zero);
    await vm.generate();
    expect(service.uploads, 1);
    service.pending!.complete(
      const UploadedReport(path: 'owner', storageUri: 'gs://owner'),
    );
    await operation;
    vm.dispose();
  });
  test(
    'PDF generation loads bundled Vietnamese fonts and real empty state',
    () async {
      // Flutter test replaces font assets with empty buffers by default.
      // Exercise the actual repository font bytes used by the PDF renderer.
      final service = PdfReportService(
        now: () => DateTime(2026, 11, 9),
        loadFont: (path) => SynchronousFuture(
          ByteData.sublistView(File(path).readAsBytesSync()),
        ),
      );
      final bytes = await service.generate(_data());
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(bytes.length, greaterThan(1000));
      expect(bytes.length, lessThan(maxReportBytes));
      if (const bool.fromEnvironment('REPORT_PDF_QA')) {
        final example = ReportData(
          profile: _data().profile,
          meals: List.generate(
            35,
            (i) => MealRecord(
              id: 'qa_$i',
              draft: MealDraft(
                id: 'qa_$i',
                name: 'Đậu hũ, rau xanh và gạo lứt — bữa ăn mẫu ${i + 1}',
                mealType: MealType.lunch,
                eatenAt: DateTime(2026, 11, 9).subtract(Duration(days: i)),
                ingredients: List.generate(
                  6,
                  (n) => MealIngredient(
                    name: 'Rau xanh và đậu hũ loại ${n + 1}',
                    amount: 'Một phần vừa',
                    preparation: 'Hấp, luộc, thêm ít gia vị sau khi nấu',
                  ),
                ),
              ),
              analysis: MealAnalysis(
                title: 'Mẫu kiểm tra bố cục',
                summary: '',
                highlights: const [],
                improvements: const [],
                profileNote: '',
                limitations: const [],
                references: const [],
                healthConnections: const [],
                mode: 'localBook',
              ),
              savedAt: DateTime(2026, 11, 9),
            ),
          ),
          progress: [
            LessonReadProgress(
              lessonId: 'p1-ch01',
              readAt: DateTime.utc(2026, 11, 9),
            ),
          ],
        );
        final output = File('tmp/pdfs/report-preview.pdf');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(await service.generate(example));
      }
    },
  );
  test(
    'unauthenticated and switched accounts cannot upload or download',
    () async {
      var current = 'owner';
      final service = PdfReportService(
        uid: 'owner',
        currentUserId: () => current,
      );
      current = 'other';
      await expectLater(service.upload(Uint8List(1), (_) {}), throwsStateError);
      await expectLater(
        service.download(
          const UploadedReport(
            path: 'reports/owner/1.pdf',
            storageUri: 'gs://bucket/path',
          ),
        ),
        throwsStateError,
      );
    },
  );
}
